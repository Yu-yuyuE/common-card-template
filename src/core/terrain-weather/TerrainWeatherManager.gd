## TerrainWeatherManager.gd
## 地形天气系统（D1）——战斗环境管理核心
##
## 职责：集中管理地形和天气状态，提供统一的配置加载和切换接口
## 位置：作为战斗系统的子节点（由BattleManager注入）
##
## 设计文档：design/gdd/terrain-weather-system.md
## 依赖：
##   - BattleManager（获取当前战场配置）
##   - StatusManager（触发地形效果状态）
##
## 使用示例：
##   var twm := TerrainWeatherManager.new()
##   twm.setup_battle("forest", "rain")
##   twm.change_weather("fog", "event_123")

class_name TerrainWeatherManager extends Node

# ---------------------------------------------------------------------------
# 地形和天气枚举
# ---------------------------------------------------------------------------

## 地形类型
enum Terrain {
	PLAIN = 0,      ## 平原
	MOUNTAIN = 1,   ## 山地
	FOREST = 2,     ## 森林
	WATER = 3,      ## 水域
	DESERT = 4,     ## 沙漠
	PASS = 5,       ## 关隘
	SNOW = 6,       ## 雪地
}

## 天气类型
enum Weather {
	CLEAR = 0,      ## 晴朗
	WIND = 1,       ## 大风
	RAIN = 2,       ## 雨天
	FOG = 3,        ## 雾天
}

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## 地形变化时发射
## 参数：new_terrain - 新的地形类型
signal terrain_changed(new_terrain: Terrain)

## 天气变化时发射
## 参数：new_weather - 新的天气类型
signal weather_changed(new_weather: Weather)

# ---------------------------------------------------------------------------
# 内部状态
# ---------------------------------------------------------------------------

## 当前地形
var current_terrain: Terrain = Terrain.PLAIN

## 当前天气
var current_weather: Weather = Weather.CLEAR

## 天气切换冷却记录
## key: source_id, value: remaining_rounds
var weather_cooldowns: Dictionary = {}

## 天气变更历史
var weather_change_history: Array = []

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 初始化时设置默认值
func _ready() -> void:
	current_terrain = Terrain.PLAIN
	current_weather = Weather.CLEAR

# ---------------------------------------------------------------------------
# 核心接口
# ---------------------------------------------------------------------------

## 设置战斗环境
## 参数：
##   terrain_str: 地形名称字符串（"plain", "forest"等）
##   weather_str: 天气名称字符串（"clear", "rain"等）
## 功能：
##   - 解析并设置当前地形和天气
##   - 清除天气冷却记录和历史
func setup_battle(terrain_str: String, weather_str: String) -> void:
	# 解析地形
	current_terrain = _parse_terrain(terrain_str)

	# 解析天气
	current_weather = _parse_weather(weather_str)

	# 清除天气冷却和历史
	weather_cooldowns.clear()
	weather_change_history.clear()

	# 发射变化信号
	terrain_changed.emit(current_terrain)
	weather_changed.emit(current_weather)

	# 应用初始化效果
	_apply_initial_effects()


## 改变天气
## 参数：
##   new_weather: 新天气名称字符串
##   source_id: 触发来源ID（卡牌ID/事件ID）
##   cooldown: 冷却回合数（默认2）
## 返回：true=成功切换，false=失败（重复/冷却中）
func change_weather(new_weather_str: String, source_id: String, cooldown: int = 2) -> bool:
	# 解析新天气
	var new_weather: Weather = _parse_weather(new_weather_str)

	# 检查是否为相同天气
	if new_weather == current_weather:
		return false

	# 检查是否在冷却中
	if weather_cooldowns.has(source_id) and weather_cooldowns[source_id] > 0:
		return false

	# 应用新天气
	var old_weather = current_weather
	current_weather = new_weather

	# 记录冷却
	weather_cooldowns[source_id] = cooldown

	# 记录历史
	weather_change_history.append({
		"from": old_weather,
		"to": new_weather,
		"source": source_id,
		"timestamp": Time.get_unix_time_from_system()
	})

	# 发射变化信号
	weather_changed.emit(current_weather)

	# 应用新天气的效果
	_apply_weather_effects()

	return true


