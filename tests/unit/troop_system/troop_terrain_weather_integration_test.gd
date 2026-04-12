## troop_terrain_weather_integration_test.gd
## 兵种地形天气联动集成测试 (Story 4-3)
## 验证兵种卡在不同地形天气下的费用和伤害修正正确应用
## 作者: Claude Code
## 创建日期: 2026-04-12

class_name TroopTerrainWeatherIntegrationTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 测试用的 BattleManager 实例
var _battle_manager: BattleManager

## 测试用的 TerrainWeatherManager 实例
var _terrain_weather_manager: TerrainWeatherManager

## 测试用的 ResourceManager 实例
var _resource_manager: ResourceManager

## 测试用的 CardManager 实例
var _card_manager: CardManager

## 测试用的 Mock EnemyManager 节点
var _mock_enemy_manager: Node

# ==================== 测试生命周期 ====================

func before_test() -> void:
	# 创建 ResourceManager
	_resource_manager = ResourceManager.new()
	_resource_manager._ready()

	# 创建 TerrainWeatherManager
	_terrain_weather_manager = TerrainWeatherManager.new()
	_terrain_weather_manager._ready()

	# 创建 CardManager
	_card_manager = CardManager.new(_battle_manager)

	# 创建 BattleManager
	_battle_manager = BattleManager.new()
	_battle_manager.terrain_weather_manager = _terrain_weather_manager
	_battle_manager.resource_manager = _resource_manager
	_battle_manager.card_manager = _card_manager

	# 添加到场景树
	add_child(_resource_manager)
	add_child(_terrain_weather_manager)
	add_child(_battle_manager)


func after_test() -> void:
	# 清理测试实例
	if _battle_manager and is_instance_valid(_battle_manager):
		_battle_manager.queue_free()
	if _resource_manager and is_instance_valid(_resource_manager):
		_resource_manager.queue_free()
	if _terrain_weather_manager and is_instance_valid(_terrain_weather_manager):
		_terrain_weather_manager.queue_free()
	if _card_manager and is_instance_valid(_card_manager):
		_card_manager.queue_free()
	if _mock_enemy_manager and is_instance_valid(_mock_enemy_manager):
		_mock_enemy_manager.queue_free()
	_battle_manager = null
	_resource_manager = null
	_terrain_weather_manager = null
	_card_manager = null
	_mock_enemy_manager = null


# ==================== AC-1: 沙漠减费 ====================

## AC-1: 沙漠地形骑兵费用-1（最低为0）
## Given: current_terrain = DESERT, 骑兵卡费用为1
## When: 玩家尝试打出骑兵卡
## Then: 实际消耗0费
func test_cavalry_desert_cost_reduction() -> void:
	# Arrange: 设置地形为沙漠，骑兵卡费用为1
	_terrain_weather_manager.setup_battle("desert", "clear")

	# 创建骑兵卡数据
	var troop_card_data = CardData.new("TroopCard", 1, "骑兵卡", 1)
	# 模拟兵种卡属性
	troop_card_data._is_troop_card = true
	troop_card_data._troop_type = TroopCard.TroopType.CAVALRY

	# 添加到手牌
	_card_manager.hand_cards.append(troop_card_data)

	# 设置玩家行动点为3
	_battle_manager.player_entity.action_points = 3

	# Act: 执行出牌
	var result = _battle_manager.play_card("TroopCard", 0)

	# Assert: 验证费用正确减少为0
	assert_int(_battle_manager.player_entity.action_points).is_equal(3)  # 费用从1减到0，行动点仍为3
	assert_true(result, "骑兵卡在沙漠地形应能成功打出")


# ==================== AC-2: 弓兵雨天伤害衰减 ====================

