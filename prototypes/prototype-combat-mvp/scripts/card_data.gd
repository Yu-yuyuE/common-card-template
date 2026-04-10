# PROTOTYPE - NOT FOR PRODUCTION
# Question: 1v3 战场模型 + 兵种卡 + 地形系统的战斗循环是否有趣且可操作？
# Date: 2026-04-10

# 卡牌数据类 - 硬编码基础兵种卡

extends Node

# 兵种类型
const TROOP_TYPES: Array[String] = ["步兵", "骑兵", "弓兵", "谋士", "盾兵"]

# 基础卡数据（从 troop_cards.csv 摘录，仅用于原型）
const CARD_DATA: Dictionary = {
	"步兵": {
		"name": "步兵",
		"type": "步兵",
		"base_damage": 10,
		"description": "近战单位，基础攻击",
		"icon": "res://assets/placeholder/infantry.png"
	},
	"骑兵": {
		"name": "骑兵",
		"type": "骑兵",
		"base_damage": 15,
		"description": "高伤害，平原地形+50%伤害",
		"icon": "res://assets/placeholder/cavalry.png"
	},
	"弓兵": {
		"name": "弓兵",
		"type": "弓兵",
		"base_damage": 12,
		"description": "远程单位，山地地形-30%伤害",
		"icon": "res://assets/placeholder/archer.png"
	},
	"谋士": {
		"name": "谋士",
		"type": "谋士",
		"base_damage": 8,
		"description": "辅助单位，森林地形+50%伤害",
		"icon": "res://assets/placeholder/scholar.png"
	},
	"盾兵": {
		"name": "盾兵",
		"type": "盾兵",
		"base_damage": 5,
		"description": "防御单位，水域地形+30%护盾",
		"icon": "res://assets/placeholder/shield.png"
	}
}

# 获取初始手牌（每种兵种卡一张）
static func get_starting_hand() -> Array[Dictionary]:
	var hand: Array[Dictionary] = []
	for type in TROOP_TYPES:
		hand.append(CARD_DATA[type])
	return hand

# 地形伤害修正
static func get_damage_modifier(troop_type: String, terrain: String) -> float:
	match terrain:
		"平原":
			if troop_type == "骑兵":
				return 1.5
			return 1.0
		"山地":
			if troop_type == "骑兵":
				return 0.5
			if troop_type == "弓兵":
				return 1.3
			return 1.0
		"森林":
			if troop_type == "谋士":
				return 1.5
			return 1.0
		"水域":
			if troop_type == "盾兵":
				return 1.3
			return 1.0
		_:
			return 1.0

# 检查地形是否适合兵种
static func is_terrain_compatible(troop_type: String, terrain: String) -> bool:
	# 简化逻辑：除骑兵在山地外，其他都兼容
	if terrain == "山地" and troop_type == "骑兵":
		return false
	return true