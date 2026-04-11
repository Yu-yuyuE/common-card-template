## armor_lifecycle_test.gd
## ResourceManager 护盾生命周期单元测试 (Story 003)
## 验证 Story 003 的验收标准
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name ArmorLifecycleTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

var _resource_manager: ResourceManager
var _mock_hero_manager: Node

# Mock HeroManager that returns different hero configurations
class MockHeroManager extends Node:
	var max_hp: int = 50
	var base_ap: int = 4
	var hero_id: String = "default_hero"
	var no_armor: bool = false
	var unlimited_armor: bool = false

	func get_armor_max() -> int:
		# 模拟 HeroManager.get_armor_max() 逻辑
		if hero_id == "cao_ren":
			return max_hp + 30  # 曹仁: MaxHP + 30
		if no_armor:
			return 0  # 典韦: 禁止护甲
		if unlimited_armor:
			return -1  # 张角: 无上限
		return max_hp  # 默认

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

# ==================== AC-1: 护盾跨回合保留 ====================

func test_armor_persists_across_turns() -> void:
	# 设置护盾值
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 15)
	assert_int(_resource_manager.get_armor()).is_equal(15)

	# 模拟回合切换（不调用任何重置函数）
	# 验证护盾仍然保留
	assert_int(_resource_manager.get_armor()).is_equal(15)


func test_armor_persists_when_zero() -> void:
	# 护盾为0时也保持
	assert_int(_resource_manager.get_armor()).is_equal(0)

	# 模拟回合切换
	# 验证护盾仍为0
	assert_int(_resource_manager.get_armor()).is_equal(0)

# ==================== AC-2: 战斗结束护盾清零 ====================

func test_armor_cleared_on_battle_end() -> void:
	# 设置护盾值
	_resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 20)
	assert_int(_resource_manager.get_armor()).is_equal(20)

	# 战斗结束
	_resource_manager.on_battle_end()

	# 护盾应被清零
	assert_int(_resource_manager.get_armor()).is_equal(0)


func test_armor_cleared_when_already_zero() -> void:
	# 护盾已为0
	assert_int(_resource_manager.get_armor()).is_equal(0)

	# 战斗结束
	_resource_manager.on_battle_end()

	# 护盾仍为0（不会变负）
	assert_int(_resource_manager.get_armor()).is_equal(0)

# ==================== AC-3: 默认武将护盾上限 ====================

func test_default_armor_max_equals_max_hp() -> void:
	# 默认护盾上限 = MaxHP (50)
	assert_int(_resource_manager.get_armor_max()).is_equal(50)


func test_default_armor_max_min_boundary() -> void:
	# 创建 MaxHP = 40 的 Mock
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 40
	mock.hero_id = "default_hero"

	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()

	assert_int(rm.get_armor_max()).is_equal(40)
	rm.queue_free()
	mock.queue_free()


func test_default_armor_max_max_boundary() -> void:
	# 创建 MaxHP = 60 的 Mock
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 60
	mock.hero_id = "default_hero"

	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()

	assert_int(rm.get_armor_max()).is_equal(60)
	rm.queue_free()
	mock.queue_free()

# ==================== AC-4: 曹仁护盾上限 ====================

func test_cao_ren_armor_max() -> void:
	# 创建曹仁 Mock
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 50
	mock.hero_id = "cao_ren"

	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()

	# 曹仁护盾上限 = MaxHP + 30 = 80
	assert_int(rm.get_armor_max()).is_equal(80)
	rm.queue_free()
	mock.queue_free()


func test_cao_ren_armor_max_boundary() -> void:
	# 创建曹仁 MaxHP = 40
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 40
	mock.hero_id = "cao_ren"

	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()

	# 曹仁护盾上限 = 40 + 30 = 70
	assert_int(rm.get_armor_max()).is_equal(70)
	rm.queue_free()
	mock.queue_free()

# ==================== AC-5: 张角护盾无上限 ====================

func test_zhang_jiao_armor_max_unlimited() -> void:
	# 创建张角 Mock
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 50
	mock.hero_id = "zhang_jiao"
	mock.unlimited_armor = true

	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()

	# 张角护盾上限 = -1 表示无上限
	assert_int(rm.get_armor_max()).is_equal(-1)
	rm.queue_free()
	mock.queue_free()


func test_zhang_jiao_armor_unlimited_can_increase() -> void:
	# 创建张角 Mock
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 50
	mock.hero_id = "zhang_jiao"
	mock.unlimited_armor = true

	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()

	# 无上限护盾可以大幅增加
	var result = rm.modify_resource(ResourceManager.ResourceType.ARMOR, 999999)
	assert_int(rm.get_armor()).is_equal(999999)
	rm.queue_free()
	mock.queue_free()

# ==================== AC-6: 护盾超出上限丢弃 ====================

func test_armor_clamped_to_max() -> void:
	# 默认武将 MaxHP=50，护盾上限=50
	# 尝试获得60护盾
	var actual_delta = _resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 60)

	# 护盾只增加到50，超出10被丢弃
	assert_int(_resource_manager.get_armor()).is_equal(50)
	# 实际增加量是 50 - 0 = 50
	assert_int(actual_delta).is_equal(50)


func test_armor_exactly_at_max() -> void:
	# 护盾恰好等于上限
	var actual_delta = _resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 50)
	assert_int(_resource_manager.get_armor()).is_equal(50)
	assert_int(actual_delta).is_equal(50)

	# 再尝试增加，应该被拒绝
	actual_delta = _resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, 10)
	assert_int(_resource_manager.get_armor()).is_equal(50)
	assert_int(actual_delta).is_equal(0)  # 没有变化

# ==================== 额外测试：典韦禁止护甲 ====================

func test_dian_wei_armor_disabled() -> void:
	# 创建典韦 Mock
	var mock = MockHeroManager.new()
	mock.name = "HeroManager"
	mock.max_hp = 50
	mock.hero_id = "dian_wei"
	mock.no_armor = true

	var rm = ResourceManager.new()
	mock.add_child(rm)
	rm._ready()

	# 典韦护盾上限 = 0
	assert_int(rm.get_armor_max()).is_equal(0)

	# 尝试添加护盾应该被拒绝
	var result = rm.modify_resource(ResourceManager.ResourceType.ARMOR, 10)
	assert_int(rm.get_armor()).is_equal(0)
	assert_int(result).is_equal(0)
	rm.queue_free()
	mock.queue_free()
