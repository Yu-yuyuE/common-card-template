## StatusEffectHUD.gd
## 战斗 HUD——状态效果可视化面板（Story 4-11）
##
## 职责：以只读方式订阅 StatusManager 的信号，将当前激活状态
##       以"图标占位符 + 名称 + 层数"的形式排列展示，最多 8 格，
##       超出时在末尾显示 +N more 溢出文字。
##
## 使用示例：
##   var hud := StatusEffectHUD.new()
##   add_child(hud)
##   hud.setup(player_status_manager)
##
## 依赖：
##   - StatusManager（依赖注入，不持有所有权）
##   - StatusEffect（数据层，只读查询）
##
## 设计约束：
##   - 本节点不修改任何游戏状态（display-only）
##   - 最多同时显示 MAX_VISIBLE_SLOTS 个状态槽
##   - 所有用户可见文字由 StatusEffect 元数据提供
##
## 设计文档：design/gdd/status-effects.md

class_name StatusEffectHUD extends Control

# ---------------------------------------------------------------------------
# 常量
# ---------------------------------------------------------------------------

## 最多同时显示的状态槽数量
const MAX_VISIBLE_SLOTS: int = 8

## 图标占位符尺寸（像素）
const ICON_SIZE: int = 32

## Buff 图标颜色
const BUFF_COLOR: Color = Color(0.3, 0.5, 0.9)

## Debuff 图标颜色
const DEBUFF_COLOR: Color = Color(0.9, 0.3, 0.3)

# ---------------------------------------------------------------------------
# 内部辅助类：单个状态槽（程序化节点）
# ---------------------------------------------------------------------------

class _StatusSlot:
	## 槽位根容器
	var root: PanelContainer
	## 图标占位符（ColorRect，颜色按 buff/debuff 区分）
	var icon: ColorRect
	## 名称 + 层数标签（格式："名称\n×层数"）
	var label: Label

	func _init() -> void:
		root  = PanelContainer.new()
		var vbox := VBoxContainer.new()
		icon  = ColorRect.new()
		label = Label.new()

		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)

		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode        = TextServer.AUTOWRAP_ARBITRARY

		vbox.add_child(icon)
		vbox.add_child(label)
		root.add_child(vbox)

	## 用效果数据填充槽位并设为可见
	func show_effect(effect_type_int: int, stacks: int, name_text: String, is_buff: bool) -> void:
		icon.color = BUFF_COLOR if is_buff else DEBUFF_COLOR
		label.text = name_text + "\n×" + str(stacks)
		root.visible = true

	## 隐藏并清空槽位
	func hide_slot() -> void:
		root.visible = false
		label.text   = ""

# ---------------------------------------------------------------------------
# 子节点（程序化创建于 _ready）
# ---------------------------------------------------------------------------

## 状态槽容器（HBoxContainer）
var _slot_container: HBoxContainer

## 固定 8 个槽位节点，循环复用
var _slots: Array = []

## 溢出提示标签（"+N more"）
var _overflow_label: Label

# ---------------------------------------------------------------------------
# 内部引用（不持有所有权）
# ---------------------------------------------------------------------------

## 当前监听的 StatusManager 实例；null = 未绑定
var _status_manager: StatusManager = null

# ---------------------------------------------------------------------------
# 生命周期
# ---------------------------------------------------------------------------

func _ready() -> void:
	_build_layout()


# ---------------------------------------------------------------------------
# 公开接口
# ---------------------------------------------------------------------------

## 注入 StatusManager 依赖并绑定信号。
## 必须在 _ready 之后调用。
##
## 参数：
##   manager — 目标单位的 StatusManager 实例（不可为 null）
##
## 示例：
##   hud.setup(battle_manager.status_manager)
func setup(manager: StatusManager) -> void:
	assert(manager != null, "StatusEffectHUD.setup(): manager 不可为 null")

	# 如果已绑定旧实例，先断开信号
	if _status_manager != null:
		_disconnect_signals()

	_status_manager = manager
	_connect_signals()
	_refresh()


## 解绑当前 StatusManager，清空 HUD 显示。
##
## 示例：
##   hud.teardown()  # 战斗结束时调用
func teardown() -> void:
	if _status_manager != null:
		_disconnect_signals()
		_status_manager = null
	_clear_all_slots()

# ---------------------------------------------------------------------------
# 布局构建（程序化，无需 .tscn）
# ---------------------------------------------------------------------------

