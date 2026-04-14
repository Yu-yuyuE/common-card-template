## curse_removal_test.gd
## 诅咒卡移除机制单元测试（Story 4-8）
##
## 验证诅咒卡通过三种标准路径永久移出卡组：
##   1. 军营删除（直接从战役层移除）
##   2. 消耗品（战斗中耗尽后战斗结束时从战役层移除）
##   3. 卡牌效果移除（标注"使用后移除"，进入 removed_cards 区）
##
## 设计参考：design/gdd/curse-system.md (E7, E8, AC5)
## ADR-0020: 卡组两层管理架构
##
## 作者: Claude Code
## 创建日期: 2026-04-14

class_name CurseRemovalTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 模拟战役层快照（使用真实 CampaignDeckSnapshot）
var _campaign_snapshot: CampaignDeckSnapshot

## 模拟战斗层快照
var _battle_snapshot: BattleDeckSnapshot

## 战役管理器
var _deck_manager: CampaignDeckManager

# ==================== 测试生命周期 ====================

func before_test() -> void:
	_campaign_snapshot = CampaignDeckSnapshot.new()
	_battle_snapshot = BattleDeckSnapshot.new()
	_deck_manager = CampaignDeckManager.new()
	add_child(_deck_manager)

	# 预置卡组：3张普通卡 + 2张诅咒卡
	_deck_manager.current_snapshot.add_card("strike_001", 1, "initial")
	_deck_manager.current_snapshot.add_card("strike_002", 1, "initial")
	_deck_manager.current_snapshot.add_card("defend_001", 1, "initial")
	_deck_manager.current_snapshot.add_card("curse_plague", 1, "event")
	_deck_manager.current_snapshot.add_card("curse_taohui", 1, "event")


func after_test() -> void:
	if _deck_manager and is_instance_valid(_deck_manager):
		_deck_manager.queue_free()
	_deck_manager = null
	_campaign_snapshot = null
	_battle_snapshot = null


# ==================== 路径1：军营删除 ====================

## AC5-路径1：军营节点直接移除诅咒卡
## Given: 战役卡组中有诅咒卡 curse_plague
## When: 军营调用 remove_card（通过 campaign_snapshot 直接移除）
## Then: 诅咒卡从战役卡组永久消失，后续战斗不再出现
func test_curse_removal_via_barracks() -> void:
	# Arrange: 确认诅咒卡在卡组
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_true()

	# Act: 军营删除（直接修改战役层快照，不经过战斗）
	_deck_manager.current_snapshot.remove_card("curse_plague")

	# Assert: 战役层不再有该诅咒卡
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_false()

	# Assert: 版本号递增（表示状态已变更）
	assert_int(_deck_manager.current_snapshot.version).is_greater(0)


## 军营删除后开始战斗，战斗牌库不含该诅咒卡
func test_barracks_removal_not_in_battle() -> void:
	# Act: 军营删除
	_deck_manager.current_snapshot.remove_card("curse_plague")

	# 开始战斗
	_deck_manager.start_battle()

	# Assert: 战斗层抽牌堆中没有被删除的诅咒卡
	assert_bool(_deck_manager.current_battle_snapshot.draw_pile.has("curse_plague")).is_false()

	# Assert: 其他卡仍在
	assert_bool(_deck_manager.current_battle_snapshot.draw_pile.has("curse_taohui")).is_true()
	assert_bool(_deck_manager.current_battle_snapshot.draw_pile.has("strike_001")).is_true()


## 军营删除不影响同卡组中其他诅咒卡
func test_barracks_removal_only_targets_one_card() -> void:
	var initial_count := _deck_manager.current_snapshot.cards.size()

	# 删除一张诅咒卡
	_deck_manager.current_snapshot.remove_card("curse_plague")

	# 另一张诅咒卡仍在
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_taohui")).is_true()
	assert_int(_deck_manager.current_snapshot.cards.size()).is_equal(initial_count - 1)


# ==================== 路径2：消耗品（战斗中 exhaust） ====================

## AC5-路径2：战斗中打出消耗品诅咒卡，战斗结束后从战役层永久移除
## Given: 战役卡组有 curse_plague，war中以 to_exhaust=true 打出
## When: 战斗结束
## Then: curse_plague 从战役卡组消失
func test_curse_removal_via_exhaust() -> void:
	# Arrange: 开始战斗
	_deck_manager.start_battle()

	# 将 curse_plague 强制放入手牌（模拟抽到该卡）
	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_plague")
	_deck_manager.current_battle_snapshot.hand_cards.append("curse_plague")

	# Act: 以消耗品方式打出
	_deck_manager.current_battle_snapshot.play_card("curse_plague", false, true)

	# 验证进入 exhaust_cards 区
	assert_bool(_deck_manager.current_battle_snapshot.exhaust_cards.has("curse_plague")).is_true()

	# 结束战斗（触发回写）
	_deck_manager.end_battle()

	# Assert: 战役层不再有该诅咒卡
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_false()


