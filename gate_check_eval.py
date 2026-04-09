import os
import glob
import re

print("Running Quality Checks for Technical Setup -> Pre-Production...")

# Architecture Core Systems Check
adr_files = glob.glob('docs/architecture/adr-*.md')
print(f"ADRs found: {len(adr_files)} (Requires >= 3 Foundation-layer ADRs)")

# Deprecated API Check
dep_usage = False
dep_file = 'docs/engine-reference/godot/deprecated-apis.md'
if os.path.exists(dep_file):
    with open(dep_file, 'r', encoding='utf-8') as f:
        dep_apis = f.read()
    # Check ADRs against this
else:
    print("No deprecated API file found.")

# Circular Dependency Check
dependencies = {}
for adr in adr_files:
    try:
        with open(adr, 'r', encoding='utf-8') as f:
            content = f.read()
            # Extract ADR-NNNN ID
            adr_match = re.search(r'# (ADR-\d+):', content)
            if not adr_match:
                continue
            adr_id = adr_match.group(1)
            
            # Extract Depends On
            dep_match = re.search(r'\*\*Depends On\*\*\s*\|\s*(.*?)\s*\|', content)
            if dep_match:
                deps = dep_match.group(1)
                dep_ids = re.findall(r'ADR-\d+', deps)
                dependencies[adr_id] = dep_ids
            else:
                dependencies[adr_id] = []
    except Exception as e:
        print(f"Error parsing {adr}: {e}")

print("ADR Dependency Tree parsed.")
# Cycle detection (DFS)
visited = set()
path = []
cycles = []

def dfs(node):
    if node in path:
        cycles.append(path[path.index(node):] + [node])
        return
    if node in visited:
        return
    visited.add(node)
    path.append(node)
    for neighbor in dependencies.get(node, []):
        dfs(neighbor)
    path.pop()

for node in dependencies:
    dfs(node)

if cycles:
    print("Cycles found:", cycles)
else:
    print("No circular dependencies detected.")