func _build_layout() -> void:
	_slot_container = HBoxContainer.new()
	_slot_container.add_theme_constant_override("separation", 4)
	add_child(_slot_container)

	# 预分配 MAX_VISIBLE_SLOTS 个槽位
	for i: int in MAX_VISIBLE_SLOTS:
		var slot := _StatusSlot.new()
		slot.root.visible = false
		_slot_container.add_child(slot.root)
		_slots.append(slot)

	# 溢出标签
	_overflow_label = Label.new()
	_overflow_label.visible = false
	_overflow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot_container.add_child(_overflow_label)

# ---------------------------------------------------------------------------
# 信号连接 / 断开
# ---------------------------------------------------------------------------

func _connect_signals() -> void:
	if _status_manager == null:
		return
	if _status_manager.has_signal("status_applied"):
		_status_manager.status_applied.connect(_on_status_changed)
	if _status_manager.has_signal("status_removed"):
		_status_manager.status_removed.connect(_on_status_changed_removed)
	if _status_manager.has_signal("status_stacks_changed"):
		_status_manager.status_stacks_changed.connect(_on_stacks_changed)


func _disconnect_signals() -> void:
	if _status_manager == null:
		return
	if _status_manager.has_signal("status_applied") and \
			_status_manager.status_applied.is_connected(_on_status_changed):
		_status_manager.status_applied.disconnect(_on_status_changed)
	if _status_manager.has_signal("status_removed") and \
			_status_manager.status_removed.is_connected(_on_status_changed_removed):
		_status_manager.status_removed.disconnect(_on_status_changed_removed)
	if _status_manager.has_signal("status_stacks_changed") and \
			_status_manager.status_stacks_changed.is_connected(_on_stacks_changed):
		_status_manager.status_stacks_changed.disconnect(_on_stacks_changed)

# ---------------------------------------------------------------------------
# 信号回调（仅触发刷新，不直接操作状态）
# ---------------------------------------------------------------------------

func _on_status_changed(_type, _new_layers, _source) -> void:
	_refresh()


func _on_status_changed_removed(_type, _reason) -> void:
	_refresh()


func _on_stacks_changed(_type, _new_stacks) -> void:
	_refresh()

# ---------------------------------------------------------------------------
# 刷新逻辑
# ---------------------------------------------------------------------------

## 从 StatusManager 读取当前状态快照并更新所有槽位显示。
## 仅读取数据，不修改任何游戏状态。
func _refresh() -> void:
	if _status_manager == null:
		_clear_all_slots()
		return

	# 获取只读快照
	var effects: Array = _status_manager.get_all_effects()

	var total: int   = effects.size()
	var visible: int = mini(total, MAX_VISIBLE_SLOTS)
	var overflow: int = total - visible

	# 填充可见槽位
	for i: int in MAX_VISIBLE_SLOTS:
		var slot: _StatusSlot = _slots[i]
		if i < visible:
			var effect: StatusEffect = effects[i]
			# 尝试获取本地化名称
			var name_text: String = _get_effect_name(effect)
			var is_buff: bool = _is_buff_effect(effect)
			slot.show_effect(int(effect.effect_type), effect.stacks, name_text, is_buff)
		else:
			slot.hide_slot()

	# 溢出标签
	if overflow > 0:
		var fmt: String = TranslationServer.translate("STATUS_HUD_OVERFLOW")
		if fmt == "STATUS_HUD_OVERFLOW":
			fmt = "+%d more"
		_overflow_label.text    = fmt % overflow
		_overflow_label.visible = true
	else:
		_overflow_label.visible = false


## 从 StatusEffect 获取本地化显示名称
func _get_effect_name(effect: StatusEffect) -> String:
	# 优先从 StatusEffect 元数据获取
	if effect.has_method("get_display_name"):
		return effect.get_display_name()
	# 回退：翻译枚举名
	var type_name: String = StatusEffect.EffectType.keys()[effect.effect_type] \
		if effect.effect_type < StatusEffect.EffectType.size() else "UNKNOWN"
	var key: String = "STATUS_" + type_name
	var translated: String = TranslationServer.translate(key)
	return translated if translated != key else type_name


## 判断效果是否为 Buff（正面效果）
func _is_buff_effect(effect: StatusEffect) -> bool:
	if effect.has_method("is_buff"):
		return effect.is_buff()
	# 根据枚举名判断：含 "UP"、"SHIELD"、"HEAL" 等为 Buff
	var type_name: String = StatusEffect.EffectType.keys()[effect.effect_type] \
		if effect.effect_type < StatusEffect.EffectType.size() else ""
	return type_name.contains("UP") or type_name.contains("SHIELD") or type_name.contains("HEAL")


## 隐藏全部槽位并清空溢出标签
func _clear_all_slots() -> void:
	for slot in _slots:
		(slot as _StatusSlot).hide_slot()
	_overflow_label.visible = false
