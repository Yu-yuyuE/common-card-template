# === battle_cycle_test.gd ===
#
# Integration test for the complete battle cycle
# Verifies the interaction between CampaignDeckManager, CampaignDeckSnapshot, and BattleDeckSnapshot
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 003: 卡组管理器集成
#
# Using GdUnit4 testing framework
#

extends "res://tests/gdunit4.gd"

# Import the classes being tested
var CampaignDeckManager = preload("res://src/core/deck-management/CampaignDeckManager.gd")
var CampaignDeckSnapshot = preload("res://src/core/deck-management/CampaignDeckSnapshot.gd")
var BattleDeckSnapshot = preload("res://src/core/deck-management/BattleDeckSnapshot.gd")


## Test Setup

func setup():
	# Create a new instance for each test
	global manager = CampaignDeckManager.new()
	global campaign_snapshot = CampaignDeckSnapshot.new()
	global battle_snapshot = BattleDeckSnapshot.new()

	# Initialize with test cards
	campaign_snapshot.add_card("card_001", 1, "initial")
	campaign_snapshot.add_card("card_002", 1, "shop")
	campaign_snapshot.add_card("card_003", 2, "reward")


## Test: Full battle cycle with card exhaustion
func test_full_battle_cycle_exhaust():
	# Initialize campaign
	manager.initialize_campaign("hero_001")
	var initial_campaign_cards = manager.get_campaign_cards().keys()
	var initial_campaign_count = manager.current_snapshot.cards.size()

	# Start battle
	manager.start_battle()
	assert_not_null(manager.current_battle_snapshot, "Battle snapshot should be created")

	# Draw cards
	var drawn = manager.current_battle_snapshot.draw_cards(3)
	assert_equal(drawn.size(), 3, "Should draw 3 cards")

	# Play one card to exhaust
	var card_to_exhaust = drawn[0]
	manager.current_battle_snapshot.play_card(card_to_exhaust, to_exhaust=true)

	# End battle
	manager.end_battle()

	# Verify battle snapshot destroyed
	assert_null(manager.current_battle_snapshot, "Battle snapshot should be destroyed")

	# Verify exhausted card removed from campaign
	assert_false(manager.current_snapshot.cards.has(card_to_exhaust), "Exhausted card should be removed from campaign")

	# Verify other cards still in campaign
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count - 1, "Campaign should have one less card")


## Test: Full battle cycle with permanent addition
func test_full_battle_cycle_permanent_add():
	# Initialize campaign
	manager.initialize_campaign("hero_001")
	var initial_campaign_cards = manager.get_campaign_cards().keys()
	var initial_campaign_count = manager.current_snapshot.cards.size()

	# Start battle
	manager.start_battle()
	assert_not_null(manager.current_battle_snapshot, "Battle snapshot should be created")

	# Draw cards
	var drawn = manager.current_battle_snapshot.draw_cards(3)
	assert_equal(drawn.size(), 3, "Should draw 3 cards")

	# Permanently add a card during battle
	manager.permanent_add_card("permanent_card_001", 1, "event")

	# Verify card added to both snapshots
	assert_true(manager.current_snapshot.cards.has("permanent_card_001"), "Permanent card should be in campaign")
	assert_true(manager.current_battle_snapshot.draw_pile.has("permanent_card_001"), "Permanent card should be in battle")

	# End battle
	manager.end_battle()

	# Verify battle snapshot destroyed
	assert_null(manager.current_battle_snapshot, "Battle snapshot should be destroyed")

	# Verify permanent card remains in campaign
	assert_true(manager.current_snapshot.cards.has("permanent_card_001"), "Permanent card should remain in campaign")
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count + 1, "Campaign should have one more card")


## Test: Full battle cycle with enemy stealing
func test_full_battle_cycle_steal():
	# Initialize campaign
	manager.initialize_campaign("hero_001")
	var initial_campaign_cards = manager.get_campaign_cards().keys()
	var initial_campaign_count = manager.current_snapshot.cards.size()

	# Start battle
	manager.start_battle()
	assert_not_null(manager.current_battle_snapshot, "Battle snapshot should be created")

	# Draw cards
	var drawn = manager.current_battle_snapshot.draw_cards(3)
	assert_equal(drawn.size(), 3, "Should draw 3 cards")

	# Enemy steals a card
	var card_to_steal = drawn[0]
	manager.current_battle_snapshot.steal_card(card_to_steal)

	# Verify card moved to stolen_cards
	assert_true(manager.current_battle_snapshot.stolen_cards.has(card_to_steal), "Card should be in stolen_cards")
	assert_false(manager.current_battle_snapshot.hand_cards.has(card_to_steal), "Card should be removed from hand")

	# End battle
	manager.end_battle()

	# Verify battle snapshot destroyed
	assert_null(manager.current_battle_snapshot, "Battle snapshot should be destroyed")

	# Verify stolen card still in campaign (not removed)
	assert_true(manager.current_snapshot.cards.has(card_to_steal), "Stolen card should still be in campaign")
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count, "Campaign should be unchanged")


## Test: Serialize and deserialize whole system
func test_serialize_deserialize_system():
	# Initialize campaign
	manager.initialize_campaign("hero_001")
	manager.permanent_add_card("special_card_001", 2, "event")

	# Start battle
	manager.start_battle()
	manager.current_battle_snapshot.draw_cards(2)
	manager.current_battle_snapshot.play_card("card_001", to_exhaust=true)
	manager.permanent_add_card("additional_card_001", 1, "shop")

	# Serialize
	var serialized = manager.serialize()

	# Create new manager and deserialize
	var new_manager = CampaignDeckManager.new()
	new_manager.deserialize(serialized)

	# Verify campaign state preserved
	assert_equal(new_manager.current_snapshot.cards.size(), manager.current_snapshot.cards.size(), "Campaign card count should match")
	assert_true(new_manager.current_snapshot.cards.has("special_card_001"), "Special card should be preserved")
	assert_true(new_manager.current_snapshot.cards.has("additional_card_001"), "Additional card should be preserved")
	assert_false(new_manager.current_snapshot.cards.has("card_001"), "Exhausted card should be removed")

	# Verify battle snapshot not preserved (it's temporary)
	assert_null(new_manager.current_battle_snapshot, "Battle snapshot should not be preserved after deserialization")


## Test: Validate deck size across cycles
func test_validate_deck_size_across_cycles():
	# Initialize
	manager.initialize_campaign("hero_001")
	assert_true(manager.validate_deck_size(), "Initial deck should be valid")

	# Start battle
	manager.start_battle()
	assert_true(manager.validate_deck_size(), "Deck should still be valid after start_battle")

	# Draw cards
	manager.current_battle_snapshot.draw_cards(3)
	assert_true(manager.validate_deck_size(), "Deck should still be valid after drawing")

	# Play cards
	manager.current_battle_snapshot.play_card(manager.current_battle_snapshot.hand_cards[0])
	assert_true(manager.validate_deck_size(), "Deck should still be valid after playing")

	# End battle
	manager.end_battle()
	assert_true(manager.validate_deck_size(), "Deck should still be valid after end_battle")

	# Add card
	manager.permanent_add_card("new_card_001", 1, "test")
	assert_true(manager.validate_deck_size(), "Deck should still be valid after adding card")

	# Exhaust card
	manager.exhaust_card("card_001")
	assert_true(manager.validate_deck_size(), "Deck should still be valid after exhausting card")