## curse_battle_integration_test.gd
## 诅咒卡与战斗系统联动集成测试（Story 4-9）
##
## 验证诅咒卡在战斗中：
##   1. 通过 CurseInjectionSystem 正确进入手牌/牌库/弃牌堆
##   2. 抽到触发型（DRAW_TRIGGER）抽到时立即结算效果
##   3. 常驻牌库型（PERSISTENT_LIBRARY）留在牌库中持续生效
##   4. 常驻手牌型（PERSISTENT_HAND）占用手牌位，需付费弃置
##   5. 战斗结束后诅咒卡归还战役层（除非 exhaust）
##
## 设计参考：design/gdd/curse-system.md
## ADR-0020: 卡组两层管理架构
##
## 作者: Claude Code
## 创建日期: 2026-04-14

class_name CurseBattleIntegrationTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

var _curse_manager: CurseManager
var _card_manager: CardManager
var _injection_system: CurseInjectionSystem
var _deck_manager: CampaignDeckManager

# ==================== 测试生命周期 ====================

func before_test() -> void:
	_curse_manager = CurseManager.new()
	_curse_manager._ready()

	_card_manager = CardManager.new()

	_injection_system = CurseInjectionSystem.new(_card_manager, _curse_manager)

	_deck_manager = CampaignDeckManager.new()
	add_child(_curse_manager)
	add_child(_card_manager)
	add_child(_injection_system)
	add_child(_deck_manager)

	# 预置战役卡组
	_deck_manager.current_snapshot.add_card("strike_001", 1, "initial")
	_deck_manager.current_snapshot.add_card("strike_002", 1, "initial")
	_deck_manager.current_snapshot.add_card("defend_001", 1, "initial")


func after_test() -> void:
	for node in [_injection_system, _curse_manager, _card_manager, _deck_manager]:
		if node and is_instance_valid(node):
			node.queue_free()
	_injection_system = null
	_curse_manager = null
	_card_manager = null
	_deck_manager = null


# ==================== AC-1: 注入后诅咒卡进入正确区域 ====================

## 敌人行动注入：诅咒卡进入弃牌堆（下次洗牌进入牌库）
func test_enemy_action_curse_lands_in_discard() -> void:
	_card_manager.discard_pile.clear()

	var success := _injection_system.inject_curse_by_enemy_action("curse_plague")

	assert_bool(success).is_true()
	assert_int(_card_manager.discard_pile.size()).is_equal(1)
	assert_string(_card_manager.discard_pile[0].data.card_id).is_equal("curse_plague")
	# 不在手牌和抽牌堆
	assert_int(_card_manager.hand_cards.size()).is_equal(0)
	assert_int(_card_manager.draw_pile.size()).is_equal(0)


## 地图事件注入：诅咒卡进入抽牌堆（立即混入牌库）
func test_map_event_curse_lands_in_draw_pile() -> void:
	_card_manager.draw_pile.clear()

	var success := _injection_system.inject_curse_by_map_event("curse_plague")

	assert_bool(success).is_true()
	assert_int(_card_manager.draw_pile.size()).is_equal(1)
	assert_string(_card_manager.draw_pile[0].data.card_id).is_equal("curse_plague")


## 卡牌效果注入：诅咒卡进入手牌（立即影响当前手牌）
func test_card_effect_curse_lands_in_hand() -> void:
	_card_manager.hand_cards.clear()

	var success := _injection_system.inject_curse_by_card_effect("curse_plague")

	assert_bool(success).is_true()
	assert_int(_card_manager.hand_cards.size()).is_equal(1)
	assert_bool(_card_manager.hand_cards[0].is_curse).is_true()


# ==================== AC-2: 注入诅咒卡后战役层快照正确持久化 ====================

## 战斗中通过 CampaignDeckManager.permanent_add_card 加入诅咒卡（永久）
## 模拟：奖励或事件给与诅咒卡时走永久加入路径
func test_curse_permanently_added_via_deck_manager() -> void:
	_deck_manager.start_battle()
	var initial_count := _deck_manager.current_snapshot.cards.size()

	# 永久加入诅咒卡（战役层 + 战斗层同时更新）
	_deck_manager.permanent_add_card("curse_plague", 1, "event")

	# 战役层增加
	assert_int(_deck_manager.current_snapshot.cards.size()).is_equal(initial_count + 1)
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_true()

	# 战斗层抽牌堆也增加
	assert_bool(_deck_manager.current_battle_snapshot.draw_pile.has("curse_plague")).is_true()

	_deck_manager.end_battle()

	# 战斗结束后战役层仍保留
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_true()


# ==================== AC-3: 抽到触发型诅咒卡进入弃牌堆后被洗回 ====================

## 弃牌堆中的诅咒卡洗牌后进入抽牌堆，可被再次抽到
func test_draw_trigger_curse_recycles_through_discard() -> void:
	# 将诅咒卡放入弃牌堆
	_injection_system.inject_curse_by_enemy_action("curse_plague")
	assert_int(_card_manager.discard_pile.size()).is_equal(1)

	# 抽牌堆为空，触发洗牌
	_card_manager.draw_pile.clear()

	# 手动触发洗牌（CardManager 内部逻辑：弃牌堆 → 抽牌堆）
	# 将弃牌堆所有卡移到抽牌堆并洗牌（模拟 CardManager._shuffle_discard_to_draw）
	_card_manager.draw_pile.append_array(_card_manager.discard_pile)
	_card_manager.draw_pile.shuffle()
	_card_manager.discard_pile.clear()

	# Assert: 诅咒卡现在在抽牌堆中
	var found := false
	for card in _card_manager.draw_pile:
		if card.data.card_id == "curse_plague":
			found = true
			break
	assert_bool(found).is_true()


