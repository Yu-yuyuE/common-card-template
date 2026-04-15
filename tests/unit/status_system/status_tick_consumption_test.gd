extends GdUnitTestSuite

# Story 5-8: 状态回合结束结算机制
# 覆盖 AC-1（正常层数消耗）、AC-2（层数归零自动移除）、AC-3（遍历安全性）

func _make_sm() -> StatusManager:
	return StatusManager.new()

# ---------------------------------------------------------------------------
# AC-1: 正常层数消耗
# ---------------------------------------------------------------------------

func test_ac1_per_round_status_decrements_on_round_end() -> void:
	# Arrange: 3 层中毒（PER_ROUND）
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 3, "")
	# Act
	sm.on_round_end()
	# Assert: 变为 2 层
	assert_int(sm.get_layers(StatusEffect.Type.POISON)).is_equal(2)

func test_ac1_multiple_statuses_all_decrement() -> void:
	# 多种状态同时 -1 层
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.POISON, 3, "")
	sm.apply(StatusEffect.Type.FURY, 2, "")
	sm.on_round_end()
	assert_int(sm.get_layers(StatusEffect.Type.POISON)).is_equal(2)
	assert_int(sm.get_layers(StatusEffect.Type.FURY)).is_equal(1)

func test_ac1_no_status_round_end_no_crash() -> void:
	# 目标无任何状态时 on_round_end 不崩溃
	var sm := _make_sm()
	sm.on_round_end()  # 不应抛出异常
	assert_int(sm.get_all_effects().size()).is_equal(0)

# ---------------------------------------------------------------------------
# AC-2: 层数归零自动移除
# ---------------------------------------------------------------------------

func test_ac2_one_layer_removed_after_tick() -> void:
	# Arrange: 1 层破甲
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")
	# Act
	sm.on_round_end()
	# Assert: 状态消失
	assert_bool(sm.has_status(StatusEffect.Type.ARMOR_BREAK)).is_false()
	assert_int(sm.get_layers(StatusEffect.Type.ARMOR_BREAK)).is_equal(0)

func test_ac2_removal_sends_status_removed_signal() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")
	var removed_type: int = -1
	sm.status_removed.connect(func(t, _r): removed_type = int(t))
	sm.on_round_end()
	assert_int(removed_type).is_equal(int(StatusEffect.Type.ARMOR_BREAK))

func test_ac2_two_statuses_one_layer_one_two() -> void:
	# 1 层的移除，2 层的变为 1 层
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")  # 1 层
	sm.apply(StatusEffect.Type.POISON, 2, "")        # 2 层（不同类，需先清掉 ARMOR_BREAK 后施加？）
	# 实际：ARMOR_BREAK 是 Debuff，POISON 是 Debuff → 互斥，POISON 会替换 ARMOR_BREAK
	# 所以改为 Buff + Debuff 共存场景：
	var sm2 := _make_sm()
	sm2.apply(StatusEffect.Type.FURY, 1, "")         # Buff, 1 层
	sm2.apply(StatusEffect.Type.POISON, 2, "")       # Debuff, 2 层
	sm2.on_round_end()
	# 1 层 FURY 消失，2 层 POISON 变为 1 层
	assert_bool(sm2.has_status(StatusEffect.Type.FURY)).is_false()
	assert_int(sm2.get_layers(StatusEffect.Type.POISON)).is_equal(1)

# ---------------------------------------------------------------------------
# AC-3: 遍历安全性（迭代中移除不引发越界）
# ---------------------------------------------------------------------------

func test_ac3_iteration_safe_during_removal() -> void:
	# Arrange: 多个状态，其中部分将在 on_round_end 时归零并移除
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY, 1, "")          # Buff 1 层 → 将被移除
	sm.apply(StatusEffect.Type.POISON, 1, "")        # Debuff 1 层 → 将被移除
	# Act: 不应抛出越界或迭代修改错误
	sm.on_round_end()
	# Assert: 两者均已移除
	assert_bool(sm.has_status(StatusEffect.Type.FURY)).is_false()
	assert_bool(sm.has_status(StatusEffect.Type.POISON)).is_false()

func test_ac3_many_statuses_partial_removal() -> void:
	# 多个状态混合：部分层数 >1（不移除），部分 =1（移除）
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY, 3, "")          # Buff 3 层 → 变 2 层
	sm.apply(StatusEffect.Type.WEAKEN, 1, "")        # Debuff 1 层 → 移除（施加时 WEAKEN 会替换已有 Debuff）
	sm.on_round_end()
	assert_int(sm.get_layers(StatusEffect.Type.FURY)).is_equal(2)
	assert_bool(sm.has_status(StatusEffect.Type.WEAKEN)).is_false()

# ---------------------------------------------------------------------------
# 消耗型状态不受 on_round_end 影响（CONSUME 类型）
# ---------------------------------------------------------------------------

func test_consume_type_not_decremented_by_round_end() -> void:
	# BLOCK 是 CONSUME 型 — 不应在 on_round_end 时自动 -1 层
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 2, "")
	sm.on_round_end()
	# BLOCK 层数应保持不变（CONSUME 型只在 consume() 被主动调用时才消耗）
	assert_int(sm.get_layers(StatusEffect.Type.BLOCK)).is_equal(2)

# ---------------------------------------------------------------------------
# on_battle_end: 战斗结束后清空所有状态
# ---------------------------------------------------------------------------

func test_battle_end_clears_all_effects() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY, 2, "")
	sm.apply(StatusEffect.Type.POISON, 3, "")
	sm.on_battle_end()
	assert_int(sm.get_all_effects().size()).is_equal(0)
