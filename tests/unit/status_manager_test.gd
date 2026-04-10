## status_manager_test.gd
## StatusManager 单元测试套件
##
## 覆盖范围：
##   - apply：基础施加、同类叠加（层数相加）
##   - apply：负面状态互斥覆盖（不同类 Debuff 互斥）
##   - apply：剧毒覆盖中毒时层数合并（Edge Case）
##   - apply：免疫状态阻止负面状态施加（E5）
##   - apply：正面状态可共存
##   - on_round_start_dot：中毒穿透伤害、灼烧走护盾伤害、瘟疫传播信号
##   - on_round_end：PER_ROUND 状态层数衰减与归零移除
##   - consume：消耗型状态（格挡）逐层消耗与移除
##   - force_remove：强制移除
##   - 伤害修正查询（怒气/虚弱/坚守/破甲/盲目/迅捷）
##
## 运行方式：GdUnit4（--headless）

extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# 辅助：创建空白 StatusManager
# ---------------------------------------------------------------------------

func _make_sm() -> StatusManager:
	return StatusManager.new()


func _make_rm(p_max_hp: int = 50, p_base_ap: int = 3) -> ResourceManager:
	var rm := ResourceManager.new()
	rm.init_hero(p_max_hp, p_base_ap)
	return rm


# ===========================================================================
# 1. 基础施加 & 查询
# ===========================================================================

func test_apply_adds_new_status_with_correct_layers() -> void:
	# Arrange
	var sm := _make_sm()
	# Act
	var ok := sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Assert
	assert_bool(ok).is_true()
	assert_bool(sm.has_status(StatusEffect.Type.POISON)).is_true()
	assert_int(sm.get_layers(StatusEffect.Type.POISON)).is_equal(3)


func test_apply_returns_false_for_missing_status() -> void:
	# Arrange
	var sm := _make_sm()
	# Assert：未施加时 get_layers 返回 0
	assert_int(sm.get_layers(StatusEffect.Type.BURN)).is_equal(0)
	assert_bool(sm.has_status(StatusEffect.Type.BURN)).is_false()


func test_apply_emits_status_applied_signal() -> void:
	# Arrange
	var sm := _make_sm()
	var received_layers := -1
	sm.status_applied.connect(func(_t: StatusEffect.Type, new_layers: int, _s: String) -> void:
		received_layers = new_layers
	)
	# Act
	sm.apply(StatusEffect.Type.BURN, 2, "火攻卡")
	# Assert
	assert_int(received_layers).is_equal(2)


# ===========================================================================
# 2. 同类叠加（层数相加）
# ===========================================================================

func test_apply_same_type_stacks_layers() -> void:
	# Arrange：先施加 3 层中毒
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Act：再施加 2 层中毒
	sm.apply(StatusEffect.Type.POISON, 2, "剧毒卡")
	# Assert：总层数 = 5
	assert_int(sm.get_layers(StatusEffect.Type.POISON)).is_equal(5)


func test_apply_same_buff_type_stacks_layers() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY, 2, "怒气卡")
	# Act
	sm.apply(StatusEffect.Type.FURY, 3, "激怒卡")
	# Assert
	assert_int(sm.get_layers(StatusEffect.Type.FURY)).is_equal(5)


# ===========================================================================
# 3. 负面状态互斥覆盖
# ===========================================================================

func test_apply_debuff_overrides_existing_different_debuff() -> void:
	# Arrange：先施加中毒
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Act：施加异类负面状态（灼烧）
	sm.apply(StatusEffect.Type.BURN, 2, "火攻卡")
	# Assert：中毒被移除，灼烧生效
	assert_bool(sm.has_status(StatusEffect.Type.POISON)).is_false()
	assert_bool(sm.has_status(StatusEffect.Type.BURN)).is_true()
	assert_int(sm.get_layers(StatusEffect.Type.BURN)).is_equal(2)


func test_apply_debuff_override_emits_status_removed_for_old() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BURN, 3, "火攻卡")
	var removed_type   := -1
	var removed_reason := ""
	sm.status_removed.connect(func(t: StatusEffect.Type, reason: String) -> void:
		removed_type   = t
		removed_reason = reason
	)
	# Act：施加异类 Debuff（盲目）
	sm.apply(StatusEffect.Type.BLIND, 1, "烟雾卡")
	# Assert：灼烧以 "overridden" 被移除
	assert_int(removed_type).is_equal(StatusEffect.Type.BURN)
	assert_str(removed_reason).is_equal("overridden")


# ===========================================================================
# 4. 剧毒覆盖中毒（层数合并）
# ===========================================================================

