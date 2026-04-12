## d3_c2_integration_test.gd
## 武将系统与卡牌战斗系统集成测试 (Story 3-9)
## 验证武将被动技能在战斗中正确触发，属性加成正确应用，事件系统正确执行
## 作者: Claude Code
## 创建日期: 2026-04-12

class_name D3C2IntegrationTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 测试用的 BattleManager 实例
var _battle_manager: BattleManager

## 测试用的 ResourceManager 实例
var _resource_manager: ResourceManager

## 测试用的 TerrainWeatherManager 实例
var _terrain_weather_manager: TerrainWeatherManager

## 测试用的 StatusManager 实例
var _status_manager: StatusManager

## 测试用的 EnemyManager 实例
var _enemy_manager: EnemyManager

## 测试用的 EnemyTurnManager 实例
var _enemy_turn_manager: EnemyTurnManager

## 测试用的 Mock HeroManager 节点
var _mock_hero_manager: Node

## 测试用的 PassiveSkillManager 实例
var _passive_skill_manager: PassiveSkillManager

## 包装后的 Mock HeroManager 用于测试
class MockHeroManager extends Node:
	var max_hp: int = 50
	var base_ap: int = 4
	var _armor_max_override: int = 0

	func get_current_hero_data() -> Dictionary:
		return {
			"max_hp": max_hp,
			"base_ap": base_ap,
			"armor_max_override": _armor_max_override
		}

# ==================== 测试生命周期 ====================

func before_test() -> void:
	# 创建 Mock HeroManager
	_mock_hero_manager = MockHeroManager.new()
	_mock_hero_manager.name = "HeroManager"

	# 创建 ResourceManager 并作为子节点添加到 Mock HeroManager
	_resource_manager = ResourceManager.new()
	_mock_hero_manager.add_child(_resource_manager)
	# 触发 _ready()
	_resource_manager._ready()

	# 创建 StatusManager
	_status_manager = StatusManager.new()

	# 创建 EnemyManager
	_enemy_manager = EnemyManager.new()
	# 加载敌人数据（需要真实数据文件，但为测试我们使用模拟）
	# 在真实测试中，会加载 assets/csv_data/enemies.csv
	# 为简化测试，我们手动添加敌人数据
	# 创建一个简单的敌人
	var enemy_data := EnemyData.new("e1", "普通敌人", 0, 0, 100, 0)
	enemy_data.action_sequence = ["A01", "A02"]  # 简化行动序列
	enemy_data.phase_transition = "HP<40%"  # 设置相变条件
	_enemy_manager._enemies["e1"] = enemy_data

	# 创建 EnemyTurnManager
	_enemy_turn_manager = EnemyTurnManager.new()
	# 设置引用
	_enemy_turn_manager.set_enemy_manager(_enemy_manager)
	_enemy_turn_manager.set_battle_manager(_battle_manager, _status_manager)

	# 创建 TerrainWeatherManager
	_terrain_weather_manager = TerrainWeatherManager.new()

	# 创建 PassiveSkillManager
	_passive_skill_manager = PassiveSkillManager.new()

	# 创建 BattleManager
	_battle_manager = BattleManager.new()
	_battle_manager.enemy_turn_manager = _enemy_turn_manager
	_battle_manager.status_manager = _status_manager
	_battle_manager.enemy_manager = _enemy_manager
	_battle_manager.terrain_weather_manager = _terrain_weather_manager
	_battle_manager.passive_skill_manager = _passive_skill_manager

	# 添加所有组件到场景树
	_mock_hero_manager.add_child(_battle_manager)
	_mock_hero_manager.add_child(_enemy_turn_manager)
	_mock_hero_manager.add_child(_terrain_weather_manager)
	_mock_hero_manager.add_child(_passive_skill_manager)

	# 注册被动技能
	_register_skills()


