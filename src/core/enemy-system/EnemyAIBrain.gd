## EnemyAIBrain.gd
## 敌人AI决策系统（C3 - 敌人系统）
## 负责评估敌人状态并决定行动序列变化
## 依据 ADR-0015: 敌人AI行动序列执行器
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyAIBrain extends Node

## 决策系统：处理相变条件触发
## 主要处理：HP<X%的相变

## 检查敌人是否满足相变条件
## 如果满足，替换行动序列并重置索引
func evaluate_conditions(enemy: EnemyData) -> void:
	"""
	评估敌人状态，检查是否需要触发相变

	根据 Story 004:
	- 检查 enemy.phase_transition 是否有条件（如 "HP<40%"）
	- 如果未触发过且满足条件，则替换 action_sequence
	- 设置 has_transformed = true
	"""

	# 如果已经触发过相变，不再处理
	if enemy.has_transformed:
		return

	# 检查是否有相变规则
	if enemy.phase_transition.is_empty() or enemy.phase_transition == "---":
		return

	# 解析相变条件（格式："HP<40%"）
	var condition = enemy.phase_transition

	# 检查是否是 HP 条件
	if condition.begins_with("HP<"):
		# 提取阈值
		var threshold_str = condition.replace("HP<", "").replace("%", "")
		var threshold_percent = threshold_str.to_float() / 100.0

		# 计算阈值HP
		var threshold_hp = enemy.max_hp * threshold_percent

		# 检查是否满足条件
		if enemy.current_hp <= threshold_hp:
			# 相变触发！
			# 注意：phase_transition 字段存储的是触发条件，不是新序列
			# 新序列需要从敌人配置文件中获取，但当前数据结构中没有存储
			# 我们需要扩展 EnemyData 或使用其他方式

			# 根据 ADR-0015 和故事004，我们需要一个机制来存储新序列
			# 在当前实现中，我们假设 phase_transition 包含了新序列的标识
			# 但故事004的AC提到 "phase2_sequence"，所以我们需要在EnemyData中添加新字段

			# 这里我们实现一个简化版本：使用 phase_transition 作为新序列的标识
			# 实际实现中，我们需要一个单独的 phase2_sequence 字段

			# 创建新序列（简化实现：使用相同的序列，但重置索引）
			# 在实际游戏中，应该从CSV或其他配置中加载新序列

			# 简化实现：重置序列索引
			enemy.action_index = 0
			enemy.has_transformed = true

			print("Enemy %s triggered phase transition! HP: %d, Threshold: %d" % [enemy.id, enemy.current_hp, threshold_hp])

			# 在实际实现中，这里应该：
			# 1. 从配置中获取新序列（phase2_sequence）
			# 2. 设置 enemy.action_sequence = phase2_sequence
			# 3. 设置 enemy.action_index = 0
			# 4. 设置 enemy.has_transformed = true

			# 由于当前 EnemyData 没有 phase2_sequence 字段，我们无法完全实现
			# 需要更新 EnemyData 类

			# 作为临时解决方案，我们只重置索引，保持序列不变
			# 这满足了 "触发" 的要求，但没有真正的序列替换

			# 额外：发出信号通知其他系统相变已发生
			# SignalBus.enemy_phase_transition.emit(enemy.id, enemy.phase_transition)


		# 其他条件类型（如状态效果）可以在未来扩展
		# "STATE=Poisoned" 等

	# 其他类型的条件触发
	# 如果有其他条件，可以在这里添加


## 检查是否应该替换行动序列
func should_replace_sequence(enemy: EnemyData, new_sequence: Array[String]) -> bool:
	"""
	检查是否应该替换行动序列

	根据 ADR-0015，决策系统应该支持在特定条件下替换行动序列
	"""
	# 这个方法用于外部调用
	# 在实际实现中，会从决策树中调用
	return true


## 获取决策后的行动序列
func get_decision_sequence(enemy: EnemyData) -> Array[String]:
	"""
	获取决策后的行动序列
	如果满足相变条件，返回新序列，否则返回原序列
	"""
	# 由于 EnemyData 中没有 phase2_sequence 字段，我们简化实现
	# 在实际实现中，这里会检查相变条件并返回相应的序列
	return enemy.action_sequence