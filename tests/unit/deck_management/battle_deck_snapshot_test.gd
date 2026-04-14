# === battle_deck_snapshot_test.gd ===
#
# Unit tests for BattleDeckSnapshot class
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 002: 战斗层卡组快照基础实现
#
# Using GdUnit4 testing framework
#

extends "res://tests/gdunit4.gd"

# Import the classes being tested
var CampaignDeckSnapshot = preload("res://src/core/deck-management/CampaignDeckSnapshot.gd")
var BattleDeckSnapshot = preload("res://src/core/deck-management/BattleDeckSnapshot.gd")


## Test Setup

func setup():
	# Create a new instance for each test
	global battle_snapshot = BattleDeckSnapshot.new()
	global campaign_snapshot = CampaignDeckSnapshot.new()

	# Add some cards to campaign snapshot
	campaign_snapshot.add_card("card_001", 1, "initial")
	campaign_snapshot.add_card("card_002", 1, "shop")
	campaign_snapshot.add_card("card_003", 2, "reward")


## Test: Initialize from campaign
func test_initialize_from_campaign():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)

	# Verify source version
	assert_equal(battle_snapshot.source_version, campaign_snapshot.version, "Source version should match")

	# Verify draw pile has all cards
	assert_equal(battle_snapshot.draw_pile.size(), 3, "Draw pile should have 3 cards")
	assert_true(battle_snapshot.draw_pile.has("card_001"))
	assert_true(battle_snapshot.draw_pile.has("card_002"))
	assert_true(battle_snapshot.draw_pile.has("card_003"))

	# Verify other zones are empty
	assert_equal(battle_snapshot.hand_cards.size(), 0, "Hand should be empty")
	assert_equal(battle_snapshot.discard_pile.size(), 0, "Discard pile should be empty")
	assert_equal(battle_snapshot.removed_cards.size(), 0, "Removed cards should be empty")
	assert_equal(battle_snapshot.exhaust_cards.size(), 0, "Exhaust cards should be empty")
	assert_equal(battle_snapshot.temporary_upgrades.size(), 0, "Temporary upgrades should be empty")
	assert_equal(battle_snapshot.stolen_cards.size(), 0, "Stolen cards should be empty")


## Test: Draw cards
func test_draw_cards():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)

	# Draw 2 cards
	var drawn = battle_snapshot.draw_cards(2)

	# Verify drawn cards
	assert_equal(drawn.size(), 2, "Should draw 2 cards")
	assert_true(drawn.has("card_001") or drawn.has("card_002") or drawn.has("card_003"))
	assert_true(drawn.has("card_001") or drawn.has("card_002") or drawn.has("card_003"))

	# Verify hand has the drawn cards
	assert_equal(battle_snapshot.hand_cards.size(), 2, "Hand should have 2 cards")
	assert_true(battle_snapshot.hand_cards.has(drawn[0]))
	assert_true(battle_snapshot.hand_cards.has(drawn[1]))

	# Verify draw pile has one card left
	assert_equal(battle_snapshot.draw_pile.size(), 1, "Draw pile should have 1 card left")


## Test: Draw cards with empty draw pile
func test_draw_cards_empty_draw_pile():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)

	# Draw all cards
	battle_snapshot.draw_cards(3)

	# Play all cards to discard pile
	for card in battle_snapshot.hand_cards:
		battle_snapshot.play_card(card)

	# Draw again (should trigger shuffle)
	var drawn = battle_snapshot.draw_cards(1)

	# Verify card was drawn from shuffled discard pile
	assert_equal(drawn.size(), 1, "Should draw 1 card")
	assert_true(drawn[0] in ["card_001", "card_002", "card_003"])

	# Verify discard pile is empty after shuffle
	assert_equal(battle_snapshot.discard_pile.size(), 0, "Discard pile should be empty after shuffle")


## Test: Play card
func test_play_card():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)
	battle_snapshot.draw_cards(1)  # Get one card in hand

	var card_in_hand = battle_snapshot.hand_cards[0]

	# Play card to discard pile (default)
	battle_snapshot.play_card(card_in_hand)

	# Verify card moved from hand to discard pile
	assert_false(battle_snapshot.hand_cards.has(card_in_hand), "Card should be removed from hand")
	assert_true(battle_snapshot.discard_pile.has(card_in_hand), "Card should be in discard pile")


## Test: Play card to removed
func test_play_card_to_removed():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)
	battle_snapshot.draw_cards(1)

	var card_in_hand = battle_snapshot.hand_cards[0]

	# Play card to removed
	battle_snapshot.play_card(card_in_hand, to_removed=true)

	# Verify card moved to removed_cards
	assert_false(battle_snapshot.hand_cards.has(card_in_hand), "Card should be removed from hand")
	assert_true(battle_snapshot.removed_cards.has(card_in_hand), "Card should be in removed_cards")


## Test: Play card to exhaust
func test_play_card_to_exhaust():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)
	battle_snapshot.draw_cards(1)

	var card_in_hand = battle_snapshot.hand_cards[0]

	# Play card to exhaust
	battle_snapshot.play_card(card_in_hand, to_exhaust=true)

	# Verify card moved to exhaust_cards
	assert_false(battle_snapshot.hand_cards.has(card_in_hand), "Card should be removed from hand")
	assert_true(battle_snapshot.exhaust_cards.has(card_in_hand), "Card should be in exhaust_cards")