## AC-2: 弓兵在雨天伤害×0.5
## Given: current_weather = RAIN, 弓兵卡基础伤害为7
## When: 玩家打出弓兵卡
## Then: 造成4点伤害（7×0.5=3.5，取整为4）
func test_archer_rain_damage_reduction() -> void:
	# Arrange: 设置天气为雨天，弓兵卡基础伤害为7
	_terrain_weather_manager.setup_battle("plain", "rain")

	# 创建弓兵卡数据
	var archer_card_data = CardData.new("TroopCard", 1, "弓兵卡", 1)
	archer_card_data._is_troop_card = true
	archer_card_data._troop_type = TroopCard.TroopType.ARCHER
	archer_card_data._lv1_damage = 7  # 设置基础伤害

	# 添加到手牌
	_card_manager.hand_cards.append(archer_card_data)

	# 设置玩家行动点为3
	_battle_manager.player_entity.action_points = 3

	# 创建敌人实体
	var enemy = BattleEntity.new("enemy1", false)
	enemy.max_hp = 100
	enemy.current_hp = 100
	_battle_manager.enemy_entities.append(enemy)

	# Act: 执行出牌
	var result = _battle_manager.play_card("TroopCard", 0)

	# Assert: 验证伤害正确衰减为4（7×0.5=3.5→4）
	assert_int(enemy.current_hp).is_equal(96)  # 100 - 4 = 96
	assert_true(result, "弓兵卡在雨天应能成功打出")


# ==================== AC-3: 谋士雨天伤害衰减 ====================

## AC-3: 谋士在雨天伤害×0.5（与弓兵相同）
## Given: current_weather = RAIN, 谋士卡基础伤害为7
## When: 玩家打出谋士卡
## Then: 造成4点伤害（7×0.5=3.5，取整为4）
func test_strategist_rain_damage_reduction() -> void:
	# Arrange: 设置天气为雨天，谋士卡基础伤害为7
	_terrain_weather_manager.setup_battle("plain", "rain")

	# 创建谋士卡数据
	var strategist_card_data = CardData.new("TroopCard", 1, "谋士卡", 1)
	strategist_card_data._is_troop_card = true
	strategist_card_data._troop_type = TroopCard.TroopType.STRATEGIST
	strategist_card_data._lv1_damage = 7  # 设置基础伤害

	# 添加到手牌
	_card_manager.hand_cards.append(strategist_card_data)

	# 设置玩家行动点为3
	_battle_manager.player_entity.action_points = 3

	# 创建敌人实体
	var enemy = BattleEntity.new("enemy1", false)
	enemy.max_hp = 100
	enemy.current_hp = 100
	_battle_manager.enemy_entities.append(enemy)

	# Act: 执行出牌
	var result = _battle_manager.play_card("TroopCard", 0)

	# Assert: 验证伤害正确衰减为4（7×0.5=3.5→4）
	assert_int(enemy.current_hp).is_equal(96)  # 100 - 4 = 96
	assert_true(result, "谋士卡在雨天应能成功打出")


# ==================== AC-4: 骑兵在非沙漠地形无费用修正 ====================

## AC-4: 骑兵在平原地形无费用修正
## Given: current_terrain = PLAIN, 骑兵卡费用为1
## When: 玩家尝试打出骑兵卡
## Then: 消耗1费
func test_cavalry_plain_no_cost_reduction() -> void:
	# Arrange: 设置地形为平原，骑兵卡费用为1
	_terrain_weather_manager.setup_battle("plain", "clear")

	# 创建骑兵卡数据
	var troop_card_data = CardData.new("TroopCard", 1, "骑兵卡", 1)
	troop_card_data._is_troop_card = true
	troop_card_data._troop_type = TroopCard.TroopType.CAVALRY

	# 添加到手牌
	_card_manager.hand_cards.append(troop_card_data)

	# 设置玩家行动点为3
	_battle_manager.player_entity.action_points = 3

	# Act: 执行出牌
	var result = _battle_manager.play_card("TroopCard", 0)

	# Assert: 验证费用未减少，消耗1费
	assert_int(_battle_manager.player_entity.action_points).is_equal(2)  # 3 - 1 = 2
	assert_true(result, "骑兵卡在平原地形应能成功打出")


# ==================== AC-5: 弓兵在雾天伤害衰减 ====================