## 应用当前天气效果
## 调用时机：天气切换后、回合开始时
func _apply_weather_effects() -> void:
	# 根据天气应用效果
	match current_weather:
		Weather.RAIN:
			# 雨天：施加湿润状态（影响火系效果）
			# 需要StatusManager支持
			# 这里是占位
			# if _status_manager != null:
			#   _status_manager.apply(StatusEffect.Type.WET, 1, "雨天")
			pass
		Weather.FOG:
			# 雾天：施加视野模糊状态（降低命中率）
			# 需要StatusManager支持
			# 这里是占位
			# if _status_manager != null:
			#   _status_manager.apply(StatusEffect.Type.BLIND, 1, "雾天")
			pass
		Weather.WIND:
			# 大风：施加飘摇状态（影响远程攻击）
			# 需要StatusManager支持
			# 这里是占位
			# if _status_manager != null:
			#   _status_manager.apply(StatusEffect.Type.WINDY, 1, "大风")
			pass
		_:
			# 晴朗：清除所有天气效果
			# 需要StatusManager支持
			# 这里是占位
			# if _status_manager != null:
			#   _status_manager.force_remove(StatusEffect.Type.WET, "天气变化")
			#   _status_manager.force_remove(StatusEffect.Type.BLIND, "天气变化")
			#   _status_manager.force_remove(StatusEffect.Type.WINDY, "天气变化")
			pass


## 每回合结束时更新天气冷却
## 调用方：BattleManager在回合结束时调用
func tick_cooldowns() -> void:
	var to_remove = []

	for source_id in weather_cooldowns.keys():
		weather_cooldowns[source_id] -= 1
		if weather_cooldowns[source_id] <= 0:
			to_remove.append(source_id)

	for source_id in to_remove:
		weather_cooldowns.erase(source_id)


## 设置BattleManager引用（由BattleManager调用）
func set_battle_manager(battle_mgr: Node) -> void:
	_battle_manager = battle_mgr


## 设置StatusManager引用（用于施加地形效果状态）
func set_status_manager(status_mgr: Node) -> void:
	_status_manager = status_mgr

# 内部变量
var _battle_manager: Node = null
var _status_manager: Node = null

# ---------------------------------------------------------------------------
# 辅助方法
# ---------------------------------------------------------------------------

## 解析地形字符串
func _parse_terrain(terrain_str: String) -> Terrain:
	match terrain_str.to_lower():
		"plain": return Terrain.PLAIN
		"mountain": return Terrain.MOUNTAIN
		"forest": return Terrain.FOREST
		"water": return Terrain.WATER
		"desert": return Terrain.DESERT
		"pass": return Terrain.PASS
		"snow": return Terrain.SNOW
		_:
			push_warning("TerrainWeatherManager: 未知地形 '%s'，默认 PLAIN" % terrain_str)
			return Terrain.PLAIN


## 解析天气字符串
func _parse_weather(weather_str: String) -> Weather:
	match weather_str.to_lower():
		"clear": return Weather.CLEAR
		"wind": return Weather.WIND
		"rain": return Weather.RAIN
		"fog": return Weather.FOG
		_:
			push_warning("TerrainWeatherManager: 未知天气 '%s'，默认 CLEAR" % weather_str)
			return Weather.CLEAR


## 应用地形天气初始化效果
## 由 setup_battle 在设置后调用
func _apply_initial_effects() -> void:
	# 根据地形应用初始效果
	match current_terrain:
		Terrain.WATER:
			# 水域：初始施加滑倒状态（D6）
			# 这需要通过StatusManager来实现
			# 这里是占位，实际实现需要依赖StatusManager
			# status_manager.apply(StatusEffect.Type.SLIP, 1, "水域地形")
			pass
		Terrain.DESERT:
			# 沙漠：初始施加疲劳效果（减少行动点）
			# 这需要通过BattleManager和ResourceManager来实现
			# 这里是占位
			pass
		_:
			# 其他地形无初始效果
			pass

	# 根据天气应用初始效果
	match current_weather:
		Weather.RAIN:
			# 雨天：降低命中率
			# 这需要通过StatusManager来实现
			# 这里是占位
			# status_manager.apply(StatusEffect.Type.BLIND, 1, "雨天")
			pass
		Weather.FOG:
			# 雾天：降低命中率
			# 这需要通过StatusManager来实现
			# 这里是占位
			# status_manager.apply(StatusEffect.Type.BLIND, 1, "雾天")
			pass
		_:
			# 其他天气无初始效果
			pass


