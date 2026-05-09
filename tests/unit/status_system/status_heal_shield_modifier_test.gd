## status_heal_shield_modifier_test.gd
## StatusManager 治疗与护盾修正系数单元测试
##
## 覆盖验收标准（Story 8-7）：
##   AC-1 流血(BLEEDING)状态减少治疗量 × 0.5
##   AC-2 生锈(RUSTY)状态减少护盾量 × 0.5
##   AC-3 无状态时正常返回原值
##   AC-4 流血与生锈互斥（不同类 Debuff，后施加覆盖前者）
##   AC-5 多次施加同类状态层数刷新（取累加值）
##   AC-6 治疗与护盾修正独立生效（BLEEDING 不影响护盾，RUSTY 不影响治疗）
##   AC-1/AC-2 边界：基础值为 1 时向下取整为 0
##
## 测试框架：GdUnit4（extends GdUnitTestSuite）
## 被测类：StatusManager（src/core/StatusManager.gd）

extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# 工具方法
# ---------------------------------------------------------------------------

## 创建干净的 StatusManager 实例
func _make_sm() -> StatusManager:
	return StatusManager.new()


# ---------------------------------------------------------------------------
# AC-3：无状态时正常返回原值（基础路径，先验证）
# ---------------------------------------------------------------------------

## 无任何状态时，calculate_heal_modifier 返回原始治疗量
func test_no_status_heal_modifier_returns_base_value() -> void:
	# Arrange
	var sm := _make_sm()

	# Act
	var result: int = sm.calculate_heal_modifier(10)

	# Assert
	assert_int(result).is_equal(10)


## 无任何状态时，calculate_shield_modifier 返回原始护盾量
func test_no_status_shield_modifier_returns_base_value() -> void:
	# Arrange
	var sm := _make_sm()

	# Act
	var result: int = sm.calculate_shield_modifier(10)

	# Assert
	assert_int(result).is_equal(10)


# ---------------------------------------------------------------------------
# AC-1：流血状态减少治疗量
# ---------------------------------------------------------------------------

## 流血状态下 calculate_heal_modifier 返回 base × 0.5（向下取整）
func test_bleeding_reduces_heal_modifier_by_half() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLEEDING, 1, "test")

	# Act
	var result: int = sm.calculate_heal_modifier(10)

	# Assert — 10 × 0.5 = 5
	assert_int(result).is_equal(5)


## 流血边界：基础治疗为 1 时，int(1 × 0.5) = 0
func test_bleeding_heal_modifier_base_1_rounds_down_to_0() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLEEDING, 1, "test")

	# Act
	var result: int = sm.calculate_heal_modifier(1)

	# Assert — int(1 × 0.5) = 0
	assert_int(result).is_equal(0)


## 流血层数不影响修正系数大小（流血只有有/无，层数仅决定持续时间）
func test_bleeding_multiple_layers_still_halves_heal() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLEEDING, 3, "test")  # 3 层流血

	# Act
	var result: int = sm.calculate_heal_modifier(20)

	# Assert — 20 × 0.5 = 10（层数不影响系数）
	assert_int(result).is_equal(10)


# ---------------------------------------------------------------------------
# AC-2：生锈状态减少护盾量
# ---------------------------------------------------------------------------

## 生锈状态下 calculate_shield_modifier 返回 base × 0.5（向下取整）
func test_rusty_reduces_shield_modifier_by_half() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.RUSTY, 1, "test")

	# Act
	var result: int = sm.calculate_shield_modifier(10)

	# Assert — 10 × 0.5 = 5
	assert_int(result).is_equal(5)


## 生锈边界：基础护盾为 1 时，int(1 × 0.5) = 0
func test_rusty_shield_modifier_base_1_rounds_down_to_0() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.RUSTY, 1, "test")

	# Act
	var result: int = sm.calculate_shield_modifier(1)

	# Assert — int(1 × 0.5) = 0
	assert_int(result).is_equal(0)


# ---------------------------------------------------------------------------
# AC-4：流血与生锈互斥（不同类 Debuff，后施加覆盖先者）
# ---------------------------------------------------------------------------

## 先施加流血，后施加生锈：流血被移除，生锈生效
## 治疗修正恢复正常，护盾修正减半
func test_rusty_overrides_bleeding_different_debuff_types() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLEEDING, 2, "first")
	assert_bool(sm.has_status(StatusEffect.Type.BLEEDING)).is_true()

	# 施加生锈（不同类 Debuff → 覆盖流血）
	sm.apply(StatusEffect.Type.RUSTY, 1, "second")

	# Assert — 流血被移除
	assert_bool(sm.has_status(StatusEffect.Type.BLEEDING)).is_false()
	# Assert — 生锈已生效
	assert_bool(sm.has_status(StatusEffect.Type.RUSTY)).is_true()
	# Assert — 治疗修正回到正常（无流血）
	assert_int(sm.calculate_heal_modifier(10)).is_equal(10)
	# Assert — 护盾修正减半（有生锈）
	assert_int(sm.calculate_shield_modifier(10)).is_equal(5)


# ---------------------------------------------------------------------------
# AC-5：多次施加同类状态层数叠加
# ---------------------------------------------------------------------------

## 同类 Debuff 叠加：流血层数相加（2 + 3 = 5）
func test_bleeding_layers_stack_same_type() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLEEDING, 2, "first")
	sm.apply(StatusEffect.Type.BLEEDING, 3, "second")

	# Assert — 层数相加为 5
	assert_int(sm.get_layers(StatusEffect.Type.BLEEDING)).is_equal(5)
	# Assert — 修正系数仍为 0.5（层数不改变系数）
	assert_int(sm.calculate_heal_modifier(10)).is_equal(5)


# ---------------------------------------------------------------------------
# AC-6：治疗与护盾修正独立生效
# ---------------------------------------------------------------------------

## 流血不影响护盾修正（BLEEDING 只修正治疗）
func test_bleeding_does_not_affect_shield_modifier() -> void:
	# Arrange
	var sm := _make_sm()
	sm.apply(StatusEffect.Type.BLEEDING, 1, "test")

	# Assert — 治疗修正减半
	assert_int(sm.calculate_heal_modifier(10)).is_equal(5)
	# Assert — 护盾修正不受影响（返回原值）
	assert_int(sm.calculate_shield_modifier(10)).is_equal(10)
