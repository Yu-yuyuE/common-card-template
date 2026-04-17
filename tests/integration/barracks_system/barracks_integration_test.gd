## 军营系统集成测试（story-002）
##
## 覆盖范围：BarracksManager 集成层所有公共方法的 AC 验收条件。
## Story ID: TR-barracks-system-001
## 测试框架：GdUnit4
##
## 注意：
##   - 每个测试独立创建 BarracksManager 实例，不依赖任何单例
##   - 不涉及 ResourceManager、EventBus 或文件系统
extends GdUnitTestSuite


# ===========================================================================
# initialize_session
# ===========================================================================

## AC: initialize_session 后，get_pending_deck 应返回与初始卡组相同内容
func test_initialize_session_sets_pending_deck() -> void:
	# Arrange
	var b := BarracksManager.new()
	var initial: Array[String] = ["card_a", "card_b", "card_c"]

	# Act
	b.initialize_session(initial)

	# Assert
	assert_array(b.get_pending_deck()).contains_exactly(["card_a", "card_b", "card_c"])


# ===========================================================================
# commit_add_card
# ===========================================================================

## AC: 未达统帅上限时，添加卡牌应成功并出现在暂存卡组中
func test_commit_add_card_success() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["card_a", "card_b"])

	# Act
	var result := b.commit_add_card("troop_001_lv1", 0, 3)

	# Assert
	assert_bool(result["success"]).is_true()
	assert_str(result["reason"]).is_equal("")
	assert_array(b.get_pending_deck()).contains(["troop_001_lv1"])


## AC: 已达统帅上限时，commit_add_card 应返回 LEADERSHIP_CAP 且不修改暂存卡组
func test_commit_add_card_leadership_cap() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["troop_a", "troop_b"])
	# current_troop_count == leadership → 不可再添加

	# Act
	var result := b.commit_add_card("troop_003_lv1", 3, 3)

	# Assert
	assert_bool(result["success"]).is_false()
	assert_str(result["reason"]).is_equal("LEADERSHIP_CAP")
	assert_int(b.get_pending_deck().size()).is_equal(2)


# ===========================================================================
# commit_upgrade_card
# ===========================================================================

## AC: 金币充足且卡牌存在时，升级应成功：旧卡移除、新 Lv2 卡加入、gold_spent=50
func test_commit_upgrade_card_success() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["sword_lv1", "shield_lv1"])

	# Act
	var result := b.commit_upgrade_card("sword_lv1", 100)

	# Assert
	assert_bool(result["success"]).is_true()
	assert_int(result["gold_spent"]).is_equal(50)
	assert_str(result["new_card_id"]).is_equal("sword_lv2")
	assert_str(result["reason"]).is_equal("")
	var deck := b.get_pending_deck()
	assert_array(deck).not_contains(["sword_lv1"])
	assert_array(deck).contains(["sword_lv2"])


## AC: 卡牌 ID 无 "_lv1" 后缀时，升级应追加 "_lv2" 而非替换
func test_commit_upgrade_card_success_no_lv1_suffix() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["archer", "pike"])

	# Act
	var result := b.commit_upgrade_card("archer", 100)

	# Assert
	assert_bool(result["success"]).is_true()
	assert_str(result["new_card_id"]).is_equal("archer_lv2")
	assert_array(b.get_pending_deck()).contains(["archer_lv2"])
	assert_array(b.get_pending_deck()).not_contains(["archer"])


## AC: 金币 < 50 时，commit_upgrade_card 应返回 INSUFFICIENT_GOLD
func test_commit_upgrade_card_insufficient_gold() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["sword_lv1"])

	# Act
	var result := b.commit_upgrade_card("sword_lv1", 30)

	# Assert
	assert_bool(result["success"]).is_false()
	assert_int(result["gold_spent"]).is_equal(0)
	assert_str(result["new_card_id"]).is_equal("")
	assert_str(result["reason"]).is_equal("INSUFFICIENT_GOLD")
	# 暂存卡组不应有任何变化
	assert_array(b.get_pending_deck()).contains_exactly(["sword_lv1"])


