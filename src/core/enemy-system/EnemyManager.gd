## EnemyManager.gd
## 敌人系统管理器（C3 - 敌人系统）
## 负责加载和管理所有敌人数据
## 依据 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

## 敌人系统管理器
## 采用单例模式，作为全局资源加载敌人数据

class_name EnemyManager extends Node

## 敌人数据字典：id -> EnemyData
var _enemies: Dictionary = {}

## 行动数据字典：action_id -> EnemyAction
var _action_database: Dictionary = {}

## 加载敌人数据的CSV文件路径
const DATA_PATH: String = "res://assets/csv_data/enemies.csv"

## 加载敌人行动库的CSV文件路径
const ACTION_DATA_PATH: String = "res://assets/csv_data/enemy_actions.csv"

## 预定义敌人职业和等级
enum EnemyClass {
	INFANTRY  = 0, ## 步兵
	CAVALRY   = 1, ## 骑兵
	ARCHER    = 2, ## 弓兵
	STRATEGIST = 3, ## 谋士
	SHIELD    = 4, ## 盾兵
}

enum EnemyTier {
	NORMAL    = 0, ## 普通
	ELITE     = 1, ## 精英
	STRONG    = 2, ## 强力
}

# 初始化时加载敌人数据
func _ready() -> void:
	_load_enemy_data()
	_load_action_library()


## 从CSV文件加载所有敌人数据
func _load_enemy_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("EnemyManager: 敌人数据文件未找到 — %s" % DATA_PATH)
		return

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("EnemyManager: 无法打开敌人数据文件 — %s" % DATA_PATH)
		return

	# 跳过标题行
	var _header_line := file.get_line()

	var loaded_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		# 跳过空行
		if line.is_empty():
			continue

		var fields: PackedStringArray = line.split(",")
		if fields.size() < 9:
			push_warning("EnemyManager: 行字段数不足，跳过 — [%s]" % line)
			continue

		# 解析字段
		var id: String = fields[0].strip_edges()
		var name: String = fields[1].strip_edges()
		var class_str: String = fields[2].strip_edges().to_upper()
		var tier_str: String = fields[3].strip_edges().to_upper()
		var max_hp: int = fields[4].strip_edges().to_int()
		var armor: int = fields[5].strip_edges().to_int()
		var speed: int = fields[6].strip_edges().to_int()
		var action_sequence_str: String = fields[7].strip_edges()
		var phase_transition: String = fields[8].strip_edges()

		# 解析职业
		var enemy_class: int = -1
		match class_str:
			"INFANTRY": enemy_class = EnemyClass.INFANTRY
			"CAVALRY": enemy_class = EnemyClass.CAVALRY
			"ARCHER": enemy_class = EnemyClass.ARCHER
			"STRATEGIST": enemy_class = EnemyClass.STRATEGIST
			"SHIELD": enemy_class = EnemyClass.SHIELD
			_:
				push_warning("EnemyManager: 未知职业 '%s'，默认 INFANTRY" % class_str)
				enemy_class = EnemyClass.INFANTRY

		# 解析等级
		var tier: int = -1
		match tier_str:
			"NORMAL": tier = EnemyTier.NORMAL
			"ELITE": tier = EnemyTier.ELITE
			"STRONG": tier = EnemyTier.STRONG
			_:
				push_warning("EnemyManager: 未知等级 '%s'，默认 NORMAL" % tier_str)
				tier = EnemyTier.NORMAL

		# 解析行动序列
		var action_sequence: Array[String] = []
		if not action_sequence_str.is_empty() and action_sequence_str != "---":
			action_sequence = action_sequence_str.split("→")

		# 创建敌人数据
		var enemy_data := EnemyData.new()
		enemy_data._init(
			id,
			name,
			enemy_class,
			tier,
			max_hp,
			armor,
			speed
		)
		enemy_data.action_sequence = action_sequence
		enemy_data.phase_transition = phase_transition

		# 存入字典
		_enemies[id] = enemy_data
		loaded_count += 1

	file.close()
	print("EnemyManager: 加载了 %d 个敌人" % loaded_count)


