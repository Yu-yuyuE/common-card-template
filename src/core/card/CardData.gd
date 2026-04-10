## 卡牌数据类（Resource）
## 存储卡牌的静态配置数据，不随战斗状态变化。
class_name CardData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var cost: int = 1
@export var type: int = 0 # 0: 攻击, 1: 技能, 2: 状态, 3: 诅咒
@export var description: String = ""

func _init(p_id: String = "", p_cost: int = 1) -> void:
	id = p_id
	cost = p_cost
