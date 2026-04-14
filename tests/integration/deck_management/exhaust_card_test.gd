# === exhaust_card_test.gd ===
#
# Integration test for "消耗品" mechanism
# Verifies that consumable cards are permanently removed from campaign
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 005: 消耗品处理
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


## Test: Exhaust card during battle
func test_exhaust_card_during_battle():
	manager.initialize_campaign("hero_001")
	var initial_campaign_count = manager.current_snapshot.cards.size()

	# Start battle
	manager.start_battle()

	# Draw a card
	manager.current_battle_snapshot.draw_cards(1)
	var card_to_exhaust = manager.current_battle_snapshot.hand_cards[0]

	# Play card to exhaust
	manager.current_battle_snapshot.play_card(card_to_exhaust, to_exhaust=true)

	# End battle
	manager.end_battle()

	# Verify card removed from campaign
	assert_false(manager.current_snapshot.cards.has(card_to_exhaust), "Consumable card should be permanently removed")
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count - 1, "Campaign should have one less card")


## Test: Exhaust card directly (outside battle)
func test_exhaust_card_directly():
	manager.initialize_campaign("hero_001")
	var initial_campaign_count = manager.current_snapshot.cards.size()

	# Add a card to exhaust
	manager.permanent_add_card("consumable_card_001", 1, "shop")
	assert_true(manager.current_snapshot.cards.has("consumable_card_001"))

	# Exhaust card directly
	manager.exhaust_card("consumable_card_001")

	# Verify card removed from campaign
	assert_false(manager.current_snapshot.cards.has("consumable_card_001"), "Consumable card should be permanently removed")
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count, "Campaign should have one less card")


## Test: Exhaust card then try to draw again
func test_exhaust_card_then_draw():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	# Draw a card
	manager.current_battle_snapshot.draw_cards(1)
	var card_to_exhaust = manager.current_battle_snapshot.hand_cards[0]

	# Play card to exhaust
	manager.current_battle_snapshot.play_card(card_to_exhaust, to_exhaust=true)

	# End battle
	manager.end_battle()

	# Start new battle
	manager.start_battle()

	# Verify exhausted card is not in new battle
	assert_false(manager.current_battle_snapshot.draw_pile.has(card_to_exhaust), "Exhausted card should not appear in new battle")
	assert_false(manager.current_battle_snapshot.hand_cards.has(card_to_exhaust), "Exhausted card should not appear in new battle")


## Test: Exhaust card during battle then permanent add
func test_exhaust_then_permanent_add():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	# Draw a card
	manager.current_battle_snapshot.draw_cards(1)
	var card_to_exhaust = manager.current_battle_snapshot.hand_cards[0]

	# Play card to exhaust
	manager.current_battle_snapshot.play_card(card_to_exhaust, to_exhaust=true)

	# End battle
	manager.end_battle()

	# Add same card back permanently
	manager.permanent_add_card(card_to_exhaust, 1, "event")

	# Verify card added back
	assert_true(manager.current_snapshot.cards.has(card_to_exhaust), "Card should be added back permanently")

	# Start new battle
	manager.start_battle()

	# Verify card in new battle
	assert_true(manager.current_battle_snapshot.draw_pile.has(card_to_exhaust), "Card should be in new battle")


## Test: Exhaust card with multiple instances
func test_exhaust_multiple_instances():
	manager.initialize_campaign("hero_001")

	# Add multiple copies of same card
	manager.permanent_add_card("card_001", 1, "shop")
	manager.permanent_add_card("card_001", 1, "shop")
	assert_equal(manager.current_snapshot.cards.size(), 3, "Should have 3 cards total")

	# Start battle
	manager.start_battle()
	manager.current_battle_snapshot.draw_cards(2)

	# Exhaust one copy
	manager.current_battle_snapshot.play_card("card_001", to_exhaust=true)
	manager.end_battle()

	# Verify one copy remains in campaign
	assert_true(manager.current_snapshot.cards.has("card_001"), "One copy should remain")
	assert_equal(manager.current_snapshot.cards.size(), 2, "Should have 2 cards total")


## Test: Exhaust card with level 2
func test_exhaust_level_2_card():
	manager.initialize_campaign("hero_001")
	manager.permanent_add_card("card_001", 2, "reward")
	assert_equal(manager.current_snapshot.cards["card_001"]["level"], 2, "Card should be level 2")

	# Start battle
	manager.start_battle()
	manager.current_battle_snapshot.draw_cards(1)

	# Exhaust the card
	manager.current_battle_snapshot.play_card("card_001", to_exhaust=true)
	manager.end_battle()

	# Verify card removed from campaign
	assert_false(manager.current_snapshot.cards.has("card_001"), "Level 2 card should be permanently removed")


## Test: Exhaust card then permanently add
func test_exhaust_then_permanent_add_same_card():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	# Draw a card
	manager.current_battle_snapshot.draw_cards(1)
	var card_to_exhaust = manager.current_battle_snapshot.hand_cards[0]

	# Play card to exhaust
	manager.current_battle_snapshot.play_card(card_to_exhaust, to_exhaust=true)
	manager.end_battle()

	# Verify card removed
	assert_false(manager.current_snapshot.cards.has(card_to_exhaust), "Card should be removed")

	# Add same card back permanently
	manager.permanent_add_card(card_to_exhaust, 1, "event")
	assert_true(manager.current_snapshot.cards.has(card_to_exhaust), "Card should be added back")


## Test: Exhaust card from different sources
func test_exhaust_from_different_sources():
	manager.initialize_campaign("hero_001")

	# Add cards from different sources
	manager.permanent_add_card("shop_card_001", 1, "shop")
	manager.permanent_add_card("event_card_001", 1, "event")
	manager.permanent_add_card("reward_card_001", 1, "reward")

	# Start battle
	manager.start_battle()
	manager.current_battle_snapshot.draw_cards(3)

	# Exhaust each card
	for card in manager.current_battle_snapshot.hand_cards:
		manager.current_battle_snapshot.play_card(card, to_exhaust=true)

	manager.end_battle()

	# Verify all cards removed
	assert_false(manager.current_snapshot.cards.has("shop_card_001"))
	assert_false(manager.current_snapshot.cards.has("event_card_001"))
	assert_false(manager.current_snapshot.cards.has("reward_card_001"))