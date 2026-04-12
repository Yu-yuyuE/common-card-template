## resource_status_integration_test.gd
## F2+C1 资源与状态联动集成测试 (Story 001)
## 验证 ResourceManager 与 StatusManager 的信号联动
## 作者: Claude Code
## 创建日期: 2026-04-11

extends GdUnitTestSuite

# 导入所需类
const ResourceManagerClass = preload("res://src/core/ResourceManager.gd")
const StatusManagerClass = preload("res://src/core/StatusManager.gd")
const StatusEffectClass = preload("res://src/core/StatusEffect.gd")

# ==================== 测试数据 ====================

## 测试用的 ResourceManager 实例
var _resource_manager: ResourceManager

## 测试用的 StatusManager 实例
var _status_manager: StatusManager

## Mock HeroManager 节点
var _mock_hero_manager: Node

## 包装后的 Mock HeroManager 用于测试
class MockHeroManager extends Node:
	var max_hp: int = 50
	var base_ap: int = 4
	var armor_max: int = 20  # 护盾上限

	func get_current_hero_data() -> Dictionary:
		return {
			"max_hp": max_hp,
			"base_ap": base_ap,
			"armor_max_override": armor_max
		}

	func get_armor_max() -> int:
		return armor_max

# ==================== 测试生命周期 ====================

func before_test() -> void:
	# 创建 Mock HeroManager
	_mock_hero_manager = MockHeroManager.new()
	_mock_hero_manager.name = "HeroManager"

	# 创建 ResourceManager 并作为子节点添加到 Mock HeroManager
	_resource_manager = ResourceManagerClass.new()
	_mock_hero_manager.add_child(_resource_manager)
	# 触发 _ready()
	_resource_manager._ready()

	# 创建 StatusManager
	_status_manager = StatusManagerClass.new()


func after_test() -> void:
	# 清理测试实例
	if _resource_manager and is_instance_valid(_resource_manager):
		if _resource_manager.get_parent() != null:
			_resource_manager.get_parent().remove_child(_resource_manager)
		_resource_manager = null
	if _status_manager and is_instance_valid(_status_manager):
		_status_manager = null
	if _mock_hero_manager and is_instance_valid(_mock_hero_manager):
		if _mock_hero_manager.get_parent() != null:
			_mock_hero_manager.get_parent().remove_child(_mock_hero_manager)
		_mock_hero_manager = null

# ==================== AC-1: 毒性持续伤害（Poison） ====================

## AC-1: 毒性持续伤害（Poison）
## Given: ResourceManager当前HP=50，StatusManager施加了 POISON（层数=3，伤害=4，穿透护盾=true）
## When: ResourceManager被攻击，HP减少至40
## Then: StatusManager在下一个回合前结算，扣除4点HP，并发出 dot_dealt 信号
## Edge cases: 护盾会被保留，直接扣HP
func test_poison_dot_damage() -> void:
	# Arrange: 施加毒状态
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证毒状态已施加
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()
	assert_int(_status_manager.get_layers(StatusEffect.Type.POISON)).is_equal(3)

	# 模拟伤害：从50减少到40（减少10）
	var damage = 10
	var hp_before = _resource_manager.get_hp()

	# 确保是正常伤害路径（非穿透）
	_resource_manager.apply_damage(damage, false)

	# 确认HP已减少
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - damage)

	# 设置信号捕获
	var signals_received = []
	_status_manager.dot_dealt.connect(func(type: StatusEffect.Type, dmg: int, pierced: bool):
		signals_received.append({
			"type": type,
			"damage": dmg,
			"pierced": pierced
		})
	)

	# Act: 手动触发DOT结算（在战斗系统中由on_round_start_dot()调用）
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 毒性伤害应被结算（固定4点，不乘层数）
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - damage - 4)

	# 验证信号被正确接收
	assert_int(signals_received.size()).is_equal(1)
	var signal_data = signals_received[0]
	assert_int(signal_data.type).is_equal(StatusEffect.Type.POISON)
	assert_int(signal_data.damage).is_equal(4)
	assert_bool(signal_data.pierced).is_true()


## 边界值测试：护盾存在时POISON穿透护盾
func test_poison_dot_with_shield() -> void:
	# Arrange: 设置护盾并施加毒状态
	_resource_manager.add_armor(20)  # 护盾=20
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证护盾和毒状态
	assert_int(_resource_manager.get_armor()).is_equal(20)
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 由于POISON穿透护盾，护盾不被消耗，直接扣HP
	assert_int(_resource_manager.get_armor()).is_equal(20)  # 护盾不变
	assert_int(_resource_manager.get_hp()).is_equal(46)  # 50 - 4


