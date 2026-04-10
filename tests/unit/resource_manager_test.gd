## resource_manager_test.gd
## ResourceManager 单元测试套件
##
## 覆盖范围：
##   - HP / 护盾伤害结算（非穿透与穿透）
##   - 护盾上限变体（默认、曹仁、张角无上限）
##   - 信号发射（hp_changed / armor_changed / hp_depleted / food_penalty_applied）
##   - 行动点消耗、恢复、全花（X费）、累积、上限
##   - 粮草消耗（充足 / 不足扣HP / 恰好归零边界）
##   - 战斗结束清零护盾与行动点
##
## 运行方式：GdUnit4（--headless）

extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# 辅助：构建已初始化的 ResourceManager
# ---------------------------------------------------------------------------

## 创建一个标准英雄配置（HP50, AP3）的 ResourceManager
func _make_rm(
	p_max_hp: int = 50,
	p_base_ap: int = 3,
	p_armor_max_override: int = 0
) -> ResourceManager:
	var rm := ResourceManager.new()
	rm.init_hero(p_max_hp, p_base_ap, p_armor_max_override)
	return rm


# ===========================================================================
# 1. 初始化状态验证
# ===========================================================================

func test_resource_manager_init_sets_hp_full() -> void:
	# Arrange / Act
	var rm := _make_rm(50, 3)
	# Assert
	assert_int(rm.get_hp()).is_equal(50)
	assert_int(rm.get_max_hp()).is_equal(50)


func test_resource_manager_init_sets_ap_full() -> void:
	# Arrange / Act
	var rm := _make_rm(50, 4)
	# Assert：战斗开始时行动点应加满
	assert_int(rm.get_ap()).is_equal(4)
	assert_int(rm.get_max_ap()).is_equal(4)


func test_resource_manager_init_sets_armor_zero() -> void:
	# Arrange / Act
	var rm := _make_rm()
	# Assert
	assert_int(rm.get_armor()).is_equal(0)


func test_resource_manager_init_armor_max_defaults_to_max_hp() -> void:
	# Arrange / Act
	var rm := _make_rm(50, 3, 0)
	# Assert：默认护盾上限 = MaxHP
	assert_int(rm.get_armor_max()).is_equal(50)


func test_resource_manager_init_armor_max_custom_override() -> void:
	# Arrange / Act（曹仁：MaxHP + 30 = 80）
	var rm := _make_rm(50, 3, 80)
	# Assert
	assert_int(rm.get_armor_max()).is_equal(80)


func test_resource_manager_init_armor_max_unlimited_for_zhang_jiao() -> void:
	# Arrange / Act（张角：-1 = 无上限）
	var rm := _make_rm(45, 3, -1)
	# Assert
	assert_int(rm.get_armor_max()).is_equal(-1)


# ===========================================================================
# 2. 非穿透伤害结算（护盾先挡）
# ===========================================================================

func test_apply_damage_non_pierce_shield_absorbs_partial() -> void:
	# Arrange：护盾 20，施加 15 点非穿透伤害
	var rm := _make_rm(50, 3)
	rm.add_armor(20)
	# Act
	var hp_lost := rm.apply_damage(15, false)
	# Assert：护盾从 20 降到 5，HP 不变，返回值 = 0
	assert_int(hp_lost).is_equal(0)
	assert_int(rm.get_armor()).is_equal(5)
	assert_int(rm.get_hp()).is_equal(50)


