#!/usr/bin/env python3
"""
Model a complete problem-solving session with cleaned data showing database structure.
Allows user to select from multiple problems.
"""

import pandas as pd
from pathlib import Path
import json

def clean_value(val):
    """Clean and format values for display."""
    if pd.isna(val) or val == '' or val == 'nan':
        return None
    val_str = str(val).strip()
    if val_str.startswith("'"):
        val_str = val_str[1:]
    return val_str if val_str else None

def extract_available_problems(df):
    """Extract available problems with their details."""
    # Find all unique problem/student/session combinations
    # Include START problems too, but prioritize actual problems
    problem_data = df[
        (df['Problem Name'].notna()) & 
        (df['Anon Student Id'].notna()) &
        (df['Session Id'].notna())
    ].copy()
    
    if len(problem_data) == 0:
        return []
    
    # Group by problem and get unique problems with student/session info
    problems = []
    seen = set()
    
    for _, row in problem_data.iterrows():
        problem_name = clean_value(row.get('Problem Name'))
        student_id = clean_value(row.get('Anon Student Id'))
        session_id = clean_value(row.get('Session Id'))
        kc_problem = clean_value(row.get('KC (Problem)'))
        
        if not problem_name or not student_id or not session_id:
            continue
        
        key = (problem_name, student_id, session_id)
        if key not in seen:
            seen.add(key)
            # Count transactions for this problem
            tx_count = len(df[
                (df['Problem Name'] == problem_name) &
                (df['Anon Student Id'] == student_id) &
                (df['Session Id'] == session_id)
            ])
            
            # Only include if has reasonable number of transactions
            if tx_count >= 5:
                problems.append({
                    'problem_name': problem_name,
                    'student_id': student_id,
                    'session_id': session_id,
                    'kc_problem': kc_problem,
                    'transaction_count': tx_count,
                })
    
    # Separate actual problems from START
    actual_problems = [p for p in problems if p['problem_name'] != 'START']
    start_problems = [p for p in problems if p['problem_name'] == 'START']
    
    # Sort each group by transaction count
    actual_problems.sort(key=lambda x: x['transaction_count'], reverse=True)
    start_problems.sort(key=lambda x: x['transaction_count'], reverse=True)
    
    # Combine: actual problems first, then START problems
    combined = actual_problems[:7] + start_problems[:3]  # 7 actual + 3 START = 10 total
    return combined[:10]

def extract_problem_session(df, problem_name, student_id, session_id):
    """Extract a complete problem-solving session for specific problem."""
    problem_sessions = df[
        (df['Problem Name'] == problem_name) &
        (df['Anon Student Id'] == student_id) &
        (df['Session Id'] == session_id)
    ].head(50).copy()
    
    return problem_sessions