## 边界值测试：护盾低时POISON仍然穿透
func test_poison_dot_with_insufficient_shield() -> void:
	# Arrange: 设置少量护盾并施加毒状态
	_resource_manager.add_armor(5)  # 护盾=5
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证护盾和毒状态
	assert_int(_resource_manager.get_armor()).is_equal(5)
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: POISON穿透护盾，护盾不变，直接扣HP
	assert_int(_resource_manager.get_armor()).is_equal(5)  # 护盾不变
	assert_int(_resource_manager.get_hp()).is_equal(46)  # 50 - 4


# ==================== AC-3: 护盾穿透（poison） ====================

## AC-3: POISON护盾穿透
## Given: ResourceManager当前护盾=10，StatusManager施加了 POISON（穿透护盾=true）
## When: POISON结算
## Then: 护盾保持10，HP被扣除4
func test_poison_pierces_shield() -> void:
	# Arrange: 设置护盾并施加毒状态
	_resource_manager.add_armor(10)  # 护盾=10
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证护盾和毒状态
	assert_int(_resource_manager.get_armor()).is_equal(10)
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 护盾不变，直接扣HP
	assert_int(_resource_manager.get_armor()).is_equal(10)  # 护盾不变
	assert_int(_resource_manager.get_hp()).is_equal(46)  # 50 - 4


# ==================== 信号联动测试 ====================

## 测试 resource_changed 信号触发 DOT 结算
func test_resource_changed_triggers_dot() -> void:
	# Arrange: 施加毒状态
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 模拟一个信号处理函数来触发DOT结算
	var dot_triggered = {"value": false}

	# 在实际系统中，ResourceManager会发射 resource_changed 信号
	# 为测试目的，我们模拟此逻辑
	_resource_manager.resource_changed.connect(func(type: int, old_val: int, new_val: int, delta: int):
		if type == ResourceManager.ResourceType.HP and delta < 0:  # HP减少
			dot_triggered.value = true
			# 触发状态管理器DOT结算
			_status_manager.on_round_start_dot(_resource_manager)
	)

	# Act: 模拟HP减少（如被攻击）
	_resource_manager.apply_damage(5, false)

	# Assert: DOT应被触发
	assert_bool(dot_triggered.value).is_true()


# ==================== 边界情况测试 ====================

## 测试多个状态同时存在时的DOT结算
func test_multiple_dot_states() -> void:
	# Arrange: 施加多个DOT状态
	_status_manager.apply(StatusEffect.Type.POISON, 2, "毒箭卡")
	_status_manager.apply(StatusEffect.Type.BURN, 1, "火攻卡")

	# 验证两个状态都存在
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()
	assert_bool(_status_manager.has_status(StatusEffect.Type.BURN)).is_true()

	# 记录初始HP
	var hp_before = _resource_manager.get_hp()

	# 设置信号捕获
	var poison_dot_emitted = false
	var burn_dot_emitted = false

	_status_manager.dot_dealt.connect(func(type: StatusEffect.Type, dmg: int, pierced: bool):
		if type == StatusEffect.Type.POISON:
			poison_dot_emitted = true
		elif type == StatusEffect.Type.BURN:
			burn_dot_emitted = true
	)

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 两个DOT都应被结算
	# Poison: 固定4点
	# Burn: 固定5点
	# 总伤害 = 9
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - 9)

	assert_bool(poison_dot_emitted).is_true()
	assert_bool(burn_dot_emitted).is_true()


## 测试非DOT状态不触发DOT结算
func test_non_dot_status_no_damage() -> void:
	# Arrange: 施加一个非DOT状态（如FURY）
	_status_manager.apply(StatusEffect.Type.FURY, 1, "怒气状态")

	# 验证状态已施加
	assert_bool(_status_manager.has_status(StatusEffect.Type.FURY)).is_true()

	# 记录初始HP
	var hp_before = _resource_manager.get_hp()

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: HP不应变化
	assert_int(_resource_manager.get_hp()).is_equal(hp_before)


## 测试护盾消耗后DOT继续造成伤害
func test_shield_zero_then_dot_continues() -> void:
	# Arrange: 设置护盾为1，施加毒状态（伤害=4）
	_resource_manager.add_armor(1)
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 毒伤害直接扣HP，护盾不受影响
	assert_int(_resource_manager.get_armor()).is_equal(1)  # 护盾不变
	assert_int(_resource_manager.get_hp()).is_equal(50 - 4)

	# 再次触发DOT结算（应继续扣HP）
	var hp_after_second = _resource_manager.get_hp()
	_status_manager.on_round_start_dot(_resource_manager)
	assert_int(_resource_manager.get_hp()).is_equal(hp_after_second - 4)


## 测试状态移除后DOT停止
func test_dot_stops_after_status_removed() -> void:
	# Arrange: 施加毒状态
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 记录初始HP
	var hp_before = _resource_manager.get_hp()

	# Act: 触发一次DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: HP已减少4
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - 4)

	# Act: 移除毒状态
	_status_manager.force_remove(StatusEffect.Type.POISON, "治疗")

	# Act: 再次触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: HP不再减少
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - 4)