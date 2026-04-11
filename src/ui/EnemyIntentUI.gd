## EnemyIntentUI.gd
## 敌人意图UI组件（C3 - 敌人系统）
## 实现 Story 007: 敌人意图与状态UI绑定
## 依据 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyIntentUI extends Control

## 敌人ID
var enemy_id: String

## UI组件引用
@onready var hp_label: Label = $HPLabel
@onready var hp_progress_bar: ProgressBar = $HPProgressBar
@onready var intent_label: Label = $IntentLabel
@onready var intent_icon: TextureRect = $IntentIcon
@onready var charging_indicator: Control = $CharingIndicator

## 数据引用
var enemy_data: EnemyData = null
var enemy_manager: EnemyManager = null

## 初始化
func _ready() -> void:
	if not hp_label:
		push_error("EnemyIntentUI: HPLabel 未找到，请检查场景结构")
	if not hp_progress_bar:
		push_error("EnemyIntentUI: HPProgressBar 未找到，请检查场景结构")
	if not intent_label:
		push_error("EnemyIntentUI: IntentLabel 未找到，请检查场景结构")


## 设置敌人数据
func set_enemy_data(eid: String, enemy_mgr: EnemyManager) -> void:
	enemy_id = eid
	enemy_manager = enemy_mgr
	enemy_data = enemy_manager.get_enemy(eid)

	if enemy_data == null:
		push_error("EnemyIntentUI: 敌人ID不存在 — %s" % eid)
		return

	# 更新血量显示
	update_hp_display()

	# 连接伤害和治疗信号
	# TODO: 连接 BattleManager 的伤害/治疗信号


## 更新血量显示
func update_hp_display() -> void:
	if enemy_data == null:
		return

	var hp_text = "%d/%d" % [enemy_data.current_hp, enemy_data.max_hp]
	hp_label.text = hp_text

	# 更新进度条
	var hp_percent = float(enemy_data.current_hp) / float(enemy_data.max_hp) * 100.0
	hp_progress_bar.value = hp_percent

	# 根据血量调整颜色
	if hp_percent > 50:
		hp_progress_bar.modulate = Color.GREEN
	elif hp_percent > 25:
		hp_progress_bar.modulate = Color.YELLOW
	else:
		hp_progress_bar.modulate = Color.RED


## 更新意图显示
func update_intent_display(action_data: Dictionary) -> void:
	if action_data.is_empty():
		intent_label.text = "无行动"
		intent_icon.texture = null
		charging_indicator.visible = false
		return

	var action_name = action_data.get("name", "")
	var action_description = action_data.get("description", "")
	var is_charging = action_data.get("is_charging", false)

	# 显示蓄力状态
	if is_charging:
		intent_label.text = "蓄力中..."
		intent_label.modulate = Color.RED
		charging_indicator.visible = true
	elif action_description.contains("攻击") and action_description.contains("伤害"):
		# 提取伤害值
		var damage_match = _extract_damage_value(action_description)
		if damage_match > 0:
			intent_label.text = "攻击 %d点" % damage_match
		else:
			intent_label.text = action_name
		intent_label.modulate = Color.WHITE
		charging_indicator.visible = false
	else:
		intent_label.text = action_name
		intent_label.modulate = Color.WHITE
		charging_indicator.visible = false

	# 根据行动类型设置图标
	_set_intent_icon(action_data.get("type", ""))


## 蓄力状态特殊提示
## 显示当前蓄力行动，预告下回合将要释放的行动
func show_charging_preview(charging_action: Dictionary, next_turn_action: Dictionary) -> void:
	if charging_action.is_empty():
		return

	intent_label.text = "蓄力：%s → %s" % [
		charging_action.get("name", ""),
		next_turn_action.get("description", "")
	]
	intent_label.modulate = Color.ORANGE
	charging_indicator.visible = true


## 敌人死亡时隐藏
func on_enemy_death() -> void:
	visible = false
	# 或选择播放死亡动画后移除：
	# play_death_animation()
	# queue_free()


## 从行动描述中提取伤害值
func _extract_damage_value(description: String) -> int:
	var regex := RegEx.new()
	regex.compile("\\d+")
	var match_result: RegExMatch = regex.search(description)
	if match_result:
		return match_result.get_string().to_int()
	return 0


## 根据行动类型设置意图图标
func _set_intent_icon(action_type: String) -> void:
	# TODO: 根据action_type加载对应的图标纹理
	# 示例：
	# if action_type == "attack":
	#     intent_icon.texture = preload("res://ui/icons/attack.png")
	# elif action_type == "defend":
	#     intent_icon.texture = preload("res://ui/icons/defend.png")
	# ...

	# 临时设置简单颜色代替图标
	match action_type.to_lower():
		"attack":
			intent_icon.modulate = Color.RED
		"defend", "buff":
			intent_icon.modulate = Color.GREEN
		"heal":
			intent_icon.modulate = Color.CYAN
		"debuff", "curse":
			intent_icon.modulate = Color.PURPLE
		"summon":
			intent_icon.modulate = Color.YELLOW
		"special":
			intent_icon.modulate = Color.ORANGE
		_:
			intent_icon.modulate = Color.WHITE
