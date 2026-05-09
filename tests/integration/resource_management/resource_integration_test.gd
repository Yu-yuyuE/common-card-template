## resource_integration_test.gd
## ResourceManager 集成测试套件
##
## 覆盖验收标准：
##   AC-1 跨回合集成 — 战斗结束清零（护盾、行动点）
##   AC-2 跨系统伤害与移动惩罚 — 粮草耗尽扣 HP、HP 归零发信号
##   UI集成 — resource_changed / food_penalty_applied 信号广播验证
##
## 测试框架：GdUnit4（extends GdUnitTestSuite）
## 被测类：ResourceManager（src/core/ResourceManager.gd）
## Sprint 8 Story 8-6

extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# 工具方法：每个测试独立创建并初始化 ResourceManager 实例
# ---------------------------------------------------------------------------

## 创建独立的 ResourceManager 实例并挂入场景树（确保信号正常工作）
func _make_rm(max_hp: int = 30, base_ap: int = 4, armor_max: int = 20) -> ResourceManager:
	var rm := ResourceManager.new()
	add_child(rm)
	rm.init_hero(max_hp, base_ap, armor_max)
	return rm


## 释放实例（测试结束后调用）
func _free_rm(rm: ResourceManager) -> void:
	rm.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# AC-1：跨回合集成 — 战斗结束清零
# ---------------------------------------------------------------------------

## AC-1 主路径：战斗结束后护盾清零、行动点清零，HP 和粮草保持不变
func test_battle_end_clears_armor_and_ap() -> void:
	var rm := _make_rm(30, 4, 20)

	# 准备：给予护盾和部分消耗 AP
	rm.add_armor(10)
	rm.spend_action_points(1)  # AP 从 4 减到 3

	assert_int(rm.get_armor()).is_equal(10)
	assert_int(rm.get_action_points()).is_equal(3)

	var hp_before: int = rm.get_hp()
	var prov_before: int = rm.get_provisions()

	# 执行
	rm.on_battle_end()

	# 验证：护盾清零
	assert_int(rm.get_armor()).is_equal(0)
	# 验证：行动点清零
	assert_int(rm.get_action_points()).is_equal(0)
	# 验证：HP 不变
	assert_int(rm.get_hp()).is_equal(hp_before)
	# 验证：粮草不变
	assert_int(rm.get_provisions()).is_equal(prov_before)

	await _free_rm(rm)


## AC-1 边界：行动点本已为 0 时调用 on_battle_end() 不报错，护盾同样清零
func test_battle_end_ap_already_zero_no_error() -> void:
	var rm := _make_rm(30, 4, 20)

	# 准备：AP 耗尽，护盾有值
	rm.spend_action_points(4)  # AP → 0
	rm.add_armor(5)

	assert_int(rm.get_action_points()).is_equal(0)
	assert_int(rm.get_armor()).is_equal(5)

	# 执行：AP 本已为 0，不应抛出错误
	rm.on_battle_end()

	# 验证：护盾清零，AP 仍为 0
	assert_int(rm.get_armor()).is_equal(0)
	assert_int(rm.get_action_points()).is_equal(0)

	await _free_rm(rm)


# ---------------------------------------------------------------------------
# AC-2：跨系统伤害与移动惩罚
# ---------------------------------------------------------------------------

## AC-2 主路径：粮草为 0 时消耗粮草，差额从 HP 扣除
func test_provisions_depleted_reduces_hp() -> void:
	var rm := _make_rm(30, 4, 20)

	# 准备：将粮草手动设置为 0（先消耗全部粮草）
	rm.modify_resource(ResourceManager.ResourceType.PROVISIONS, -rm.get_provisions())
	assert_int(rm.get_provisions()).is_equal(0)

	var hp_before: int = rm.get_hp()  # 应为 30

	# 执行：粮草不足 2，差额 2 扣 HP
	rm.consume_provisions(2)

	# 验证：HP 减少 2
	assert_int(rm.get_hp()).is_equal(hp_before - 2)
	# 验证：粮草仍为 0
	assert_int(rm.get_provisions()).is_equal(0)

	await _free_rm(rm)


