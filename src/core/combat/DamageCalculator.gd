## DamageCalculator.gd
## 伤害计算器
##
## 职责：集中处理伤害计算逻辑，包括地形天气修正、护甲扣除等
## 位置：作为独立工具类，由BattleManager或TroopCard调用
##
## 设计文档：design/gdd/troop-cards-design.md, design/gdd/card-battle-system.md
## 依赖：
##   - TerrainWeatherManager（获取地形天气修正）
##
## 使用示例：
##   var calculator = DamageCalculator.new()
##   var final_damage = calculator.calculate_damage(base_damage, troop_type, terrain_manager)

class_name DamageCalculator extends RefCounted

# ---------------------------------------------------------------------------
# 天气修正常量表
# ---------------------------------------------------------------------------

## 天气对各类兵种伤害的修正系数
const WEATHER_MODIFIERS: Dictionary = {
	"rain": {
		"archer": 0.5,      # 弓兵雨天伤害×0.5
		"strategist": 0.5,  # 谋士远程效果雨天同样×0.5
	},
	"fog": {
		"archer": 0.5,      # 弓兵雾天（盲目等效）伤害×0.5
		"strategist": 0.5,  # 谋士雾天同样×0.5
	},
	"wind": {
		# 大风对远程的影响可在此扩展
	},
	"clear": {
		# 晴天无特殊修正
	}
}

# ---------------------------------------------------------------------------
# 核心计算方法
# ---------------------------------------------------------------------------

## 计算最终伤害值
## 参数：
##   base_damage: 基础伤害值
##   troop_type: 兵种类型（TroopCard.TroopType枚举）
##   terrain_manager: TerrainWeatherManager实例（用于获取地形天气修正）
## 返回：最终伤害值（整数）
func calculate_damage(base_damage: int, troop_type: int, terrain_manager: TerrainWeatherManager) -> int:
	if terrain_manager == null:
		return base_damage

	var final_damage: float = float(base_damage)

	# 1. 应用地形修正
	var terrain_modifier = terrain_manager.get_attack_terrain_modifier()
	final_damage *= terrain_modifier

	# 2. 应用天气修正（针对特定兵种）
	final_damage *= _get_weather_damage_modifier(troop_type, terrain_manager)

	# 3. 取整返回
	return int(round(final_damage))


## 获取天气对特定兵种的伤害修正系数
## 参数：
##   troop_type: 兵种类型
##   terrain_manager: TerrainWeatherManager实例
## 返回：修正系数（0.5表示减半，1.0表示无变化）
func _get_weather_damage_modifier(troop_type: int, terrain_manager: TerrainWeatherManager) -> float:
	var current_weather = terrain_manager.get_current_weather()
	var weather_name = _weather_to_string(current_weather)

	# 检查是否有该天气的修正规则
	if not WEATHER_MODIFIERS.has(weather_name):
		return 1.0

	var weather_rules: Dictionary = WEATHER_MODIFIERS[weather_name]

	# 根据兵种类型匹配修正规则
	var troop_name = _troop_type_to_string(troop_type)
	if weather_rules.has(troop_name):
		return weather_rules[troop_name]

	return 1.0


# ---------------------------------------------------------------------------
# 辅助转换方法
# ---------------------------------------------------------------------------

## 将天气枚举转换为字符串
func _weather_to_string(weather: int) -> String:
	match weather:
		TerrainWeatherManager.Weather.CLEAR:
			return "clear"
		TerrainWeatherManager.Weather.WIND:
			return "wind"
		TerrainWeatherManager.Weather.RAIN:
			return "rain"
		TerrainWeatherManager.Weather.FOG:
			return "fog"
		_:
			return "clear"


## 将兵种类型枚举转换为字符串
func _troop_type_to_string(troop_type: int) -> String:
	match troop_type:
		TroopCard.TroopType.ARCHER:
			return "archer"
		TroopCard.TroopType.STRATEGIST:
			return "strategist"
		TroopCard.TroopType.INFANTRY:
			return "infantry"
		TroopCard.TroopType.CAVALRY:
			return "cavalry"
		TroopCard.TroopType.SHIELD:
			return "shield"
		_:
			return "unknown"
