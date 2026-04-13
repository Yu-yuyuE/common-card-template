import re

path = 'src/core/enemy-system/ActionExecutor.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    # Curse delivery methods
    (r'"手牌" in action.description', r'("手牌" in action.description or "hand" in action.description)'),
    (r'"抽牌堆顶" in action.description', r'("抽牌堆顶" in action.description or "draw" in action.description)'),
    (r'"弃牌堆" in action.description', r'("弃牌堆" in action.description or "discard" in action.description)'),
    
    # Steal gold and cards
    (r'if "偷" in action.description and "金" in action.description:', r'if ("偷" in action.description and "金" in action.description) or "steal_gold" in action.type:'),
    (r'elif "偷" in action.description and "牌" in action.description:', r'elif ("偷" in action.description and "牌" in action.description) or "steal_card" in action.type:'),
    
    # Base types
    (r'elif "诅咒" in action.description or action.type == "curse":', r'elif action.type == "curse" or "curse" in action.description or "诅咒" in action.description:'),
    (r'elif "召唤" in action.description or action.type == "summon":', r'elif action.type == "summon" or "summon" in action.description or "召唤" in action.description:'),
    (r'elif "移动" in action.description or action.type == "move":', r'elif action.type == "move" or "move" in action.description or "移动" in action.description:'),
    (r'elif "天气" in action.description or action.type == "weather":', r'elif action.type == "weather" or "weather" in action.description or "天气" in action.description:')
]

for old, new in replacements:
    content = content.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

