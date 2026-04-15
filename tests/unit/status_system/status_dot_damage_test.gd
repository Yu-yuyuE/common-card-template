extends GdUnitTestSuite

# Story 5-10: 状态持续伤害（DoT）
# AC-1: 穿透护盾伤害（中毒）
# AC-2: 走护盾伤害完全吸收（灼烧）
# AC-3: 走护盾伤害溢出（灼烧）
# AC-4: 冻伤出牌触发（HP-1，层数不减）

# ---------------------------------------------------------------------------
# 测试辅助
# ---------------------------------------------------------------------------

func _make_rm(hp: int, armor: int = 0) -> ResourceManager:
	var rm := ResourceManager.new()
	rm.init_hero(hp, 4)
	if armor > 0:
		rm.add_armor(armor)
	return rm

func _make_sm() -> StatusManager:
	return StatusManager.new()

# ---------------------------------------------------------------------------
# AC-1: 穿透护盾伤害（中毒 D1，每层 4 伤）
# ---------------------------------------------------------------------------

func test_ac1_poison_dot_pierces_shield() -> void:
	# Arrange: HP=50, 护盾=10, 3 层中毒
	var rm := _make_rm(50, 10)
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 3, "")

	# Act: 回合开始结算 DoT
	sm.on_round_start_dot(rm)

	# Assert: 穿透护盾伤害 3×4=12，HP=38，护盾仍=10
	assert_int(rm.get_hp()).is_equal(38)
	assert_int(rm.get_armor()).is_equal(10)

func test_ac1_dot_damage_signal_emitted() -> void:
	var rm := _make_rm(50)
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 2, "")
	var dot_received := false
	sm.dot_dealt.connect(func(t, _d, _p): dot_received = true)
	sm.on_round_start_dot(rm)
	assert_bool(dot_received).is_true()

# ---------------------------------------------------------------------------
# AC-2: 走护盾完全吸收（灼烧 D9，每层 5 伤）
# ---------------------------------------------------------------------------

func test_ac2_burn_dot_absorbed_by_armor_fully() -> void:
	# Arrange: HP=50, 护盾=20, 3 层灼烧 → 3×5=15 伤
	var rm := _make_rm(50, 20)
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BURN, 3, "")

	sm.on_round_start_dot(rm)

	# Assert: 护盾从 20 变 5，HP 不变
	assert_int(rm.get_armor()).is_equal(5)
	assert_int(rm.get_hp()).is_equal(50)

# ---------------------------------------------------------------------------
# AC-3: 走护盾溢出（灼烧）
# ---------------------------------------------------------------------------

func test_ac3_burn_dot_overflows_to_hp() -> void:
	# Arrange: HP=50, 护盾=5, 2 层灼烧 → 2×5=10 伤
	var rm := _make_rm(50, 5)
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BURN, 2, "")

	sm.on_round_start_dot(rm)

	# Assert: 护盾 0，HP 减少 5（溢出）
	assert_int(rm.get_armor()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(45)

func test_ac3_burn_exact_shield_equals_dot_damage() -> void:
	# 护盾恰好等于 DoT 伤害：护盾归0，HP不变
	var rm := _make_rm(50, 10)
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BURN, 2, "")  # 2×5=10

	sm.on_round_start_dot(rm)

	assert_int(rm.get_armor()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(50)

# ---------------------------------------------------------------------------
# AC-4: 冻伤出牌触发（每次出牌 HP-1，层数不减）
# ---------------------------------------------------------------------------

func test_ac4_frostbite_card_cost_is_one_hp() -> void:
	# 冻伤单位每次出牌应向战斗系统报告 HP 扣减量 = 1
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FROSTBITE, 2, "")
	# get_frostbite_card_cost() 应返回 1（固定，不乘层数）
	assert_int(sm.get_frostbite_card_cost()).is_equal(1)

func test_ac4_frostbite_layers_not_consumed_by_round_start_dot() -> void:
	# 冻伤的 DoT 不在 on_round_start_dot 中触发（dot_base_damage=0）
	# 层数在 on_round_end 才 -1
	var rm := _make_rm(50)
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FROSTBITE, 2, "")

	sm.on_round_start_dot(rm)

	# HP 不变（冻伤不造成回合 DoT）
	assert_int(rm.get_hp()).is_equal(50)
	# 层数仍为 2（未被 DoT 消耗）
	assert_int(sm.get_layers(StatusEffect.Type.FROSTBITE)).is_equal(2)

# ---------------------------------------------------------------------------
# 重伤（D12）：层数乘法 DoT
# ---------------------------------------------------------------------------

func test_wound_dot_multiplies_layers() -> void:
	# 重伤：每层 1 伤，3 层 → 3×1=3 穿透伤害
	var rm := _make_rm(50, 10)
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.WOUND, 3, "")

	sm.on_round_start_dot(rm)

	# 穿透：护盾不变，HP=47
	assert_int(rm.get_hp()).is_equal(47)
	assert_int(rm.get_armor()).is_equal(10)

# ---------------------------------------------------------------------------
# 边缘情况：无状态时 on_round_start_dot 不崩溃
# ---------------------------------------------------------------------------

func test_no_status_round_start_dot_no_crash() -> void:
	var rm := _make_rm(50)
	var sm := _make_sm()
	sm.on_round_start_dot(rm)
	assert_int(rm.get_hp()).is_equal(50)
