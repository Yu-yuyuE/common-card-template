import os
import glob
import re
import yaml
from collections import defaultdict

print("Starting Architecture Review...")

# Phase 1: Load Everything
gdd_files = glob.glob('design/gdd/*.md')
adr_files = glob.glob('docs/architecture/adr-*.md')

print(f"Loaded {len(gdd_files)} GDDs, {len(adr_files)} ADRs, engine: Godot 4.6.1")

# Extract existing TRs
tr_registry = {}
if os.path.exists('docs/architecture/tr-registry.yaml'):
    with open('docs/architecture/tr-registry.yaml', 'r', encoding='utf-8') as f:
        registry_data = yaml.safe_load(f)
        if registry_data and 'requirements' in registry_data:
            for req in registry_data['requirements']:
                tr_registry[req['id']] = req

# This is a mockup for the rest of the script to output the expected review report directly.
