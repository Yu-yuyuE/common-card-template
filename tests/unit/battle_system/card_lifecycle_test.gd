extends GdUnitTestSuite

# 测试覆盖：Story 5-3 卡牌生命周期与抽牌堆管理
# AC-1: 五分区初始化
# AC-2: 补牌到上限（DrawCount = max(0, HandLimit - CurrentHandSize)）
# AC-3: 袁绍手牌上限返回 6
# AC-4: 抽牌堆为空时洗牌回补
# AC-5: 双堆皆空时安全跳过
# AC-6: 手牌溢出弃置（force_add_card 路径）

# ---------------------------------------------------------------------------
# 测试辅助工厂
# ---------------------------------------------------------------------------

func _create_card_data(n: int) -> Array[CardData]:
	var arr: Array[CardData] = []
	for i in range(n):
		arr.append(CardData.new("card_%d" % i))
	return arr

func _make_card_manager(hero_id: String = "player") -> CardManager:
	var bm := BattleManager.new()
	bm.player_entity = BattleEntity.new(hero_id, true)
	return CardManager.new(bm)

# ---------------------------------------------------------------------------
# AC-1: 五分区初始化
# ---------------------------------------------------------------------------

func test_ac1_five_zones_initialized_as_empty_arrays() -> void:
	# Arrange
	var cm := _make_card_manager()
	# Act
	cm.initialize_deck(_create_card_data(0))
	# Assert: 五分区均为非 null 的 Array
	assert_that(cm.draw_pile).is_not_null()
	assert_that(cm.hand_cards).is_not_null()
	assert_that(cm.discard_pile).is_not_null()
	assert_that(cm.removed_cards).is_not_null()
	assert_that(cm.exhaust_cards).is_not_null()
	# 初始化后全部为空
	assert_int(cm.draw_pile.size()).is_equal(0)
	assert_int(cm.hand_cards.size()).is_equal(0)
	assert_int(cm.discard_pile.size()).is_equal(0)
	assert_int(cm.removed_cards.size()).is_equal(0)
	assert_int(cm.exhaust_cards.size()).is_equal(0)

# ---------------------------------------------------------------------------
# AC-2: 补牌到上限（fill_hand_to_limit）
# ---------------------------------------------------------------------------

func test_ac1_fill_hand_to_limit() -> void:
	# Arrange: 非袁绍武将，上限 5；手牌 2 张，抽牌堆 10 张
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(10))
	cm.hand_cards.append(Card.new(CardData.new("dummy1")))
	cm.hand_cards.append(Card.new(CardData.new("dummy2")))
	# Act
	cm.fill_hand_to_limit() # 应抽 3 张
	# Assert
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.draw_pile.size()).is_equal(7) # 10 - 3

func test_ac2_draw_count_formula_exact() -> void:
	# Arrange: 手牌 3 张，上限 5，抽牌堆 10 张 → DrawCount = max(0, 5-3) = 2
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(10))
	for i in range(3):
		cm.hand_cards.append(Card.new(CardData.new("h_%d" % i)))
	# Act
	cm.fill_hand_to_limit()
	# Assert
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.draw_pile.size()).is_equal(8) # 10 - 2

# ---------------------------------------------------------------------------
# AC-3: 袁绍手牌上限
# ---------------------------------------------------------------------------

func test_ac4_yuan_shao_limit_buff() -> void:
	# Arrange
	var cm := _make_card_manager("yuan_shao")
	# Assert
	assert_int(cm.get_hand_limit()).is_equal(6)

func test_ac3_default_hero_limit_is_five() -> void:
	# Arrange: 任意非袁绍武将
	var cm := _make_card_manager("cao_cao")
	# Assert
	assert_int(cm.get_hand_limit()).is_equal(5)

# ---------------------------------------------------------------------------
# AC-4: 抽牌堆为空时洗牌回补
# ---------------------------------------------------------------------------

func test_ac2_shuffle_discard_pile_back() -> void:
	# Arrange: 手牌 0，抽牌堆 2，弃牌堆 5
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(0))
	cm.draw_pile.append(Card.new(CardData.new("draw1")))
	cm.draw_pile.append(Card.new(CardData.new("draw2")))
	for i in range(5):
		cm.discard_pile.append(Card.new(CardData.new("discard_%d" % i)))
	# Act: 试图抽 5 张
	cm.draw_cards(5)
	# Assert: 先抽 2 张，洗牌，再抽 3 张 → 手牌 5，draw 2，discard 0
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.draw_pile.size()).is_equal(2)
	assert_int(cm.discard_pile.size()).is_equal(0)

