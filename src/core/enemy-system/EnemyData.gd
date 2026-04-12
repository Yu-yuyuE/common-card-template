## EnemyData.gd
## 敌人数据类（C3 - 敌人系统）
## 存储单个敌人的静态配置数据
## 依据 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyData extends RefCounted

## 敌人唯一标识
var id: String

## 敌人名称
var name: String

## 敌人职业（步兵/骑兵/弓兵/谋士/盾兵）
var enemy_class: int

## 敌人等级（普通/精英/强力）
var tier: int

## 最大生命值
var max_hp: int

## 当前生命值
var current_hp: int

## 护盾
var armor: int

## 是否存活
var is_alive: bool = true

## 行动序列（如 ["A01", "A01", "A03"]）
var action_sequence: Array[String] = []

## 当前行动索引（用于轮转序列）
var action_index: int = 0

## 冷却中的行动（Dictionary: {action_id: remaining_rounds}）
var cooldown_actions: Dictionary = {}

## 是否已完成相变（防止重复触发）
var has_transformed: bool = false

## 相变规则（如 "HP<40%:B01→C01→B14→C12"）
var phase_transition: String = ""

## 相变后的新序列（从 phase_transition 解析）
var phase2_sequence: Array[String] = []

## 行动参数覆盖（文本格式：action_id:param1=value1;param2=value2）
var action_params_text: String = ""

## 解析后的行动参数字典 {action_id: {param: value}}
var action_params: Dictionary = {}

## 初始化函数
func _init(
	p_id: String,
	p_name: String,
	p_class: int,
	p_tier: int,
	p_hp: int,
	p_armor: int = 0,
	p_action_sequence: Array[String] = [],
	p_phase_transition: String = "",
	p_action_params_text: String = "",  # 新增参数
) -> void:
	id = p_id
	name = p_name
	enemy_class = p_class
	tier = p_tier
	max_hp = p_hp
	current_hp = p_hp
	armor = p_armor
	is_alive = true
	action_sequence = p_action_sequence.duplicate()
	phase_transition = p_phase_transition

	# 新增：解析行动参数文本
	action_params_text = p_action_params_text
	_parse_action_params()

	# 解析相变规则，如果包含新序列，则提取
	if phase_transition.contains(":"):
		var colon_index = phase_transition.find(":")
		if colon_index != -1:
			phase2_sequence = phase_transition.substr(colon_index + 1).split("→")
			has_transformed = false
			action_index = 0

## 检查是否满足相变条件
func meets_phase_transition_condition() -> bool:
	if phase_transition.is_empty() or phase_transition == "---" or has_transformed:
		return false

	# 检查 HP 条件（格式：HP<40% 或 HP<40%:新序列）
	if phase_transition.begins_with("HP<"):
		var condition_part = phase_transition
		# 如果有冒号，只取条件部分
		var colon_index = phase_transition.find(":")
		if colon_index != -1:
			condition_part = phase_transition.substr(0, colon_index)

		# 提取阈值
		var threshold_str = condition_part.replace("HP<", "").replace("%", "")
		var threshold_percent = threshold_str.to_float() / 100.0
		var threshold_hp = max_hp * threshold_percent

		return current_hp <= threshold_hp

	# 未来可扩展其他条件类型（如状态效果）
	return false


## 解析行动参数文本
func _parse_action_params() -> void:
	action_params.clear()

	if action_params_text.is_empty() or action_params_text == "—" or action_params_text == "---":
		return

	# 格式：action_id1:param1=value1;action_id2:param2=value2
	# 单个行动多个参数：action_id:param1=value1&param2=value2
	# 无参数行动：action_id
	# 例如：A04:damage=6;A00;B16:summon_count=1&summon_enemy_id=E001;B01:damage=10

	var entries = action_params_text.split(";")
	for entry in entries:
		if entry.is_empty():
			continue

		# 分离 action_id 和参数字符串
		var colon_index = entry.find(":")
		if colon_index == -1:
			# 无参数行动，直接使用action_id
			action_params[entry.strip_edges()] = {}
			continue

		var action_id = entry.substr(0, colon_index).strip_edges()
		var params_str = entry.substr(colon_index + 1).strip_edges()

		if action_id.is_empty():
			continue

		# 解析参数：param1=value1&param2=value2
		var param_dict = {}
		var param_pairs = params_str.split("&")
		for pair in param_pairs:
			if pair.is_empty():
				continue
			var eq_index = pair.find("=")
			if eq_index == -1:
				continue
			var key = pair.substr(0, eq_index).strip_edges()
			var value_str = pair.substr(eq_index + 1).strip_edges()
			param_dict[key] = value_str

		# 存入字典
		action_params[action_id] = param_dict

## 触发相变
func trigger_phase_transition() -> void:
	if phase2_sequence.size() > 0:
		# 使用预解析的新序列
		action_sequence = phase2_sequence.duplicate()
		action_index = 0
		has_transformed = true
		print("Enemy %s triggered phase transition! New sequence: %s" % [id, action_sequence])
	else:
		# 如果没有预解析序列，尝试从phase_transition中实时解析
		if phase_transition.contains(":"):
			var colon_index = phase_transition.find(":")
			if colon_index != -1:
				var new_sequence_str = phase_transition.substr(colon_index + 1)
				if not new_sequence_str.is_empty():
					action_sequence = new_sequence_str.split("→")
					action_index = 0
					has_transformed = true
					print("Enemy %s triggered phase transition! New sequence: %s" % [id, action_sequence])
					return

		# 如果都无法解析，至少重置索引
		action_index = 0
		has_transformed = true
		print("Enemy %s triggered phase transition! Reset index." % id)

## 获取当前行动序列（考虑相变）
func get_current_sequence() -> Array[String]:
	if has_transformed and phase2_sequence.size() > 0:
		return phase2_sequence
	return action_sequence

## 获取下一个行动并推进索引
func get_next_action() -> String:
	var sequence = get_current_sequence()
	if sequence.size() == 0:
		return ""

	var current_action_id = sequence[action_index]
	# 推进索引
	action_index = (action_index + 1) % sequence.size()
	return current_action_id

## 消耗冷却
func tick_cooldown() -> void:
	var to_remove = []
	for action_id in cooldown_actions.keys():
		cooldown_actions[action_id] -= 1
		if cooldown_actions[action_id] <= 0:
			to_remove.append(action_id)

	for action_id in to_remove:
		cooldown_actions.erase(action_id)

## 应用冷却
func apply_cooldown(action_id: String, rounds: int) -> void:
	if rounds > 0:
		cooldown_actions[action_id] = rounds

## 检查行动是否在冷却中
func is_action_on_cooldown(action_id: String) -> bool:
	return cooldown_actions.has(action_id) and cooldown_actions[action_id] > 0
