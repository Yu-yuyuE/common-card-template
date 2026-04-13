import re

path = 'src/core/StatusEffect.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r'"怒气"', r'TranslationServer.translate("STATUS_FURY")'),
    (r'"迅捷"', r'TranslationServer.translate("STATUS_AGILITY")'),
    (r'"格挡"', r'TranslationServer.translate("STATUS_BLOCK")'),
    (r'"坚守"', r'TranslationServer.translate("STATUS_DEFEND")'),
    (r'"反击"', r'TranslationServer.translate("STATUS_COUNTER")'),
    (r'"穿透"', r'TranslationServer.translate("STATUS_PIERCE")'),
    (r'"免疫"', r'TranslationServer.translate("STATUS_IMMUNE")'),
    (r'"中毒"', r'TranslationServer.translate("STATUS_POISON")'),
    (r'"剧毒"', r'TranslationServer.translate("STATUS_TOXIC")'),
    (r'"恐惧"', r'TranslationServer.translate("STATUS_FEAR")'),
    (r'"混乱"', r'TranslationServer.translate("STATUS_CONFUSION")'),
    (r'"盲目"', r'TranslationServer.translate("STATUS_BLIND")'),
    (r'"滑倒"', r'TranslationServer.translate("STATUS_SLIP")'),
    (r'"破甲"', r'TranslationServer.translate("STATUS_ARMOR_BREAK")'),
    (r'"虚弱"', r'TranslationServer.translate("STATUS_WEAKEN")'),
    (r'"灼烧"', r'TranslationServer.translate("STATUS_BURN")'),
    (r'"瘟疫"', r'TranslationServer.translate("STATUS_PLAGUE")'),
    (r'"眩晕"', r'TranslationServer.translate("STATUS_STUN")'),
    (r'"重伤"', r'TranslationServer.translate("STATUS_WOUND")'),
    (r'"冻伤"', r'TranslationServer.translate("STATUS_FROSTBITE")'),
    (r'"流血"', r'TranslationServer.translate("STATUS_BLEEDING")'),
    (r'"生锈"', r'TranslationServer.translate("STATUS_RUSTY")'),
]

for old, new in replacements:
    content = content.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

