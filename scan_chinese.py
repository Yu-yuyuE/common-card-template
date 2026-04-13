import os
import re

def find_chinese_in_files(directory):
    # Regex to match Chinese characters
    zh_pattern = re.compile(r'[\u4e00-\u9fff]+')
    
    # Regex to match string literals (both single and double quotes)
    # We want to find Chinese characters *inside* string literals
    string_pattern = re.compile(r'(".*?"|\'.*?\')')

    results = []
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.gd'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for i, line in enumerate(lines):
                    # Skip comments
                    if line.strip().startswith('#'):
                        continue
                        
                    # Find string literals in the line
                    for string_literal in string_pattern.findall(line):
                        if zh_pattern.search(string_literal):
                            # It's a string containing Chinese characters
                            results.append((path, i + 1, line.strip()))

    return results

files = find_chinese_in_files('src/')
for path, line_num, line in files:
    print(f"{path}:{line_num}: {line}")

if not files:
    print("No Chinese string literals found in .gd files (excluding comments).")