func after_test() -> void:
	# 清理测试实例
	if _battle_manager and is_instance_valid(_battle_manager):
		_battle_manager.queue_free()
	if _resource_manager and is_instance_valid(_resource_manager):
		_resource_manager.queue_free()
	if _status_manager and is_instance_valid(_status_manager):
		_status_manager.queue_free()
	if _enemy_manager and is_instance_valid(_enemy_manager):
		_enemy_manager.queue_free()
	if _enemy_turn_manager and is_instance_valid(_enemy_turn_manager):
		_enemy_turn_manager.queue_free()
	if _terrain_weather_manager and is_instance_valid(_terrain_weather_manager):
		_terrain_weather_manager.queue_free()
	if _passive_skill_manager and is_instance_valid(_passive_skill_manager):
		_passive_skill_manager.queue_free()
	if _mock_hero_manager and is_instance_valid(_mock_hero_manager):
		_mock_hero_manager.queue_free()
	_battle_manager = null
	_resource_manager = null
	_status_manager = null
	_enemy_manager = null
	_enemy_turn_manager = null
	_terrain_weather_manager = null
	_passive_skill_manager = null
	_mock_hero_manager = null


## 注册测试用的被动技能
func _register_skills() -> void:
	# 注册曹操的被动技能
	var caocao_skill := CaoCaoPassiveSkill.new()
	_passive_skill_manager.register_skill(caocao_skill)

	# 注册关羽的被动技能
	var guanyu_skill := GuanYuPassiveSkill.new()
	_passive_skill_manager.register_skill(guanyu_skill)

	# 注册诸葛亮的被动技能
	var zhugeliang_skill := ZhugeLiangPassiveSkill.new()
	_passive_skill_manager.register_skill(zhugeliang_skill)

	# 注册刘备的被动技能
	var liubei_skill := LiuBeiPassiveSkill.new()
	_passive_skill_manager.register_skill(liubei_skill)

	# 注册夏侯惇的被动技能
	var xiahoudun_skill := XiahouDunPassiveSkill.new()
	_passive_skill_manager.register_skill(xiahoudun_skill)

	# 设置当前武将
	_passive_skill_manager.set_current_hero(_mock_hero_manager.get_current_hero_data())


# ==================== AC-1: 曹操挟令诸侯 - 施加虚弱 ====================

## AC-1: 曹操挟令诸侯 - 施加虚弱
## Given: 曹操在场，使用兵种卡攻击敌人
## When: 出牌
## Then: 随机敌人施加1层虚弱
func test_cao_cao_weaken() -> void:
	# Arrange: 初始化战斗，使用曹操
	var stage_config = {
		"stage_count": 1,
		"terrain": "plain",
		"weather": "clear",
		"enemies": [
			{"id": "e1", "hp": 100, "ap": 1}
		]
	}
	_battle_manager.setup_battle(stage_config, _resource_manager)

	# 验证初始状态
	assert_int(_status_manager.get_layers(StatusEffect.Type.WEAKEN)).is_equal(0)

	# Act: 玩家出牌（兵种卡）
	# 为简化，我们创建一个兵种卡
	var card := Card.new(CardData.new("TroopCard", 1, "兵种卡", 1))
	card._is_troop_card = true  # 模拟兵种卡

	# 预设出牌函数
	_battle_manager.play_card("TroopCard", 0)

	# Assert: 验证施加虚弱
	assert_int(_status_manager.get_layers(StatusEffect.Type.WEAKEN)).is_greater_than(0)