func test_toxic_overrides_poison_and_merges_layers() -> void:
	# Arrange：施加 3 层中毒
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Act：施加 2 层剧毒（应合并 3 + 2 = 5 层）
	sm.apply(StatusEffect.Type.TOXIC, 2, "剧毒卡")
	# Assert：中毒消失，剧毒 = 5 层
	assert_bool(sm.has_status(StatusEffect.Type.POISON)).is_false()
	assert_bool(sm.has_status(StatusEffect.Type.TOXIC)).is_true()
	assert_int(sm.get_layers(StatusEffect.Type.TOXIC)).is_equal(5)


func test_toxic_without_existing_poison_uses_own_layers() -> void:
	# Arrange：无中毒状态
	var sm := _make_sm()
	# Act
	sm.apply(StatusEffect.Type.TOXIC, 4, "剧毒卡")
	# Assert：剧毒 = 4 层（无合并）
	assert_int(sm.get_layers(StatusEffect.Type.TOXIC)).is_equal(4)


# ===========================================================================
# 5. 免疫阻止 Debuff（E5）
# ===========================================================================

func test_immune_blocks_debuff_application() -> void:
	# Arrange：单位持有免疫状态
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 1, "免疫丹")
	# Act：尝试施加负面状态
	var ok := sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Assert：施加失败
	assert_bool(ok).is_false()
	assert_bool(sm.has_status(StatusEffect.Type.POISON)).is_false()


func test_immune_does_not_block_buff() -> void:
	# Arrange：单位持有免疫状态
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 1, "免疫丹")
	# Act：施加正面状态（怒气）
	var ok := sm.apply(StatusEffect.Type.FURY, 2, "怒气卡")
	# Assert：Buff 正常施加
	assert_bool(ok).is_true()
	assert_bool(sm.has_status(StatusEffect.Type.FURY)).is_true()


# ===========================================================================
# 6. 正面状态共存
# ===========================================================================

func test_multiple_buffs_can_coexist() -> void:
	# Arrange
	var sm := _make_sm()
	# Act：施加两种不同 Buff
	sm.apply(StatusEffect.Type.FURY, 2, "怒气卡")
	sm.apply(StatusEffect.Type.DEFEND, 1, "坚守卡")
	# Assert：两者共存
	assert_bool(sm.has_status(StatusEffect.Type.FURY)).is_true()
	assert_bool(sm.has_status(StatusEffect.Type.DEFEND)).is_true()


# ===========================================================================
# 7. on_round_start_dot：持续伤害结算
# ===========================================================================

func test_dot_poison_pierces_armor_and_deals_4_per_layer() -> void:
	# Arrange：3 层中毒（每层 4 点穿透伤害 → 共 12）
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	rm.add_armor(20)  # 护盾不应被扣减
	sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Act
	sm.on_round_start_dot(rm)
	# Assert：HP = 38，护盾不变
	assert_int(rm.get_hp()).is_equal(38)
	assert_int(rm.get_armor()).is_equal(20)


func test_dot_burn_uses_armor_and_deals_5_per_layer() -> void:
	# Arrange：2 层灼烧（每层 5 点走护盾伤害 → 共 10）；护盾 15
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	rm.add_armor(15)
	sm.apply(StatusEffect.Type.BURN, 2, "火攻卡")
	# Act
	sm.on_round_start_dot(rm)
	# Assert：护盾 15 - 10 = 5，HP 不变
	assert_int(rm.get_armor()).is_equal(5)
	assert_int(rm.get_hp()).is_equal(50)


