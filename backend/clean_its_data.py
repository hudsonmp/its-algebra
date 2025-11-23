#!/usr/bin/env python3
"""Extract KCs from ITS data for Helix RAG - Compact Version"""
import pandas as pd
import json
from collections import defaultdict, Counter

print("Loading data...")
df = pd.read_csv('data/ds6230_tx_All_Data_8663_2024_0830_105337.txt', 
                 sep='\t', low_memory=False, na_values=['', 'NaN'])

# Extract KCs
print("Extracting KCs...")
kc_data = df[df['KC (Step)'].notna()].groupby('KC (Step)').agg({
    'KC Category (Step)': lambda x: x.mode()[0] if len(x) > 0 else 'Unknown',
    'Outcome': lambda x: (x == 'CORRECT').sum() / len(x) if len(x) > 0 else 0,
    'Step Name': lambda x: list(x.dropna().unique()[:2])
}).to_dict('index')

kcs = []
for kc, data in kc_data.items():
    kcs.append({
        'kc_name': kc,
        'kc_category': data['KC Category (Step)'],
        'success_rate': round(data['Outcome'], 3),
        'examples': data['Step Name']
    })

# Extract feedback
print("Extracting feedback...")
feedback = df[(df['Feedback Text'].notna()) & (df['KC (Step)'].notna())][
    ['KC (Step)', 'Feedback Text', 'Outcome']
].to_dict('records')

# Extract mistakes
print("Extracting mistakes...")
mistakes = df[(df['Outcome'] == 'INCORRECT') & (df['Input'].notna())][
    ['KC (Step)', 'Input', 'Step Name']
].groupby(['KC (Step)', 'Input']).size().reset_index(name='count').to_dict('records')

# Save
with open('cleaned_data/kcs.json', 'w') as f:
    json.dump(kcs, f, indent=2)
with open('cleaned_data/feedback.json', 'w') as f:
    json.dump(feedback[:1000], f, indent=2)
with open('cleaned_data/mistakes.json', 'w') as f:
    json.dump(mistakes[:500], f, indent=2)

print(f"✅ Extracted {len(kcs)} KCs, {len(feedback)} feedbacks, {len(mistakes)} mistakes")
print("📁 Output: cleaned_data/")
