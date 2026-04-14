## EnemyActionPreviewHUD.gd
## 敌人行动公示 HUD（UI 层 — Story 4-12）
##
## 在敌人回合前展示当前敌人接下来最多 3 个行动的预告序列。
## 仅读取游戏状态，不修改任何游戏数据。
##
## 使用示例：
##   hud.initialize(turn_manager, enemy_manager)
##
## 场景搭建时，根节点下需要以下子节点结构：
##   $Container/TitleLabel
##   $Container/Slot0/ActionNameLabel
##   $Container/Slot0/DescriptionLabel
##   $Container/Slot0/CurrentIndicator
##   （Slot1, Slot2 同理）
##
## 设计文档：design/gdd/enemies-design.md
## ADR：ADR-0019（敌人行动参数覆盖系统）

class_name EnemyActionPreviewHUD extends Control

# ---------------------------------------------------------------------------
# 常量
# ---------------------------------------------------------------------------

## 最大预告槽位数量
const MAX_PREVIEW_SLOTS: int = 3

# ---------------------------------------------------------------------------
# 子节点（@onready 占位符，.tscn 中补全）
# ---------------------------------------------------------------------------

@onready var _container: VBoxContainer = $Container
@onready var _title_label: Label = $Container/TitleLabel

@onready var _slot_rows: Array[Control] = [
	$Container/Slot0,
	$Container/Slot1,
	$Container/Slot2,
]

@onready var _name_labels: Array[Label] = [
	$Container/Slot0/ActionNameLabel,
	$Container/Slot1/ActionNameLabel,
	$Container/Slot2/ActionNameLabel,
]

@onready var _desc_labels: Array[Label] = [
	$Container/Slot0/DescriptionLabel,
	$Container/Slot1/DescriptionLabel,
	$Container/Slot2/DescriptionLabel,
]

@onready var _current_indicators: Array[Control] = [
	$Container/Slot0/CurrentIndicator,
	$Container/Slot1/CurrentIndicator,
	$Container/Slot2/CurrentIndicator,
]

# ---------------------------------------------------------------------------
# 内部运行时状态
# ---------------------------------------------------------------------------

var _turn_manager: EnemyTurnManager = null
var _enemy_manager: EnemyManager = null
var _current_enemy_id: String = ""
var _executed_action_count: int = 0

# ---------------------------------------------------------------------------
# 内部数据类：行动槽
# ---------------------------------------------------------------------------

class _ActionSlot:
	var action_id:   String = ""
	var action_name: String = ""
	var summary:     String = ""
	var is_current:  bool   = false

# ---------------------------------------------------------------------------
# 生命周期
# ---------------------------------------------------------------------------

func _ready() -> void:
	_validate_nodes()
	_clear_all_slots()
	visible = false

# ---------------------------------------------------------------------------
# 公开 API
# ---------------------------------------------------------------------------

## 注入 EnemyTurnManager 与 EnemyManager 依赖，并连接信号。
## 必须在 _ready 之后调用。
##
## 参数：
##   turn_mgr   — 当前战斗的 EnemyTurnManager
##   enemy_mgr  — 当前战斗的 EnemyManager
##
## 示例：
##   hud.initialize(battle_manager.enemy_turn_manager, battle_manager.enemy_manager)
func initialize(turn_mgr: EnemyTurnManager, enemy_mgr: EnemyManager) -> void:
	_turn_manager  = turn_mgr
	_enemy_manager = enemy_mgr
	_connect_signals()
	_clear_all_slots()


## 强制刷新指定敌人的预告显示（相变后可调用）。
##
## 参数：
##   enemy_id — 要刷新预告的敌人 ID
func refresh_for_enemy(enemy_id: String) -> void:
	_current_enemy_id      = enemy_id
	_executed_action_count = 0
	_rebuild_preview(enemy_id)

# ---------------------------------------------------------------------------
# 信号连接
# ---------------------------------------------------------------------------

func _connect_signals() -> void:
	if _turn_manager == null:
		push_error("EnemyActionPreviewHUD: EnemyTurnManager 未注入，无法连接信号")
		return

	if not _turn_manager.enemy_turn_started.is_connected(_on_enemy_turn_started):
		_turn_manager.enemy_turn_started.connect(_on_enemy_turn_started)

	if not _turn_manager.enemy_turn_ended.is_connected(_on_enemy_turn_ended):
		_turn_manager.enemy_turn_ended.connect(_on_enemy_turn_ended)

	if not _turn_manager.enemy_action_executed.is_connected(_on_action_executed):
		_turn_manager.enemy_action_executed.connect(_on_action_executed)

