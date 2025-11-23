#!/usr/bin/env python3
import pandas as pd
import json
from collections import defaultdict

print("Loading data...")
df = pd.read_csv('data/ds6230_tx_All_Data_8663_2024_0830_105337.txt', 
                 sep='\t', low_memory=False, na_values=[''])

print("Extracting KCs...")
kc_df = df[df['KC (Step)'].notna()]

kcs = []
for kc in kc_df['KC (Step)'].unique():
    rows = kc_df[kc_df['KC (Step)'] == kc]
    cat = rows['KC Category (Step)'].mode()[0] if len(rows) > 0 else 'Unknown'
    correct = (rows['Outcome'] == 'CORRECT').sum()
    total = len(rows[rows['Outcome'].notna()])
    rate = correct / total if total > 0 else 0
    
    kcs.append({
        'name': kc,
        'category': cat,
        'success_rate': round(rate, 3),
        'attempts': total
    })

print("Extracting feedback...")
fb_df = df[(df['Feedback Text'].notna()) & (df['KC (Step)'].notna())]
feedback = defaultdict(list)
for _, row in fb_df.head(500).iterrows():
    feedback[row['KC (Step)']].append({
        'text': row['Feedback Text'][:200],
        'outcome': row['Outcome']
    })

print("Extracting mistakes...")
err_df = df[(df['Outcome'] == 'INCORRECT') & (df['Input'].notna())]
mistakes = defaultdict(list)
for kc in err_df['KC (Step)'].dropna().unique()[:100]:
    rows = err_df[err_df['KC (Step)'] == kc]
    for inp in rows['Input'].value_counts().head(3).index:
        mistakes[kc].append(str(inp))

with open('kcs.json', 'w') as f:
    json.dump(kcs, f, indent=2)
with open('feedback.json', 'w') as f:
    json.dump(dict(feedback), f, indent=2)
with open('mistakes.json', 'w') as f:
    json.dump(dict(mistakes), f, indent=2)

print(f"\n✅ Done! {len(kcs)} KCs extracted")
print(f"📁 Files: kcs.json, feedback.json, mistakes.json")

