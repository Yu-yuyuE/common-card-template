extends GdUnitTestSuite

# AC-1: 补满手牌上限
# AC-2: 弃牌堆洗回
# AC-3: 牌库耗尽保护
# AC-4: 袁绍上限特权

func _create_card_data(n: int) -> Array[CardData]:
	var arr: Array[CardData] = []
	for i in range(n):
		arr.append(CardData.new("card_%d" % i))
	return arr

func test_ac1_fill_hand_to_limit() -> void:
	var bm = BattleManager.new()
	bm.player_entity = BattleEntity.new("player", true)
	var cm = CardManager.new(bm)
	
	cm.initialize_deck(_create_card_data(10)) # 10张抽牌堆
	cm.hand_cards.append(Card.new(CardData.new("dummy1")))
	cm.hand_cards.append(Card.new(CardData.new("dummy2")))
	# 初始2手牌，8抽牌堆（因为 dummy 没有从抽牌堆拿，仅仅测试补充逻辑）
	
	cm.fill_hand_to_limit() # 应该抽3张
	
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.draw_pile.size()).is_equal(7) # 10 - 3

func test_ac2_shuffle_discard_pile_back() -> void:
	var bm = BattleManager.new()
	bm.player_entity = BattleEntity.new("player", true)
	var cm = CardManager.new(bm)
	
	cm.initialize_deck(_create_card_data(0))
	cm.draw_pile.append(Card.new(CardData.new("draw1")))
	cm.draw_pile.append(Card.new(CardData.new("draw2")))
	
	for i in range(5):
		cm.discard_pile.append(Card.new(CardData.new("discard_%d" % i)))
		
	# draw_pile: 2, discard_pile: 5
	cm.draw_cards(5)
	
	# 先抽了 2 张，导致 discard (5张) 洗牌进 draw_pile。然后再抽 3 张。
	# 最终：手牌 5 张，draw_pile 2 张，discard_pile 0 张。
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.draw_pile.size()).is_equal(2)
	assert_int(cm.discard_pile.size()).is_equal(0)

func test_ac3_empty_deck_protection() -> void:
	var bm = BattleManager.new()
	bm.player_entity = BattleEntity.new("player", true)
	var cm = CardManager.new(bm)
	
	cm.initialize_deck(_create_card_data(1)) # 仅1张牌
	cm.draw_cards(5)
	
	# 抽出1张后停止
	assert_int(cm.hand_cards.size()).is_equal(1)
	assert_int(cm.draw_pile.size()).is_equal(0)
	assert_int(cm.discard_pile.size()).is_equal(0)

func test_ac4_yuan_shao_limit_buff() -> void:
	var bm = BattleManager.new()
	bm.player_entity = BattleEntity.new("yuan_shao", true)
	var cm = CardManager.new(bm)
	
	assert_int(cm.get_hand_limit()).is_equal(6)

func test_ac5_hand_full_discard() -> void:
	var bm = BattleManager.new()
	bm.player_entity = BattleEntity.new("player", true)
	var cm = CardManager.new(bm)
	
	cm.initialize_deck(_create_card_data(5))
	
	# 强行塞满 5 张手牌
	for i in range(5):
		cm.hand_cards.append(Card.new(CardData.new("dummy_%d" % i)))
		
	# 再强抽 1 张（因为卡牌效果之类）
	cm.draw_cards(1)
	
	# 手牌维持 5 张，溢出的那 1 张进了弃牌堆
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.discard_pile.size()).is_equal(1)
