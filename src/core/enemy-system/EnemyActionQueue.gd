## EnemyActionQueue.gd
## 敌人行动队列执行器（C3 - 敌人系统）
## 实现 Story 005: 行动队列与间隔执行
## 依据 ADR-0015 和 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyActionQueue extends Node

## 信号
signal action_started(action: EnemyAction)
signal action_completed(action: EnemyAction)
signal all_actions_completed()

## 行动队列
var queue: Array[EnemyAction] = []

## 执行器状态
var is_executing: bool = false

## 添加行动到队列
func add_action(action: EnemyAction) -> void:
	queue.append(action)

## 执行队列中所有行动（带间隔）
func execute_all(interval: float = 0.8) -> void:
	if is_executing:
		return  # 防止重复调用

	is_executing = true
	var index: int = 0

	# 内部协程执行函数
	func _execute_next() -> void:
		if index >= queue.size():
			all_actions_completed.emit()
			is_executing = false
			return

		var action: EnemyAction = queue[index]
		index += 1

		# 检查敌人是否存活
		var enemy: EnemyData = EnemyManager.get_enemy(action.source_enemy_id)
		if enemy == null or not enemy.is_alive:
			# 跳过死亡敌人，直接执行下一个
			await get_tree().create_timer(interval).timeout
			_execute_next()
			return

		# 激活动画和效果
		action_started.emit(action)

		# 执行单个行动（调用 Story 006 的效果派发器）
		await _execute_single_action(action)

		# 等待间隔后执行下一个行动
		await get_tree().create_timer(interval).timeout
		_execute_next()

	# 启动执行流程
	_execute_next()

## 执行单个行动（调用效果派发器）
func _execute_single_action(action: EnemyAction) -> void:
	# 检查行动是否有效
	if action == null:
		return

	# 调用 Story 006 的效果派发器（待实现）
	# 在实际实现中，这里会调用 StatusManager 或 ActionExecutor
	# 本实现仅模拟调用，由 Story 006 完成具体效果

	# 模拟执行效果
	# ActionExecutor.execute_action(action)

	# 模拟动画播放
	if action.animation != "":
		# 播放对应动画
		# Animator.play_animation(action.animation)
		pass

	# 发射完成信号
	action_completed.emit(action)

## 清空队列
func clear() -> void:
	queue.clear()
	is_executing = false