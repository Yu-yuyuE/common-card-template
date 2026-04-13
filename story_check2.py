import os
import re

def check_story(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    gaps = []
    if "Type:" not in content and "Story Type:" not in content: gaps.append("Story Type")
    if "design/gdd/" not in content: gaps.append("GDD ref")
    if "ADR-" not in content and "No ADR applies" not in content and "N/A" not in content: gaps.append("ADR ref")
    if not re.search(r'Estimate[:\s]+.*[0-9]', content, re.IGNORECASE): gaps.append("Estimate")
    if "Out of Scope" not in content and "Out of scope" not in content: gaps.append("Out of Scope")
    if "Test Evidence" not in content and "测试要求" not in content: gaps.append("Test Evidence")
    
    if gaps:
        print(f"{os.path.basename(path)} gaps: {', '.join(gaps)}")

for f in os.listdir("production/epics/card-battle-system"):
    if f.startswith("story-"):
        check_story("production/epics/card-battle-system/" + f)
