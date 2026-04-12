## dynamic_weather_switch_test.gd
## 地形天气系统 - 动态天气切换测试 (Story 3-4)
## 验证天气动态切换、冷却机制、不同源独立性
## 作者: Claude Code
## 创建日期: 2026-04-12

class_name DynamicWeatherSwitchTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 测试用的 TerrainWeatherManager 实例
var _terrain_weather_manager: TerrainWeatherManager

# ==================== 测试生命周期 ====================

func before_test() -> void:
	_terrain_weather_manager = TerrainWeatherManager.new()
	_terrain_weather_manager._ready()


func after_test() -> void:
	if _terrain_weather_manager and is_instance_valid(_terrain_weather_manager):
		_terrain_weather_manager.queue_free()
	_terrain_weather_manager = null

# ==================== AC-1: 正常切换 ====================

## AC-1: 正常切换
## Given: 当前天气是 CLEAR
## When: 调用 change_weather("rain", "card_123", 2)
## Then: 结果返回 true。当前天气变为 RAIN，发射改变信号
func test_normal_weather_switch() -> void:
	# Arrange: 初始化战斗，当前天气为CLEAR
	_terrain_weather_manager.setup_battle("plain", "clear")
	assert_int(_terrain_weather_manager.get_current_weather()).is_equal(TerrainWeatherManager.Weather.CLEAR)

	# 监听天气变化信号
	var weather_changed_signal = false
	var new_weather_value = -1

	_terrain_weather_manager.weather_changed.connect(func(weather):
		weather_changed_signal = true
		new_weather_value = weather
	)

	# Act: 切换天气为雨天
	var result = _terrain_weather_manager.change_weather("rain", "card_123", 2)

	# Assert: 验证切换成功
	assert_bool(result).is_true()
	assert_int(_terrain_weather_manager.get_current_weather()).is_equal(TerrainWeatherManager.Weather.RAIN)
	assert_bool(weather_changed_signal).is_true()
	assert_int(new_weather_value).is_equal(TerrainWeatherManager.Weather.RAIN)

# ==================== AC-2: 相同天气拦截 ====================

## AC-2: 相同天气拦截
## Given: 当前天气是 RAIN
## When: 再次调用 change_weather("rain", "skill_456", 2)
## Then: 结果返回 false。当前天气不变
func test_same_weather_blocked() -> void:
	# Arrange: 初始化战斗，当前天气为RAIN
	_terrain_weather_manager.setup_battle("plain", "rain")
	assert_int(_terrain_weather_manager.get_current_weather()).is_equal(TerrainWeatherManager.Weather.RAIN)

	# Act: 尝试再次切换为雨天
	var result = _terrain_weather_manager.change_weather("rain", "skill_456", 2)

	# Assert: 验证切换失败
	assert_bool(result).is_false()
	assert_int(_terrain_weather_manager.get_current_weather()).is_equal(TerrainWeatherManager.Weather.RAIN)

# ==================== AC-3: 冷却机制生效 ====================

## AC-3: 冷却机制生效
## Given: 调用过 change_weather("rain", "card_123", 2) (天气变为雨，card_123冷却=2)
## When: 下回合立刻调用 change_weather("fog", "card_123", 2)
## Then: 结果返回 false (因为 card_123 仍在冷却中)
func test_cooldown_mechanism() -> void:
	# Arrange: 初始化战斗，当前天气为CLEAR
	_terrain_weather_manager.setup_battle("plain", "clear")

	# 第一次切换天气
	var result1 = _terrain_weather_manager.change_weather("rain", "card_123", 2)
	assert_bool(result1).is_true()
	assert_int(_terrain_weather_manager.get_current_weather()).is_equal(TerrainWeatherManager.Weather.RAIN)

	# 验证冷却已记录
	assert_bool(_terrain_weather_manager.is_weather_on_cooldown("card_123")).is_true()
	assert_int(_terrain_weather_manager.get_weather_cooldown("card_123")).is_equal(2)

	# Act: 同一个源立即尝试再次切换天气
	var result2 = _terrain_weather_manager.change_weather("fog", "card_123", 2)

	# Assert: 验证切换失败（冷却中）
	assert_bool(result2).is_false()
	assert_int(_terrain_weather_manager.get_current_weather()).is_equal(TerrainWeatherManager.Weather.RAIN)