## Test: Steal card
func test_steal_card():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)
	battle_snapshot.draw_cards(1)

	var card_in_hand = battle_snapshot.hand_cards[0]

	# Steal card
	battle_snapshot.steal_card(card_in_hand)

	# Verify card moved from hand to stolen_cards
	assert_false(battle_snapshot.hand_cards.has(card_in_hand), "Card should be removed from hand")
	assert_true(battle_snapshot.stolen_cards.has(card_in_hand), "Card should be in stolen_cards")
	assert_false(battle_snapshot.removed_cards.has(card_in_hand), "Card should NOT be in removed_cards")


## Test: Steal non-existent card
func test_steal_nonexistent_card():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)

	# Try to steal card not in hand
	battle_snapshot.steal_card("nonexistent")

	# Verify no changes
	assert_equal(battle_snapshot.stolen_cards.size(), 0, "No cards should be stolen")


## Test: Temporary upgrade
func test_temporary_upgrade():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)
	battle_snapshot.draw_cards(1)

	var card_in_hand = battle_snapshot.hand_cards[0]

	# Apply temporary upgrade
	battle_snapshot.temporary_upgrade(card_in_hand, 2, {"damage_bonus": 10})

	# Verify upgrade was applied
	assert_true(battle_snapshot.temporary_upgrades.has(card_in_hand), "Temporary upgrade should be recorded")
	assert_equal(battle_snapshot.temporary_upgrades[card_in_hand]["temp_level"], 2, "Temp level should be 2")
	assert_equal(battle_snapshot.temporary_upgrades[card_in_hand]["temp_effects"]["damage_bonus"], 10, "Temp effect should be correct")


## Test: Finalize battle
func test_finalize_battle():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)
	battle_snapshot.draw_cards(2)

	# Play one card to exhaust
	battle_snapshot.play_card(battle_snapshot.hand_cards[0], to_exhaust=true)

	# Finalize battle
	var changes = battle_snapshot.finalize_battle()

	# Verify changes contain only exhaust_cards
	assert_equal(changes["exhaust_cards"].size(), 1, "Should return 1 exhaust card")
	assert_true(changes["exhaust_cards"].has(battle_snapshot.exhaust_cards[0]))
	assert_equal(changes["source_version"], battle_snapshot.source_version, "Source version should match")

	# Verify other zones are unchanged
	assert_equal(battle_snapshot.exhaust_cards.size(), 1, "Exhaust cards should still be present")


## Test: Signal emission
func test_snapshot_updated_signal():
	var signal_emitted = false

	# Connect to signal
	battle_snapshot.snapshot_updated.connect(func():
		signal_emitted = true
	)

	# Trigger change
	battle_snapshot.initialize_from_campaign(campaign_snapshot)

	# Verify signal was emitted
	assert_true(signal_emitted, "snapshot_updated signal should be emitted")


## Test: Get total card count
func test_get_total_card_count():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)

	# Verify total count
	assert_equal(battle_snapshot.get_total_card_count(), 3, "Should have 3 cards total")

	# Draw 2 cards
	battle_snapshot.draw_cards(2)
	assert_equal(battle_snapshot.get_total_card_count(), 3, "Total count should remain 3")

	# Play one card
	battle_snapshot.play_card(battle_snapshot.hand_cards[0])
	assert_equal(battle_snapshot.get_total_card_count(), 3, "Total count should remain 3")


## Test: Get active cards
func test_get_active_cards():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)
	battle_snapshot.draw_cards(2)

	var active_cards = battle_snapshot.get_active_cards()

	# Active cards should include draw_pile and hand_cards
	assert_equal(active_cards.size(), 3, "Should have 3 active cards")
	assert_true(active_cards.has("card_001"))
	assert_true(active_cards.has("card_002"))
	assert_true(active_cards.has("card_003"))

	# Play a card
	battle_snapshot.play_card(battle_snapshot.hand_cards[0])

	# Active cards should still include all cards (except stolen/exhausted)
	active_cards = battle_snapshot.get_active_cards()
	assert_equal(active_cards.size(), 3, "Should still have 3 active cards")


## Test: Shuffle discard to draw
func test_shuffle_discard_to_draw():
	battle_snapshot.initialize_from_campaign(campaign_snapshot)

	# Draw all cards
	battle_snapshot.draw_cards(3)

	# Play all cards to discard pile
	for card in battle_snapshot.hand_cards:
		battle_snapshot.play_card(card)

	# Verify draw pile is empty and discard pile has 3 cards
	assert_equal(battle_snapshot.draw_pile.size(), 0, "Draw pile should be empty")
	assert_equal(battle_snapshot.discard_pile.size(), 3, "Discard pile should have 3 cards")

	# Shuffle
	battle_snapshot._shuffle_discard_to_draw()

	# Verify discard pile is empty and draw pile has 3 cards
	assert_equal(battle_snapshot.discard_pile.size(), 0, "Discard pile should be empty after shuffle")
	assert_equal(battle_snapshot.draw_pile.size(), 3, "Draw pile should have 3 cards after shuffle")