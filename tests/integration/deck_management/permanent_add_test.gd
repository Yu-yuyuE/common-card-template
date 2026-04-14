# === permanent_add_test.gd ===
#
# Integration test for "永久加入卡组" mechanism
# Verifies that cards added permanently persist across battles
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 004: 永久加入卡组机制
#
# Using GdUnit4 testing framework
#

extends "res://tests/gdunit4.gd"

# Import the classes being tested
var CampaignDeckManager = preload("res://src/core/deck-management/CampaignDeckManager.gd")


## Test Setup

func setup():
	# Create a new instance for each test
	global manager = CampaignDeckManager.new()


## Test: Permanent add outside battle
func test_permanent_add_outside_battle():
	manager.initialize_campaign("hero_001")
	var initial_card_count = manager.current_snapshot.cards.size()

	# Add permanent card outside battle
	manager.permanent_add_card("permanent_card_001", 1, "shop")

	# Verify card in campaign
	assert_true(manager.current_snapshot.cards.has("permanent_card_001"), "Card should be in campaign")
	assert_equal(manager.current_snapshot.cards.size(), initial_card_count + 1, "Campaign should have one more card")

	# Verify card persists across battles
	manager.start_battle()
	assert_true(manager.current_battle_snapshot.draw_pile.has("permanent_card_001") or
	            manager.current_battle_snapshot.hand_cards.has("permanent_card_001") or
	            manager.current_battle_snapshot.discard_pile.has("permanent_card_001"),
	            "Permanent card should be in battle deck")
	manager.end_battle()

	# Verify card still in campaign after battle
	assert_true(manager.current_snapshot.cards.has("permanent_card_001"), "Permanent card should persist after battle")


## Test: Permanent add during battle
func test_permanent_add_during_battle():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	var initial_campaign_count = manager.current_snapshot.cards.size()
	var initial_battle_count = manager.current_battle_snapshot.get_total_card_count()

	# Add permanent card during battle
	manager.permanent_add_card("permanent_card_002", 1, "event")

	# Verify card added to campaign
	assert_true(manager.current_snapshot.cards.has("permanent_card_002"), "Card should be in campaign")
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count + 1, "Campaign should have one more card")

	# Verify card added to battle
	assert_true(manager.current_battle_snapshot.draw_pile.has("permanent_card_002"), "Card should be in battle draw pile")
	assert_equal(manager.current_battle_snapshot.get_total_card_count(), initial_battle_count + 1, "Battle should have one more card")

	# End battle
	manager.end_battle()

	# Verify card persists in campaign after battle ends
	assert_true(manager.current_snapshot.cards.has("permanent_card_002"), "Permanent card should persist after battle")


## Test: Permanent add with level 2
func test_permanent_add_level_2():
	manager.initialize_campaign("hero_001")

	# Add permanent card with level 2
	manager.permanent_add_card("permanent_card_003", 2, "reward")

	# Verify card level
	assert_equal(manager.current_snapshot.cards["permanent_card_003"]["level"], 2, "Card level should be 2")

	# Verify card persists across battles
	manager.start_battle()
	manager.end_battle()

	assert_true(manager.current_snapshot.cards.has("permanent_card_003"), "Level 2 permanent card should persist")
	assert_equal(manager.current_snapshot.cards["permanent_card_003"]["level"], 2, "Card level should remain 2")


## Test: Multiple permanent additions
func test_multiple_permanent_additions():
	manager.initialize_campaign("hero_001")

	# Add multiple permanent cards
	manager.permanent_add_card("perm_001", 1, "shop")
	manager.permanent_add_card("perm_002", 1, "event")
	manager.permanent_add_card("perm_003", 2, "reward")

	# Verify all cards in campaign
	assert_true(manager.current_snapshot.cards.has("perm_001"))
	assert_true(manager.current_snapshot.cards.has("perm_002"))
	assert_true(manager.current_snapshot.cards.has("perm_003"))

	# Start battle, end battle, verify all persist
	manager.start_battle()
	manager.end_battle()

	assert_true(manager.current_snapshot.cards.has("perm_001"))
	assert_true(manager.current_snapshot.cards.has("perm_002"))
	assert_true(manager.current_snapshot.cards.has("perm_003"))


## Test: Permanent add then exhaust
func test_permanent_add_then_exhaust():
	manager.initialize_campaign("hero_001")

	# Add permanent card
	manager.permanent_add_card("perm_card_001", 1, "shop")
	assert_true(manager.current_snapshot.cards.has("perm_card_001"))

	# Exhaust the card
	manager.exhaust_card("perm_card_001")
	assert_false(manager.current_snapshot.cards.has("perm_card_001"), "Exhausted permanent card should be removed")


## Test: Permanent add during battle then play
func test_permanent_add_during_battle_then_play():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	# Add permanent card during battle
	manager.permanent_add_card("perm_card_002", 1, "event")
	assert_true(manager.current_battle_snapshot.draw_pile.has("perm_card_002"))

	# Draw and play the card
	manager.current_battle_snapshot.draw_cards(manager.current_battle_snapshot.draw_pile.size())  # Draw all cards
	var card_in_hand = manager.current_battle_snapshot.hand_cards.find("perm_card_002")
	if card_in_hand >= 0:
		manager.current_battle_snapshot.play_card("perm_card_002")

	# End battle
	manager.end_battle()

	# Verify permanent card persists even though it was played
	assert_true(manager.current_snapshot.cards.has("perm_card_002"), "Permanent card should persist even after being played")


## Test: Event scenario - receive reward card
func test_event_scenario_receive_reward():
	manager.initialize_campaign("hero_001")

	# Simulate event giving a permanent card
	manager.permanent_add_card("reward_card_001", 1, "reward")

	# Verify card source
	assert_equal(manager.current_snapshot.cards["reward_card_001"]["source"], "reward", "Card source should be 'reward'")

	# Verify persistence
	manager.start_battle()
	manager.end_battle()

	assert_true(manager.current_snapshot.cards.has("reward_card_001"), "Event reward should persist")


## Test: Shop scenario - purchase card
func test_shop_scenario_purchase():
	manager.initialize_campaign("hero_001")

	# Simulate shop purchase
	manager.permanent_add_card("shop_card_001", 1, "shop")

	# Verify card source
	assert_equal(manager.current_snapshot.cards["shop_card_001"]["source"], "shop", "Card source should be 'shop'")

	# Verify persistence
	manager.start_battle()
	manager.end_battle()

	assert_true(manager.current_snapshot.cards.has("shop_card_001"), "Shop purchase should persist")