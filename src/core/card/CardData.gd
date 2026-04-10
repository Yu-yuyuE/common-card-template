## 卡牌数据类（Resource）
## 存储卡牌的静态配置数据，不随战斗状态变化。
class_name CardData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var cost: int = 1
@export var type: int = 0 # 0: 攻击, 1: 技能, 2: 状态, 3: 诅咒
@export var description: String = ""

# 卡牌流转规则控制
@export var remove_after_use: bool = false # 打出后移入移除区 (Removed)
@export var exhaust: bool = false          # 打出后移入消耗区 (Exhaust)

func _init(p_id: String = "", p_cost: int = 1, p_remove: bool = false, p_exhaust: bool = false) -> void:
	id = p_id
	cost = p_cost
	remove_after_use = p_remove
	exhaust = p_exhaust
