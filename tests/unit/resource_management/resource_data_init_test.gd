## resource_data_init_test.gd
## ResourceManager 资源数据初始化单元测试 (Story 001)
## 验证 Story 001 的验收标准
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name ResourceDataInitTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 测试用的 ResourceManager 实例
var _resource_manager: ResourceManager

## Mock HeroManager 节点
var _mock_hero_manager: Node

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


func after_test() -> void:
	# 清理测试实例
	if _resource_manager and is_instance_valid(_resource_manager):
		_resource_manager.queue_free()
	if _mock_hero_manager and is_instance_valid(_mock_hero_manager):
		_mock_hero_manager.queue_free()
	_resource_manager = null
	_mock_hero_manager = null

# ==================== AC-1: HP 初始化 ====================

## AC-1: HP 初始化
## Given: 武将 MaxHP=50（从 HeroManager 读取）
## When: ResourceManager 初始化
## Then: resources[HP] == 50, max_values[HP] == 50
func test_hp_initialization() -> void:
	assert_int(_resource_manager.get_hp()).is_equal(50)
	assert_int(_resource_manager.get_max_hp()).is_equal(50)


## 边界值测试: MaxHP = 40
func test_hp_initialization_min_boundary() -> void:
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 40
	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()
	assert_int(rm.get_hp()).is_equal(40)
	assert_int(rm.get_max_hp()).is_equal(40)
	rm.queue_free()
	mock.queue_free()


## 边界值测试: MaxHP = 60
func test_hp_initialization_max_boundary() -> void:
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 60
	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()
	assert_int(rm.get_hp()).is_equal(60)
	assert_int(rm.get_max_hp()).is_equal(60)
	rm.queue_free()
	mock.queue_free()

# ==================== AC-2: 粮草初始化 ====================

## AC-2: 粮草初始化
## Given: 武将选择完成
## When: ResourceManager 初始化
## Then: resources[PROVISIONS] == 150, max_values[PROVISIONS] == 150
func test_provisions_initialization() -> void:
	assert_int(_resource_manager.get_provisions()).is_equal(150)
	# 上限固定为 150
	assert_int(_resource_manager.max_values[ResourceManager.ResourceType.PROVISIONS]).is_equal(150)

# ==================== AC-3: 金币初始化 ====================

## AC-3: 金币初始化
## Given: 武将选择完成
## When: ResourceManager 初始化
## Then: resources[GOLD] == 0, max_values[GOLD] == 99999
func test_gold_initialization() -> void:
	assert_int(_resource_manager.get_gold()).is_equal(0)
	assert_int(_resource_manager.max_values[ResourceManager.ResourceType.GOLD]).is_equal(99999)

# ==================== AC-4: 行动点初始化 ====================

## AC-4: 行动点初始化
## Given: 武将基础行动点=4
## When: ResourceManager 初始化
## Then: resources[ACTION_POINTS] == 4, max_values[ACTION_POINTS] == 4
func test_action_points_initialization() -> void:
	assert_int(_resource_manager.get_action_points()).is_equal(4)
	assert_int(_resource_manager.get_max_action_points()).is_equal(4)


## 边界值测试: 基础行动点 = 3
func test_action_points_initialization_min_boundary() -> void:
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.base_ap = 3
	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()
	assert_int(rm.get_action_points()).is_equal(3)
	assert_int(rm.get_max_action_points()).is_equal(3)
	rm.queue_free()
	mock.queue_free()


## 边界值测试: 基础行动点 = 4
func test_action_points_initialization_max_boundary() -> void:
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.base_ap = 4
	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()
	assert_int(rm.get_action_points()).is_equal(4)
	assert_int(rm.get_max_action_points()).is_equal(4)
	rm.queue_free()
	mock.queue_free()

# ==================== AC-5: GameState 子节点 ====================

## AC-5: GameState 子节点
## Given: GameState 场景已加载
## When: 场景进入 _ready()
## Then: GameState 包含名为 "ResourceManager" 的子节点
func test_resource_manager_is_child_node() -> void:
	assert_bool(_resource_manager.get_parent() == _mock_hero_manager).is_true()
	assert_str(_resource_manager.get_parent().name).is_equal("HeroManager")

# ==================== 信号测试 ====================

## 测试 modify_resource 触发 resource_changed 信号
func test_modify_resource_emits_signal() -> void:
	var signal_called: bool = false
	var captured_type: int = -1
	var captured_old: int = -1
	var captured_new: int = -1
	var captured_delta: int = 0

	_resource_manager.resource_changed.connect(
		func(type: int, old_val: int, new_val: int, delta: int):
			signal_called = true
			captured_type = type
			captured_old = old_val
			captured_new = new_val
			captured_delta = delta
	)

	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -10)

	assert_bool(signal_called).is_true()
	assert_int(captured_type).is_equal(ResourceManager.ResourceType.HP)
	assert_int(captured_old).is_equal(50)
	assert_int(captured_new).is_equal(40)
	assert_int(captured_delta).is_equal(-10)


## 测试 HP 归零时触发 hp_depleted 信号
func test_hp_depleted_signal() -> void:
	var signal_called: bool = false

	_resource_manager.hp_depleted.connect(
		func():
			signal_called = true
	)

	# 将 HP 降到 0
	_resource_manager.modify_resource(ResourceManager.ResourceType.HP, -50)

	assert_bool(signal_called).is_true()

# ==================== 边界情况测试 ====================

## 测试资源修改不超过上限
func test_resource_clamped_to_max() -> void:
	# 尝试恢复超过上限的 HP
	var delta = _resource_manager.modify_resource(ResourceManager.ResourceType.HP, 100)
	# 实际只会增加 0（因为已经是最大值 50）
	assert_int(_resource_manager.get_hp()).is_equal(50)


## 测试资源修改不低于下限
func test_resource_clamped_to_min() -> void:
	# 尝试减少超过当前值的 HP
	var delta = _resource_manager.modify_resource(ResourceManager.ResourceType.HP, -100)
	# 实际会降到 0
	assert_int(_resource_manager.get_hp()).is_equal(0)


## 测试护盾初始化
func test_armor_initialization() -> void:
	# 初始护盾应为 0
	assert_int(_resource_manager.get_armor()).is_equal(0)
	# 护盾上限默认等于 MaxHP
	assert_int(_resource_manager.get_armor_max()).is_equal(50)
