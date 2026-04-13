import re

path = 'src/core/terrain-weather/TerrainWeatherManager.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = {
    r'return "平原"': r'return TranslationServer.translate("TERRAIN_PLAIN")',
    r'return "山地"': r'return TranslationServer.translate("TERRAIN_MOUNTAIN")',
    r'return "森林"': r'return TranslationServer.translate("TERRAIN_FOREST")',
    r'return "水域"': r'return TranslationServer.translate("TERRAIN_WATER")',
    r'return "沙漠"': r'return TranslationServer.translate("TERRAIN_DESERT")',
    r'return "关隘"': r'return TranslationServer.translate("TERRAIN_PASS")',
    r'return "雪地"': r'return TranslationServer.translate("TERRAIN_SNOW")',
    r'return "未知地形"': r'return TranslationServer.translate("TERRAIN_UNKNOWN")',
    r'return "晴朗"': r'return TranslationServer.translate("WEATHER_CLEAR")',
    r'return "大风"': r'return TranslationServer.translate("WEATHER_WIND")',
    r'return "雨天"': r'return TranslationServer.translate("WEATHER_RAIN")',
    r'return "雾天"': r'return TranslationServer.translate("WEATHER_FOG")',
    r'return "未知天气"': r'return TranslationServer.translate("WEATHER_UNKNOWN")',
}

for old, new in replacements.items():
    content = re.sub(old, new, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