## AC-2 边界：消耗量超过 HP，HP 归零并发出 hp_depleted 信号
func test_provisions_depleted_hp_to_zero_emits_hp_depleted() -> void:
	var rm := _make_rm(10, 4, 20)

	# 准备：粮草归零，HP = 10
	rm.modify_resource(ResourceManager.ResourceType.PROVISIONS, -rm.get_provisions())
	assert_int(rm.get_provisions()).is_equal(0)
	assert_int(rm.get_hp()).is_equal(10)

	# 信号捕获标志
	var hp_depleted_received: bool = false
	rm.hp_depleted.connect(func() -> void:
		hp_depleted_received = true
	)

	# 执行：消耗 10 点粮草，全部差额扣 HP，HP → 0
	rm.consume_provisions(10)

	# 验证：HP 为 0
	assert_int(rm.get_hp()).is_equal(0)
	# 验证：hp_depleted 信号已发出
	assert_bool(hp_depleted_received).is_true()

	await _free_rm(rm)


# ---------------------------------------------------------------------------
# 护盾溢出集成测试
# ---------------------------------------------------------------------------

## 护盾破裂溢出：伤害超过护盾时，溢出部分扣 HP
func test_apply_damage_shield_absorbs_overflow_to_hp() -> void:
	var rm := _make_rm(30, 4, 20)

	# 准备：给予 5 点护盾
	rm.add_armor(5)
	assert_int(rm.get_armor()).is_equal(5)

	var hp_before: int = rm.get_hp()  # 30

	# 执行：施加 8 点伤害（护盾吸收 5，溢出 3 扣 HP）
	var total_damage: int = rm.apply_damage(8)

	# 验证：护盾清零
	assert_int(rm.get_armor()).is_equal(0)
	# 验证：HP 减少 3（溢出部分）
	assert_int(rm.get_hp()).is_equal(hp_before - 3)
	# 验证：返回的总伤害值为 8（护盾5 + HP3）
	assert_int(total_damage).is_equal(8)

	await _free_rm(rm)


# ---------------------------------------------------------------------------
# UI 集成：信号广播验证
# ---------------------------------------------------------------------------

## 信号广播：consume_provisions 不足时 food_penalty_applied 携带正确的 hp_cost
func test_food_penalty_signal_carries_correct_hp_cost() -> void:
	var rm := _make_rm(30, 4, 20)

	# 准备：粮草剩余 3，消耗 5（差额 = 5 - 3 = 2，即 hp_cost = 2）
	rm.modify_resource(ResourceManager.ResourceType.PROVISIONS, -rm.get_provisions())
	rm.modify_resource(ResourceManager.ResourceType.PROVISIONS, 3)
	assert_int(rm.get_provisions()).is_equal(3)

	# 信号捕获
	var received_hp_cost: int = -1
	rm.food_penalty_applied.connect(func(hp_cost: int) -> void:
		received_hp_cost = hp_cost
	)

	# 执行
	rm.consume_provisions(5)

	# 验证：信号已发出且 hp_cost 值正确（差额 = 2）
	assert_int(received_hp_cost).is_equal(2)
	# 验证：HP 实际减少了 2
	assert_int(rm.get_hp()).is_equal(28)

	await _free_rm(rm)


## 信号广播：apply_damage 护盾破裂时 resource_changed 对护盾和 HP 均正确发出
func test_apply_damage_shield_break_emits_resource_changed_for_armor_and_hp() -> void:
	var rm := _make_rm(30, 4, 20)

	# 准备：给予 5 点护盾
	rm.add_armor(5)

	# 信号捕获：收集所有 resource_changed 发射记录
	var changes: Array = []
	rm.resource_changed.connect(func(res_type: int, old_val: int, new_val: int, delta: int) -> void:
		changes.append({
			"type": res_type,
			"old": old_val,
			"new": new_val,
			"delta": delta
		})
	)

	# 执行：伤害 8（护盾 5 + HP 溢出 3）
	rm.apply_damage(8)

	# 验证：至少发出了两次 resource_changed（护盾 + HP）
	assert_int(changes.size()).is_greater_equal(2)

	# 找护盾变化记录
	var armor_change: Dictionary = {}
	var hp_change: Dictionary = {}
	for c in changes:
		if c["type"] == ResourceManager.ResourceType.ARMOR:
			armor_change = c
		elif c["type"] == ResourceManager.ResourceType.HP:
			hp_change = c

	# 验证护盾变化：5 → 0，delta = -5
	assert_bool(armor_change.is_empty()).is_false()
	assert_int(armor_change["old"]).is_equal(5)
	assert_int(armor_change["new"]).is_equal(0)
	assert_int(armor_change["delta"]).is_equal(-5)

	# 验证 HP 变化：30 → 27，delta = -3
	assert_bool(hp_change.is_empty()).is_false()
	assert_int(hp_change["old"]).is_equal(30)
	assert_int(hp_change["new"]).is_equal(27)
	assert_int(hp_change["delta"]).is_equal(-3)

	await _free_rm(rm)
