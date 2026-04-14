## TerrainWeatherHUD.gd
## 战斗 HUD 地形天气信息显示组件（Story 4-10）
##
## 职责：订阅 TerrainWeatherManager 的信号，实时展示当前地形、天气及对卡组的效果提示。
## 本组件为纯显示节点——不持有也不修改任何游戏状态。
##
## 使用示例：
##   var hud := TerrainWeatherHUD.new()
##   add_child(hud)
##   hud.setup(terrain_weather_manager)
##
## 场景搭建时，根节点下需要以下子节点（路径可在 Inspector 覆盖）：
##   $TerrainLabel       — Label  显示地形名称
##   $WeatherLabel       — Label  显示天气名称
##   $TerrainEffectLabel — Label  显示地形效果提示
##   $WeatherEffectLabel — Label  显示天气效果提示
##
## 设计文档：design/gdd/terrain-weather-system.md
## ADR：ADR-0010（地形天气系统架构）

class_name TerrainWeatherHUD extends Control

# ---------------------------------------------------------------------------
# 子节点引用（路径需与 .tscn 保持一致）
# ---------------------------------------------------------------------------

@onready var _terrain_label: Label = $TerrainLabel
@onready var _weather_label: Label = $WeatherLabel
@onready var _terrain_effect_label: Label = $TerrainEffectLabel
@onready var _weather_effect_label: Label = $WeatherEffectLabel

# ---------------------------------------------------------------------------
# 内部依赖
# ---------------------------------------------------------------------------

## 注入的 TerrainWeatherManager 引用；通过 setup() 设置，不使用 Autoload
var _manager: TerrainWeatherManager = null

# ---------------------------------------------------------------------------
# 地形效果提示本地化键表
## key: TerrainWeatherManager.Terrain 枚举值
## value: 翻译键（在本地化 .csv/.po 中定义）
# ---------------------------------------------------------------------------

const _TERRAIN_EFFECT_KEYS: Dictionary = {
	TerrainWeatherManager.Terrain.PLAIN:    "HUD_TERRAIN_EFFECT_PLAIN",
	TerrainWeatherManager.Terrain.MOUNTAIN: "HUD_TERRAIN_EFFECT_MOUNTAIN",
	TerrainWeatherManager.Terrain.FOREST:   "HUD_TERRAIN_EFFECT_FOREST",
	TerrainWeatherManager.Terrain.WATER:    "HUD_TERRAIN_EFFECT_WATER",
	TerrainWeatherManager.Terrain.DESERT:   "HUD_TERRAIN_EFFECT_DESERT",
	TerrainWeatherManager.Terrain.PASS:     "HUD_TERRAIN_EFFECT_PASS",
	TerrainWeatherManager.Terrain.SNOW:     "HUD_TERRAIN_EFFECT_SNOW",
}

# ---------------------------------------------------------------------------
# 天气效果提示本地化键表
# ---------------------------------------------------------------------------

const _WEATHER_EFFECT_KEYS: Dictionary = {
	TerrainWeatherManager.Weather.CLEAR: "HUD_WEATHER_EFFECT_CLEAR",
	TerrainWeatherManager.Weather.WIND:  "HUD_WEATHER_EFFECT_WIND",
	TerrainWeatherManager.Weather.RAIN:  "HUD_WEATHER_EFFECT_RAIN",
	TerrainWeatherManager.Weather.FOG:   "HUD_WEATHER_EFFECT_FOG",
}

# ---------------------------------------------------------------------------
# 生命周期
# ---------------------------------------------------------------------------

func _ready() -> void:
	# 节点校验——在编辑器中快速发现场景结构问题
	if not _terrain_label:
		push_error("TerrainWeatherHUD: 缺少子节点 $TerrainLabel，请检查场景结构")
	if not _weather_label:
		push_error("TerrainWeatherHUD: 缺少子节点 $WeatherLabel，请检查场景结构")
	if not _terrain_effect_label:
		push_error("TerrainWeatherHUD: 缺少子节点 $TerrainEffectLabel，请检查场景结构")
	if not _weather_effect_label:
		push_error("TerrainWeatherHUD: 缺少子节点 $WeatherEffectLabel，请检查场景结构")

# ---------------------------------------------------------------------------
# 公开接口
# ---------------------------------------------------------------------------

## 注入 TerrainWeatherManager 并完成初始刷新。
## 必须在节点进入场景树后调用（即 _ready 执行后）。
##
## 参数：
##   manager — 当前战斗的 TerrainWeatherManager 实例
##
## 示例：
##   hud.setup(battle_manager.terrain_weather_manager)
func setup(manager: TerrainWeatherManager) -> void:
	if _manager != null:
		# 防止重复订阅：先断开旧连接
		if _manager.terrain_changed.is_connected(_on_terrain_changed):
			_manager.terrain_changed.disconnect(_on_terrain_changed)
		if _manager.weather_changed.is_connected(_on_weather_changed):
			_manager.weather_changed.disconnect(_on_weather_changed)

	_manager = manager

	if _manager == null:
		push_error("TerrainWeatherHUD.setup(): 传入的 manager 为 null")
		return

	# 订阅信号
	_manager.terrain_changed.connect(_on_terrain_changed)
	_manager.weather_changed.connect(_on_weather_changed)

	# 读取当前状态并立即刷新，保证首帧显示正确
	_refresh_terrain(_manager.get_current_terrain())
	_refresh_weather(_manager.get_current_weather())


## 主动刷新显示（外部强制刷新时使用，正常情况由信号驱动）。
func refresh() -> void:
	if _manager == null:
		push_warning("TerrainWeatherHUD.refresh(): manager 尚未注入，跳过刷新")
		return
	_refresh_terrain(_manager.get_current_terrain())
	_refresh_weather(_manager.get_current_weather())

# ---------------------------------------------------------------------------
# 信号回调
# ---------------------------------------------------------------------------

## 地形变化回调
func _on_terrain_changed(new_terrain: TerrainWeatherManager.Terrain) -> void:
	_refresh_terrain(new_terrain)


## 天气变化回调
func _on_weather_changed(new_weather: TerrainWeatherManager.Weather) -> void:
	_refresh_weather(new_weather)

# ---------------------------------------------------------------------------
# 内部刷新逻辑
# ---------------------------------------------------------------------------

## 刷新地形名称与效果提示标签。
##
## 参数：
##   terrain — 当前地形枚举值
func _refresh_terrain(terrain: TerrainWeatherManager.Terrain) -> void:
	if _terrain_label == null or _terrain_effect_label == null:
		return

	# 地形名称（TerrainWeatherManager.get_terrain_name 内部已调用 TranslationServer）
	_terrain_label.text = TerrainWeatherManager.get_terrain_name(terrain)

	# 效果提示文本
	var effect_key: String = _TERRAIN_EFFECT_KEYS.get(terrain, "HUD_TERRAIN_EFFECT_PLAIN")
	_terrain_effect_label.text = TranslationServer.translate(effect_key)


## 刷新天气名称与效果提示标签。
##
## 参数：
##   weather — 当前天气枚举值
func _refresh_weather(weather: TerrainWeatherManager.Weather) -> void:
	if _weather_label == null or _weather_effect_label == null:
		return

	# 天气名称（TerrainWeatherManager.get_weather_name 内部已调用 TranslationServer）
	_weather_label.text = TerrainWeatherManager.get_weather_name(weather)

	# 效果提示文本
	var effect_key: String = _WEATHER_EFFECT_KEYS.get(weather, "HUD_WEATHER_EFFECT_CLEAR")
	_weather_effect_label.text = TranslationServer.translate(effect_key)
