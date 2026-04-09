import yaml
import glob
import re
from datetime import datetime

date_str = datetime.now().strftime('%Y-%m-%d')

# Parse ADRs to extract requirements
reqs = []
id_counter = {}

for f in glob.glob('docs/architecture/adr-*.md'):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
        match = re.search(r'## GDD Requirements Addressed\s*\|.*?\n\|.*?\n((?:\|.*?\n)+)', content)
        if match:
            lines = match.group(1).strip().split('\n')
            for line in lines:
                parts = [p.strip() for p in line.split('|')]
                if len(parts) >= 4:
                    gdd = parts[1]
                    req_text = parts[2]
                    
                    sys_match = re.search(r'([a-z-]+)\.md', gdd)
                    if sys_match:
                        sys = sys_match.group(1)
                    else:
                        sys = 'core'
                        
                    if sys not in id_counter:
                        id_counter[sys] = 1
                    
                    tr_id = f"TR-{sys}-{id_counter[sys]:03d}"
                    id_counter[sys] += 1
                    
                    reqs.append({
                        'id': tr_id,
                        'system': sys,
                        'gdd': f"design/gdd/{sys}.md",
                        'requirement': req_text,
                        'created': date_str,
                        'revised': "",
                        'status': 'active'
                    })

registry = {
    'version': 1,
    'last_updated': date_str,
    'requirements': reqs
}

with open('docs/architecture/tr-registry.yaml', 'w', encoding='utf-8') as f:
    yaml.dump(registry, f, allow_unicode=True, sort_keys=False)

print(f"Generated {len(reqs)} TRs.")
