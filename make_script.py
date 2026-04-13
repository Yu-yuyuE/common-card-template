import re

path = 'src/core/curse-system/CurseCardData.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = {
    r'return "抽到时触发"': r'return TranslationServer.translate("CURSE_DRAW_TRIGGER")',
    r'return "常驻牌库中"': r'return TranslationServer.translate("CURSE_PERSIST_LIB")',
    r'return "常驻手牌中"': r'return TranslationServer.translate("CURSE_PERSIST_HAND")',
    r'return "未知诅咒类型"': r'return TranslationServer.translate("CURSE_UNKNOWN")',
    r'== "无法使用"': r'== TranslationServer.translate("CURSE_UNPLAYABLE")',
}

for old, new in replacements.items():
    content = re.sub(old, new, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