# ---------------------------------------------------------------------------
# 信号回调
# ---------------------------------------------------------------------------

func _on_enemy_turn_started() -> void:
	# EnemyTurnManager 不携带 enemy_id，尝试从 action_queue 读取首个敌人
	if _turn_manager == null or _enemy_manager == null:
		return

	# 尝试从 action_queue 获取当前敌人 ID
	var first_enemy_id: String = _try_get_current_enemy_id()
	if first_enemy_id.is_empty():
		_clear_all_slots()
		return

	_current_enemy_id      = first_enemy_id
	_executed_action_count = 0
	_rebuild_preview(first_enemy_id)
	visible = true


func _on_action_executed(_enemy_id: String, _action_id: String) -> void:
	_executed_action_count += 1
	if not _current_enemy_id.is_empty():
		_rebuild_preview(_current_enemy_id)


func _on_enemy_turn_ended() -> void:
	_clear_all_slots()
	visible = false

# ---------------------------------------------------------------------------
# 核心：预告重建
# ---------------------------------------------------------------------------

## 根据当前敌人和已执行计数，重建最多 MAX_PREVIEW_SLOTS 个行动预告。
func _rebuild_preview(enemy_id: String) -> void:
	if _enemy_manager == null:
		push_error("EnemyActionPreviewHUD: EnemyManager 未注入")
		return

	var enemy: EnemyData = _enemy_manager.get_enemy(enemy_id)
	if enemy == null:
		_clear_all_slots()
		return

	# 获取行动序列
	var sequence: Array = _get_action_sequence(enemy)
	if sequence.is_empty():
		_clear_all_slots()
		return

	# 当前起始索引（已执行偏移）
	var base_index: int = (enemy.action_index + _executed_action_count) % sequence.size()

	for slot_idx: int in range(MAX_PREVIEW_SLOTS):
		var seq_index: int = (base_index + slot_idx) % sequence.size()
		var action_id: String = sequence[seq_index]
		var slot: _ActionSlot = _build_slot(action_id, enemy, slot_idx == 0)
		_render_slot(slot_idx, slot)


## 获取敌人行动序列（兼容不同字段命名）
func _get_action_sequence(enemy: EnemyData) -> Array:
	if enemy.has_method("get_current_sequence"):
		return enemy.get_current_sequence()
	if "action_sequence" in enemy:
		return enemy.action_sequence
	if "actions" in enemy:
		return enemy.actions
	return []


## 从 action_id + EnemyData 构建槽数据（遵循 ADR-0019 参数覆盖）
func _build_slot(action_id: String, enemy: EnemyData, is_current: bool) -> _ActionSlot:
	var slot := _ActionSlot.new()
	slot.action_id  = action_id
	slot.is_current = is_current

	# 从行动库查询基础数据
	var base_action: EnemyAction = _get_base_action(action_id)
	if base_action == null:
		slot.action_name = action_id
		slot.summary     = ""
		return slot

	slot.action_name = base_action.action_name if base_action.action_name != "" else action_id

	# ADR-0019：使用覆盖后的最终参数
	slot.summary = _format_summary(base_action, enemy)
	return slot


## 从 EnemyManager 获取基础行动数据
func _get_base_action(action_id: String) -> EnemyAction:
	if _enemy_manager == null:
		return null
	if _enemy_manager.has_method("get_action_by_id"):
		return _enemy_manager.get_action_by_id(action_id)
	# 回退：直接访问内部字典（兼容旧版本）
	if "_action_database" in _enemy_manager:
		return _enemy_manager._action_database.get(action_id, null)
	return null


