import re

path = 'src/core/troop-card/TroopCard.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = {
    r'return "步兵"': r'return TranslationServer.translate("TYPE_INFANTRY")',
    r'return "骑兵"': r'return TranslationServer.translate("TYPE_CAVALRY")',
    r'return "弓兵"': r'return TranslationServer.translate("TYPE_ARCHER")',
    r'return "谋士"': r'return TranslationServer.translate("TYPE_STRATEGIST")',
    r'return "盾兵"': r'return TranslationServer.translate("TYPE_SHIELD")',
    r'return "未知类型"': r'return TranslationServer.translate("UNKNOWN_TYPE")',
}

for old, new in replacements.items():
    content = re.sub(old, new, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

