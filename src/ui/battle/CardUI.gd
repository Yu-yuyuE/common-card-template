## 手牌单张卡牌UI
##
## 以纯代码方式创建子节点（不依赖 .tscn），
## 显示卡牌 ID 与费用，并根据当前行动点决定是否灰显。
##
## 灰显规则（ADR-0007 响应式模式）：
## - 费用 > current_ap → modulate.a = 0.4，mouse_filter = MOUSE_FILTER_IGNORE
## - 费用 <= current_ap → modulate.a = 1.0，mouse_filter = MOUSE_FILTER_STOP
class_name CardUI extends Control

## 当前卡牌的唯一 ID
var card_id: String = ""

## 该卡牌的行动点费用（由 _parse_cost 从 card_id 解析）
var cost: int = 1

# 子节点引用（_init 中创建）
var _cost_label: Label
var _name_label: Label

# ---------------------------------------------------------------------------
# 初始化（代码构建节点树）
# ---------------------------------------------------------------------------

func _init() -> void:
	var panel := PanelContainer.new()
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_cost_label = Label.new()
	_cost_label.name = "CostLabel"
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	vbox.add_child(_cost_label)
	vbox.add_child(_name_label)

	custom_minimum_size = Vector2(80, 120)

# ---------------------------------------------------------------------------
# 公开接口
# ---------------------------------------------------------------------------

## 初始化卡牌显示。
## p_card_id: 卡牌唯一 ID（同时作为显示名称）
## current_ap: 当前行动点，用于判定该牌是否可打出（灰显逻辑）
func setup(p_card_id: String, current_ap: int) -> void:
	card_id = p_card_id
	cost = _parse_cost(card_id)
	_cost_label.text = str(cost)
	_name_label.text = card_id
	_update_availability(current_ap)

# ---------------------------------------------------------------------------
# 内部工具（私有）
# ---------------------------------------------------------------------------

## 根据当前行动点更新可用/灰显状态。
func _update_availability(current_ap: int) -> void:
	if current_ap < cost:
		modulate.a = 0.4
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		modulate.a = 1.0
		mouse_filter = Control.MOUSE_FILTER_STOP

## 从 card_id 中解析费用。
## 规则：若 ID 含 "_cost_N" 片段（例如 "fireball_cost_2"），返回 N；
## 否则默认返回 1。
func _parse_cost(id: String) -> int:
	var parts := id.split("_")
	for i in range(parts.size() - 1):
		if parts[i] == "cost" and parts[i + 1].is_valid_int():
			return parts[i + 1].to_int()
	return 1
