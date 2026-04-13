## CurseManager.gd
## 诅咒管理器
##
## 职责：加载和管理诅咒卡数据，提供诅咒卡查询接口
## 位置：作为ResourceManager的一部分或独立组件
##
## 设计文档：design/gdd/curse-system-design.md
## 依赖：
##   - ResourceManager（资源管理）
##   - CurseCardData（诅咒卡数据结构）
##
## 使用示例：
##   var curse_mgr = CurseManager.new()
##   curse_mgr.load_curse_data()
##   var curse = curse_mgr.get_curse("curse_plague")

class_name CurseManager extends Node

# ---------------------------------------------------------------------------
# 内部状态
# ---------------------------------------------------------------------------

## 诅咒数据字典：key = card_id, value = CurseCardData
var _curse_data: Dictionary = {}

## 诅咒卡列表
var _curse_cards: Array[CurseCardData] = []

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 初始化时加载诅咒数据
func _ready() -> void:
	load_curse_data()


## 从CSV文件加载诅咒数据
func load_curse_data() -> void:
	var file_path := "res://assets/csv_data/all_cards/curse_cards.csv"

	if not FileAccess.file_exists(file_path):
		push_error("CurseManager: 诅咒数据文件未找到 — %s" % file_path)
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("CurseManager: 无法打开诅咒数据文件 — %s" % file_path)
		return

	# 跳过标题行
	var header_line := file.get_line()

	var loaded_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		# 跳过空行
		if line.is_empty():
			continue

		var fields: PackedStringArray = line.split(",")
		if fields.size() < 7:
			push_warning("CurseManager: 诅咒卡数据字段数不足，跳过 — [%s]" % line)
			continue

		# 解析字段
		var card_id: String = fields[0].strip_edges()
		var card_name: String = fields[1].strip_edges()
		var card_type_str: String = fields[2].strip_edges()
		var cost_str: String = fields[3].strip_edges()
		var effect: String = fields[4].strip_edges()
		var special_attr: String = fields[5].strip_edges()
		var catalog: String = fields[6].strip_edges()

		# 解析费用（"不可使用"视为0）
		var card_cost: int = 0
		if cost_str != "不可使用":
			card_cost = cost_str.to_int()

		# 创建诅咒卡数据（稀有度暂时为0，因为CSV中没有这个字段）
		var curse_data = CurseCardData.new(card_id, card_cost)
		curse_data.effect_text = effect
		curse_data.special_attribute = special_attr
		curse_data.catalog = catalog

		# 根据效果描述推断诅咒类型
		curse_data.curse_type = _infer_curse_type(effect, special_attr)

		# 如果是常驻手牌型且有费用，设置弃置费用
		if curse_data.curse_type == CurseCardData.CurseType.PERSISTENT_HAND and card_cost > 0:
			curse_data.discard_cost = card_cost

		# 存储到字典
		_curse_data[card_id] = curse_data
		_curse_cards.append(curse_data)
		loaded_count += 1

	file.close()
	print("CurseManager: 加载了 %d 张诅咒卡" % loaded_count)


# ---------------------------------------------------------------------------
# 查询接口
# ---------------------------------------------------------------------------

## 获取指定ID的诅咒卡数据
func get_curse(card_id: String) -> CurseCardData:
	if _curse_data.has(card_id):
		return _curse_data[card_id]
	return null


## 获取所有诅咒卡数据
func get_all_curses() -> Array[CurseCardData]:
	return _curse_cards.duplicate()


## 根据诅咒类型获取诅咒卡列表
func get_curses_by_type(curse_type: int) -> Array[CurseCardData]:
	var result: Array[CurseCardData] = []
	for curse in _curse_cards:
		if curse.curse_type == curse_type:
			result.append(curse)
	return result


## 获取所有抽到触发型诅咒
func get_draw_trigger_curses() -> Array[CurseCardData]:
	return get_curses_by_type(CurseCardData.CurseType.DRAW_TRIGGER)


## 获取所有常驻牌库型诅咒
func get_persistent_library_curses() -> Array[CurseCardData]:
	return get_curses_by_type(CurseCardData.CurseType.PERSISTENT_LIBRARY)


## 获取所有常驻手牌型诅咒
func get_persistent_hand_curses() -> Array[CurseCardData]:
	return get_curses_by_type(CurseCardData.CurseType.PERSISTENT_HAND)


## 检查指定卡ID是否为诅咒卡
func is_curse_card(card_id: String) -> bool:
	return _curse_data.has(card_id)


## 获取诅咒卡的弃置费用（仅常驻手牌型有效）
func get_discard_cost(card_id: String) -> int:
	if not _curse_data.has(card_id):
		return 0
	var curse = _curse_data[card_id]
	if curse.curse_type == CurseCardData.CurseType.PERSISTENT_HAND:
		return curse.discard_cost
	return 0


## 获取诅咒卡的效果文本
func get_curse_effect(card_id: String) -> String:
	if not has(card_id):
		return ""
	var curse = _curse_data[card_id]
	return curse.get_effect_description()


# ---------------------------------------------------------------------------
# 辅助方法
# ---------------------------------------------------------------------------

## 解析诅咒类型字符串
func _parse_curse_type(type_str: String) -> int:
	match type_str:
		"draw_trigger", "抽到触发型", "drawtrigger":
			return CurseCardData.CurseType.DRAW_TRIGGER
		"persistent_library", "常驻牌库型", "persistentlibrary":
			return CurseCardData.CurseType.PERSISTENT_LIBRARY
		"persistent_hand", "常驻手牌型", "persistenthand":
			return CurseCardData.CurseType.PERSISTENT_HAND
		_:
			push_warning("CurseManager: 未知诅咒类型 '%s'，默认使用DRAW_TRIGGER" % type_str)
			return CurseCardData.CurseType.DRAW_TRIGGER


## 检查是否存在指定诅咒
func has(card_id: String) -> bool:
	return _curse_data.has(card_id)


## 根据效果文本推断诅咒类型
func _infer_curse_type(effect_text: String, special_attr: String) -> int:
	# 常驻手牌型：包含"常驻手牌"、"持有时"、"在手牌中"、"无法使用"等关键词
	if effect_text.contains("常驻手牌") or effect_text.contains("持有时") or effect_text.contains("在手牌中") or effect_text.contains("无法使用"):
		return CurseCardData.CurseType.PERSISTENT_HAND

	# 常驻牌库型：包含"在牌库中"、"持续生效"、"每回合"等关键词，但不是抽到触发型
	if effect_text.contains("在牌库中") or effect_text.contains("持续生效") or effect_text.contains("每回合"):
		# 排除抽到触发型的关键词
		if not effect_text.contains("抽入手牌") and not effect_text.contains("抽到时"):
			return CurseCardData.CurseType.PERSISTENT_LIBRARY

	# 抽到触发型：包含"抽入手牌"、"抽到时"等关键词
	if effect_text.contains("抽入手牌") or effect_text.contains("抽到时"):
		return CurseCardData.CurseType.DRAW_TRIGGER

	# 如果是"不可使用"但没有其他关键词，根据特殊属性判断
	if effect_text.is_empty() and special_attr == "不可使用":
		# 默认为抽到触发型
		return CurseCardData.CurseType.DRAW_TRIGGER

	# 默认为抽到触发型
	return CurseCardData.CurseType.DRAW_TRIGGER