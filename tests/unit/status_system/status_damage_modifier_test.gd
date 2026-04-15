extends GdUnitTestSuite

# Story 5-11: 状态伤害修正系数
# AC-1: 攻击方修正（怒气+25%、虚弱-25%）
# AC-2: 受击方修正（破甲+25%）
# AC-3: 受击方复合修正（坚守×0.75 + 恐惧+层数）
# AC-4: 盲目闪避（使用确定性 RNG 注入验证）
# AC-5: 最小伤害保底 = 1

func _make_sm() -> StatusManager:
	return StatusManager.new()

# ---------------------------------------------------------------------------
# AC-1: 攻击方伤害修正
# ---------------------------------------------------------------------------

func test_ac1_fury_increases_damage_by_25_percent() -> void:
	# Arrange: 攻击方有怒气
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY, 1, "")
	# Act
	var result := sm.calculate_damage_modifier(10)
	# Assert: 10 × 1.25 = 12（int(12.5) = 12，向下取整）
	assert_int(result).is_equal(12)

func test_ac1_weaken_reduces_damage_by_25_percent() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.WEAKEN, 1, "")
	# 但怒气和虚弱互斥（均为 Debuff/Buff 不同类），这里只有虚弱
	# 10 × 0.75 = 7（int(7.5) = 7）
	var result := sm.calculate_damage_modifier(10)
	assert_int(result).is_equal(7)

func test_ac1_no_status_no_modifier() -> void:
	var sm := _make_sm()
	assert_int(sm.calculate_damage_modifier(10)).is_equal(10)

func test_ac1_minimum_damage_is_1_after_weaken() -> void:
	# 极小基础伤害经过 ×0.75 后若 < 1，仍保底返回 1
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.WEAKEN, 1, "")
	assert_int(sm.calculate_damage_modifier(1)).is_equal(1)

# ---------------------------------------------------------------------------
# AC-2: 受击方修正（破甲）
# ---------------------------------------------------------------------------

func test_ac2_armor_break_increases_incoming_by_25_percent() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")
	# 传入 10，× 1.25 = 12
	var result := sm.calculate_incoming_damage_with_rng(10, 0.9) # rng=0.9 不触发盲目
	assert_int(result).is_equal(12)

func test_ac2_defend_reduces_incoming_by_25_percent() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.DEFEND, 1, "")
	# 传入 10，× 0.75 = 7
	var result := sm.calculate_incoming_damage_with_rng(10, 0.9)
	assert_int(result).is_equal(7)

# ---------------------------------------------------------------------------
# AC-3: 受击方复合修正（坚守 + 恐惧）
# ---------------------------------------------------------------------------

func test_ac3_defend_plus_fear_3_layers() -> void:
	# 坚守×0.75 = 7，+恐惧3层 = 10
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.DEFEND, 1, "")
	sm.apply(StatusEffect.Type.FEAR, 3, "")
	var result := sm.calculate_incoming_damage_with_rng(10, 0.9)
	assert_int(result).is_equal(10) # int(10×0.75)=7，+3=10

func test_ac3_armor_break_plus_fear_2_layers() -> void:
	# 破甲×1.25=12，+恐惧2=14
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")
	sm.apply(StatusEffect.Type.FEAR, 2, "")
	var result := sm.calculate_incoming_damage_with_rng(10, 0.9)
	assert_int(result).is_equal(14) # int(10×1.25)=12，+2=14

func test_ac3_multiply_precision_0_75_x_1_25() -> void:
	# 连乘精度：10 × 0.75 × 1.25 = 9.375 → int = 9
	# 注：坚守和破甲互斥（均为 Buff/Debuff 不同类，但坚守是Buff破甲是Debuff可共存）
	# 只有当同时存在才验证连乘，但设计上坚守为 Buff、破甲为 Debuff，两者可共存
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.DEFEND, 1, "")   # Buff
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")  # Debuff（会覆盖任何其他Debuff）
	var result := sm.calculate_incoming_damage_with_rng(10, 0.9)
	# 坚守×0.75 × 破甲×1.25 = 0.9375 → int(9.375) = 9，无恐惧
	assert_int(result).is_equal(9)

# ---------------------------------------------------------------------------
# AC-4: 盲目闪避（确定性 RNG 注入）
# ---------------------------------------------------------------------------

func test_ac4_blind_dodge_when_rng_below_0_5() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLIND, 1, "")
	# rng=0.3 < 0.5 → 触发闪避，返回 0
	var result := sm.calculate_incoming_damage_with_rng(10, 0.3)
	assert_int(result).is_equal(0)

func test_ac4_blind_no_dodge_when_rng_above_0_5() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLIND, 1, "")
	# rng=0.7 >= 0.5 → 不闪避，正常伤害
	var result := sm.calculate_incoming_damage_with_rng(10, 0.7)
	assert_int(result).is_equal(10)

func test_ac4_no_blind_rng_irrelevant() -> void:
	var sm := _make_sm()
	# 无盲目，rng=0.1 也不会闪避
	var result := sm.calculate_incoming_damage_with_rng(10, 0.1)
	assert_int(result).is_equal(10)

func test_ac4_blind_plus_armor_break_dodge_returns_zero() -> void:
	# 盲目+破甲：触发闪避时返回0，不走破甲加成
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLIND, 1, "")
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")
	# rng=0.2 → 闪避，返回 0（不是 12）
	var result := sm.calculate_incoming_damage_with_rng(10, 0.2)
	assert_int(result).is_equal(0)

# ---------------------------------------------------------------------------
# AC-5: 最小伤害保底 = 1
# ---------------------------------------------------------------------------

func test_ac5_minimum_damage_floor_is_1() -> void:
	# 坚守对极小伤害减益后仍保底1
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.DEFEND, 1, "")
	# 传入 1，×0.75=0，保底1
	var result := sm.calculate_incoming_damage_with_rng(1, 0.9)
	assert_int(result).is_equal(1)