## 格式化行动效果摘要（ADR-0019：显示覆盖后的数值）
func _format_summary(action: EnemyAction, enemy: EnemyData) -> String:
	# 获取该敌人对此行动的参数覆盖
	var params: Dictionary = {}
	if enemy.has_method("get_action_params"):
		params = enemy.get_action_params(action.action_id)
	elif "action_params" in enemy:
		params = enemy.action_params.get(action.action_id, {})

	# 读取最终数值（覆盖值优先）
	var damage: int  = params.get("damage", action.damage if "damage" in action else 0)
	var shield: int  = params.get("shield", action.shield if "shield" in action else 0)
	var heal: int    = params.get("heal", action.heal if "heal" in action else 0)
	var status: String = params.get("status", action.status_effect if "status_effect" in action else "")
	var layers: int  = params.get("layers", action.status_layers if "status_layers" in action else 0)

	# 根据行动类型生成描述
	var action_type: String = action.action_type if "action_type" in action else ""
	match action_type.to_lower():
		"attack":
			if damage > 0 and status != "" and layers > 0:
				return "攻击 %d + %s ×%d" % [damage, status, layers]
			elif damage > 0:
				return "攻击 %d" % damage
		"defend":
			if shield > 0:
				return "防御 +%d 护盾" % shield
		"heal":
			if heal > 0:
				return "治疗 %d HP" % heal
		"buff", "debuff":
			if status != "" and layers > 0:
				return "%s ×%d" % [status, layers]
		"curse":
			return TranslationServer.translate("ENEMY_ACTION_INJECT_CURSE")

	# 兜底：使用 description
	var desc: String = action.description if "description" in action else ""
	return desc

# ---------------------------------------------------------------------------
# 渲染
# ---------------------------------------------------------------------------

## 将槽数据写入对应行 UI 节点
func _render_slot(slot_idx: int, slot: _ActionSlot) -> void:
	if slot_idx >= MAX_PREVIEW_SLOTS:
		return

	if _name_labels.size() <= slot_idx or _name_labels[slot_idx] == null:
		return

	_name_labels[slot_idx].text = slot.action_name
	_desc_labels[slot_idx].text = slot.summary

	if _current_indicators.size() > slot_idx and _current_indicators[slot_idx] != null:
		_current_indicators[slot_idx].visible = slot.is_current

	if _slot_rows.size() > slot_idx and _slot_rows[slot_idx] != null:
		match slot_idx:
			0: _slot_rows[slot_idx].modulate = Color(1.0, 1.0, 1.0, 1.0)
			1: _slot_rows[slot_idx].modulate = Color(0.85, 0.85, 0.85, 0.9)
			2: _slot_rows[slot_idx].modulate = Color(0.65, 0.65, 0.65, 0.75)


## 清空所有槽位
func _clear_all_slots() -> void:
	for i: int in range(MAX_PREVIEW_SLOTS):
		if _name_labels.size() > i and _name_labels[i] != null:
			_name_labels[i].text = ""
		if _desc_labels.size() > i and _desc_labels[i] != null:
			_desc_labels[i].text = ""
		if _current_indicators.size() > i and _current_indicators[i] != null:
			_current_indicators[i].visible = false
		if _slot_rows.size() > i and _slot_rows[i] != null:
			_slot_rows[i].modulate = Color.WHITE

# ---------------------------------------------------------------------------
# 辅助
# ---------------------------------------------------------------------------

## 尝试从 action_queue 获取当前活跃敌人 ID
func _try_get_current_enemy_id() -> String:
	if _turn_manager == null:
		return ""
	if "action_queue" in _turn_manager and _turn_manager.action_queue != null:
		var queue: EnemyActionQueue = _turn_manager.action_queue
		if "queue" in queue and not queue.queue.is_empty():
			var first = queue.queue[0]
			if "source_enemy_id" in first:
				return first.source_enemy_id
			if "enemy_id" in first:
				return first.enemy_id
	return ""


## 节点校验（在 _ready 中调用）
func _validate_nodes() -> void:
	if _container == null:
		push_error("EnemyActionPreviewHUD: 缺少 $Container 节点，请检查场景结构")
	if _title_label == null:
		push_warning("EnemyActionPreviewHUD: 缺少 $Container/TitleLabel（可选节点）")
	for i: int in range(MAX_PREVIEW_SLOTS):
		if _slot_rows.size() <= i or _slot_rows[i] == null:
			push_error("EnemyActionPreviewHUD: 缺少 Slot%d 节点" % i)
		if _name_labels.size() <= i or _name_labels[i] == null:
			push_error("EnemyActionPreviewHUD: 缺少 Slot%d/ActionNameLabel 节点" % i)
		if _desc_labels.size() <= i or _desc_labels[i] == null:
			push_error("EnemyActionPreviewHUD: 缺少 Slot%d/DescriptionLabel 节点" % i)