def create_database_model(session_data):
    """Create a cleaned database model."""
    
    # Extract unique entities
    student_id = session_data.iloc[0]['Anon Student Id']
    session_id = session_data.iloc[0]['Session Id']
    problem_name = None
    problem_kc = None
    
    # Find the actual problem (not START)
    for _, row in session_data.iterrows():
        pname = clean_value(row.get('Problem Name'))
        if pname and pname != 'START':
            problem_name = pname
            problem_kc = clean_value(row.get('KC (Problem)'))
            break
    
    if not problem_name:
        problem_name = 'START'
    
    # Build nodes
    nodes = {
        'Student': {
            'id': student_id,
            'properties': {
                'student_id': student_id,
                'school': clean_value(session_data.iloc[0].get('School')),
                'class': clean_value(session_data.iloc[0].get('Class')),
            }
        },
        'Session': {
            'id': session_id,
            'properties': {
                'session_id': session_id,
                'start_time': clean_value(session_data.iloc[0].get('Problem Start Time')),
                'timezone': clean_value(session_data.iloc[0].get('Time Zone')),
            }
        },
        'Problem': {
            'id': problem_name,
            'properties': {
                'problem_name': problem_name,
                'kc_problem': problem_kc,
                'kc_category': clean_value(session_data.iloc[0].get('KC Category (Problem)')),
                'course': clean_value(session_data.iloc[0].get('Level (Course)')),
            }
        }
    }
    
    # Build transactions (edges) with cleaned data
    transactions = []
    steps_seen = set()
    
    for idx, row in session_data.iterrows():
        transaction_id = clean_value(row.get('Transaction Id'))
        step_name = clean_value(row.get('Step Name'))
        response_type = clean_value(row.get('Student Response Type'))
        outcome = clean_value(row.get('Outcome'))
        input_val = clean_value(row.get('Input'))
        action = clean_value(row.get('CF (ACTION)'))
        action_type = clean_value(row.get('CF (ACTION_TYPE)'))
        feedback = clean_value(row.get('Feedback Text'))
        attempt_num = int(row.get('Attempt At Step', 0)) if pd.notna(row.get('Attempt At Step')) else 0
        duration = clean_value(row.get('Duration (sec)'))
        time = clean_value(row.get('Time'))
        
        # Parse step equation
        step_eq = None
        step_action = None
        if step_name and step_name != 'Unknown':
            if '[' in step_name:
                parts = step_name.split('[')
                step_eq = parts[0]
                step_action = parts[1].rstrip(']') if len(parts) > 1 else None
            else:
                step_eq = step_name
        
        # Get KC info
        kc_step = clean_value(row.get('KC (Step)'))
        kc_category = clean_value(row.get('KC Category (Step)'))
        
        transaction = {
            'transaction_id': transaction_id,
            'from': 'Student',
            'to': 'Problem',
            'properties': {
                'time': time,
                'duration_sec': duration,
                'response_type': response_type,
                'outcome': outcome,
                'attempt_number': attempt_num,
                'step_name': step_eq,
                'step_action': step_action,
                'input': input_val if input_val and input_val != '-1' else None,
                'action': action,
                'action_type': action_type,
                'feedback': feedback[:100] if feedback else None,  # Truncate long feedback
                'kc_step': kc_step,
                'kc_category': kc_category,
            }
        }
        transactions.append(transaction)
        
        # Track unique steps
        if step_eq:
            steps_seen.add(step_eq)
    
    # Add Step nodes
    for step_eq in sorted(steps_seen):
        if step_eq and step_eq != 'Unknown':
            nodes[f'Step_{step_eq[:20]}'] = {
                'id': step_eq,
                'properties': {
                    'step_name': step_eq,
                    'step_type': 'Transformation' if '=' in step_eq else 'Typein',
                }
            }
    
    return {
        'nodes': nodes,
        'transactions': transactions,
        'summary': {
            'student_id': student_id,
            'session_id': session_id,
            'problem_name': problem_name,
            'total_transactions': len(transactions),
            'unique_steps': len(steps_seen),
        }
    }

