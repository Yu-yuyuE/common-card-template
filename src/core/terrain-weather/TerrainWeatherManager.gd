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
	PASS = 5,       ## 通道
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
			break
		Weather.FOG:
			# 雾天：施加视野模糊状态（降低命中率）
			# 需要StatusManager支持
			# 这里是占位
			# if _status_manager != null:
			#   _status_manager.apply(StatusEffect.Type.BLIND, 1, "雾天")
			break
		Weather.WIND:
			# 大风：施加飘摇状态（影响远程攻击）
			# 需要StatusManager支持
			# 这里是占位
			# if _status_manager != null:
			#   _status_manager.apply(StatusEffect.Type.WINDY, 1, "大风")
			break
		_:
			# 晴朗：清除所有天气效果
			# 需要StatusManager支持
			# 这里是占位
			# if _status_manager != null:
			#   _status_manager.force_remove(StatusEffect.Type.WET, "天气变化")
			#   _status_manager.force_remove(StatusEffect.Type.BLIND, "天气变化")
			#   _status_manager.force_remove(StatusEffect.Type.WINDY, "天气变化")
			break


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
			break
		Terrain.DESERT:
			# 沙漠：初始施加疲劳效果（减少行动点）
			# 这需要通过BattleManager和ResourceManager来实现
			# 这里是占位
			break
		_:
			# 其他地形无初始效果
			break

	# 根据天气应用初始效果
	match current_weather:
		Weather.RAIN:
			# 雨天：降低命中率
			# 这需要通过StatusManager来实现
			# 这里是占位
			# status_manager.apply(StatusEffect.Type.BLIND, 1, "雨天")
			break
		Weather.FOG:
			# 雾天：降低命中率
			# 这需要通过StatusManager来实现
			# 这里是占位
			# status_manager.apply(StatusEffect.Type.BLIND, 1, "雾天")
			break
		_:
			# 其他天气无初始效果
			break


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
		Terrain.PLAIN: return "平原"
		Terrain.MOUNTAIN: return "山地"
		Terrain.FOREST: return "森林"
		Terrain.WATER: return "水域"
		Terrain.DESERT: return "沙漠"
		Terrain.PASS: return "通道"
		Terrain.SNOW: return "雪地"
		_: return "未知地形"


## 获取天气名称
static func get_weather_name(w: Weather) -> String:
	match w:
		Weather.CLEAR: return "晴朗"
		Weather.WIND: return "大风"
		Weather.RAIN: return "雨天"
		Weather.FOG: return "雾天"
		_: return "未知天气"


# ---------------------------------------------------------------------------
# 战斗修正值计算
# ---------------------------------------------------------------------------

## 计算攻击伤害的地形修正
## 返回：修正系数（如1.25表示+25%，0.75表示-25%）
func get_attack_terrain_modifier() -> float:
	match current_terrain:
		Terrain.MOUNTAIN:
			return 1.10  # 山地：攻击+10%
		Terrain.DESERT:
			return 0.90  # 沙漠：攻击-10%
		_:
			return 1.0


## 计算防御的地形修正
func get_defense_terrain_modifier() -> float:
	match current_terrain:
		Terrain.FOREST:
			return 0.85  # 森林：防御-15%（更容易受伤）
		Terrain.SNOW:
			return 0.90  # 雪地：防御-10%
		_:
			return 1.0


## 计算行动点的天气修正
func get_action_points_weather_modifier() -> float:
	match current_weather:
		Weather.WIND:
			return 0.90  # 大风：行动点-10%
		Weather.RAIN:
			return 0.85  # 雨天：行动点-15%
		Weather.FOG:
			return 0.95  # 雾天：行动点-5%
		_:
			return 1.0


## 计算命中率的天气修正
func get_hit_chance_weather_modifier() -> float:
	match current_weather:
		Weather.RAIN:
			return 0.90  # 雨天：命中率-10%
		Weather.FOG:
			return 0.75  # 雾天：命中率-25%
		Weather.WIND:
			return 0.95  # 大风：命中率-5%
		_:
			return 1.0


## 应用地形天气修正到战斗实体
## 返回：修正后的attack_damage_factor
func apply_terrain_weather_modifiers(attack_base: float) -> float:
	var terrain_factor = get_attack_terrain_modifier()
	var weather_factor = get_action_points_weather_modifier()  # 天气对攻击也有轻微影响

	# 综合修正
	var final_factor = attack_base * terrain_factor * weather_factor

	# 记录日志
	# print("Attack: base=%.2f, terrain=%.2f, weather=%.2f, final=%.2f" % [attack_base, terrain_factor, weather_factor, final_factor])

	return final_factor


## 获取当前环境对人数的限制影响
## 某些地形可能限制最大参战人数
func get_max_participants_modifier() -> int:
	# 默认无影响
	return 3  # 标准支持3v3