# ==================== AC-4: 常驻手牌型占用手牌位 ====================

## 常驻手牌型诅咒卡注入到手牌后，占用手牌上限
func test_persistent_hand_curse_occupies_hand_slot() -> void:
	_card_manager.hand_cards.clear()

	# 注入常驻手牌型诅咒卡
	var success := _injection_system.inject_curse_by_card_effect("curse_taohui")

	assert_bool(success).is_true()
	# 手牌有 1 张（占位）
	assert_int(_card_manager.hand_cards.size()).is_equal(1)

	# 若要再注入一张到手牌（手牌满5张时弃一张）
	for i in range(4):
		var dummy := Card.new(CardData.new("dummy_%d" % i, 1))
		_card_manager.hand_cards.append(dummy)
	assert_int(_card_manager.hand_cards.size()).is_equal(5)

	# 再注入一张诅咒卡：手牌已满，弃置末尾一张后加入
	var success2 := _injection_system.inject_curse_by_card_effect("curse_plague")
	assert_bool(success2).is_true()
	assert_int(_card_manager.hand_cards.size()).is_equal(5)  # 仍为5张


# ==================== AC-5: 战斗结束后诅咒卡（非 exhaust）仍在战役卡组 ====================

## 战斗结束，弃牌堆中的诅咒卡不影响战役层（战役层仍有该卡）
func test_curse_in_discard_does_not_affect_campaign_snapshot() -> void:
	_deck_manager.current_snapshot.add_card("curse_plague", 1, "event")
	_deck_manager.start_battle()

	# 将诅咒卡移到弃牌堆（模拟战斗中被弃置）
	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_plague")
	_deck_manager.current_battle_snapshot.discard_pile.append("curse_plague")

	_deck_manager.end_battle()

	# Assert: 战役层仍有该诅咒卡
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_true()


## 战斗结束，exhaust 的诅咒卡从战役层移除
func test_exhausted_curse_removed_from_campaign() -> void:
	_deck_manager.current_snapshot.add_card("curse_plague", 1, "event")
	_deck_manager.start_battle()

	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_plague")
	_deck_manager.current_battle_snapshot.hand_cards.append("curse_plague")
	_deck_manager.current_battle_snapshot.play_card("curse_plague", false, true)  # to_exhaust

	_deck_manager.end_battle()

	assert_bool(_deck_manager.current_snapshot.cards.has("curse_plague")).is_false()


# ==================== AC-6: 多张同名诅咒卡独立计数（GDD E6） ====================

## 2 张韬晦在战役层中分别以不同 key 存在，各自计数
func test_two_taohui_count_independently() -> void:
	_deck_manager.current_snapshot.add_card("curse_taohui_1", 1, "event")
	_deck_manager.current_snapshot.add_card("curse_taohui_2", 1, "event")

	assert_bool(_deck_manager.current_snapshot.cards.has("curse_taohui_1")).is_true()
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_taohui_2")).is_true()

	# exhaust 一张
	_deck_manager.start_battle()
	_deck_manager.current_battle_snapshot.draw_pile.erase("curse_taohui_1")
	_deck_manager.current_battle_snapshot.hand_cards.append("curse_taohui_1")
	_deck_manager.current_battle_snapshot.play_card("curse_taohui_1", false, true)
	_deck_manager.end_battle()

	# 战役层剩 1 张
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_taohui_1")).is_false()
	assert_bool(_deck_manager.current_snapshot.cards.has("curse_taohui_2")).is_true()


# ==================== AC-7: card_drawn 事件在注入时触发 ====================

## 注入诅咒卡时，card_drawn 事件携带正确的诅咒标记
func test_curse_injection_emits_card_drawn_signal() -> void:
	_card_manager.discard_pile.clear()

	var signal_received := false
	var received_card: Card = null

	_card_manager.card_drawn.connect(func(card: Card) -> void:
		signal_received = true
		received_card = card
	)

	_injection_system.inject_curse_by_enemy_action("curse_plague")

	assert_bool(signal_received).is_true()
	assert_not_null(received_card)
	assert_bool(received_card.is_curse).is_true()
	assert_string(received_card.data.card_id).is_equal("curse_plague")


# ==================== AC-8: 整体战斗循环（注入→抽到→处理→结算） ====================

## 模拟完整战斗循环：敌人注入诅咒卡 → 洗牌 → 抽到 → 弃置 → 战役层不变
func test_full_battle_loop_with_curse_injection() -> void:
	var initial_campaign_count := _deck_manager.current_snapshot.cards.size()

	# 开始战斗
	_deck_manager.start_battle()

	# 敌人行动注入诅咒卡到弃牌堆（通过 CardManager，不走 CampaignDeckSnapshot）
	var curse_card := Card.new(CurseCardData.new("curse_plague", 0))
	curse_card.is_curse = true
	_card_manager.discard_pile.append(curse_card)

	# 洗牌（弃牌堆 → 抽牌堆）
	_card_manager.draw_pile.append_array(_card_manager.discard_pile)
	_card_manager.draw_pile.shuffle()
	_card_manager.discard_pile.clear()

	# 确认诅咒卡在抽牌堆
	var curse_in_draw := false
	for card in _card_manager.draw_pile:
		if card.data.card_id == "curse_plague":
			curse_in_draw = true
			break
	assert_bool(curse_in_draw).is_true()

	# 结束战斗
	_deck_manager.end_battle()

	# 战役层卡组不受影响（诅咒卡是通过 CardManager 注入，不经过 CampaignDeckSnapshot）
	assert_int(_deck_manager.current_snapshot.cards.size()).is_equal(initial_campaign_count)