func test_apply_damage_non_pierce_overflow_damages_hp() -> void:
	# Arrange：护盾 10，施加 15 点非穿透伤害（溢出 5）
	var rm := _make_rm(50, 3)
	rm.add_armor(10)
	# Act
	var hp_lost := rm.apply_damage(15, false)
	# Assert：护盾归零，HP = 45，返回值 = 5
	assert_int(hp_lost).is_equal(5)
	assert_int(rm.get_armor()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(45)


func test_apply_damage_non_pierce_no_armor_all_to_hp() -> void:
	# Arrange：无护盾，施加 20 点非穿透伤害
	var rm := _make_rm(50, 3)
	# Act
	var hp_lost := rm.apply_damage(20, false)
	# Assert：HP = 30，返回值 = 20
	assert_int(hp_lost).is_equal(20)
	assert_int(rm.get_hp()).is_equal(30)


func test_apply_damage_non_pierce_shield_fully_blocks() -> void:
	# Arrange：护盾 30，施加 10 点非穿透伤害（护盾全挡）
	var rm := _make_rm(50, 3)
	rm.add_armor(30)
	# Act
	var hp_lost := rm.apply_damage(10, false)
	# Assert：护盾 20，HP 不变，返回值 = 0
	assert_int(hp_lost).is_equal(0)
	assert_int(rm.get_armor()).is_equal(20)
	assert_int(rm.get_hp()).is_equal(50)


# ===========================================================================
# 3. 穿透伤害结算（中毒/剧毒/重伤）
# ===========================================================================

func test_apply_damage_pierce_ignores_armor() -> void:
	# Arrange：护盾 20，施加 12 点穿透伤害
	var rm := _make_rm(50, 3)
	rm.add_armor(20)
	# Act
	var hp_lost := rm.apply_damage(12, true)
	# Assert：护盾不变，HP = 38，返回值 = 12
	assert_int(hp_lost).is_equal(12)
	assert_int(rm.get_armor()).is_equal(20)
	assert_int(rm.get_hp()).is_equal(38)


func test_apply_damage_pierce_zero_armor_same_as_direct() -> void:
	# Arrange：无护盾，施加 8 点穿透伤害
	var rm := _make_rm(50, 3)
	# Act
	var hp_lost := rm.apply_damage(8, true)
	# Assert：HP = 42，返回值 = 8
	assert_int(hp_lost).is_equal(8)
	assert_int(rm.get_hp()).is_equal(42)


# ===========================================================================
# 4. 信号发射验证
# ===========================================================================

func test_apply_damage_emits_hp_changed_signal() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	var signal_received := false
	var received_delta  := 0
	rm.hp_changed.connect(func(new_hp: int, delta: int) -> void:
		signal_received = true
		received_delta  = delta
	)
	# Act
	rm.apply_damage(10, true)
	# Assert
	assert_bool(signal_received).is_true()
	assert_int(received_delta).is_equal(-10)


func test_hp_depleted_signal_emitted_when_hp_reaches_zero() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	var depleted := false
	rm.hp_depleted.connect(func() -> void: depleted = true)
	# Act：一次性造成足以归零HP的伤害
	rm.apply_damage(50, true)
	# Assert
	assert_bool(depleted).is_true()
	assert_int(rm.get_hp()).is_equal(0)


func test_hp_not_depleted_signal_when_hp_above_zero() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	var depleted := false
	rm.hp_depleted.connect(func() -> void: depleted = true)
	# Act
	rm.apply_damage(30, true)
	# Assert：HP > 0，信号不应发射
	assert_bool(depleted).is_false()


func test_armor_changed_signal_emitted_on_armor_set() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	var signal_received := false
	rm.armor_changed.connect(func(_a: int, _d: int) -> void: signal_received = true)
	# Act
	rm.add_armor(10)
	# Assert
	assert_bool(signal_received).is_true()


# ===========================================================================
# 5. 治疗与护盾恢复
# ===========================================================================

func test_heal_increases_hp_up_to_max() -> void:
	# Arrange：先受伤 20
	var rm := _make_rm(50, 3)
	rm.apply_damage(20, true)
	# Act
	rm.heal(15)
	# Assert：HP = 45（不超过 50）
	assert_int(rm.get_hp()).is_equal(45)


func test_heal_does_not_exceed_max_hp() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	rm.apply_damage(5, true)  # HP = 45
	# Act：治疗量远超缺口
	rm.heal(100)
	# Assert：HP 上限为 50
	assert_int(rm.get_hp()).is_equal(50)


func test_add_armor_respects_armor_max() -> void:
	# Arrange：护盾上限 50（默认=MaxHP）
	var rm := _make_rm(50, 3)
	# Act：尝试添加 60 护盾
	rm.add_armor(60)
	# Assert：上限截断至 50
	assert_int(rm.get_armor()).is_equal(50)


func test_add_armor_unlimited_for_zhang_jiao() -> void:
	# Arrange：张角无上限（-1）
	var rm := _make_rm(45, 3, -1)
	# Act
	rm.add_armor(200)
	# Assert：无截断
	assert_int(rm.get_armor()).is_equal(200)


# ===========================================================================
# 6. 行动点管理
# ===========================================================================

func test_spend_ap_succeeds_when_sufficient() -> void:
	# Arrange：AP = 3
	var rm := _make_rm(50, 3)
	# Act
	var ok := rm.spend_ap(2)
	# Assert
	assert_bool(ok).is_true()
	assert_int(rm.get_ap()).is_equal(1)


func test_spend_ap_fails_when_insufficient() -> void:
	# Arrange：AP = 3
	var rm := _make_rm(50, 3)
	# Act：尝试消耗 5 点 AP
	var ok := rm.spend_ap(5)
	# Assert：失败，AP 不变
	assert_bool(ok).is_false()
	assert_int(rm.get_ap()).is_equal(3)


func test_restore_ap_does_not_exceed_max_ap() -> void:
	# Arrange：AP 已满（3/3）
	var rm := _make_rm(50, 3)
	# Act：再恢复 2 点
	rm.restore_ap(2)
	# Assert：上限截断至 3
	assert_int(rm.get_ap()).is_equal(3)


func test_spend_all_ap_returns_current_ap_and_zeroes_it() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	rm.spend_ap(1)  # AP = 2
	# Act
	var x := rm.spend_all_ap()
	# Assert：返回值 = 2，AP 归零
	assert_int(x).is_equal(2)
	assert_int(rm.get_ap()).is_equal(0)


func test_on_round_start_carry_ap_clips_to_max() -> void:
	# Arrange：先临时提升上限再降回（模拟超出上限情形）
	var rm := _make_rm(50, 3)
	rm.add_temp_ap_cap(2)    # max_ap = 5
	rm.restore_ap(5)         # ap = 5
	rm._max_ap = 3           # 模拟上限回落到 3
	# Act
	rm.on_round_start_carry_ap()
	# Assert：ap 截断至新上限 3
	assert_int(rm.get_ap()).is_equal(3)


func test_ap_carries_over_to_next_round() -> void:
	# Arrange：出牌后剩余 1 点 AP
	var rm := _make_rm(50, 3)
	rm.spend_ap(2)  # AP = 1
	# Act：模拟回合开始，AP 不重置
	rm.on_round_start_carry_ap()
	# Assert：AP 保留
	assert_int(rm.get_ap()).is_equal(1)


func test_add_temp_ap_cap_raises_limit() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	# Act
	rm.add_temp_ap_cap(2)
	rm.restore_ap(10)  # 尝试加满
	# Assert：新上限 = 5
	assert_int(rm.get_ap()).is_equal(5)
	assert_int(rm.get_max_ap()).is_equal(5)


# ===========================================================================
# 7. 粮草管理
# ===========================================================================

func test_consume_food_sufficient_reduces_food() -> void:
	# Arrange：粮草满载 150
	var rm := ResourceManager.new()
	rm.init_map()
	# Act
	var ok := rm.consume_food_for_move(5)
	# Assert
	assert_bool(ok).is_true()
	assert_int(rm.get_food()).is_equal(145)


func test_consume_food_exactly_zero_no_hp_penalty() -> void:
	# Arrange：粮草恰好等于本次消耗（Edge Case §4）
	var rm := ResourceManager.new()
	rm.init_hero(50, 3)
	rm.restore_food(10)    # food = 10
	var penalty_triggered := false
	rm.food_penalty_applied.connect(func(_c: int) -> void: penalty_triggered = true)
	# Act：消耗全部粮草
	var ok := rm.consume_food_for_move(10)
	# Assert：粮草归零但不扣 HP
	assert_bool(ok).is_true()
	assert_int(rm.get_food()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(50)
	assert_bool(penalty_triggered).is_false()


func test_consume_food_insufficient_deducts_hp() -> void:
	# Arrange：粮草 3，消耗 8
	var rm := ResourceManager.new()
	rm.init_hero(50, 3)
	rm.restore_food(3)
	# Act
	var ok := rm.consume_food_for_move(8)
	# Assert：差额 5 扣 HP；HP = 45；food = 0；返回 true（HP > 0）
	assert_bool(ok).is_true()
	assert_int(rm.get_food()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(45)


func test_consume_food_emits_food_penalty_applied_signal() -> void:
	# Arrange
	var rm := ResourceManager.new()
	rm.init_hero(50, 3)
	rm.restore_food(3)
	var penalty_hp := -1
	rm.food_penalty_applied.connect(func(cost: int) -> void: penalty_hp = cost)
	# Act
	rm.consume_food_for_move(8)
	# Assert：信号带有正确的差额
	assert_int(penalty_hp).is_equal(5)


func test_consume_food_hp_depleted_returns_false() -> void:
	# Arrange：HP = 5，粮草 0，消耗 10
	var rm := ResourceManager.new()
	rm.init_hero(5, 3)
	# food = 0（未调用 init_map）
	# Act
	var ok := rm.consume_food_for_move(10)
	# Assert：HP 耗尽，返回 false
	assert_bool(ok).is_false()
	assert_int(rm.get_hp()).is_equal(0)


func test_restore_food_capped_at_food_max() -> void:
	# Arrange：粮草满载
	var rm := ResourceManager.new()
	rm.init_map()  # food = 150
	# Act：尝试超量恢复
	rm.restore_food(50)
	# Assert：上限截断至 150
	assert_int(rm.get_food()).is_equal(ResourceManager.FOOD_MAX)


# ===========================================================================
# 8. 战斗结束结算
# ===========================================================================

func test_on_battle_end_clears_armor_and_ap() -> void:
	# Arrange
	var rm := _make_rm(50, 3)
	rm.add_armor(20)
	# AP = 3（战斗开始时已满）
	# Act
	rm.on_battle_end()
	# Assert：护盾与行动点清零，HP 保留
	assert_int(rm.get_armor()).is_equal(0)
	assert_int(rm.get_ap()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(50)


func test_on_battle_end_hp_persists() -> void:
	# Arrange：战斗中受伤 15
	var rm := _make_rm(50, 3)
	rm.apply_damage(15, true)
	# Act
	rm.on_battle_end()
	# Assert：HP = 35 保留
	assert_int(rm.get_hp()).is_equal(35)


# ===========================================================================
# 9. apply_modified_damage（含乘法系数）
# ===========================================================================

func test_apply_modified_damage_applies_multiplier_correctly() -> void:
	# Arrange：基础伤害 20，系数 0.75（坚守减伤）
	var rm := _make_rm(50, 3)
	# Act
	var hp_lost := rm.apply_modified_damage(20, 0.75, true)
	# Assert：floor(20 * 0.75) = 15
	assert_int(hp_lost).is_equal(15)
	assert_int(rm.get_hp()).is_equal(35)


func test_apply_modified_damage_rounds_correctly() -> void:
	# Arrange：基础伤害 7，系数 1.25（破甲增伤）→ round(8.75) = 9
	var rm := _make_rm(50, 3)
	# Act
	var hp_lost := rm.apply_modified_damage(7, 1.25, true)
	# Assert：roundi(8.75) = 9
	assert_int(hp_lost).is_equal(9)
