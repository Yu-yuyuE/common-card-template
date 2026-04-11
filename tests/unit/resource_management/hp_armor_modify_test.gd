## hp_armor_modify_test.gd
## ResourceManager HP/护盾修改单元测试 (Story 002)
## 验证 Story 002 的验收标准
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name HpArmorModifyTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

var _resource_manager: ResourceManager
var _mock_hero_manager: Node

class MockHeroManager extends Node:
	var max_hp: int = 50
	var base_ap: int = 4

# ==================== 测试生命周期 ====================

func before_test() -> void:
	_mock_hero_manager = MockHeroManager.new()
	_mock_hero_manager.name = "HeroManager"
	_resource_manager = ResourceManager.new()
	_mock_hero_manager.add_child(_resource_manager)
	_resource_manager._ready()


func after_test() -> void:
	if _resource_manager and is_instance_valid(_resource_manager):
		_resource_manager.queue_free()
	if _mock_hero_manager and is_instance_valid(_mock_hero_manager):
		_mock_hero_manager.queue_free()
	_resource_manager = null
	_mock_hero_manager = null

# ==================== AC-1: HP 归零触发战斗失败 ====================

func test_hp_zero_triggers_depleted_signal() -> void:
	assert_int(_resource_manager.get_hp()).is_equal(50)

	var signal_emitted: Array[bool] = [false]
	_resource_manager.hp_depleted.connect(
		func():
			signal_emitted[0] = true
	)

	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -50)

	assert_int(_resource_manager.get_hp()).is_equal(0)
	assert_bool(signal_emitted[0]).is_true()


func test_hp_exactly_zero() -> void:
	var signal_emitted: Array[bool] = [false]
	_resource_manager.hp_depleted.connect(
		func():
			signal_emitted[0] = true
	)

	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -50)

	assert_int(_resource_manager.get_hp()).is_equal(0)
	assert_bool(signal_emitted[0]).is_true()


func test_hp_cannot_go_negative() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -100)
	assert_int(_resource_manager.get_hp()).is_equal(0)

# ==================== AC-2: 护盾吸收伤害 ====================

func test_armor_absorbs_all_damage() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)

	assert_int(_resource_manager.get_hp()).is_equal(50)
	assert_int(_resource_manager.get_armor()).is_equal(10)

	_resource_manager.apply_damage(8)

	assert_int(_resource_manager.get_armor()).is_equal(2)
	assert_int(_resource_manager.get_hp()).is_equal(50)


func test_armor_exactly_zero() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 8)
	_resource_manager.apply_damage(8)

	assert_int(_resource_manager.get_armor()).is_equal(0)
	assert_int(_resource_manager.get_hp()).is_equal(50)

# ==================== AC-3: 护盾溢出扣 HP ====================

func test_armor_overflow_damages_hp() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)

	assert_int(_resource_manager.get_hp()).is_equal(50)
	assert_int(_resource_manager.get_armor()).is_equal(10)

	_resource_manager.apply_damage(15)

	assert_int(_resource_manager.get_armor()).is_equal(0)
	assert_int(_resource_manager.get_hp()).is_equal(45)


func test_damage_exceeds_armor_and_hp() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -45)
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)
	_resource_manager.apply_damage(20)

	assert_int(_resource_manager.get_armor()).is_equal(0)
	assert_int(_resource_manager.get_hp()).is_equal(0)

# ==================== AC-4: HP 恢复上限检查 ====================

func test_hp_recovery_clamped_to_max() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -20)
	assert_int(_resource_manager.get_hp()).is_equal(30)

	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, 30)
	assert_int(_resource_manager.get_hp()).is_equal(50)


func test_hp_recovery_exactly_to_max() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -30)
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, 30)
	assert_int(_resource_manager.get_hp()).is_equal(50)

# ==================== AC-5: Signal 参数正确 ====================

func test_resource_changed_signal_parameters() -> void:
	var captured: Array = [false, -1, -1, -1, 0]

	_resource_manager.resource_changed.connect(
		func(type: int, old_val: int, new_val: int, delta: int):
			captured[0] = true
			captured[1] = type
			captured[2] = old_val
			captured[3] = new_val
			captured[4] = delta
	)

	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -10)

	assert_bool(captured[0]).is_true()
	assert_int(captured[1]).is_equal(ResourceManager.ResourceType.HP)
	assert_int(captured[2]).is_equal(50)
	assert_int(captured[3]).is_equal(40)
	assert_int(captured[4]).is_equal(-10)


func test_resource_changed_signal_with_positive_delta() -> void:
	# First reduce HP so we can actually recover it
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -20)
	assert_int(_resource_manager.get_hp()).is_equal(30)

	var captured: Array = [false, -1, -1, -1, 0]

	_resource_manager.resource_changed.connect(
		func(type: int, old_val: int, new_val: int, delta: int):
			captured[0] = true
			captured[1] = type
			captured[2] = old_val
			captured[3] = new_val
			captured[4] = delta
	)

	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, 10)

	assert_bool(captured[0]).is_true()
	assert_int(captured[1]).is_equal(ResourceManager.ResourceType.HP)
	assert_int(captured[2]).is_equal(30)
	assert_int(captured[3]).is_equal(40)
	assert_int(captured[4]).is_equal(10)

# ==================== 护盾修改 Signal ====================

func test_armor_modify_emits_signal() -> void:
	var signal_emitted: Array[bool] = [false]

	_resource_manager.resource_changed.connect(
		func(type: int, _old_val: int, _new_val: int, _delta: int):
			if type == ResourceManager.ResourceType.ARMOR:
				signal_emitted[0] = true
	)

	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)
	assert_bool(signal_emitted[0]).is_true()

# ==================== 边界情况 ====================

func test_zero_damage() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)
	var result = _resource_manager.apply_damage(0)

	assert_int(result).is_equal(0)
	assert_int(_resource_manager.get_armor()).is_equal(10)


func test_negative_damage() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)
	var result = _resource_manager.apply_damage(-5)

	assert_int(result).is_equal(0)
	assert_int(_resource_manager.get_armor()).is_equal(10)


func test_piercing_damage_ignores_armor() -> void:
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)
	var result = _resource_manager.apply_damage(15, true)

	assert_int(_resource_manager.get_armor()).is_equal(10)
	assert_int(_resource_manager.get_hp()).is_equal(35)
	assert_int(result).is_equal(15)
