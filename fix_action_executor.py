import re

path = 'src/core/enemy-system/ActionExecutor.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r'"中毒"', r'TranslationServer.translate("STATUS_POISON")'),
    (r'"剧毒"', r'TranslationServer.translate("STATUS_TOXIC")'),
    (r'"灼烧"', r'TranslationServer.translate("STATUS_BURN")'),
    (r'"瘟疫"', r'TranslationServer.translate("STATUS_PLAGUE")'),
    (r'"重伤"', r'TranslationServer.translate("STATUS_WOUND")'),
    (r'"恐惧"', r'TranslationServer.translate("STATUS_FEAR")'),
    (r'"混乱"', r'TranslationServer.translate("STATUS_CONFUSION")'),
    (r'"眩晕"', r'TranslationServer.translate("STATUS_STUN")'),
    (r'"盲目"', r'TranslationServer.translate("STATUS_BLIND")'),
    (r'"虚弱"', r'TranslationServer.translate("STATUS_WEAKEN")'),
    (r'"破甲"', r'TranslationServer.translate("STATUS_ARMOR_BREAK")'),
    (r'"冻伤"', r'TranslationServer.translate("STATUS_FROSTBITE")'),
    (r'"滑倒"', r'TranslationServer.translate("STATUS_SLIP")'),
]

for old, new in replacements:
    content = content.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

