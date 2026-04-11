## EnemyView.gd
## 敌人视图组件（C3 - 敌人系统）
## 实现 Story 007: 敌人意图与状态UI绑定
## 集成 EnemyIntentUI 并连接战斗系统信号
## 依据 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyView extends Control

## 信号
signal enemy_clicked(enemy_id: String)

## 组件引用
@onready var intent_ui: EnemyIntentUI = $EnemyIntentUI
@onready var enemy_sprite: Sprite2D = $EnemySprite

## 数据引用
var enemy_id: String
var battle_manager: BattleManager
var enemy_manager: EnemyManager

## 初始化
func _ready() -> void:
	if intent_ui == null:
		push_error("EnemyView: EnemyIntentUI 未找到，请检查场景结构")
		return


## 设置敌人数据
func initialize(eid: String, battle_mgr: BattleManager, enemy_mgr: EnemyManager) -> void:
	enemy_id = eid
	battle_manager = battle_mgr
	enemy_manager = enemy_mgr

	# 初始化意图UI
	intent_ui.set_enemy_data(eid, enemy_mgr)

	# 连接战斗信号
	_connect_battle_signals()


## 连接战斗信号
func _connect_battle_signals() -> void:
	if battle_manager == null:
		return

	# 连接回合开始信号（玩家回合开始时刷新意图）
	if not battle_manager.turn_started.is_connected(_on_turn_started):
		battle_manager.turn_started.connect(_on_turn_started)

	# 连接卡牌打出信号（玩家攻击敌人时更新血量）
	if not battle_manager.card_played.is_connected(_on_card_played):
		battle_manager.card_played.connect(_on_card_played)


## 玩家回合开始时刷新敌人意图
func _on_turn_started(is_player: bool) -> void:
	if not is_player:
		return

	# 刷新意图显示
	refresh_intent_display()


## 卡牌打出时检查是否攻击此敌人
func _on_card_played(card_id: String, target_position: int) -> void:
	# TODO: 检查目标位置是否为此敌人
	# 根据卡牌效果判断是否影响此敌人
	# 更新血量显示
	refresh_hp_display()


## 刷新意图显示
func refresh_intent_display() -> void:
	if enemy_manager == null:
		return

	var action_data = enemy_manager.get_displayed_action(enemy_id)
	intent_ui.update_intent_display(action_data)


## 刷新血量显示
func refresh_hp_display() -> void:
	if intent_ui:
		intent_ui.update_hp_display()


## 敌人死亡处理
func on_enemy_death() -> void:
	if intent_ui:
		intent_ui.on_enemy_death()

	# 播放死亡动画或隐藏
	visible = false


## 敌人受击处理（带动画）
func on_enemy_damaged(damage: int) -> void:
	refresh_hp_display()

	# 播放受击动画（使用 Tween）
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.2)


## 点击敌人（选择目标）
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		enemy_clicked.emit(enemy_id)