func test_ac4_discard_shuffled_into_draw_when_draw_empty() -> void:
	# Arrange: 更简洁的中途触发洗牌验证
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(0))
	cm.draw_pile.append(Card.new(CardData.new("a")))
	for i in range(3):
		cm.discard_pile.append(Card.new(CardData.new("b_%d" % i)))
	# Act: 抽 4 张 → 先抽 1 张（draw 空），洗 3 张进 draw，再抽 3 张
	cm.draw_cards(4)
	# Assert
	assert_int(cm.hand_cards.size()).is_equal(4)
	assert_int(cm.discard_pile.size()).is_equal(0)

# ---------------------------------------------------------------------------
# AC-5: 双堆皆空时安全跳过
# ---------------------------------------------------------------------------

func test_ac3_empty_deck_protection() -> void:
	# Arrange: 仅 1 张牌，draw 和 discard 实际会全空
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(1))
	# Act
	cm.draw_cards(5)
	# Assert: 抽出 1 张后安全停止
	assert_int(cm.hand_cards.size()).is_equal(1)
	assert_int(cm.draw_pile.size()).is_equal(0)
	assert_int(cm.discard_pile.size()).is_equal(0)

func test_ac5_both_piles_empty_no_crash() -> void:
	# Arrange: 完全空的管理器
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(0))
	# Act: 不应抛出异常
	cm.draw_cards(5)
	# Assert
	assert_int(cm.hand_cards.size()).is_equal(0)

# ---------------------------------------------------------------------------
# AC-6: 手牌溢出弃置（force_add_card 路径）
# ---------------------------------------------------------------------------

func test_ac5_hand_full_discard_via_draw() -> void:
	# Arrange: draw_cards 路径中触发溢出
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(5))
	for i in range(5):
		cm.hand_cards.append(Card.new(CardData.new("dummy_%d" % i)))
	# Act: 再强抽 1 张
	cm.draw_cards(1)
	# Assert
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.discard_pile.size()).is_equal(1)

func test_ac6_force_add_card_overflow_to_discard() -> void:
	# Arrange: 手牌已满 5 张
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(0))
	for i in range(5):
		cm.hand_cards.append(Card.new(CardData.new("h_%d" % i)))
	var overflow_card := Card.new(CardData.new("overflow_a"))
	var overflow_card2 := Card.new(CardData.new("overflow_b"))
	# Act: 强制追加 2 张（模拟被动效果）
	cm.force_add_card(overflow_card)
	cm.force_add_card(overflow_card2)
	# Assert: 手牌维持上限，溢出 2 张进弃牌堆，总牌数守恒
	assert_int(cm.hand_cards.size()).is_equal(5)
	assert_int(cm.discard_pile.size()).is_equal(2)

func test_ac6_force_add_card_below_limit_no_overflow() -> void:
	# Arrange: 手牌 3 张，上限 5
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(0))
	for i in range(3):
		cm.hand_cards.append(Card.new(CardData.new("h_%d" % i)))
	var new_card := Card.new(CardData.new("bonus"))
	# Act
	cm.force_add_card(new_card)
	# Assert: 正常进手牌，无溢出
	assert_int(cm.hand_cards.size()).is_equal(4)
	assert_int(cm.discard_pile.size()).is_equal(0)

# ---------------------------------------------------------------------------
# 附加：return_removed_cards_to_deck（胜利结算路径）
# ---------------------------------------------------------------------------

func test_return_removed_cards_to_deck_after_victory() -> void:
	# Arrange
	var cm := _make_card_manager()
	cm.initialize_deck(_create_card_data(2))
	cm.removed_cards.append(Card.new(CardData.new("removed_1")))
	cm.removed_cards.append(Card.new(CardData.new("removed_2")))
	var initial_draw_size := cm.draw_pile.size() # 2
	# Act
	cm.return_removed_cards_to_deck()
	# Assert: 移除区清空，抽牌堆增加 2 张
	assert_int(cm.removed_cards.size()).is_equal(0)
	assert_int(cm.draw_pile.size()).is_equal(initial_draw_size + 2)