func test_dot_burn_overflow_damages_hp() -> void:
	# Arrange：3 层灼烧（15点走护盾）；护盾 10，HP 50
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	rm.add_armor(10)
	sm.apply(StatusEffect.Type.BURN, 3, "烈火卡")
	# Act
	sm.on_round_start_dot(rm)
	# Assert：护盾归零，HP = 50 - 5 = 45
	assert_int(rm.get_armor()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(45)


func test_dot_toxic_deals_7_per_layer_pierce() -> void:
	# Arrange：2 层剧毒（7×2 = 14 穿透）；护盾 20
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	rm.add_armor(20)
	sm.apply(StatusEffect.Type.TOXIC, 2, "剧毒卡")
	# Act
	sm.on_round_start_dot(rm)
	# Assert：HP = 36，护盾不变
	assert_int(rm.get_hp()).is_equal(36)
	assert_int(rm.get_armor()).is_equal(20)


func test_dot_wound_deals_1_per_layer_pierce() -> void:
	# Arrange：4 层重伤（1×4 = 4 穿透）
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	rm.add_armor(20)
	sm.apply(StatusEffect.Type.WOUND, 4, "重伤卡")
	# Act
	sm.on_round_start_dot(rm)
	# Assert：HP = 46，护盾不变
	assert_int(rm.get_hp()).is_equal(46)
	assert_int(rm.get_armor()).is_equal(20)


func test_dot_plague_emits_spread_signal() -> void:
	# Arrange：施加瘟疫
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	sm.apply(StatusEffect.Type.PLAGUE, 2, "瘟疫卡")
	var spread_layers := -1
	sm.plague_spread_requested.connect(func(layers: int) -> void: spread_layers = layers)
	# Act
	sm.on_round_start_dot(rm)
	# Assert：传播信号发出且层数固定为 1
	assert_int(spread_layers).is_equal(1)


func test_dot_plague_damage_is_3_per_layer_pierce() -> void:
	# Arrange：2 层瘟疫（3×2 = 6 穿透）；护盾 10
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	rm.add_armor(10)
	sm.apply(StatusEffect.Type.PLAGUE, 2, "瘟疫卡")
	# Act
	sm.on_round_start_dot(rm)
	# Assert：HP = 44，护盾不变
	assert_int(rm.get_hp()).is_equal(44)
	assert_int(rm.get_armor()).is_equal(10)


func test_dot_emits_dot_dealt_signal() -> void:
	# Arrange
	var sm := _make_sm()
	var rm := _make_rm(50, 3)
	sm.apply(StatusEffect.Type.POISON, 2, "毒箭卡")
	var dot_damage   := -1
	var dot_pierced  := false
	sm.dot_dealt.connect(func(_t: StatusEffect.Type, damage: int, pierced: bool) -> void:
		dot_damage  = damage
		dot_pierced = pierced
	)
	# Act
	sm.on_round_start_dot(rm)
	# Assert：伤害量 = 8，穿透 = true
	assert_int(dot_damage).is_equal(8)
	assert_bool(dot_pierced).is_true()


# ===========================================================================
# 8. on_round_end：PER_ROUND 层数衰减
# ===========================================================================

func test_on_round_end_decrements_per_round_status() -> void:
	# Arrange：3 层中毒
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Act：过一回合
	sm.on_round_end()
	# Assert：层数 = 2
	assert_int(sm.get_layers(StatusEffect.Type.POISON)).is_equal(2)


func test_on_round_end_removes_status_when_layers_reach_zero() -> void:
	# Arrange：1 层中毒
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 1, "毒箭卡")
	# Act
	sm.on_round_end()
	# Assert：中毒消失
	assert_bool(sm.has_status(StatusEffect.Type.POISON)).is_false()


func test_on_round_end_emits_expired_reason_on_removal() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.STUN, 1, "眩晕卡")
	var reason := ""
	sm.status_removed.connect(func(_t: StatusEffect.Type, r: String) -> void: reason = r)
	# Act
	sm.on_round_end()
	# Assert
	assert_str(reason).is_equal("expired")


func test_on_round_end_does_not_decrement_consume_type() -> void:
	# Arrange：格挡（消耗型，不应被 on_round_end 衰减）
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 3, "格挡卡")
	# Act
	sm.on_round_end()
	# Assert：层数不变
	assert_int(sm.get_layers(StatusEffect.Type.BLOCK)).is_equal(3)


func test_on_round_end_multiple_statuses_decay_independently() -> void:
	# Arrange：3 层怒气 + 2 层坚守
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY,   3, "怒气卡")
	sm.apply(StatusEffect.Type.DEFEND, 2, "坚守卡")
	# Act
	sm.on_round_end()
	# Assert
	assert_int(sm.get_layers(StatusEffect.Type.FURY)).is_equal(2)
	assert_int(sm.get_layers(StatusEffect.Type.DEFEND)).is_equal(1)


# ===========================================================================
# 9. consume：消耗型状态
# ===========================================================================

func test_consume_block_decrements_layer() -> void:
	# Arrange：2 层格挡
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 2, "格挡卡")
	# Act
	var ok := sm.consume(StatusEffect.Type.BLOCK)
	# Assert
	assert_bool(ok).is_true()
	assert_int(sm.get_layers(StatusEffect.Type.BLOCK)).is_equal(1)


func test_consume_block_removes_when_last_layer_consumed() -> void:
	# Arrange：1 层格挡
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 1, "格挡卡")
	# Act
	sm.consume(StatusEffect.Type.BLOCK)
	# Assert：格挡消失
	assert_bool(sm.has_status(StatusEffect.Type.BLOCK)).is_false()


