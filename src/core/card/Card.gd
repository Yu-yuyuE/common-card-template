## 卡牌实例类（RefCounted）
## 包装CardData，记录其在一场战斗中的动态状态（例如费用改变、临时属性等）。
class_name Card extends RefCounted

var data: CardData
var current_cost: int

func _init(p_data: CardData) -> void:
	data = p_data
	current_cost = data.cost if data else 0

func get_id() -> String:
	return data.id if data else ""