## AC: 要升级的卡牌不在暂存卡组中时，应返回 CARD_NOT_FOUND
func test_commit_upgrade_card_card_not_found() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["shield_lv1"])

	# Act
	var result := b.commit_upgrade_card("sword_lv1", 100)

	# Assert
	assert_bool(result["success"]).is_false()
	assert_int(result["gold_spent"]).is_equal(0)
	assert_str(result["new_card_id"]).is_equal("")
	assert_str(result["reason"]).is_equal("CARD_NOT_FOUND")


# ===========================================================================
# commit_remove_card
# ===========================================================================

## AC: 移除存在的卡牌应成功，暂存卡组中该卡不再存在
func test_commit_remove_card_success() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["card_a", "card_b", "card_c"])

	# Act
	var result := b.commit_remove_card("card_b")

	# Assert
	assert_bool(result["success"]).is_true()
	assert_str(result["reason"]).is_equal("")
	assert_array(b.get_pending_deck()).not_contains(["card_b"])
	assert_int(b.get_pending_deck().size()).is_equal(2)


## AC: 移除不存在的卡牌应返回 CARD_NOT_FOUND，暂存卡组不变
func test_commit_remove_card_not_found() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["card_a", "card_b"])

	# Act
	var result := b.commit_remove_card("card_z")

	# Assert
	assert_bool(result["success"]).is_false()
	assert_str(result["reason"]).is_equal("CARD_NOT_FOUND")
	assert_int(b.get_pending_deck().size()).is_equal(2)


# ===========================================================================
# reset_pending
# ===========================================================================

## AC: reset_pending 后，暂存卡组应完全恢复到 initialize_session 时的初始快照
func test_reset_pending_restores_initial_deck() -> void:
	# Arrange
	var b := BarracksManager.new()
	var initial: Array[String] = ["card_a", "card_b"]
	b.initialize_session(initial)
	# 进行若干变更
	b.commit_add_card("card_c", 0, 5)
	b.commit_remove_card("card_a")

	# Act
	b.reset_pending()

	# Assert
	assert_array(b.get_pending_deck()).contains_exactly(["card_a", "card_b"])


# ===========================================================================
# save_and_exit
# ===========================================================================

## AC: save_and_exit 应返回当前暂存卡组的副本
func test_save_and_exit_returns_final_deck() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["card_a", "card_b"])
	b.commit_add_card("card_c", 0, 5)

	# Act
	var final_deck := b.save_and_exit()

	# Assert
	assert_array(final_deck).contains_exactly(["card_a", "card_b", "card_c"])


## AC: save_and_exit 后，reset_pending 不应回滚到旧快照（initial_deck 已更新）
func test_save_and_exit_updates_initial_snapshot() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["card_a"])
	b.commit_add_card("card_b", 0, 5)
	b.save_and_exit()  # 提交，initial_deck 应更新为 ["card_a", "card_b"]

	# Act
	b.reset_pending()

	# Assert — reset 后应回到已保存状态，而非最初进入时的状态
	assert_array(b.get_pending_deck()).contains_exactly(["card_a", "card_b"])


# ===========================================================================
# 综合流程
# ===========================================================================

## AC: 添加卡后 pending 与 initial 不同；reset 后 pending 恢复与 initial 一致
func test_pending_not_equal_initial_before_save() -> void:
	# Arrange
	var b := BarracksManager.new()
	b.initialize_session(["card_a", "card_b"])

	# Act — 添加卡后暂存与初始应不同
	b.commit_add_card("card_c", 0, 5)
	var pending_after_add := b.get_pending_deck()

	# Assert — pending 包含 card_c，已与初始不同
	assert_int(pending_after_add.size()).is_equal(3)
	assert_array(pending_after_add).contains(["card_c"])

	# Act — reset 后应恢复
	b.reset_pending()
	var pending_after_reset := b.get_pending_deck()

	# Assert — 恢复为初始两张卡
	assert_array(pending_after_reset).contains_exactly(["card_a", "card_b"])
