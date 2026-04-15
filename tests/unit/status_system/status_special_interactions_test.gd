extends GdUnitTestSuite

# Story 5-13: 特殊交互规则（免疫/穿透/瘟疫）
# 覆盖：
# AC-1: 免疫阻止 Debuff
# AC-2: 免疫不阻止 Buff
# AC-3: 瘟疫传播信号（on_round_start_dot 时发射）
# AC-4: is_immune() 辅助查询
# AC-5: get_layers(BLOCK) 正确返回格挡层数
# 边缘：免疫到期后可再施加 Debuff；瘟疫层数0时不发传播信号

func _make_sm() -> StatusManager:
	return StatusManager.new()

func _make_rm(hp: int = 50) -> ResourceManager:
	var rm := ResourceManager.new()
	rm.init_hero(hp, 4)
	return rm

# ---------------------------------------------------------------------------
# AC-1: 免疫阻止 Debuff
# ---------------------------------------------------------------------------

func test_ac1_immune_blocks_all_debuff_types() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 2, "")

	# 尝试多种 Debuff，全部应静默失败
	assert_bool(sm.apply(StatusEffect.Type.POISON, 3, "")).is_false()
	assert_bool(sm.apply(StatusEffect.Type.BURN, 2, "")).is_false()
	assert_bool(sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")).is_false()
	assert_bool(sm.apply(StatusEffect.Type.BLIND, 1, "")).is_false()
	assert_bool(sm.apply(StatusEffect.Type.STUN, 1, "")).is_false()

	# 确认所有 Debuff 均未施加
	assert_int(sm.get_layers(StatusEffect.Type.POISON)).is_equal(0)
	assert_int(sm.get_layers(StatusEffect.Type.BURN)).is_equal(0)

func test_ac1_immune_block_does_not_send_status_applied_signal() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 1, "")

	var signal_count := 0
	# 仅统计 POISON 的 status_applied（IMMUNE 本身施加时会发一次，这里重连）
	sm.status_applied.connect(func(t, _l, _s):
		if int(t) == int(StatusEffect.Type.POISON):
			signal_count += 1
	)
	sm.apply(StatusEffect.Type.POISON, 3, "")
	assert_int(signal_count).is_equal(0)

# ---------------------------------------------------------------------------
# AC-2: 免疫不阻止 Buff
# ---------------------------------------------------------------------------

func test_ac2_immune_allows_buff_to_be_applied() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 2, "")

	var ok := sm.apply(StatusEffect.Type.FURY, 1, "")
	assert_bool(ok).is_true()
	assert_int(sm.get_layers(StatusEffect.Type.FURY)).is_equal(1)

func test_ac2_immune_allows_all_buff_types() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 1, "")

	# 施加不同种 Buff，均应成功
	assert_bool(sm.apply(StatusEffect.Type.DEFEND, 1, "")).is_true()
	assert_int(sm.get_layers(StatusEffect.Type.DEFEND)).is_equal(1)

# ---------------------------------------------------------------------------
# AC-3: 瘟疫传播信号
# ---------------------------------------------------------------------------

func test_ac3_plague_spread_signal_emitted_on_round_start_dot() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.PLAGUE, 2, "")
	var rm := _make_rm(50)

	var spread_layers := -1
	sm.plague_spread_requested.connect(func(layers: int): spread_layers = layers)

	sm.on_round_start_dot(rm)

	# 应发射传播信号，层数为 1
	assert_int(spread_layers).is_equal(1)

func test_ac3_no_plague_no_spread_signal() -> void:
	var sm := _make_sm()
	var rm := _make_rm(50)
	sm.apply(StatusEffect.Type.POISON, 2, "")  # 只有中毒，无瘟疫

	var spread_called := false
	sm.plague_spread_requested.connect(func(_l): spread_called = true)

	sm.on_round_start_dot(rm)
	assert_bool(spread_called).is_false()

func test_ac3_plague_layers_decrement_after_round_end() -> void:
	# 瘟疫也是 PER_ROUND，回合结束层数 -1
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.PLAGUE, 2, "")
	sm.on_round_end()
	assert_int(sm.get_layers(StatusEffect.Type.PLAGUE)).is_equal(1)

# ---------------------------------------------------------------------------
# AC-4: is_immune() 辅助查询
# ---------------------------------------------------------------------------

func test_ac4_is_immune_returns_true_when_immune_active() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 1, "")
	assert_bool(sm.is_immune()).is_true()

func test_ac4_is_immune_returns_false_without_immune() -> void:
	var sm := _make_sm()
	assert_bool(sm.is_immune()).is_false()

func test_ac4_is_immune_false_after_immune_expires() -> void:
	# 免疫到期后，可再施加 Debuff
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.IMMUNE, 1, "")
	sm.on_round_end()  # 免疫层数 -1 → 到期移除
	assert_bool(sm.is_immune()).is_false()
	# 现在可以施加 Debuff
	var ok := sm.apply(StatusEffect.Type.POISON, 2, "")
	assert_bool(ok).is_true()

# ---------------------------------------------------------------------------
# AC-5: get_layers(BLOCK) 正确返回格挡层数
# ---------------------------------------------------------------------------

func test_ac5_get_layers_block_returns_correct_count() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 3, "")
	assert_int(sm.get_layers(StatusEffect.Type.BLOCK)).is_equal(3)

func test_ac5_block_consume_decrements_layer() -> void:
	# BLOCK 是消耗型（CONSUME），调用 consume() 后层数 -1
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 2, "")
	sm.consume(StatusEffect.Type.BLOCK)
	assert_int(sm.get_layers(StatusEffect.Type.BLOCK)).is_equal(1)

func test_ac5_block_removed_when_consume_to_zero() -> void:
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLOCK, 1, "")
	sm.consume(StatusEffect.Type.BLOCK)
	assert_bool(sm.has_status(StatusEffect.Type.BLOCK)).is_false()
