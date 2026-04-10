extends GdUnitTestSuite

# AC-1: 费用不足拦截
# AC-2: 正常出牌及弃牌流转
# AC-3: 移除/消耗卡流转

func _create_card(id: String, cost: int, remove: bool = false, exhaust: bool = false) -> Card:
	return Card.new(CardData.new(id, cost, remove, exhaust))

func test_ac1_insufficient_cost_intercept() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 4)
	
	bm.setup_battle({"enemies": []}, rm)
	# 此时已经是 PLAYER_PLAY 阶段，AP=4
	
	# 将 AP 降至 2
	bm.player_entity.action_points = 2
	
	# 加入一张 Cost=3 的手牌
	var card = _create_card("heavy_attack", 3)
	bm.card_manager.hand_cards.append(card)
	
	# Act: 尝试打出
	var success = bm.play_card("heavy_attack", 0)
	
	# Assert: 打出失败，手牌还在，AP还是2
	assert_bool(success).is_false()
	assert_int(bm.card_manager.hand_cards.size()).is_equal(1)
	assert_int(bm.player_entity.action_points).is_equal(2)

func test_ac2_normal_play_and_discard() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 4)
	bm.setup_battle({"enemies": []}, rm) # AP=4
	
	var card = _create_card("normal_attack", 1)
	bm.card_manager.hand_cards.append(card)
	
	var played_signal_emitted = false
	bm.card_played.connect(func(cid, tpos):
		if cid == "normal_attack" and tpos == 1:
			played_signal_emitted = true
	)
	
	# Act
	var success = bm.play_card("normal_attack", 1)
	
	# Assert
	assert_bool(success).is_true()
	assert_int(bm.player_entity.action_points).is_equal(3) # 4 - 1
	assert_int(bm.card_manager.hand_cards.size()).is_equal(0)
	assert_int(bm.card_manager.discard_pile.size()).is_equal(1)
	assert_str(bm.card_manager.discard_pile[0].get_id()).is_equal("normal_attack")
	assert_bool(played_signal_emitted).is_true()

func test_ac3_remove_and_exhaust_cards() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 10)
	bm.setup_battle({"enemies": []}, rm) # AP=10
	
	var card_remove = _create_card("remove_skill", 1, true, false)
	var card_exhaust = _create_card("exhaust_attack", 2, false, true)
	
	bm.card_manager.hand_cards.append(card_remove)
	bm.card_manager.hand_cards.append(card_exhaust)
	
	# Act 1: 打出带 remove 的卡
	var ok1 = bm.play_card("remove_skill", 0)
	assert_bool(ok1).is_true()
	assert_int(bm.card_manager.removed_cards.size()).is_equal(1)
	assert_str(bm.card_manager.removed_cards[0].get_id()).is_equal("remove_skill")
	
	# Act 2: 打出带 exhaust 的卡
	var ok2 = bm.play_card("exhaust_attack", 0)
	assert_bool(ok2).is_true()
	assert_int(bm.card_manager.exhaust_cards.size()).is_equal(1)
	assert_str(bm.card_manager.exhaust_cards[0].get_id()).is_equal("exhaust_attack")
	
	# 手牌和弃牌堆应该是空的
	assert_int(bm.card_manager.hand_cards.size()).is_equal(0)
	assert_int(bm.card_manager.discard_pile.size()).is_equal(0)