## AC-2: 关羽武圣 - 施加恐惧和恢复行动点
## Given: 关羽在场，攻击敌人
## When: 攻击敌人
## Then: 敌人施加恐惧，且若敌人有恐惧则恢复1行动点
func test_guan_yu_fear_and_ap() -> void:
	# Arrange: 初始化战斗，使用关羽
	var stage_config = {
		"stage_count": 1,
		"terrain": "plain",
		"weather": "clear",
		"enemies": [
			{"id": "e1", "hp": 100, "ap": 1}
		]
	}
	_battle_manager.setup_battle(stage_config, _resource_manager)

	# 验证初始状态
	assert_int(_status_manager.get_layers(StatusEffect.Type.FEAR)).is_equal(0)
	assert_int(_resource_manager.get_action_points()).is_equal(4)

	# Act: 模拟攻击敌人
	# 创建一个攻击卡
	var card := Card.new(CardData.new("AttackCard", 1, "攻击卡", 1))
	card._is_attack_card = true  # 模拟攻击卡

	# 预设出牌函数
	_battle_manager.play_card("AttackCard", 0)

	# Assert: 验证施加恐惧
	assert_int(_status_manager.get_layers(StatusEffect.Type.FEAR)).is_equal(1)

	# 验证行动点恢复（关羽攻击恐惧目标时恢复行动点）
	# 我们需要先给敌人施加恐惧，然后攻击
	_status_manager.apply(StatusEffect.Type.FEAR, 1, "测试")
	assert_int(_status_manager.get_layers(StatusEffect.Type.FEAR)).is_equal(1)
	_battle_manager.play_card("AttackCard", 0)
	assert_int(_resource_manager.get_action_points()).is_greater_than(4)


## AC-3: 诸葛亮卧龙 - 回合开始恢复行动点
## Given: 诸葛亮在场
## When: 回合开始
## Then: 恢复1行动点
func test_zhuge_liang_round_start_ap() -> void:
	# Arrange: 初始化战斗，使用诸葛亮
	var stage_config = {
		"stage_count": 1,
		"terrain": "plain",
		"weather": "clear",
		"enemies": [
			{"id": "e1", "hp": 100, "ap": 1}
		]
	}
	_battle_manager.setup_battle(stage_config, _resource_manager)

	# 验证初始状态
	assert_int(_resource_manager.get_action_points()).is_equal(4)

	# Act: 模拟回合开始
	# 通过结束玩家回合触发回合开始
	_battle_manager.end_player_turn()
	_battle_manager._start_player_turn()

	# Assert: 验证行动点恢复
	assert_int(_resource_manager.get_action_points()).is_equal(5)


## AC-4: 刘备仁德 - 使用兵种卡恢复HP
## Given: 刘备在场，使用兵种卡
## When: 出牌
## Then: 为己方全体恢复1点HP
func test_liu_bei_ren_de_hp() -> void:
	# Arrange: 初始化战斗，使用刘备
	var stage_config = {
		"stage_count": 1,
		"terrain": "plain",
		"weather": "clear",
		"enemies": [
			{"id": "e1", "hp": 100, "ap": 1}
		]
	}
	_battle_manager.setup_battle(stage_config, _resource_manager)

	# 验证初始状态
	assert_int(_resource_manager.get_hp()).is_equal(50)

	# Act: 玩家出牌（兵种卡）
	var card := Card.new(CardData.new("TroopCard", 1, "兵种卡", 1))
	card._is_troop_card = true  # 模拟兵种卡

	# 预设出牌函数
	_battle_manager.play_card("TroopCard", 0)

	# Assert: 验证HP恢复
	assert_int(_resource_manager.get_hp()).is_equal(51)


## AC-5: 夏侯惇骁勇 - HP低于50%时受到攻击恢复HP
## Given: 夏侯惇在场，HP低于50%，受到攻击
## When: 受到攻击
## Then: 恢复20%最大HP
func test_xiahou_dun_savage_heal() -> void:
	# Arrange: 初始化战斗，使用夏侯惇，设置HP低于50%
	var stage_config = {
		"stage_count": 1,
		"terrain": "plain",
		"weather": "clear",
		"enemies": [
			{"id": "e1", "hp": 100, "ap": 1}
		]
	}
	_battle_manager.setup_battle(stage_config, _resource_manager)

	# 设置HP低于50%
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -26)  # 50-26=24 < 50% of 50
	assert_int(_resource_manager.get_hp()).is_equal(24)

	# Act: 模拟受到攻击
	# 通过应用伤害来模拟
	var damage = 5
	_resource_manager.apply_damage(damage)

	# Assert: 验证恢复20%最大HP（50 * 0.2 = 10）
	assert_int(_resource_manager.get_hp()).is_equal(24 + 10)