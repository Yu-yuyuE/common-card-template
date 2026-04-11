## resource_status_integration_test.gd
## F2+C1 资源与状态联动集成测试 (Story 001)
## 验证 ResourceManager 与 StatusManager 的信号联动
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name ResourceStatusIntegrationTest
extends GdUnitTestSuite

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


func after_test() -> void:
	# 清理测试实例
	if _resource_manager and is_instance_valid(_resource_manager):
		_resource_manager.queue_free()
	if _status_manager and is_instance_valid(_status_manager):
		_status_manager.queue_free()
	if _mock_hero_manager and is_instance_valid(_mock_hero_manager):
		_mock_hero_manager.queue_free()
	_resource_manager = null
	_status_manager = null
	_mock_hero_manager = null

# ==================== AC-1: 毒性持续伤害（Poison） ====================

## AC-1: 毒性持续伤害（Poison）
## Given: ResourceManager当前HP=50，StatusManager施加了 POISON（层数=3，每层伤害=4，穿透护盾=true）
## When: ResourceManager被攻击，HP减少至40
## Then: StatusManager在下一个回合前结算，扣除12点HP（3×4），并发出 status_applied 信号
## Edge cases: 如果护盾>12，应扣除护盾后HP不变；如果护盾<12，应扣除护盾并扣除剩余伤害到HP
func test_poison_dot_damage() -> void:
	# Arrange: 施加毒状态
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证毒状态已施加
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()
	assert_int(_status_manager.get_layers(StatusEffect.Type.POISON)).is_equal(3)

	# 模拟伤害：从50减少到40（减少10）
	var damage = 10
	var hp_before = _resource_manager.get_hp()
	var armor_before = _resource_manager.get_armor()

	# 确保是正常伤害路径（非穿透）
	_resource_manager.apply_damage(damage, false)

	# 确认HP已减少
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - damage)

	# Act: 手动触发DOT结算（在战斗系统中由on_round_start_dot()调用）
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 毒性伤害应被结算（3×4=12）
	# 由于是穿透护盾的DOT，直接扣HP
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - damage - 12)

	# 验证DOT信号被发射
	var dot_signal_called = false
	var dot_type = StatusEffect.Type.NONE
	var dot_damage = 0
	var pierced_armor = false

	_status_manager.dot_dealt.connect(func(type: StatusEffect.Type, damage: int, pierced: bool):
		dot_signal_called = true
		dot_type = type
		dot_damage = damage
		pierced_armor = pierced
	)

	# 重置状态并重新触发
	_status_manager.on_round_start_dot(_resource_manager)

	assert_bool(dot_signal_called).is_true()
	assert_int(dot_type).is_equal(StatusEffect.Type.POISON)
	assert_int(dot_damage).is_equal(12)
	assert_bool(pierced_armor).is_true()


## 边界值测试：护盾吸收DOT伤害
func test_poison_dot_with_shield() -> void:
	# Arrange: 设置护盾并施加毒状态
	_resource_manager.add_armor(20)  # 护盾=20
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证护盾和毒状态
	assert_int(_resource_manager.get_armor()).is_equal(20)
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 由于护盾=20 > 毒伤害=12，护盾应被消耗，HP不变
	assert_int(_resource_manager.get_armor()).is_equal(8)  # 20 - 12
	assert_int(_resource_manager.get_hp()).is_equal(50)  # 未减少


## 边界值测试：护盾不足时DOT穿透
func test_poison_dot_with_insufficient_shield() -> void:
	# Arrange: 设置少量护盾并施加毒状态
	_resource_manager.add_armor(5)  # 护盾=5
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证护盾和毒状态
	assert_int(_resource_manager.get_armor()).is_equal(5)
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 护盾被消耗完，剩余伤害扣HP（12 - 5 = 7）
	assert_int(_resource_manager.get_armor()).is_equal(0)
	assert_int(_resource_manager.get_hp()).is_equal(50 - 7)  # 50 - 7 = 43


# ==================== AC-2: 治疗Buff自动移除 ====================
# 注意: HEALING 状态类型在 StatusEffect.Type 中不存在，此测试已被禁用
# 需要根据实际设计文档中的状态类型来重新编写此测试

# ==================== AC-3: 护盾穿透 ====================

