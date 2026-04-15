extends GdUnitTestSuite

# Story 5-6: 状态数据结构与基础增删改
# 覆盖 AC-1（枚举与数据初始化）、AC-2（施加与读取）、AC-3（移除）、AC-4（信号）

# ---------------------------------------------------------------------------
# 测试辅助
# ---------------------------------------------------------------------------

func _make_sm() -> StatusManager:
	return StatusManager.new()

# ---------------------------------------------------------------------------
# AC-1: 20 种枚举与数据初始化
# ---------------------------------------------------------------------------

func test_ac1_poison_meta_attributes() -> void:
	# Arrange / Act
	var meta := StatusEffect.get_status_meta(StatusEffect.Type.POISON)
	# Assert: 中毒 D1 穿透护盾，每回合 4 伤害
	assert_bool(meta.is_buff).is_false()
	assert_int(meta.dot_base_damage).is_equal(4)
	assert_bool(meta.dot_uses_armor).is_false()   # 穿透护盾
	assert_int(meta.decay_mode).is_equal(StatusEffect.DecayMode.PER_ROUND)

func test_ac1_burn_meta_walks_shield() -> void:
	# 灼烧 D9 走护盾，每回合 5 伤害
	var meta := StatusEffect.get_status_meta(StatusEffect.Type.BURN)
	assert_bool(meta.is_buff).is_false()
	assert_int(meta.dot_base_damage).is_equal(5)
	assert_bool(meta.dot_uses_armor).is_true()    # 走护盾

func test_ac1_fury_is_buff_per_round() -> void:
	var meta := StatusEffect.get_status_meta(StatusEffect.Type.FURY)
	assert_bool(meta.is_buff).is_true()
	assert_int(meta.decay_mode).is_equal(StatusEffect.DecayMode.PER_ROUND)

func test_ac1_block_is_consume_type() -> void:
	var meta := StatusEffect.get_status_meta(StatusEffect.Type.BLOCK)
	assert_bool(meta.is_buff).is_true()
	assert_int(meta.decay_mode).is_equal(StatusEffect.DecayMode.CONSUME)

func test_ac1_wound_damage_multiplies_layers() -> void:
	# 重伤 D12：伤害 = 层数 × 1（dot_layers_multiply = true）
	var meta := StatusEffect.get_status_meta(StatusEffect.Type.WOUND)
	assert_bool(meta.dot_layers_multiply).is_true()
	assert_bool(meta.dot_uses_armor).is_false()

func test_ac1_all_20_status_types_have_meta() -> void:
	# 验证所有枚举值都有对应元数据（无缺漏）
	var all_types: Array[StatusEffect.Type] = [
		StatusEffect.Type.FURY, StatusEffect.Type.AGILITY,
		StatusEffect.Type.BLOCK, StatusEffect.Type.DEFEND,
		StatusEffect.Type.COUNTER, StatusEffect.Type.PIERCE,
		StatusEffect.Type.IMMUNE, StatusEffect.Type.POISON,
		StatusEffect.Type.TOXIC, StatusEffect.Type.FEAR,
		StatusEffect.Type.CONFUSION, StatusEffect.Type.BLIND,
		StatusEffect.Type.SLIP, StatusEffect.Type.ARMOR_BREAK,
		StatusEffect.Type.WEAKEN, StatusEffect.Type.BURN,
		StatusEffect.Type.PLAGUE, StatusEffect.Type.STUN,
		StatusEffect.Type.WOUND, StatusEffect.Type.FROSTBITE,
		StatusEffect.Type.BLEEDING, StatusEffect.Type.RUSTY,
	]
	for t: StatusEffect.Type in all_types:
		var meta := StatusEffect.get_status_meta(t)
		assert_that(meta).is_not_null()

# ---------------------------------------------------------------------------
# AC-2: 基础施加与读取
# ---------------------------------------------------------------------------

func test_ac2_apply_and_get_layers() -> void:
	# Arrange
	var sm := _make_sm()
	# Act
	sm.apply(StatusEffect.Type.FURY, 2, "火攻卡")
	# Assert
	assert_int(sm.get_layers(StatusEffect.Type.FURY)).is_equal(2)
	assert_bool(sm.has_status(StatusEffect.Type.FURY)).is_true()

func test_ac2_get_nonexistent_status_returns_zero() -> void:
	var sm := _make_sm()
	assert_int(sm.get_layers(StatusEffect.Type.POISON)).is_equal(0)
	assert_bool(sm.has_status(StatusEffect.Type.POISON)).is_false()

func test_ac2_apply_returns_true_on_success() -> void:
	var sm := _make_sm()
	var ok := sm.apply(StatusEffect.Type.ARMOR_BREAK, 3, "破甲卡")
	assert_bool(ok).is_true()

# ---------------------------------------------------------------------------
# AC-3: 基础移除
# ---------------------------------------------------------------------------

func test_ac3_remove_existing_status() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.FURY, 2, "")
	# Act
	sm.force_remove(StatusEffect.Type.FURY)
	# Assert
	assert_int(sm.get_layers(StatusEffect.Type.FURY)).is_equal(0)
	assert_bool(sm.has_status(StatusEffect.Type.FURY)).is_false()

func test_ac3_remove_nonexistent_status_no_crash() -> void:
	# 移除不存在的状态不应抛出错误
	var sm := _make_sm()
	sm.force_remove(StatusEffect.Type.BLIND)  # 不应崩溃
	assert_bool(sm.has_status(StatusEffect.Type.BLIND)).is_false()

# ---------------------------------------------------------------------------
# AC-4: 信号发射
# ---------------------------------------------------------------------------

func test_ac4_status_applied_signal_emitted() -> void:
	# Arrange
	var sm := _make_sm()
	var received_type: int = -1
	var received_layers: int = -1
	sm.status_applied.connect(func(t, l, _s):
		received_type = int(t)
		received_layers = l
	)
	# Act
	sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
	# Assert
	assert_int(received_type).is_equal(int(StatusEffect.Type.POISON))
	assert_int(received_layers).is_equal(3)

func test_ac4_status_removed_signal_emitted() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BURN, 2, "")
	var removed_type: int = -1
	var removed_reason: String = ""
	sm.status_removed.connect(func(t, r):
		removed_type = int(t)
		removed_reason = r
	)
	# Act
	sm.force_remove(StatusEffect.Type.BURN, "forced")
	# Assert
	assert_int(removed_type).is_equal(int(StatusEffect.Type.BURN))
	assert_str(removed_reason).is_equal("forced")

func test_ac4_no_signal_when_removing_nonexistent() -> void:
	# 移除不存在的状态时不应发出 status_removed 信号
	var sm := _make_sm()
	var signal_count := 0
	sm.status_removed.connect(func(_t, _r): signal_count += 1)
	sm.force_remove(StatusEffect.Type.STUN)
	assert_int(signal_count).is_equal(0)
