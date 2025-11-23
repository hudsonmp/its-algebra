#!/usr/bin/env python3
"""
Flask server for ITS Algebra RAG testing
Queries Helix-ready data to provide hints based on student problems
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import re
from typing import Dict, List, Optional

app = Flask(__name__)
CORS(app)

# Load data
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(script_dir, 'kcs.json')) as f:
    KCS = json.load(f)
with open(os.path.join(script_dir, 'feedback.json')) as f:
    FEEDBACK = json.load(f)
with open(os.path.join(script_dir, 'mistakes.json')) as f:
    MISTAKES = json.load(f)

# Create lookup maps
KC_MAP = {kc['name']: kc for kc in KCS}


def identify_kc_pattern(problem: str, step_type: Optional[str] = None) -> Optional[str]:
    """
    Identify the KC pattern from a problem string
    Maps actual problems to KC notation (v=variable, N=number)
    """
    problem = problem.strip().replace(' ', '')
    
    # Common patterns to KC mappings
    patterns = [
        # Two-step equations
        (r'[a-z]-\d+\+\d+=\d+', "'v-N+N=N"),  # x-7+3=5
        (r'\d*[a-z]\+\d+=\d+', "'Nv+N=N"),     # 3y+9=13, y+5=10
        (r'\d*[a-z]-\d+=\d+', "'Nv-N=N"),      # 2x-3=7
        (r'[a-z]\+\d+=\d+', "'v+N=N"),         # x+5=10
        (r'[a-z]-\d+=\d+', "'v-N=N"),          # x-7=3
        
        # One-step equations
        (r'\d*[a-z]=\d+', "'Nv=N"),            # 2x=10, x=5
        (r'\d+=[a-z]', "'N=v"),                # 5=x
        
        # BothSides (variables on both sides)
        (r'-?\d+-?\d*[a-z]=-?\d+-?\d*[a-z]', "'-N-Nv=-N-Nv"),  # -5-11w=-8-8w
        (r'\d+\+?\d*[a-z]=-?\d*[a-z]-?\d+', "'N+Nv=-Nv-N"),     # 7+6b=-8b-11
    ]
    
    for pattern, kc in patterns:
        if re.search(pattern, problem):
            # If step_type specified, append it
            if step_type == 'typein':
                # Look for typein variant
                typein_kc = kc + '[add N]'  # Generic, would need more logic
                if typein_kc in KC_MAP:
                    return typein_kc
            return kc if kc in KC_MAP else None
    
    # Fallback: return most common KC
    return "'v=N"


def get_kc_info(kc_name: str) -> Dict:
    """Get KC information"""
    kc = KC_MAP.get(kc_name, {})
    if not kc:
        return None
    
    difficulty = "Hard" if kc['success_rate'] < 0.5 else "Medium" if kc['success_rate'] < 0.8 else "Easy"
    
    return {
        'name': kc['name'],
        'category': kc['category'],
        'difficulty': difficulty,
        'success_rate': kc['success_rate'],
        'attempts': kc['attempts']
    }


def get_hints_for_kc(kc_name: str) -> List[Dict]:
    """Get feedback/hints for a KC"""
    feedbacks = FEEDBACK.get(kc_name, [])
    
    # Filter patterns to exclude (non-helpful intermediary messages)
    exclude_patterns = [
        'bear with me',
        'let me think',
        'hmm',
        'well',
        'okay',
        'so,',
        'is it alright',
        'would it be good',
        'does that sound',
        "i'm stuck",
        "i don't know"
    ]
    
    hints = []
    for fb in feedbacks:
        text = fb['text']
        text_lower = text.lower()
        
        # Skip intermediary thinking messages
        if any(pattern in text_lower for pattern in exclude_patterns):
            continue
            
        # Skip very short messages (usually fragments)
        if len(text) < 20:
            continue
        
        # Categorize feedback
        hint_type = "HINT"
        if any(word in text_lower for word in ['wrong', 'incorrect', 'no']):
            hint_type = "ERROR"
        elif any(word in text_lower for word in ['good', 'correct', 'yes']):
            hint_type = "ENCOURAGEMENT"
        elif '?' in text and 'why' not in text_lower:
            hint_type = "QUESTION"
        elif any(word in text_lower for word in ['why', 'because', 'reason', 'goal is', 'to isolate']):
            hint_type = "EXPLANATION"
        
        hints.append({
            'text': text,
            'type': hint_type,
            'outcome': fb.get('outcome', 'unknown')
        })
        
        # Limit to best 5 hints
        if len(hints) >= 5:
            break
    
    # Add generic hints if no good specific ones found
    if not hints:
        hints = generate_generic_hints(kc_name)
    
    return hints


def generate_generic_hints(kc_name: str) -> List[Dict]:
    """Generate generic hints based on KC pattern"""
    kc = KC_MAP.get(kc_name, {})
    category = kc.get('category', 'Unknown')
    
    generic_hints = []
    
    if category == 'Transformation':
        generic_hints.append({
            'text': 'Think about which operation will help isolate the variable.',
            'type': 'HINT'
        })
        generic_hints.append({
            'text': 'Remember: use the inverse operation to undo what\'s being done to the variable.',
            'type': 'HINT'
        })
    elif category == 'Typein':
        generic_hints.append({
            'text': 'Calculate the result after applying the operation to both sides.',
            'type': 'HINT'
        })
        generic_hints.append({
            'text': 'Don\'t forget to simplify your answer!',
            'type': 'HINT'
        })
    
    return generic_hints


def get_common_mistakes(kc_name: str) -> List[str]:
    """Get common mistakes for a KC"""
    return MISTAKES.get(kc_name, [])[:5]  # Top 5 mistakes


@app.route('/get_hints', methods=['POST'])
def get_hints():
    """Main endpoint to get hints for a problem"""
    data = request.json
    problem = data.get('problem', '')
    step_type = data.get('step_type', '')
    
    if not problem:
        return jsonify({'error': 'No problem provided'}), 400
    
    # Identify KC
    kc_name = identify_kc_pattern(problem, step_type)
    
    if not kc_name:
        return jsonify({
            'error': 'Could not identify KC pattern',
            'problem': problem,
            'suggestion': 'Try a simpler equation format like: x + 5 = 10'
        }), 404
    
    # Get KC info
    kc_info = get_kc_info(kc_name)
    
    # Get hints and mistakes
    hints = get_hints_for_kc(kc_name)
    mistakes = get_common_mistakes(kc_name)
    
    return jsonify({
        'kc': kc_info,
        'hints': hints,
        'mistakes': mistakes,
        'problem': problem
    })


@app.route('/search_kc', methods=['GET'])
def search_kc():
    """Search for KCs by name or category"""
    query = request.args.get('q', '').lower()
    category = request.args.get('category', '')
    
    results = []
    for kc in KCS:
        if (query in kc['name'].lower() or 
            (category and kc['category'] == category)):
            results.append({
                'name': kc['name'],
                'category': kc['category'],
                'success_rate': kc['success_rate']
            })
    
    return jsonify({'results': results[:20]})


@app.route('/stats', methods=['GET'])
def get_stats():
    """Get database statistics"""
    return jsonify({
        'total_kcs': len(KCS),
        'total_feedback': sum(len(v) for v in FEEDBACK.values()),
        'total_mistakes': sum(len(v) for v in MISTAKES.values()),
        'categories': {
            'Transformation': len([k for k in KCS if k['category'] == 'Transformation']),
            'Typein': len([k for k in KCS if k['category'] == 'Typein'])
        }
    })


@app.route('/', methods=['GET'])
def index():
    """Health check"""
    return jsonify({
        'status': 'running',
        'message': 'ITS Algebra RAG Server',
        'endpoints': ['/get_hints', '/search_kc', '/stats']
    })


if __name__ == '__main__':
    print("="*60)
    print("🚀 ITS Algebra RAG Server Starting...")
    print("="*60)
    print(f"📊 Loaded {len(KCS)} Knowledge Components")
    print(f"💬 Loaded {sum(len(v) for v in FEEDBACK.values())} feedback entries")
    print(f"❌ Loaded {sum(len(v) for v in MISTAKES.values())} mistake patterns")
    print()
    print("🌐 Server running at: http://localhost:8080")
    print("📄 Open test_rag.html in your browser to test!")
    print("="*60)
    
    app.run(debug=True, port=8080)

