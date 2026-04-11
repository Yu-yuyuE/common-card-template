## EnemyTurnManager.gd
## 敌人回合管理器（C3 - 敌人系统）
## 实现 Story 005: 敌人行动队列执行器
## 依据 ADR-0015 和 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyTurnManager extends Node

## 信号
signal enemy_turn_started()
signal enemy_turn_ended()

## 组件引用
@onready var action_queue: EnemyActionQueue = EnemyActionQueue.new()
@onready var enemy_manager: EnemyManager = null  # 由BattleManager注入
@onready var action_executor: ActionExecutor = ActionExecutor.new()  # 新增：执行器

## 初始化
func _ready() -> void:
	add_child(action_queue)
	add_child(action_executor)  # 添加执行器到场景树
	# 连接队列完成信号
	action_queue.all_actions_completed.connect(_on_all_actions_completed)


## 执行敌人回合
## enemies: Array[EnemyData] - 本回合要行动的敌人列表
## interval: float - 行动间隔时间（默认0.8秒）
func execute_enemy_turn(enemies: Array[EnemyData], interval: float = 0.8) -> void:
	enemy_turn_started.emit()

	# 清空上一次的行动队列
	action_queue.clear()

	# 1. 为每个存活敌人获取行动并加入队列
	for enemy in enemies:
		if not enemy.is_alive:
			continue

		# 获取敌人下一回合的行动
		var action_data: Dictionary = enemy_manager.get_next_action(enemy.id)

		if action_data.is_empty():
			# 如果没有行动（如眩晕），跳过
			continue

		# 创建EnemyAction对象
		var action: EnemyAction = EnemyAction.new()
		action._init(
			action_data.get("id", ""),
			action_data.get("name", ""),
			action_data.get("tier", "普通"),
			action_data.get("type", "attack"),
			action_data.get("target", "player"),
			action_data.get("description", ""),
			action_data.get("value_reference", ""),
			action_data.get("cooldown", 0),
			action_data.get("condition", "")
		)
		action.source_enemy_id = enemy.id
		action.animation = action_data.get("animation", "")

		# 加入队列
		action_queue.add_action(action)

	# 2. 设置执行器引用
	action_executor.initialize(_battle_manager, _status_manager, enemy_manager)

	# 3. 执行所有行动
	action_queue.execute_all(interval)


## 所有行动完成回调
func _on_all_actions_completed() -> void:
	enemy_turn_ended.emit()


## 设置敌人管理器（由BattleManager调用）
func set_enemy_manager(manager: EnemyManager) -> void:
	enemy_manager = manager


## 设置战斗管理器和状态管理器（由BattleManager调用）
func set_battle_manager(battle_mgr: BattleManager, status_mgr: StatusManager) -> void:
	_battle_manager = battle_mgr
	_status_manager = status_mgr
	# 传递给执行器
	action_executor.initialize(battle_mgr, status_mgr, enemy_manager)

# 内部变量
var _battle_manager: BattleManager = null
var _status_manager: StatusManager = null