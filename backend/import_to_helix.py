#!/usr/bin/env python3
"""
Import extracted ITS data into Helix database format
Creates nodes and edges following schema.hx structure
"""
import json

def generate_helix_queries():
    """Generate Helix query commands to import all data"""
    
    with open('kcs.json') as f:
        kcs = json.load(f)
    with open('feedback.json') as f:
        feedback = json.load(f)
    with open('mistakes.json') as f:
        mistakes = json.load(f)
    
    queries = []
    
    # 1. Create KnowledgeComponent nodes
    queries.append("// ===== CREATE KNOWLEDGE COMPONENT NODES =====\n")
    for idx, kc in enumerate(kcs):
        difficulty = "Hard" if kc['success_rate'] < 0.5 else "Medium" if kc['success_rate'] < 0.8 else "Easy"
        
        query = f"""N::KnowledgeComponent {{
    KCName: "{kc['name'].replace('"', '\\"')}",
    KCCategory: "{kc['category']}",
    Description: "KC pattern for {kc['category']} steps",
    Difficulty: "{difficulty}",
}}"""
        queries.append(query)
        
        if idx >= 10:  # Show first 10 as examples
            queries.append(f"\n// ... ({len(kcs) - 10} more KCs)")
            break
    
    # 2. Create Feedback nodes and HasFeedback edges
    queries.append("\n\n// ===== CREATE FEEDBACK NODES AND EDGES =====\n")
    feedback_count = 0
    for kc_name, feedbacks in list(feedback.items())[:5]:  # First 5 KCs
        for idx, fb in enumerate(feedbacks[:2]):  # First 2 feedbacks per KC
            fb_id = f"FB_{feedback_count}"
            feedback_count += 1
            
            fb_type = "HINT"
            if "wrong" in fb['text'].lower() or "incorrect" in fb['text'].lower():
                fb_type = "ERROR"
            elif "good" in fb['text'].lower() or "correct" in fb['text'].lower():
                fb_type = "ENCOURAGEMENT"
            
            text = fb['text'].replace('"', '\\"').replace('\n', ' ')[:150]
            
            query = f"""N::Feedback {{
    FeedbackText: "{text}",
    FeedbackType: "{fb_type}",
    HintLevel: 1,
}}

E::HasFeedback {{
    From: (KCName == "{kc_name.replace('"', '\\"')}"),
    To: Feedback,
    Properties: {{
        Condition: "{fb['outcome'].lower() if fb['outcome'] else 'on_hint_request'}",
        Order: 1,
    }}
}}"""
            queries.append(query)
    
    queries.append(f"\n// ... ({sum(len(v) for v in feedback.values()) - feedback_count} more feedbacks)")
    
    # 3. Create Mistake nodes and HasMistake edges
    queries.append("\n\n// ===== CREATE MISTAKE NODES AND EDGES =====\n")
    mistake_count = 0
    for kc_name, errs in list(mistakes.items())[:5]:  # First 5 KCs
        for err in errs[:2]:  # First 2 mistakes per KC
            mistake_id = f"MST_{mistake_count}"
            mistake_count += 1
            
            err_clean = str(err).replace('"', '\\"').replace('\n', ' ')[:100]
            
            query = f"""N::Mistake {{
    MistakePattern: "incorrect_input",
    Description: "Student entered '{err_clean}'",
    StudentInput: "{err_clean}",
    CorrectApproach: "See tutor guidance",
}}

E::HasMistake {{
    From: (KCName == "{kc_name.replace('"', '\\"')}"),
    To: Mistake,
    Properties: {{
        Frequency: 1,
    }}
}}"""
            queries.append(query)
    
    queries.append(f"\n// ... ({sum(len(v) for v in mistakes.values()) - mistake_count} more mistakes)")
    
    # Add summary
    summary = f"""

// ===== IMPORT SUMMARY =====
// Total KnowledgeComponents: {len(kcs)}
// Total Feedback: {sum(len(v) for v in feedback.values())}
// Total Mistakes: {sum(len(v) for v in mistakes.values())}
//
// To complete import, run full script with all nodes
// Use JSON files for batch import if preferred
"""
    queries.append(summary)
    
    return '\n\n'.join(queries)


if __name__ == '__main__':
    print("Generating Helix import queries...")
    
    helix_script = generate_helix_queries()
    
    with open('helix_import.hx', 'w') as f:
        f.write(helix_script)
    
    print(f"✅ Generated helix_import.hx ({len(helix_script)} characters)")
    print("\n📋 To import into Helix:")
    print("   1. Review helix_import.hx")
    print("   2. Run queries in your Helix database")
    print("   3. Use kcs.json, feedback.json, mistakes.json for batch import")

