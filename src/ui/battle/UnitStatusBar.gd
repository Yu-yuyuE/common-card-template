class_name UnitStatusBar extends HBoxContainer

## 单位状态栏：绑定到一个 StatusManager，通过信号驱动图标的增删改。
## 遵循 ADR-0002：纯 Signal 驱动，禁止轮询。

## 绑定的单位 ID（用于日志和调试标识）
var unit_id: String = ""

## 内部图标字典 key=int(StatusEffect.Type), value=StatusIconUI
var _icons: Dictionary = {}


## 绑定到指定 StatusManager。
## p_unit_id: 本状态栏所属单位 ID，用于日志标识。
## sm: 该单位的 StatusManager 实例。
func bind(p_unit_id: String, sm: StatusManager) -> void:
	unit_id = p_unit_id
	sm.status_applied.connect(_on_status_applied)
	sm.status_removed.connect(_on_status_removed)
	sm.dot_dealt.connect(_on_dot_dealt)


## 处理状态施加或刷新。
## status_applied 在层数变化时同样触发，new_layers 即最新层数，可直接用于刷新角标。
func _on_status_applied(type: StatusEffect.Type, new_layers: int, _source: String) -> void:
	var key := int(type)
	if _icons.has(key):
		# 已有图标 → 刷新层数角标
		_icons[key].set_layers(new_layers)
	else:
		# 新状态 → 实例化图标并加入容器
		var icon := StatusIconUI.new()
		icon.setup(type, new_layers)
		add_child(icon)
		_icons[key] = icon


## 处理状态移除，销毁对应图标并从字典中清除。
func _on_status_removed(type: StatusEffect.Type, _reason: String) -> void:
	var key := int(type)
	if _icons.has(key):
		_icons[key].queue_free()
		_icons.erase(key)


## 处理持续伤害事件。
## 完整的飘字 VFX 效果待 VFX Story 实现；此处仅作控制台输出占位。
func _on_dot_dealt(type: StatusEffect.Type, damage: int, _pierced_armor: bool) -> void:
	print("[UnitStatusBar] unit=%s DoT %s 造成 %d 伤害" % [
		unit_id,
		StatusEffect.Type.keys()[type],
		damage
	])