## 获取当前地形
func get_current_terrain() -> Terrain:
	return current_terrain


## 获取当前天气
func get_current_weather() -> Weather:
	return current_weather


## 检查天气是否在冷却中
func is_weather_on_cooldown(source_id: String) -> bool:
	return weather_cooldowns.has(source_id) and weather_cooldowns[source_id] > 0


## 获取天气冷却剩余回合数
func get_weather_cooldown(source_id: String) -> int:
	if weather_cooldowns.has(source_id):
		return weather_cooldowns[source_id]
	return 0


## 获取天气变更历史
func get_weather_change_history() -> Array:
	return weather_change_history


## 获取天气冷却记录
func get_weather_cooldowns() -> Dictionary:
	return weather_cooldowns


## 获取地形名称
static func get_terrain_name(t: Terrain) -> String:
	match t:
		Terrain.PLAIN: return TranslationServer.translate("TERRAIN_PLAIN")
		Terrain.MOUNTAIN: return TranslationServer.translate("TERRAIN_MOUNTAIN")
		Terrain.FOREST: return TranslationServer.translate("TERRAIN_FOREST")
		Terrain.WATER: return TranslationServer.translate("TERRAIN_WATER")
		Terrain.DESERT: return TranslationServer.translate("TERRAIN_DESERT")
		Terrain.PASS: return TranslationServer.translate("TERRAIN_PASS")
		Terrain.SNOW: return TranslationServer.translate("TERRAIN_SNOW")
		_: return TranslationServer.translate("TERRAIN_UNKNOWN")


## 获取天气名称
static func get_weather_name(w: Weather) -> String:
	match w:
		Weather.CLEAR: return TranslationServer.translate("WEATHER_CLEAR")
		Weather.WIND: return TranslationServer.translate("WEATHER_WIND")
		Weather.RAIN: return TranslationServer.translate("WEATHER_RAIN")
		Weather.FOG: return TranslationServer.translate("WEATHER_FOG")
		_: return TranslationServer.translate("WEATHER_UNKNOWN")


# ---------------------------------------------------------------------------
# 战斗修正值计算
# ---------------------------------------------------------------------------

## 计算攻击伤害的地形修正
## 返回：修正系数（如1.25表示+25%，0.75表示-25%）
## 获取地形修正系数 (ADR-0009)
func get_terrain_modifier(card_category: String) -> float:
	match current_terrain:
		Terrain.PLAIN:
			if card_category == "cavalry": return 1.50
		Terrain.MOUNTAIN:
			if card_category == "cavalry": return 0.50
		Terrain.FOREST:
			if card_category == "burn": return 1.50
		Terrain.SNOW:
			if card_category == "burn": return 0.50
	return 1.0


## 获取天气修正系数 (ADR-0009)
func get_weather_modifier(card_category: String) -> float:
	match current_weather:
		Weather.WIND:
			if card_category == "ranged": return 0.90
		Weather.RAIN:
			if card_category == "burn": return 0.50
		Weather.FOG:
			if card_category == "ranged": return 0.75
	return 1.0


## 执行每回合末的地形持续效果 (ADR-0009)
func tick_terrain_effects() -> void:
	if _status_manager == null:
		return
		
	match current_terrain:
		Terrain.FOREST:
			_status_manager.apply_to_all(StatusEffect.Type.POISON, 1, "地形：森林")
		Terrain.DESERT:
			_status_manager.apply_to_all(StatusEffect.Type.BURN, 1, "地形：沙漠")


## 执行每回合末的天气持续效果 (ADR-0009)
func tick_weather_effects() -> void:
	if current_weather == Weather.WIND:
		if _status_manager != null and _status_manager.has_method("spread_status"):
			_status_manager.spread_status(StatusEffect.Type.BURN, 1, "天气：大风传播")