## AC-5: 弓兵在雾天伤害×0.5
## Given: current_weather = FOG, 弓兵卡基础伤害为7
## When: 玩家打出弓兵卡
## Then: 造成4点伤害（7×0.5=3.5，取整为4）
func test_archer_fog_damage_reduction() -> void:
	# Arrange: 设置天气为雾天，弓兵卡基础伤害为7
	_terrain_weather_manager.setup_battle("plain", "fog")

	# 创建弓兵卡数据
	var archer_card_data = CardData.new("TroopCard", 1, "弓兵卡", 1)
	archer_card_data._is_troop_card = true
	archer_card_data._troop_type = TroopCard.TroopType.ARCHER
	archer_card_data._lv1_damage = 7  # 设置基础伤害

	# 添加到手牌
	_card_manager.hand_cards.append(archer_card_data)

	# 设置玩家行动点为3
	_battle_manager.player_entity.action_points = 3

	# 创建敌人实体
	var enemy = BattleEntity.new("enemy1", false)
	enemy.max_hp = 100
	enemy.current_hp = 100
	_battle_manager.enemy_entities.append(enemy)

	# Act: 执行出牌
	var result = _battle_manager.play_card("TroopCard", 0)

	# Assert: 验证伤害正确衰减为4（7×0.5=3.5→4）
	assert_int(enemy.current_hp).is_equal(96)  # 100 - 4 = 96
	assert_true(result, "弓兵卡在雾天应能成功打出")


# ==================== AC-6: 非弓兵/谋士在雨天无伤害修正 ====================

## AC-6: 步兵在雨天无伤害修正
## Given: current_weather = RAIN, 步兵卡基础伤害为8
## When: 玩家打出步兵卡
## Then: 造成8点伤害
func test_infantry_rain_no_damage_reduction() -> void:
	# Arrange: 设置天气为雨天，步兵卡基础伤害为8
	_terrain_weather_manager.setup_battle("plain", "rain")

	# 创建步兵卡数据
	var infantry_card_data = CardData.new("TroopCard", 1, "步兵卡", 1)
	infantry_card_data._is_troop_card = true
	infantry_card_data._troop_type = TroopCard.TroopType.INFANTRY
	infantry_card_data._lv1_damage = 8  # 设置基础伤害

	# 添加到手牌
	_card_manager.hand_cards.append(infantry_card_data)

	# 设置玩家行动点为3
	_battle_manager.player_entity.action_points = 3

	# 创建敌人实体
	var enemy = BattleEntity.new("enemy1", false)
	enemy.max_hp = 100
	enemy.current_hp = 100
	_battle_manager.enemy_entities.append(enemy)

	# Act: 执行出牌
	var result = _battle_manager.play_card("TroopCard", 0)

	# Assert: 验证伤害未衰减，造成8点伤害
	assert_int(enemy.current_hp).is_equal(92)  # 100 - 8 = 92
	assert_true(result, "步兵卡在雨天应能成功打出")


# ==================== AC-7: 骑兵在沙漠地形费用最低为0 ====================

## AC-7: 骑兵在沙漠地形费用最低为0
## Given: current_terrain = DESERT, 骑兵卡费用为0
## When: 玩家尝试打出骑兵卡
## Then: 实际消耗0费（不为负）
func test_cavalry_desert_cost_min_zero() -> void:
	# Arrange: 设置地形为沙漠，骑兵卡费用为0
	_terrain_weather_manager.setup_battle("desert", "clear")

	# 创建骑兵卡数据
	var troop_card_data = CardData.new("TroopCard", 1, "骑兵卡", 0)
	troop_card_data._is_troop_card = true
	troop_card_data._troop_type = TroopCard.TroopType.CAVALRY

	# 添加到手牌
	_card_manager.hand_cards.append(troop_card_data)

	# 设置玩家行动点为3
	_battle_manager.player_entity.action_points = 3

	# Act: 执行出牌
	var result = _battle_manager.play_card("TroopCard", 0)

	# Assert: 验证费用最低为0，消耗0费
	assert_int(_battle_manager.player_entity.action_points).is_equal(3)  # 费用从0减到0，行动点仍为3
	assert_true(result, "骑兵卡在沙漠地形应能成功打出（费用为0）")