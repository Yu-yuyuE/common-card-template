# === enemy_steal_test.gd ===
#
# Integration test for "敌人偷取卡牌" mechanism
# Verifies that stolen cards are not returned to campaign and don't affect battle deck permanently
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 006: 敌人偷取卡牌机制
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


## Test: Steal card during battle
func test_steal_card_during_battle():
	manager.initialize_campaign("hero_001")
	var initial_campaign_count = manager.current_snapshot.cards.size()

	# Start battle
	manager.start_battle()

	# Draw a card
	manager.current_battle_snapshot.draw_cards(1)
	var card_to_steal = manager.current_battle_snapshot.hand_cards[0]

	# Enemy steals card
	manager.current_battle_snapshot.steal_card(card_to_steal)

	# Verify card moved to stolen_cards
	assert_true(manager.current_battle_snapshot.stolen_cards.has(card_to_steal), "Stolen card should be in stolen_cards")
	assert_false(manager.current_battle_snapshot.hand_cards.has(card_to_steal), "Stolen card should be removed from hand")
	assert_false(manager.current_battle_snapshot.removed_cards.has(card_to_steal), "Stolen card should not be in removed_cards")

	# End battle
	manager.end_battle()

	# Verify campaign unchanged (card still there)
	assert_true(manager.current_snapshot.cards.has(card_to_steal), "Stolen card should still be in campaign")
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count, "Campaign card count should be unchanged")


## Test: Start new battle after steal
func test_start_new_battle_after_steal():
	manager.initialize_campaign("hero_001")

	# Start battle
	manager.start_battle()
	var card_to_steal = "card_001"

	# Enemy steals card
	manager.current_battle_snapshot.steal_card(card_to_steal)

	# End battle
	manager.end_battle()

	# Start new battle
	manager.start_battle()

	# Verify stolen card returns to draw pile (not stolen anymore in new battle)
	assert_true(manager.current_battle_snapshot.draw_pile.has(card_to_steal), "Stolen card should return in new battle")


## Test: Steal multiple cards
func test_steal_multiple_cards():
	manager.initialize_campaign("hero_001")

	# Start battle
	manager.start_battle()
	manager.current_battle_snapshot.draw_cards(3)

	# Enemy steals multiple cards
	for i in range(2):
		if manager.current_battle_snapshot.hand_cards.size() > 0:
			var card_to_steal = manager.current_battle_snapshot.hand_cards[0]
			manager.current_battle_snapshot.steal_card(card_to_steal)

	# Verify multiple cards stolen
	assert_equal(manager.current_battle_snapshot.stolen_cards.size(), 2, "Should have 2 stolen cards")

	# End battle
	manager.end_battle()

	# Verify campaign unchanged
	assert_equal(manager.current_snapshot.cards.size(), 3, "Campaign should still have all 3 cards")


## Test: Steal then permanently add
func test_steal_then_permanently_add():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	var card_to_steal = "card_001"

	# Enemy steals card
	manager.current_battle_snapshot.steal_card(card_to_steal)

	# Add new permanent card
	manager.permanent_add_card("new_card_001", 1, "event")

	// End battle
	manager.end_battle()

	// Verify stolen card still in campaign, new card added
	assert_true(manager.current_snapshot.cards.has(card_to_steal), "Stolen card should still be in campaign")
	assert_true(manager.current_snapshot.cards.has("new_card_001"), "New card should be in campaign")


## Test: Steal card from specific zones
func test_steal_card_from_specific_zones():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	// Draw cards
	manager.current_battle_snapshot.draw_cards(2)
	assert_equal(manager.current_battle_snapshot.hand_cards.size(), 2, "Should have 2 cards in hand")

	// Steal from hand
	manager.current_battle_snapshot.steal_card(manager.current_battle_snapshot.hand_cards[0])
	assert_equal(manager.current_battle_snapshot.hand_cards.size(), 1, "Should have 1 card left in hand")

	// End battle
	manager.end_battle()

	// Verify campaign unchanged
	assert_equal(manager.current_snapshot.cards.size(), 2, "Campaign should have all 2 cards")