# ==================== AC-4: 不同源不共享冷却 ====================

## AC-4: 不同源不共享冷却
## Given: card_123 仍在冷却中
## When: 调用 change_weather("fog", "event_789", 2)
## Then: 结果返回 true (不同源独立冷却)
func test_different_sources_independent() -> void:
	# Arrange: 初始化战斗，当前天气为CLEAR
	_terrain_weather_manager.setup_battle("plain", "clear")

	# 第一个源切换天气
	var result1 = _terrain_weather_manager.change_weather("rain", "card_123", 2)
	assert_bool(result1).is_true()

	# 验证card_123在冷却中
	assert_bool(_terrain_weather_manager.is_weather_on_cooldown("card_123")).is_true()

	# Act: 不同源尝试切换天气
	var result2 = _terrain_weather_manager.change_weather("fog", "event_789", 2)

	# Assert: 验证切换成功（不同源独立）
	assert_bool(result2).is_true()
	assert_int(_terrain_weather_manager.get_current_weather()).is_equal(TerrainWeatherManager.Weather.FOG)
	assert_bool(_terrain_weather_manager.is_weather_on_cooldown("event_789")).is_true()
	assert_int(_terrain_weather_manager.get_weather_cooldown("event_789")).is_equal(2)

# ==================== 边界值测试 ====================

## 测试冷却倒计时
func test_cooldown_tick() -> void:
	# Arrange: 初始化并切换天气
	_terrain_weather_manager.setup_battle("plain", "clear")
	_terrain_weather_manager.change_weather("rain", "card_123", 2)

	# 验证初始冷却
	assert_int(_terrain_weather_manager.get_weather_cooldown("card_123")).is_equal(2)

	# Act: 第一次回合结束
	_terrain_weather_manager.tick_cooldowns()
	assert_int(_terrain_weather_manager.get_weather_cooldown("card_123")).is_equal(1)

	# Act: 第二次回合结束
	_terrain_weather_manager.tick_cooldowns()
	assert_int(_terrain_weather_manager.get_weather_cooldown("card_123")).is_equal(0)

	# Assert: 冷却结束，可以再次切换
	assert_bool(_terrain_weather_manager.is_weather_on_cooldown("card_123")).is_false()


## 测试天气历史记录
func test_weather_history() -> void:
	# Arrange
	_terrain_weather_manager.setup_battle("plain", "clear")

	# Act: 进行多次天气切换
	_terrain_weather_manager.change_weather("rain", "card_123", 2)
	_terrain_weather_manager.tick_cooldowns()
	_terrain_weather_manager.tick_cooldowns()
	_terrain_weather_manager.change_weather("fog", "event_456", 2)

	# Assert: 验证历史记录
	var history = _terrain_weather_manager.get_weather_change_history()
	assert_int(history.size()).is_equal(2)

	# 验证第一条记录
	var record1 = history[0]
	assert_int(record1["from"]).is_equal(TerrainWeatherManager.Weather.CLEAR)
	assert_int(record1["to"]).is_equal(TerrainWeatherManager.Weather.RAIN)
	assert_str(record1["source"]).is_equal("card_123")

	# 验证第二条记录
	var record2 = history[1]
	assert_int(record2["from"]).is_equal(TerrainWeatherManager.Weather.RAIN)
	assert_int(record2["to"]).is_equal(TerrainWeatherManager.Weather.FOG)
	assert_str(record2["source"]).is_equal("event_456")