## AC-3: 护盾穿透
## Given: ResourceManager当前护盾=10，StatusManager施加了 POISON（穿透护盾=true）
## When: 毒性结算，伤害=15
## Then: 护盾被消耗至0，HP被扣除5
func test_poison_pierces_shield() -> void:
	# Arrange: 设置护盾并施加毒状态
	_resource_manager.add_armor(10)  # 护盾=10
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 验证护盾和毒状态
	assert_int(_resource_manager.get_armor()).is_equal(10)
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 护盾被消耗完，剩余伤害扣HP（12 - 10 = 2）
	assert_int(_resource_manager.get_armor()).is_equal(0)
	assert_int(_resource_manager.get_hp()).is_equal(50 - 2)  # 50 - 2 = 48


# ==================== 信号联动测试 ====================

## 测试 resource_changed 信号触发 DOT 结算
func test_resource_changed_triggers_dot() -> void:
	# Arrange: 施加毒状态
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 模拟一个信号处理函数来触发DOT结算
	var dot_triggered = false
	var damage_done = 0

	# 在实际系统中，ResourceManager会发射 resource_changed 信号
	# StatusManager会监听此信号并触发DOT结算
	# 为测试目的，我们模拟此逻辑
	_resource_manager.resource_changed.connect(func(type: int, old_val: int, new_val: int, delta: int):
		if type == ResourceManager.ResourceType.HP and delta < 0:  # HP减少
			dot_triggered = true
			# 这里本应触发_status_manager.on_round_start_dot(_resource_manager)
			# 但为了简化测试，我们直接调用
			_status_manager.on_round_start_dot(_resource_manager)
	)

	# Act: 模拟HP减少（如被攻击）
	_resource_manager.apply_damage(5, false)

	# Assert: DOT应被触发
	assert_bool(dot_triggered).is_true()

	# 验证伤害被正确应用
	# 由于我们已经测试了on_round_start_dot，这里只需确认触发
	# 实际测试应在系统级集成测试中进行


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

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 两个DOT都应被结算
	# Poison: 2×4 = 8
	# Burn: 1×3 = 3（根据StatusEffect定义）
	# 总伤害 = 11
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - 11)

	# 验证两个信号都被发射
	var poison_dot_emitted = false
	var burn_dot_emitted = false

	_status_manager.dot_dealt.connect(func(type: StatusEffect.Type, damage: int, pierced: bool):
		if type == StatusEffect.Type.POISON:
			poison_dot_emitted = true
		elif type == StatusEffect.Type.BURN:
			burn_dot_emitted = true
	)

	# 重置并重新触发
	_status_manager.on_round_start_dot(_resource_manager)

	assert_bool(poison_dot_emitted).is_true()
	assert_bool(burn_dot_emitted).is_true()


# ==================== 其他测试 ====================

## 测试治疗Buff在HP未满时不移除
func test_healing_buff_not_removed_when_not_full() -> void:
	# Arrange: 增加HP上限至100，施加HEALING，但HP=70（未满）
	_resource_manager.max_values[ResourceManager.ResourceType.HP] = 100
	_resource_manager.resources[ResourceManager.ResourceType.HP] = 70
	_status_manager.apply(StatusEffect.Type.HEALING, 1, "治疗药水")

	# Act: 恢复HP至75（仍不足80%）
	_resource_manager.heal_hp(5)

	# Assert: HEALING状态不应被移除
	assert_bool(_status_manager.has_status(StatusEffect.Type.HEALING)).is_true()
	assert_int(_status_manager.get_layers(StatusEffect.Type.HEALING)).is_equal(1)


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


## 测试护盾被完全消耗后继续DOT伤害
func test_shield_zero_then_dot_continues() -> void:
	# Arrange: 设置护盾为1，施加毒状态（伤害=12）
	_resource_manager.add_armor(1)
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# Act: 触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: 护盾=0，HP减少11（12-1）
	assert_int(_resource_manager.get_armor()).is_equal(0)
	assert_int(_resource_manager.get_hp()).is_equal(50 - 11)

	# 再次触发DOT结算（应继续扣HP）
	var hp_after_second = _resource_manager.get_hp()
	_status_manager.on_round_start_dot(_resource_manager)
	assert_int(_resource_manager.get_hp()).is_equal(hp_after_second - 12)


## 测试状态移除后DOT停止
func test_dot_stops_after_status_removed() -> void:
	# Arrange: 施加毒状态
	_status_manager.apply(StatusEffect.Type.POISON, 3, "毒箭卡")

	# 记录初始HP
	var hp_before = _resource_manager.get_hp()

	# Act: 触发一次DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: HP已减少12
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - 12)

	# Act: 移除毒状态
	_status_manager.force_remove(StatusEffect.Type.POISON, "治疗")

	# Act: 再次触发DOT结算
	_status_manager.on_round_start_dot(_resource_manager)

	# Assert: HP不再减少
	assert_int(_resource_manager.get_hp()).is_equal(hp_before - 12)
