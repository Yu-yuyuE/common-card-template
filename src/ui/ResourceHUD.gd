## ResourceHUD.gd
## 资源状态显示 HUD（UI 层 — Story 4-13）
##
## 职责：订阅 ResourceManager 信号，实时显示 HP / 护盾 / 粮草 / 金币 / 行动点。
##       不修改任何游戏状态，仅只读查询 ResourceManager。
##
## 使用方式：
##   $ResourceHUD.setup(resource_manager)
##
## 场景搭建时，根节点下需要以下子节点（Label）：
##   $HPLabel          — "HP: 45/80"
##   $ArmorLabel       — "护盾: 12"（护盾为 0 时自动隐藏）
##   $ProvisionsLabel  — "粮草: 120"
##   $GoldLabel        — "金币: 35"
##   $APLabel          — "AP: 2/3"
##
## 设计文档：design/gdd/resource-management-system.md

class_name ResourceHUD extends Control

# ---------------------------------------------------------------------------
# 子节点引用（占位符路径，.tscn 中按此名称创建 Label）
# ---------------------------------------------------------------------------

@onready var _hp_label: Label = $HPLabel
@onready var _armor_label: Label = $ArmorLabel
@onready var _provisions_label: Label = $ProvisionsLabel
@onready var _gold_label: Label = $GoldLabel
@onready var _ap_label: Label = $APLabel

# ---------------------------------------------------------------------------
# 私有状态
# ---------------------------------------------------------------------------

var _resource_manager: ResourceManager = null

# ---------------------------------------------------------------------------
# 生命周期
# ---------------------------------------------------------------------------

func _ready() -> void:
	_validate_nodes()

# ---------------------------------------------------------------------------
# 公共 API
# ---------------------------------------------------------------------------

## 注入 ResourceManager 依赖，并完成初始化显示。
## 必须在场景 _ready 之后、首次显示之前调用。
##
## 参数：
##   manager — ResourceManager 实例（不可为 null）
##
## 示例：
##   $ResourceHUD.setup(get_node("/root/GameState/ResourceManager"))
func setup(manager: ResourceManager) -> void:
	assert(manager != null, "ResourceHUD.setup: manager 不能为 null")
	_resource_manager = manager
	_resource_manager.resource_changed.connect(_on_resource_changed)
	refresh_all()


## 一次性刷新全部资源显示。
## 可在场景重新进入可见时手动调用，确保显示与状态同步。
##
## 示例：
##   $ResourceHUD.refresh_all()
func refresh_all() -> void:
	if _resource_manager == null:
		push_warning("ResourceHUD.refresh_all: ResourceManager 尚未注入，跳过刷新")
		return
	_refresh_hp()
	_refresh_armor()
	_refresh_provisions()
	_refresh_gold()
	_refresh_ap()


## 从当前 ResourceManager 解除绑定（场景销毁或切换时调用）。
func teardown() -> void:
	if _resource_manager != null:
		if _resource_manager.resource_changed.is_connected(_on_resource_changed):
			_resource_manager.resource_changed.disconnect(_on_resource_changed)
		_resource_manager = null

# ---------------------------------------------------------------------------
# 信号回调
# ---------------------------------------------------------------------------

## 资源变化时由 ResourceManager 触发，按类型路由到对应刷新函数。
func _on_resource_changed(resource_type: int, _old_value: int, _new_value: int, _delta: int) -> void:
	match resource_type:
		ResourceManager.ResourceType.HP:
			_refresh_hp()
		ResourceManager.ResourceType.ARMOR:
			_refresh_armor()
		ResourceManager.ResourceType.PROVISIONS:
			_refresh_provisions()
		ResourceManager.ResourceType.GOLD:
			_refresh_gold()
		ResourceManager.ResourceType.ACTION_POINTS:
			_refresh_ap()

# ---------------------------------------------------------------------------
# 私有刷新函数
# ---------------------------------------------------------------------------

## 刷新 HP 显示：格式 "HP: 45/80"
func _refresh_hp() -> void:
	if _hp_label == null:
		return
	var current: int = _resource_manager.get_hp()
	var max_val: int = _resource_manager.get_max_hp()
	var fmt: String = TranslationServer.translate("LABEL_HP")
	if fmt == "LABEL_HP":
		fmt = "HP: %d/%d"
	_hp_label.text = fmt % [current, max_val]


## 刷新护盾显示：格式 "护盾: 12"（护盾为 0 时隐藏行）
func _refresh_armor() -> void:
	if _armor_label == null:
		return
	var current: int = _resource_manager.get_armor()
	if current <= 0:
		_armor_label.visible = false
	else:
		_armor_label.visible = true
		var fmt: String = TranslationServer.translate("LABEL_ARMOR")
		if fmt == "LABEL_ARMOR":
			fmt = "护盾: %d"
		_armor_label.text = fmt % [current]


## 刷新粮草显示：格式 "粮草: 120"
func _refresh_provisions() -> void:
	if _provisions_label == null:
		return
	var current: int = _resource_manager.get_provisions()
	var fmt: String = TranslationServer.translate("LABEL_PROVISIONS")
	if fmt == "LABEL_PROVISIONS":
		fmt = "粮草: %d"
	_provisions_label.text = fmt % [current]


## 刷新金币显示：格式 "金币: 35"
func _refresh_gold() -> void:
	if _gold_label == null:
		return
	var current: int = _resource_manager.get_gold()
	var fmt: String = TranslationServer.translate("LABEL_GOLD")
	if fmt == "LABEL_GOLD":
		fmt = "金币: %d"
	_gold_label.text = fmt % [current]


## 刷新行动点显示：格式 "AP: 2/3"
func _refresh_ap() -> void:
	if _ap_label == null:
		return
	var current: int = _resource_manager.get_action_points()
	var max_val: int = _resource_manager.get_max_action_points()
	var fmt: String = TranslationServer.translate("LABEL_AP")
	if fmt == "LABEL_AP":
		fmt = "AP: %d/%d"
	_ap_label.text = fmt % [current, max_val]

# ---------------------------------------------------------------------------
# 节点校验
# ---------------------------------------------------------------------------

func _validate_nodes() -> void:
	if _hp_label == null:
		push_error("ResourceHUD: 缺少子节点 $HPLabel，请检查场景结构")
	if _provisions_label == null:
		push_error("ResourceHUD: 缺少子节点 $ProvisionsLabel，请检查场景结构")
	if _gold_label == null:
		push_error("ResourceHUD: 缺少子节点 $GoldLabel，请检查场景结构")
	if _ap_label == null:
		push_error("ResourceHUD: 缺少子节点 $APLabel，请检查场景结构")
	# _armor_label 可选，护盾为 0 时不显示
	if _armor_label == null:
		push_warning("ResourceHUD: 未找到 $ArmorLabel，护盾值将不被显示")