func test_consume_returns_false_when_status_absent() -> void:
	# Arrange：无格挡
	var sm := _make_sm()
	# Act
	var ok := sm.consume(StatusEffect.Type.BLOCK)
	# Assert
	assert_bool(ok).is_false()


func test_consume_emits_consumed_reason_on_removal() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 1, "格挡卡")
	var reason := ""
	sm.status_removed.connect(func(_t: StatusEffect.Type, r: String) -> void: reason = r)
	# Act
	sm.consume(StatusEffect.Type.BLOCK)
	# Assert
	assert_str(reason).is_equal("consumed")


# ===========================================================================
# 10. force_remove：强制移除
# ===========================================================================

func test_force_remove_removes_status() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.STUN, 2, "眩晕卡")
	# Act
	sm.force_remove(StatusEffect.Type.STUN)
	# Assert
	assert_bool(sm.has_status(StatusEffect.Type.STUN)).is_false()


func test_force_remove_silent_when_status_absent() -> void:
	# Arrange
	var sm := _make_sm()
	# Act & Assert：不应抛异常
	sm.force_remove(StatusEffect.Type.BLIND)
	assert_bool(sm.has_status(StatusEffect.Type.BLIND)).is_false()


# ===========================================================================
# 11. on_battle_end：清空所有状态
# ===========================================================================

func test_on_battle_end_clears_all_statuses() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY,   2, "怒气卡")
	sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")  # 会互斥，先测 Buff+Debuff
	# 由于 POISON 是 Debuff，FURY 是 Buff，两者可共存
	# Act
	sm.on_battle_end()
	# Assert：全部清空
	assert_int(sm.get_all_effects().size()).is_equal(0)


# ===========================================================================
# 12. 伤害修正查询
# ===========================================================================

func test_get_attack_damage_multiplier_fury_increases_by_25_percent() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY, 1, "怒气卡")
	# Act / Assert
	assert_float(sm.get_attack_damage_multiplier()).is_equal_approx(1.25, 0.001)


func test_get_attack_damage_multiplier_weaken_reduces_by_25_percent() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.WEAKEN, 1, "虚弱卡")
	# Act / Assert
	assert_float(sm.get_attack_damage_multiplier()).is_equal_approx(0.75, 0.001)


func test_get_attack_damage_multiplier_fury_and_weaken_combined() -> void:
	# Arrange：怒气 × 虚弱 = 1.25 × 0.75 = 0.9375
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY,   1, "怒气卡")
	sm.apply(StatusEffect.Type.WEAKEN, 1, "虚弱卡")
	# Act / Assert
	assert_float(sm.get_attack_damage_multiplier()).is_equal_approx(0.9375, 0.001)


func test_get_incoming_damage_multiplier_defend_reduces_by_25_percent() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.DEFEND, 1, "坚守卡")
	# Act / Assert
	assert_float(sm.get_incoming_damage_multiplier()).is_equal_approx(0.75, 0.001)


func test_get_incoming_damage_multiplier_armor_break_increases_by_25_percent() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "破甲卡")
	# Act / Assert
	assert_float(sm.get_incoming_damage_multiplier()).is_equal_approx(1.25, 0.001)


func test_get_hit_chance_blind_returns_0_5() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLIND, 1, "烟雾卡")
	# Act / Assert
	assert_float(sm.get_hit_chance()).is_equal_approx(0.5, 0.001)


func test_get_hit_chance_normal_returns_1_0() -> void:
	# Arrange
	var sm := _make_sm()
	# Act / Assert
	assert_float(sm.get_hit_chance()).is_equal_approx(1.0, 0.001)


func test_get_dodge_chance_agility_returns_0_5() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.AGILITY, 1, "迅捷卡")
	# Act / Assert
	assert_float(sm.get_dodge_chance()).is_equal_approx(0.5, 0.001)


func test_get_dodge_chance_no_agility_returns_0() -> void:
	# Arrange
	var sm := _make_sm()
	# Act / Assert
	assert_float(sm.get_dodge_chance()).is_equal_approx(0.0, 0.001)


func test_get_frostbite_card_cost_with_frostbite() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FROSTBITE, 1, "冻伤卡")
	# Act / Assert
	assert_int(sm.get_frostbite_card_cost()).is_equal(1)


func test_get_frostbite_card_cost_without_frostbite() -> void:
	# Arrange
	var sm := _make_sm()
	# Act / Assert
	assert_int(sm.get_frostbite_card_cost()).is_equal(0)


func test_get_fear_bonus_damage_equals_fear_layers() -> void:
	# Arrange：3 层恐惧
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FEAR, 3, "恐惧卡")
	# Act / Assert
	assert_int(sm.get_fear_bonus_damage()).is_equal(3)
