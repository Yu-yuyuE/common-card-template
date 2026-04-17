## inn_services_test.gd
## InnManager 单元测试套件
##
## 覆盖 Story inn-system-001 全部验收标准（AC1–AC5 共 12 个场景）。
## 测试不依赖 ResourceManager、EventBus 或任何单例 —— 完全参数注入。
##
## TR-ID：TR-inn-system-001
extends GdUnitTestSuite


# ============================================================
# AC1 — 歇息服务：正常恢复 15 HP
# ============================================================

## HP 差 >= REST_BASE_HEAL 时，rest() 应返回 REST_BASE_HEAL（15）
func test_rest_returns_heal_amount() -> void:
	var inn := InnManager.new()
	# current_hp=50, max_hp=100 → 差值 50 >= 15 → 应恢复 15
	var healed: int = inn.rest(50, 100)
	assert_int(healed).is_equal(15)


# ============================================================
# AC2 — HP 已满时歇息返回 0 且不改变状态
# ============================================================

## HP 满时，rest() 应返回 0，且 rest_count 不变
func test_rest_at_max_hp_returns_zero() -> void:
	var inn := InnManager.new()
	var healed: int = inn.rest(100, 100)
	assert_int(healed).is_equal(0)
	# rest_count 不应自增
	assert_int(inn.rest_count).is_equal(0)


# ============================================================
# AC1（边界）— HP 差 < REST_BASE_HEAL 时只恢复差值
# ============================================================

## HP 差为 8（< 15）时，rest() 应只返回 8
func test_rest_partial_heal() -> void:
	var inn := InnManager.new()
	# current_hp=92, max_hp=100 → 差值 8 < 15 → 应恢复 8
	var healed: int = inn.rest(92, 100)
	assert_int(healed).is_equal(8)


# ============================================================
# AC5 — 歇息后 rest_count 自增
# ============================================================

## 成功歇息一次后，rest_count 应从 0 变为 1
func test_rest_increments_count() -> void:
	var inn := InnManager.new()
	inn.rest(50, 100)
	assert_int(inn.rest_count).is_equal(1)


# ============================================================
# AC5 — 章节歇息限制阻止二次歇息
# ============================================================

## 歇息 1 次（达到 REST_LIMIT）后，can_rest() 应返回 false
func test_rest_chapter_limit_blocks() -> void:
	var inn := InnManager.new()
	inn.rest(50, 100)  # 第 1 次，消耗配额
	assert_bool(inn.can_rest(50, 100)).is_false()


# ============================================================
# AC5 — reset_chapter() 重置 rest_count
# ============================================================

## reset_chapter() 后 rest_count 应为 0，can_rest() 恢复 true
func test_reset_chapter_clears_count() -> void:
	var inn := InnManager.new()
	inn.rest(50, 100)                    # 用掉本章配额
	assert_int(inn.rest_count).is_equal(1)

	inn.reset_chapter()
	assert_int(inn.rest_count).is_equal(0)
	assert_bool(inn.can_rest(50, 100)).is_true()


# ============================================================
# AC3 — 购买粮草：成功路径
# ============================================================

## 持有 40 金且粮草未满时，buy_provisions() 应返回 success=true
func test_buy_provisions_success() -> void:
	var inn := InnManager.new()
	var result: Dictionary = inn.buy_provisions(40, 0, 100)
	assert_bool(result["success"]).is_true()
	assert_int(result["provisions_gained"]).is_equal(40)
	assert_int(result["gold_spent"]).is_equal(40)


# ============================================================
# AC3 — 购买粮草：金币不足
# ============================================================

## 金币 < 40 时，buy_provisions() 应返回 success=false
func test_buy_provisions_insufficient_gold() -> void:
	var inn := InnManager.new()
	var result: Dictionary = inn.buy_provisions(39, 0, 100)
	assert_bool(result["success"]).is_false()
	assert_str(result["reason"]).is_equal("INSUFFICIENT_GOLD")
	assert_int(result["gold_spent"]).is_equal(0)


# ============================================================
# AC3 — 购买粮草：粮草已达上限
# ============================================================

## current_provisions == max_provisions 时，buy_provisions() 应返回 success=false
func test_buy_provisions_at_cap() -> void:
	var inn := InnManager.new()
	var result: Dictionary = inn.buy_provisions(100, 80, 80)
	assert_bool(result["success"]).is_false()
	assert_str(result["reason"]).is_equal("PROVISIONS_AT_CAP")
	assert_int(result["provisions_gained"]).is_equal(0)


# ============================================================
# AC4 — 强化休整：成功路径
# ============================================================

## 60 金、HP 未满时，fortify() 应返回 success=true，hp_gained=min(20,diff)
func test_fortify_success() -> void:
	var inn := InnManager.new()
	# diff=50 >= 20 → hp_gained 应为 20
	var result: Dictionary = inn.fortify(50, 100, 60)
	assert_bool(result["success"]).is_true()
	assert_int(result["hp_gained"]).is_equal(20)
	assert_int(result["gold_spent"]).is_equal(60)


## 强化休整 HP 差 < ENHANCED_HEAL 时只恢复差值
func test_fortify_partial_heal() -> void:
	var inn := InnManager.new()
	# diff=10 < 20 → hp_gained 应为 10
	var result: Dictionary = inn.fortify(90, 100, 60)
	assert_bool(result["success"]).is_true()
	assert_int(result["hp_gained"]).is_equal(10)


# ============================================================
# AC4 — 强化休整：HP 已满时失败
# ============================================================

## HP 满时，fortify() 应返回 success=false，reason=HP_FULL
func test_fortify_at_max_hp_fails() -> void:
	var inn := InnManager.new()
	var result: Dictionary = inn.fortify(100, 100, 100)
	assert_bool(result["success"]).is_false()
	assert_str(result["reason"]).is_equal("HP_FULL")
	assert_int(result["hp_gained"]).is_equal(0)
	assert_int(result["gold_spent"]).is_equal(0)


# ============================================================
# AC4 — 强化休整：金币不足时失败
# ============================================================

## 金币 < 60 时，fortify() 应返回 success=false，reason=INSUFFICIENT_GOLD
func test_fortify_insufficient_gold_fails() -> void:
	var inn := InnManager.new()
	var result: Dictionary = inn.fortify(50, 100, 59)
	assert_bool(result["success"]).is_false()
	assert_str(result["reason"]).is_equal("INSUFFICIENT_GOLD")
	assert_int(result["hp_gained"]).is_equal(0)
	assert_int(result["gold_spent"]).is_equal(0)
