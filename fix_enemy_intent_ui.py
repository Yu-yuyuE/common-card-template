content = '''## EnemyIntentUI.gd
## 敌人意图UI组件（C3 - 敌人系统）
## 实现 Story 007: 敌人意图与状态UI绑定
## 依据 design/gdd/enemies-design.md

class_name EnemyIntentUI extends Control

## 敌人ID
var enemy_id: String

## UI组件引用
@onready var hp_label: Label = $HPLabel
@onready var hp_progress_bar: ProgressBar = $HPProgressBar
@onready var intent_label: Label = $IntentLabel
@onready var intent_icon: TextureRect = $IntentIcon
@onready var charging_indicator: Control = $ChargingIndicator  # Fixed typo from CharingIndicator

## 数据引用
var enemy_data: EnemyData = null

## 预编译的 RegEx（避免热路径分配）
var _damage_regex: RegEx

func _ready() -> void:
	if not hp_label:
		push_error("EnemyIntentUI: HPLabel 未找到，请检查场景结构")
	if not hp_progress_bar:
		push_error("EnemyIntentUI: HPProgressBar 未找到，请检查场景结构")
	if not intent_label:
		push_error("EnemyIntentUI: IntentLabel 未找到，请检查场景结构")
	
	# 预编译 RegEx
	_damage_regex = RegEx.new()
	_damage_regex.compile("\d+")


## 设置敌人数据（不再接受 Manager 引用，只接受 DTO）
func set_enemy_data(eid: String, enemy_dto: EnemyData) -> void:
	enemy_id = eid
	enemy_data = enemy_dto
	
	if enemy_data == null:
		push_error("EnemyIntentUI: 敌人数据为空 — %s" % eid)
		return
	
	update_hp_display()


## 更新血量显示
func update_hp_display() -> void:
	if enemy_data == null:
		return
	
	var hp_text = "%d/%d" % [enemy_data.current_hp, enemy_data.max_hp]
	hp_label.text = hp_text
	
	var hp_percent = float(enemy_data.current_hp) / float(enemy_data.max_hp) * 100.0
	hp_progress_bar.value = hp_percent
	
	if hp_percent > 50:
		hp_progress_bar.modulate = Color.GREEN
	elif hp_percent > 25:
		hp_progress_bar.modulate = Color.YELLOW
	else:
		hp_progress_bar.modulate = Color.RED


## 更新意图显示（通过信号调用的接口）
func update_intent_display(action_data: Dictionary) -> void:
	if action_data.is_empty():
		intent_label.text = LocalizationManager.get_text("enemy.intent.no_action")
		intent_icon.texture = null
		charging_indicator.visible = false
		return
	
	var action_name = action_data.get("name", "")
	var action_description = action_data.get("description", "")
	var is_charging = action_data.get("is_charging", false)
	
	if is_charging:
		intent_label.text = LocalizationManager.get_text("enemy.intent.charging")
		intent_label.modulate = Color.RED
		charging_indicator.visible = true
	elif "attack" in action_data.get("type", "").to_lower():
		var damage_match = _extract_damage_value(action_description)
		if damage_match > 0:
			intent_label.text = LocalizationManager.get_text("enemy.intent.attack_damage", [damage_match])
		else:
			intent_label.text = action_name
		intent_label.modulate = Color.WHITE
		charging_indicator.visible = false
	else:
		intent_label.text = action_name
		intent_label.modulate = Color.WHITE
		charging_indicator.visible = false
	
	_set_intent_icon(action_data.get("type", ""))


## 蓄力状态特殊提示
func show_charging_preview(charging_action: Dictionary, next_turn_action: Dictionary) -> void:
	if charging_action.is_empty():
		return
	
	intent_label.text = LocalizationManager.get_text(
		"enemy.intent.charging_preview",
		[charging_action.get("name", ""), next_turn_action.get("description", "")]
	)
	intent_label.modulate = Color.ORANGE
	charging_indicator.visible = true


## 敌人死亡时隐藏
func on_enemy_death() -> void:
	visible = false


## 从行动描述中提取伤害值（使用预编译 RegEx）
func _extract_damage_value(description: String) -> int:
	var match_result: RegExMatch = _damage_regex.search(description)
	if match_result:
		return match_result.get_string().to_int()
	return 0


## 根据行动类型设置意图图标
func _set_intent_icon(action_type: String) -> void:
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
'''

with open('src/ui/EnemyIntentUI.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed EnemyIntentUI.gd")
