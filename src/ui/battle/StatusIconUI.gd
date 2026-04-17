class_name StatusIconUI extends Control

## 单个状态效果图标：占位 ColorRect + 层数 Label。
## 待美术资源到位后将 ColorRect 替换为 TextureRect。
## 节点完全由代码创建，不依赖 .tscn 文件。

## 当前显示的状态类型
var status_type: StatusEffect.Type = StatusEffect.Type.POISON

var _color_rect: ColorRect
var _layer_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(32, 32)

	_color_rect = ColorRect.new()
	_color_rect.custom_minimum_size = Vector2(32, 32)
	add_child(_color_rect)

	_layer_label = Label.new()
	_layer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_layer_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	# 让 Label 铺满父节点，使右下角对齐生效
	_layer_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_layer_label)


## 初始化图标的状态类型与初始层数。
## p_type: 状态类型。
## layers: 初始层数。
func setup(p_type: StatusEffect.Type, layers: int) -> void:
	status_type = p_type
	_color_rect.color = _get_status_color(p_type)
	set_layers(layers)


## 更新层数角标。层数为 1 时隐藏角标（单层无需显示数字）。
## layers: 最新层数。
func set_layers(layers: int) -> void:
	_layer_label.text = str(layers) if layers > 1 else ""


## 根据状态类型返回占位颜色，待美术资源到位后替换。
func _get_status_color(type: StatusEffect.Type) -> Color:
	match int(type):
		0: return Color.GREEN        # POISON
		1: return Color.ORANGE_RED   # BURN
		2: return Color.DARK_GRAY    # ARMOR_BREAK
		3: return Color.YELLOW       # BUFF 类
		_: return Color.WHITE
