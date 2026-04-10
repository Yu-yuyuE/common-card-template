# PROTOTYPE - NOT FOR PRODUCTION
# Question: 1v3 战场模型 + 兵种卡 + 地形系统的战斗循环是否有趣且可操作？
# Date: 2026-04-10

# 地形数据：定义各类型的效果

extends Node

# 地形效果数据
const TERRAIN_DATA: Dictionary = {
	"平原": {
		"description": "骑兵在此地形获得 +50% 伤害加成",
		"damage_modifiers": {"骑兵": 1.5},
		"special_effects": []
	},
	"山地": {
		"description": "骑兵在此地形受到严重影响，伤害减半；弓兵略有优势",
		"damage_modifiers": {"骑兵": 0.5, "弓兵": 1.3},
		"special_effects": []
	},
	"森林": {
		"description": "谋士在此地形获得 +50% 伤害加成",
		"damage_modifiers": {"谋士": 1.5},
		"special_effects": []
	},
	"水域": {
		"description": "盾兵在此地形获得 +30% 伤害加成",
		"damage_modifiers": {"盾兵": 1.3},
		"special_effects": []
	}
}

# 获取地形的描述
static func get_description(terrain: String) -> String:
	if TERRAIN_DATA.has(terrain):
		return TERRAIN_DATA[terrain]["description"]
	return "未知地形"

# 获取特定兵种在地形上的伤害修正
static func get_damage_modifier(troop_type: String, terrain: String) -> float:
	if TERRAIN_DATA.has(terrain):
		var modifiers = TERRAIN_DATA[terrain]["damage_modifiers"]
		if modifiers.has(troop_type):
			return modifiers[troop_type]
	return 1.0

# 获取地形的特殊效果列表
static func get_special_effects(terrain: String) -> Array[String]:
	if TERRAIN_DATA.has(terrain):
		return TERRAIN_DATA[terrain]["special_effects"]
	return []

# 检查地形是否对某种兵种有利
static func is_advantageous(troop_type: String, terrain: String) -> bool:
	var mod = get_damage_modifier(troop_type, terrain)
	return mod > 1.0