## Test: Steal card with level 2
func test_steal_level_2_card():
	manager.initialize_campaign("hero_001")
	manager.permanent_add_card("card_001", 2, "reward")
	assert_equal(manager.current_snapshot.cards["card_001"]["level"], 2, "Should have level 2 card")

	// Start battle
	manager.start_battle()

	// Draw and steal the card
	manager.current_battle_snapshot.draw_cards(manager.current_battle_snapshot.draw_pile.size())
	manager.current_battle_snapshot.steal_card("card_001")

	// End battle
	manager.end_battle()

	// Verify level 2 card still in campaign
	assert_true(manager.current_snapshot.cards.has("card_001"), "Level 2 card should still be in campaign")
	assert_equal(manager.current_snapshot.cards["card_001"]["level"], 2, "Card level should still be 2")


## Test: Steal then exhaust in same battle
func test_steal_then_exhaust():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	// Draw cards
	manager.current_battle_snapshot.draw_cards(3)

	// Steal one card
	manager.current_battle_snapshot.steal_card(manager.current_battle_snapshot.hand_cards[0])

	// Exhaust another card
	manager.current_battle_snapshot.play_card(manager.current_battle_snapshot.hand_cards[0], to_exhaust=true)

	// End battle
	manager.end_battle()

	// Verify stolen card still in campaign, exhausted card removed
	var stolen_card = manager.current_battle_snapshot.stolen_cards[0]
	assert_true(manager.current_snapshot.cards.has(stolen_card), "Stolen card should still be in campaign")

	var exhausted_card = manager.current_battle_snapshot.exhaust_cards[0]
	assert_false(manager.current_snapshot.cards.has(exhausted_card), "Exhausted card should be removed")


## Test: Steal card with permanent add in same battle
func test_steal_with_permanent_add_same_battle():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	var card_to_steal = "card_001"

	// Steal card
	manager.current_battle_snapshot.steal_card(card_to_steal)

	// Add permanent card
	manager.permanent_add_card("permanent_card_001", 1, " event")

	// End battle
	manager.end_battle()

	// Verify stolen card in campaign, permanent card added
	assert_true(manager.current_snapshot.cards.has(card_to_steal), "Stolen card should be in campaign")
	assert_true(manager.current_snapshot.cards.has("permanent_card_001"), "Permanent card should be in campaign")


## Test: Enemy can query stolen cards
func test_enemy_can_query_stolen_cards():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	// Draw and steal cards
	manager.current_battle_snapshot.draw_cards(2)
	manager.current_battle_snapshot.steal_card(manager.current_battle_snapshot.hand_cards[0])

	// Enemy can query stolen cards
	var stolen_cards = manager.current_battle_snapshot.stolen_cards
	assert_equal(stolen_cards.size(), 1, "Enemy should be able to query stolen cards")

	// End battle - stolen_cards cleared automatically
	manager.end_battle()
	assert_null(manager.current_battle_snapshot, "Battle snapshot should be destroyed")


## Test: Stolen cards not in finalize_battle changes
func test_stolen_cards_not_in_finalize_changes():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	// Draw and steal card
	manager.current_battle_snapshot.draw_cards(1)
	manager.current_battle_snapshot.steal_card(manager.current_battle_snapshot.hand_cards[0])

	// Get final battle changes
	var changes = manager.current_battle_snapshot.finalize_battle()

	// Verify stolen cards not in changes
	assert_false(changes.has("stolen_cards"), "Stolen cards should not be in finalize changes")
	assert_true(changes.has("exhaust_cards"), "Should have exhaust_cards key")
	assert_equal(changes["exhaust_cards"].size(), 0, "No exhaust_cards expected")