def create_html_visualization(problems_list, models_dict, output_file="problem_model.html"):
    """Create HTML visualization with problem selector."""
    
    # Prepare problems for JavaScript
    problems_json = json.dumps(problems_list)
    
    # Prepare all models for JavaScript (serialize to JSON-safe format)
    models_json = {}
    for key, model in models_dict.items():
        models_json[key] = {
            'summary': model['summary'],
            'nodes': model['nodes'],
            'transactions': model['transactions']
        }
    models_json_str = json.dumps(models_json)
    
    html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Problem Session Database Model</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 20px;
            line-height: 1.6;
        }}
        
        .container {{
            max-width: 1600px;
            margin: 0 auto;
        }}
        
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 30px;
        }}
        
        .header h1 {{
            font-size: 2em;
            margin-bottom: 10px;
        }}
        
        .problem-selector {{
            background: #252526;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            border-left: 4px solid #667eea;
        }}
        
        .problem-selector h2 {{
            color: #4ec9b0;
            margin-bottom: 15px;
        }}
        
        .selector-controls {{
            display: flex;
            gap: 15px;
            align-items: center;
            flex-wrap: wrap;
        }}
        
        .selector-controls label {{
            color: #858585;
            font-weight: bold;
        }}
        
        .selector-controls select {{
            background: #1e1e1e;
            color: #d4d4d4;
            border: 2px solid #3e3e42;
            border-radius: 4px;
            padding: 8px 12px;
            font-size: 1em;
            min-width: 300px;
            cursor: pointer;
        }}
        
        .selector-controls select:focus {{
            outline: none;
            border-color: #667eea;
        }}
        
        .selector-controls select option {{
            background: #1e1e1e;
            color: #d4d4d4;
        }}
        
        .load-btn {{
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            font-size: 1em;
            cursor: pointer;
            font-weight: bold;
            transition: background 0.2s;
        }}
        
        .load-btn:hover {{
            background: #764ba2;
        }}
        
        .problem-info {{
            background: #252526;
            padding: 15px;
            border-radius: 6px;
            margin-top: 15px;
            border-left: 3px solid #4ec9b0;
        }}
        
        .problem-info-item {{
            margin: 5px 0;
            color: #858585;
        }}
        
        .problem-info-value {{
            color: #4ec9b0;
            font-weight: bold;
        }}
        
        .summary {{
            background: #252526;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            border-left: 4px solid #667eea;
        }}
        
        .summary h2 {{
            color: #4ec9b0;
            margin-bottom: 15px;
        }}
        
        .summary-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }}
        
        .summary-item {{
            background: #1e1e1e;
            padding: 10px;
            border-radius: 4px;
        }}
        
        .summary-label {{
            color: #858585;
            font-size: 0.9em;
        }}
        
        .summary-value {{
            color: #4ec9b0;
            font-size: 1.1em;
            margin-top: 5px;
        }}
        
        .section {{
            background: #252526;
            padding: 25px;
            border-radius: 8px;
            margin-bottom: 30px;
        }}
        
        .section h2 {{
            color: #4ec9b0;
            margin-bottom: 20px;
            border-bottom: 2px solid #3e3e42;
            padding-bottom: 10px;
        }}
        
        .node {{
            background: #1e1e1e;
            border: 2px solid #3e3e42;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 15px;
        }}
        
        .node-header {{
            color: #569cd6;
            font-weight: bold;
            margin-bottom: 10px;
            font-size: 1.1em;
        }}
        
        .node-type {{
            color: #ce9178;
            font-size: 0.9em;
            margin-left: 10px;
        }}
        
        .property {{
            margin: 8px 0;
            padding-left: 20px;
        }}
        
        .property-key {{
            color: #9cdcfe;
        }}
        
        .property-value {{
            color: #ce9178;
        }}
        
        .property-null {{
            color: #858585;
            font-style: italic;
        }}
        
        .transaction {{
            background: #1e1e1e;
            border-left: 4px solid #4ec9b0;
            border-radius: 4px;
            padding: 15px;
            margin-bottom: 15px;
            transition: all 0.2s;
        }}
        
        .transaction:hover {{
            background: #2d2d30;
            border-left-color: #569cd6;
        }}
        
        .transaction-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }}
        
        .transaction-id {{
            color: #569cd6;
            font-weight: bold;
        }}
        
        .transaction-time {{
            color: #858585;
            font-size: 0.9em;
        }}
        
        .transaction-type {{
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.85em;
            margin-right: 8px;
        }}
        
        .type-attempt {{
            background: #264f78;
            color: #4ec9b0;
        }}
        
        .type-hint {{
            background: #7a5f00;
            color: #dcdcaa;
        }}
        
        .outcome-correct {{
            color: #6a9955;
        }}
        
        .outcome-incorrect {{
            color: #f48771;
        }}
        
        .outcome-ungraded {{
            color: #858585;
        }}
        
        .equation-display {{
            background: #1e1e1e;
            border: 2px solid #4ec9b0;
            border-radius: 6px;
            padding: 20px;
            margin: 15px 0;
            text-align: center;
            font-size: 1.5em;
            color: #4ec9b0;
            font-weight: bold;
        }}
        
        .equation-display .step-action {{
            font-size: 0.7em;
            color: #858585;
            margin-top: 10px;
        }}
        
        .helix-schema {{
            background: #1e1e1e;
            border: 2px solid #ce9178;
            border-radius: 6px;
            padding: 20px;
            margin: 20px 0;
        }}
        
        .helix-schema h3 {{
            color: #ce9178;
            margin-bottom: 15px;
        }}
        
        .schema-code {{
            color: #d4d4d4;
            font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
            white-space: pre-wrap;
            line-height: 1.8;
        }}
        
        .keyword {{
            color: #569cd6;
        }}
        
        .type-name {{
            color: #4ec9b0;
        }}
        
        .field-name {{
            color: #9cdcfe;
        }}
        
        .field-type {{
            color: #ce9178;
        }}
        
        .loading {{
            text-align: center;
            padding: 40px;
            color: #858585;
            font-size: 1.2em;
        }}
        
        .hidden {{
            display: none;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Problem Session Database Model</h1>
            <p>Select a problem to view its database structure and student interactions</p>
        </div>
        
        <div class="problem-selector">
            <h2>Select Problem</h2>
            <div class="selector-controls">
                <label for="problemSelect">Choose a problem:</label>
                <select id="problemSelect">
                    <option value="">-- Select a problem --</option>
"""
    
    # Add options for each problem
    for idx, prob in enumerate(problems_list):
        display_name = f"{prob['problem_name']} ({prob['transaction_count']} transactions)"
        html += f"""
                    <option value="{idx}" data-problem="{prob['problem_name']}" data-student="{prob['student_id']}" data-session="{prob['session_id']}">
                        {display_name}
                    </option>
"""
    
    html += """
                </select>
                <button class="load-btn" onclick="loadProblem()">Load Problem</button>
            </div>
            <div id="problemInfo" class="problem-info hidden">
                <div class="problem-info-item">
                    <span>Knowledge Component:</span> 
                    <span class="problem-info-value" id="infoKC">-</span>
                </div>
                <div class="problem-info-item">
                    <span>Transactions:</span> 
                    <span class="problem-info-value" id="infoTx">-</span>
                </div>
            </div>
        </div>
        
        <div id="contentArea" class="hidden">
            <div class="summary" id="summarySection">
                <!-- Summary will be inserted here -->
            </div>
            
            <div class="section" id="nodesSection">
                <h2>📦 Database Nodes (Entities)</h2>
                <div id="nodesContent">
                    <!-- Nodes will be inserted here -->
                </div>
            </div>
            
            <div class="section" id="transactionsSection">
                <h2>🔗 Transactions (Edges)</h2>
                <p style="color: #858585; margin-bottom: 20px;">
                    Each transaction represents a student interaction. Click to see the problem state.
                </p>
                <div id="transactionsContent">
                    <!-- Transactions will be inserted here -->
                </div>
            </div>
            
            <div class="section" id="schemaSection">
                <h2>🗄️ Proposed Helix Schema</h2>
                <div class="helix-schema">
                    <h3>Node Types</h3>
                    <div class="schema-code">
<span class="keyword">N</span>::<span class="type-name">Student</span> {{
    <span class="field-name">StudentId</span>: <span class="field-type">String</span>,
    <span class="field-name">School</span>: <span class="field-type">String</span>,
    <span class="field-name">Class</span>: <span class="field-type">String</span>,
}}

<span class="keyword">N</span>::<span class="type-name">Session</span> {{
    <span class="field-name">SessionId</span>: <span class="field-type">String</span>,
    <span class="field-name">StartTime</span>: <span class="field-type">String</span>,
    <span class="field-name">Timezone</span>: <span class="field-type">String</span>,
}}

<span class="keyword">N</span>::<span class="type-name">Problem</span> {{
    <span class="field-name">ProblemName</span>: <span class="field-type">String</span>,
    <span class="field-name">KCProblem</span>: <span class="field-type">String</span>,
    <span class="field-name">KCCategory</span>: <span class="field-type">String</span>,
    <span class="field-name">Course</span>: <span class="field-type">String</span>,
}}

<span class="keyword">N</span>::<span class="type-name">Step</span> {{
    <span class="field-name">StepName</span>: <span class="field-type">String</span>,
    <span class="field-name">StepType</span>: <span class="field-type">String</span>,
}}
                    </div>
                    
                    <h3>Edge Types</h3>
                    <div class="schema-code">
<span class="keyword">E</span>::<span class="type-name">BelongsTo</span> {{
    <span class="field-name">From</span>: <span class="type-name">Student</span>,
    <span class="field-name">To</span>: <span class="type-name">Session</span>,
}}

<span class="keyword">E</span>::<span class="type-name">WorksOn</span> {{
    <span class="field-name">From</span>: <span class="type-name">Session</span>,
    <span class="field-name">To</span>: <span class="type-name">Problem</span>,
    <span class="field-name">Properties</span>: {{
        <span class="field-name">StartTime</span>: <span class="field-type">String</span>,
    }}
}}

<span class="keyword">E</span>::<span class="type-name">Transaction</span> {{
    <span class="field-name">From</span>: <span class="type-name">Student</span>,
    <span class="field-name">To</span>: <span class="type-name">Problem</span>,
    <span class="field-name">Properties</span>: {{
        <span class="field-name">TransactionId</span>: <span class="field-type">String</span>,
        <span class="field-name">Time</span>: <span class="field-type">String</span>,
        <span class="field-name">DurationSec</span>: <span class="field-type">I64</span>,
        <span class="field-name">ResponseType</span>: <span class="field-type">String</span>,
        <span class="field-name">Outcome</span>: <span class="field-type">String</span>,
        <span class="field-name">AttemptNumber</span>: <span class="field-type">I64</span>,
        <span class="field-name">StepName</span>: <span class="field-type">String</span>,
        <span class="field-name">StepAction</span>: <span class="field-type">String</span>,
        <span class="field-name">Input</span>: <span class="field-type">String</span>,
        <span class="field-name">Action</span>: <span class="field-type">String</span>,
        <span class="field-name">ActionType</span>: <span class="field-type">String</span>,
        <span class="field-name">Feedback</span>: <span class="field-type">String</span>,
        <span class="field-name">KCStep</span>: <span class="field-type">String</span>,
        <span class="field-name">KCCategory</span>: <span class="field-type">String</span>,
    }}
}}

<span class="keyword">E</span>::<span class="type-name">Performs</span> {{
    <span class="field-name">From</span>: <span class="type-name">Transaction</span>,
    <span class="field-name">To</span>: <span class="type-name">Step</span>,
}}
                    </div>
                </div>
            </div>
        </div>
        
        <div id="loadingArea" class="loading hidden">
            Loading problem data...
        </div>
    </div>
    
    <script>
        const problems = {problems_json};
        const allModels = {models_json_str};
        let currentModel = null;
        
        function loadProblem() {{
            const select = document.getElementById('problemSelect');
            const option = select.options[select.selectedIndex];
            
            if (!option.value) {{
                alert('Please select a problem first!');
                return;
            }}
            
            const problemIdx = parseInt(option.value);
            const problem = problems[problemIdx];
            
            // Show loading briefly
            document.getElementById('contentArea').classList.add('hidden');
            document.getElementById('loadingArea').classList.remove('hidden');
            document.getElementById('problemInfo').classList.remove('hidden');
            
            // Update problem info
            document.getElementById('infoKC').textContent = problem.kc_problem || 'N/A';
            document.getElementById('infoTx').textContent = problem.transaction_count;
            
            // Create key for model lookup
            const modelKey = `${{problem.problem_name}}_${{problem.student_id}}_${{problem.session_id}}`;
            
            // Load the model from pre-loaded data
            setTimeout(() => {{
                const model = allModels[modelKey];
                if (model) {{
                    displayModel(model);
                }} else {{
                    alert('Model data not found for this problem. Please regenerate the HTML file.');
                    document.getElementById('loadingArea').classList.add('hidden');
                }}
            }}, 100);
        }}
        
        function displayModel(model) {{
            if (!model) return;
            
            document.getElementById('loadingArea').classList.add('hidden');
            document.getElementById('contentArea').classList.remove('hidden');
            
            // Display summary
            const summary = model.summary;
            document.getElementById('summarySection').innerHTML = `
                <h2>Session Summary</h2>
                <div class="summary-grid">
                    <div class="summary-item">
                        <div class="summary-label">Student ID</div>
                        <div class="summary-value">${{summary.student_id}}</div>
                    </div>
                    <div class="summary-item">
                        <div class="summary-label">Session ID</div>
                        <div class="summary-value">${{summary.session_id.substring(0, 30)}}...</div>
                    </div>
                    <div class="summary-item">
                        <div class="summary-label">Problem</div>
                        <div class="summary-value">${{summary.problem_name}}</div>
                    </div>
                    <div class="summary-item">
                        <div class="summary-label">Total Transactions</div>
                        <div class="summary-value">${{summary.total_transactions}}</div>
                    </div>
                    <div class="summary-item">
                        <div class="summary-label">Unique Steps</div>
                        <div class="summary-value">${{summary.unique_steps}}</div>
                    </div>
                </div>
            `;
            
            // Display nodes
            const nodesContent = document.getElementById('nodesContent');
            nodesContent.innerHTML = '';
            for (const [nodeId, nodeData] of Object.entries(model.nodes)) {{
                const nodeType = nodeId.split('_')[0];
                const nodeDiv = document.createElement('div');
                nodeDiv.className = 'node';
                nodeDiv.innerHTML = `
                    <div class="node-header">
                        ${{nodeId}}
                        <span class="node-type">(${{nodeType}})</span>
                    </div>
                `;
                
                for (const [key, value] of Object.entries(nodeData.properties)) {{
                    const propDiv = document.createElement('div');
                    propDiv.className = 'property';
                    if (value !== null && value !== undefined) {{
                        propDiv.innerHTML = `
                            <span class="property-key">${{key}}:</span> 
                            <span class="property-value">"${{value}}"</span>
                        `;
                    }} else {{
                        propDiv.innerHTML = `
                            <span class="property-key">${{key}}:</span> 
                            <span class="property-null">null</span>
                        `;
                    }}
                    nodeDiv.appendChild(propDiv);
                }}
                
                nodesContent.appendChild(nodeDiv);
            }}
            
            // Display transactions
            const transactionsContent = document.getElementById('transactionsContent');
            transactionsContent.innerHTML = '';
            let currentEquation = null;
            
            model.transactions.forEach((tx, idx) => {{
                const responseType = tx.properties.response_type;
                const outcome = tx.properties.outcome;
                const stepEq = tx.properties.step_name;
                
                const typeClass = responseType && responseType.includes('ATTEMPT') ? 'type-attempt' : 'type-hint';
                const outcomeClass = outcome ? `outcome-${{outcome.toLowerCase()}}` : '';
                
                // Show equation when it changes
                if (stepEq && stepEq !== currentEquation) {{
                    currentEquation = stepEq;
                    const eqDiv = document.createElement('div');
                    eqDiv.className = 'equation-display';
                    eqDiv.innerHTML = `
                        ${{stepEq}}
                        ${{tx.properties.step_action ? `<div class="step-action">Action: ${{tx.properties.step_action}}</div>` : ''}}
                    `;
                    transactionsContent.appendChild(eqDiv);
                }}
                
                const txDiv = document.createElement('div');
                txDiv.className = 'transaction';
                txDiv.innerHTML = `
                    <div class="transaction-header">
                        <div>
                            <span class="transaction-id">#${{idx + 1}} ${{tx.transaction_id.substring(0, 20)}}...</span>
                            <span class="transaction-type ${{typeClass}}">${{responseType || 'N/A'}}</span>
                            ${{outcome ? `<span class="transaction-type ${{outcomeClass}}">${{outcome}}</span>` : ''}}
                        </div>
                        <span class="transaction-time">${{tx.properties.time}}</span>
                    </div>
                `;
                
                const keyProps = ['attempt_number', 'input', 'action', 'feedback', 'kc_step'];
                keyProps.forEach(prop => {{
                    const value = tx.properties[prop];
                    if (value !== null && value !== undefined) {{
                        const propDiv = document.createElement('div');
                        propDiv.className = 'property';
                        propDiv.innerHTML = `
                            <span class="property-key">${{prop}}:</span> 
                            <span class="property-value">"${{String(value).substring(0, 80)}}"</span>
                        `;
                        txDiv.appendChild(propDiv);
                    }}
                }});
                
                transactionsContent.appendChild(txDiv);
            }});
        }}
        
        // Auto-load first problem on page load if available
        window.addEventListener('DOMContentLoaded', () => {{
            if (problems.length > 0) {{
                // Show first problem info
                const firstProb = problems[0];
                document.getElementById('infoKC').textContent = firstProb.kc_problem || 'N/A';
                document.getElementById('infoTx').textContent = firstProb.transaction_count;
            }}
        }});
    </script>
</body>
</html>
"""
    
    with open(output_file, 'w') as f:
        f.write(html)
    
    print(f"✅ Database model visualization created: {output_file}")
    print(f"   Found {len(problems_list)} problems to choose from")

if __name__ == "__main__":
    filepath = "ds6230_tx_All_Data_8663_2024_0830_105337.txt"
    
    if not Path(filepath).exists():
        print(f"Error: File '{filepath}' not found!")
        exit(1)
    
    print("Reading data file...")
    df = pd.read_csv(filepath, sep='\t', low_memory=False)
    
    print("Extracting available problems...")
    problems_list = extract_available_problems(df)
    
    if len(problems_list) == 0:
        print("No problems found! Using fallback...")
        # Fallback to any session
        sample_session = df[df['Session Id'].notna()].iloc[0]['Session Id']
        session_data = df[df['Session Id'] == sample_session].head(30)
        model = create_database_model(session_data)
        create_html_visualization([], model)
    else:
        print(f"Found {len(problems_list)} problems:")
        for idx, prob in enumerate(problems_list[:5]):
            print(f"  {idx+1}. {prob['problem_name']} - {prob['transaction_count']} transactions")
        
        # Create models for all problems (only those with transactions)
        models_dict = {}
        for prob in problems_list:
            if prob['transaction_count'] == 0:
                continue  # Skip problems with no transactions
                
            session_data = extract_problem_session(
                df, 
                prob['problem_name'],
                prob['student_id'],
                prob['session_id']
            )
            
            if len(session_data) == 0:
                continue  # Skip if no data found
                
            model = create_database_model(session_data)
            model_key = f"{prob['problem_name']}_{prob['student_id']}_{prob['session_id']}"
            models_dict[model_key] = model
            print(f"  ✓ Loaded: {prob['problem_name']} - {model['summary']['total_transactions']} transactions")
        
        # Create visualization with problem selector
        create_html_visualization(problems_list, models_dict)
        
        first_model = list(models_dict.values())[0]
        print(f"\n✅ Complete! Pre-loaded {len(models_dict)} problems")
        print(f"   Default Problem: {first_model['summary']['problem_name']}")
        print(f"   Student: {first_model['summary']['student_id']}")