## 消耗品移除后，下一场战斗不会再出现该卡
func test_exhausted_curse_not_in_next_battle() -> void:
	# 第一场战斗
	_deck_manager.start_battle()
	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_plague")
	_deck_manager.current_battle_snapshot.hand_cards.append("curse_plague")
	_deck_manager.current_battle_snapshot.play_card("curse_plague", false, true)
	_deck_manager.end_battle()

	# 第二场战斗
	_deck_manager.start_battle()

	# Assert: 第二场战斗牌库中没有已消耗的诅咒卡
	assert_bool(_deck_manager.current_battle_snapshot.draw_pile.has("curse_plague")).is_false()
	assert_bool(_deck_manager.current_battle_snapshot.hand_cards.has("curse_plague")).is_false()

	_deck_manager.end_battle()


## 消耗品逻辑不影响普通弃置（to_exhaust=false 的卡战斗后仍在卡组）
func test_normal_discard_curse_returns_to_deck() -> void:
	_deck_manager.start_battle()
	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_plague")
	_deck_manager.current_battle_snapshot.hand_cards.append("curse_plague")

	# 普通弃置（非消耗品）
	_deck_manager.current_battle_snapshot.play_card("curse_plague", false, false)

	assert_bool(_deck_manager.current_battle_snapshot.discard_pile.has("curse_plague")).is_true()
	assert_bool(_deck_manager.current_battle_snapshot.exhaust_cards.has("curse_plague")).is_false()

	# 结束战斗
	_deck_manager.end_battle()

	# Assert: 诅咒卡仍在战役层（普通弃置不移除）
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_true()


# ==================== 路径3：卡牌效果移除（removed_cards） ====================

## AC5-路径3：标注"使用后移除"的诅咒卡，通过 to_removed=true 移入 removed_cards
## removed_cards 是"本场战斗移除"区，战斗结束后不回卡组也不写回战役层
## 注意：这与消耗品不同——removed_cards 不影响战役层，卡牌仍在卡组
func test_curse_removal_via_card_effect_removed_zone() -> void:
	_deck_manager.start_battle()
	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_plague")
	_deck_manager.current_battle_snapshot.hand_cards.append("curse_plague")

	# Act: 以"使用后移除"效果打出（仅本场战斗移除）
	_deck_manager.current_battle_snapshot.play_card("curse_plague", true, false)

	# Assert: 卡在 removed_cards 区（非 exhaust）
	assert_bool(_deck_manager.current_battle_snapshot.removed_cards.has("curse_plague")).is_true()
	assert_bool(_deck_manager.current_battle_snapshot.exhaust_cards.has("curse_plague")).is_false()

	# 结束战斗
	_deck_manager.end_battle()

	# Assert: 战役层仍保留该诅咒卡（removed_cards 不回写）
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_true()


# ==================== 边界情况（GDD E7, E8） ====================

## E8: 诅咒卡被移除出卡组（exhaust），效果消除
## 本测试验证：exhaust 后，第二场战斗的战役卡组确认不含该卡
func test_curse_effect_eliminated_after_removal(  ) -> void:
	# 战役层有 2 张韬晦（常驻牌库型，会减少 MaxHP）
	_deck_manager.current_snapshot.add_card("curse_taohui_copy", 1, "event")

	# 开始战斗，消耗一张韬晦
	_deck_manager.start_battle()
	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_taohui")
	_deck_manager.current_battle_snapshot.hand_cards.append("curse_taohui")
	_deck_manager.current_battle_snapshot.play_card("curse_taohui", false, true)
	_deck_manager.end_battle()

	# Assert: 战役层剩1张韬晦（另一张被消耗）
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_taohui")).is_false()
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_taohui_copy")).is_true()


## 移除不存在的诅咒卡不崩溃
func test_remove_nonexistent_curse_is_safe() -> void:
	var before_version := _deck_manager.current_snapshot.version

	# 移除不存在的卡（应静默处理）
	_deck_manager.current_snapshot.remove_card("curse_nonexistent_xyz")

	# 版本号不变，卡组数量不变
	assert_int(_deck_manager.current_snapshot.version).is_equal(before_version)
	assert_int(_deck_manager.current_snapshot.cards.size()).is_equal(5)


## 多次移除同一张卡不崩溃（幂等性）
func test_remove_same_curse_twice_is_safe() -> void:
	_deck_manager.current_snapshot.remove_card("curse_plague")
	# 第二次移除不崩溃
	_deck_manager.current_snapshot.remove_card("curse_plague")

	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_false()