## 从CSV文件加载所有敌人行动
func _load_action_library() -> void:
	if not FileAccess.file_exists(ACTION_DATA_PATH):
		push_error("EnemyManager: 行动库文件未找到 — %s" % ACTION_DATA_PATH)
		return

	var file := FileAccess.open(ACTION_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("EnemyManager: 无法打开行动库文件 — %s" % ACTION_DATA_PATH)
		return

	# 跳过标题行
	var _header_line := file.get_line()

	var loaded_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		# 跳过空行
		if line.is_empty():
			continue

		var fields: PackedStringArray = line.split(",")
		if fields.size() < 8:
			push_warning("EnemyManager: 行动库行字段数不足，跳过 — [%s]" % line)
			continue

		# 解析字段
		var id: String = fields[0].strip_edges()
		var name: String = fields[1].strip_edges()
		var tier: String = fields[2].strip_edges()
		var description: String = fields[3].strip_edges()
		var target: String = fields[4].strip_edges()
		var value_reference: String = fields[5].strip_edges()
		var cooldown: int = 0
		var condition: String = ""

		# 解析冷却回合
		if fields.size() > 6:
			var cooldown_str = fields[6].strip_edges()
			if not cooldown_str.is_empty() and cooldown_str != "—":
				cooldown = cooldown_str.to_int()

		# 解析条件触发
		if fields.size() > 7:
			condition = fields[7].strip_edges()

		# 创建行动数据
		var action := EnemyAction.new()
		action._init(
			id,
			name,
			tier,
			"",  # type will be determined by parsing
			target,
			description,
			value_reference,
			cooldown,
			condition
		)

		# 存入字典
		_action_database[id] = action
		loaded_count += 1

	file.close()
	print("EnemyManager: 加载了 %d 种敌人行动" % loaded_count)


## 根据ID获取敌人数据
func get_enemy(id: String) -> EnemyData:
	return _enemies.get(id, null)


## 获取所有敌人数据
func get_all_enemies() -> Array:
	return _enemies.values()


## 按职业获取敌人列表
func get_enemies_by_class(enemy_class: int) -> Array:
	var result: Array = []
	for enemy in _enemies.values():
		if enemy.enemy_class == enemy_class:
			result.append(enemy)
	return result


## 按等级获取敌人列表
func get_enemies_by_tier(tier: int) -> Array:
	var result: Array = []
	for enemy in _enemies.values():
		if enemy.tier == tier:
			result.append(enemy)
	return result


## 按职业和等级获取敌人列表
func get_enemies_by_class_and_tier(enemy_class: int, tier: int) -> Array:
	var result: Array = []
	for enemy in _enemies.values():
		if enemy.enemy_class == enemy_class and enemy.tier == tier:
			result.append(enemy)
	return result


## 按ID查找敌人（用于调试）
func find_enemy_by_name(enemy_name: String) -> EnemyData:
	for enemy in _enemies.values():
		if enemy.name == enemy_name:
			return enemy
	return null


## 获取敌人总数
func get_enemy_count() -> int:
	return _enemies.size()


## 获取敌人下一回合要执行的行动（推进计数器）
func get_next_action(enemy_id: String) -> Dictionary:
	"""
	获取敌人下一回合的行动，推进内部计数器

	根据 ADR-0008 和 Story 003:
	- 如果当前行动在冷却中，使用备用行动
	- 无论是否使用备用行动，action_index 都要推进
	- 如果敌人处于眩晕状态，跳过行动但推进计数器
	"""
	var enemy = _enemies.get(enemy_id)
	if enemy == null or not enemy.is_alive:
		return {}

	# 检查眩晕状态 - 由 StatusManager 提供
	# 在实际实现中，需要调用 StatusManager.is_status_active(enemy_id, "stun")
	# 这里为了简化，假设我们有这个功能
	# 根据故事003，如果眩晕，跳过行动但推进计数器
	if is_enemy_stunned(enemy_id):
		# 眩晕状态：跳过行动，但推进计数器
		enemy.action_index = (enemy.action_index + 1) % enemy.action_sequence.size()
		return {}

	# 获取当前行动ID
	var current_action_id = enemy.action_sequence[enemy.action_index]

	# 检查冷却
	if enemy.cooldown_actions.has(current_action_id):
		var remaining_cooldown = enemy.cooldown_actions[current_action_id]
		if remaining_cooldown > 0:
			# 冷却中，使用备用行动
			current_action_id = _get_backup_action(enemy)

	# 获取行动数据
	var action_data = _get_action_data(current_action_id)

	# 移动到序列下一位（即使在冷却时也要推进计数器）
	enemy.action_index = (enemy.action_index + 1) % enemy.action_sequence.size()

	return action_data


## 获取敌人当前回合公示的行动（不推进计数器）
func get_displayed_action(enemy_id: String) -> Dictionary:
	"""
	获取敌人当前回合公示的行动（玩家回合开始前），不推进计数器

	根据 ADR-0008 和 Story 003:
	- 如果当前行动在冷却中，公示备用行动
	- 不推进 action_index
	- 如果敌人处于眩晕状态，公示为 "SKIPPED" 或类似状态
	"""
	var enemy = _enemies.get(enemy_id)
	if enemy == null:
		return {}

	# 检查眩晕状态
	if is_enemy_stunned(enemy_id):
		return {"id": "SKIPPED", "name": "眩晕", "description": "本回合因眩晕无法行动", "target": "none"}

	# 获取当前行动ID（不推进计数器）
	var current_action_id = enemy.action_sequence[enemy.action_index]

	# 检查冷却
	if enemy.cooldown_actions.has(current_action_id):
		var remaining_cooldown = enemy.cooldown_actions[current_action_id]
		if remaining_cooldown > 0:
			# 冷却中，使用备用行动
			current_action_id = _get_backup_action(enemy)

	# 获取行动公示信息
	return _get_action_display(current_action_id)


## 获取备用行动（当前行动在冷却中时）
func _get_backup_action(enemy: EnemyData) -> String:
	"""
	获取备用行动（当前行动在冷却中时）
	根据 Story 003 的说明：直接使用序列中下一个非冷却行动
	"""
	# 简单策略：从当前索引开始，找到第一个非冷却的行动
	var index = enemy.action_index
	var sequence_size = enemy.action_sequence.size()

	for i in range(sequence_size):
		var next_index = (index + i) % sequence_size
		var action_id = enemy.action_sequence[next_index]
		if not enemy.cooldown_actions.has(action_id):
			return action_id

	# 如果所有行动都在冷却中，返回第一个行动（最安全的后备）
	return enemy.action_sequence[0]


## 检查敌人是否处于眩晕状态
func is_enemy_stunned(enemy_id: String) -> bool:
	"""
	检查敌人是否处于眩晕状态
	需要与 StatusManager 集成
	"""
	# 这里只是占位，实际实现需要从 StatusManager 获取状态
	# 由于 Story 003 不负责状态管理，我们暂时返回 false
	# 实际实现中，会调用 StatusManager 的接口
	return false


## 处理敌人受到伤害事件
func on_enemy_damage_dealt(enemy_id: String, damage: int) -> void:
	"""
	当敌人受到伤害时调用
	检查是否触发相变条件
	"""
	var enemy = _enemies.get(enemy_id)
	if enemy == null:
		return

	# 更新当前生命值
	enemy.current_hp -= damage

	# 检查相变条件
	# 由于我们没有直接访问 EnemyAIBrain，这里直接调用逻辑
	# 在实际实现中，应该由 EnemyTurnManager 或 BattleManager 调用
	# 这里为了简化，直接处理

	# 检查是否满足相变条件
	if not enemy.has_transformed and not enemy.phase_transition.is_empty() and enemy.phase_transition != "---":
		# 解析相变条件
		if enemy.phase_transition.begins_with("HP<"):
			var threshold_str = enemy.phase_transition.replace("HP<", "").replace("%", "")
			var threshold_percent = threshold_str.to_float() / 100.0
			var threshold_hp = enemy.max_hp * threshold_percent

			# 检查是否满足条件
			if enemy.current_hp <= threshold_hp:
				# 相变触发！
				# 从 phase_transition 解析新序列
				# 格式："HP<40%:B01→C01→B14→C12"
				var colon_index = enemy.phase_transition.find(":")
				if colon_index != -1:
					# 提取新序列
					var new_sequence_str = enemy.phase_transition.substr(colon_index + 1)
					if new_sequence_str.is_empty() == false:
						enemy.phase2_sequence = new_sequence_str.split("→")
						enemy.action_sequence = enemy.phase2_sequence
						enemy.action_index = 0
						enemy.has_transformed = true
						print("Enemy %s triggered phase transition! New sequence: %s" % [enemy_id, enemy.action_sequence])

				# 如果没有新序列，只重置索引
				else:
					enemy.action_index = 0
					enemy.has_transformed = true
					print("Enemy %s triggered phase transition! Reset index." % enemy_id)


## 处理敌人受到治疗事件
func on_enemy_healed(enemy_id: String, heal_amount: int) -> void:
	"""
	当敌人被治疗时调用
	"""
	var enemy = _enemies.get(enemy_id)
	if enemy == null:
		return

	# 更新当前生命值
	enemy.current_hp += heal_amount
	# 确保不超过最大生命值
	enemy.current_hp = min(enemy.current_hp, enemy.max_hp)


## 获取行动详细信息
func _get_action_data(action_id: String) -> Dictionary:
	"""
	获取行动详细信息
	"""
	return _action_database.get(action_id, {})


## 获取行动公示信息
func _get_action_display(action_id: String) -> Dictionary:
	"""
	获取行动公示信息
	"""
	var action_data = _get_action_data(action_id)
	return {
		"id": action_id,
		"name": action_data.get("name", ""),
		"description": action_data.get("description", ""),
		"target": action_data.get("target", "player"),
		"is_charging": action_data.get("is_charging", false),
		"charge_target": action_data.get("charge_target", "")
	}
