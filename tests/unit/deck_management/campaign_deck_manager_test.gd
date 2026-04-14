# === campaign_deck_manager_test.gd ===
#
# Unit tests for CampaignDeckManager class
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


## Test Setup

func setup():
	# Create a new instance for each test
	global manager = CampaignDeckManager.new()


## Test: Initialize campaign
func test_initialize_campaign():
	# Initialize campaign with a hero
	manager.initialize_campaign("hero_001")

	# Verify campaign snapshot created
	assert_not_null(manager.current_snapshot, "Campaign snapshot should be created")
	assert_true(manager.current_snapshot.cards.size() > 0, "Initial deck should have cards")


## Test: Start battle
func test_start_battle():
	manager.initialize_campaign("hero_001")

	# Start battle
	manager.start_battle()

	# Verify battle snapshot created
	assert_not_null(manager.current_battle_snapshot, "Battle snapshot should be created")
	assert_equal(manager.current_battle_snapshot.source_version, manager.current_snapshot.version, "Source version should match")
	assert_equal(manager.current_battle_snapshot.draw_pile.size(), manager.current_snapshot.cards.size(), "Draw pile should have all cards")


## Test: End battle
func test_end_battle():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	# Exhaust a card
	manager.current_battle_snapshot.draw_cards(1)
	var card_in_hand = manager.current_battle_snapshot.hand_cards[0]
	manager.current_battle_snapshot.play_card(card_in_hand, to_exhaust=true)

	# End battle
	manager.end_battle()

	# Verify battle snapshot destroyed
	assert_null(manager.current_battle_snapshot, "Battle snapshot should be destroyed")

	# Verify exhausted card removed from campaign
	assert_false(manager.current_snapshot.cards.has(card_in_hand), "Exhausted card should be removed from campaign")


## Test: End battle without exhausting
func test_end_battle_no_exhaust():
	manager.initialize_campaign("hero_001")
	var initial_card_count = manager.current_snapshot.cards.size()

	manager.start_battle()
	manager.end_battle()

	# Verify campaign snapshot unchanged
	assert_equal(manager.current_snapshot.cards.size(), initial_card_count, "Campaign deck should be unchanged")


## Test: Permanent add card outside battle
func test_permanent_add_card_outside_battle():
	manager.initialize_campaign("hero_001")
	var initial_card_count = manager.current_snapshot.cards.size()

	# Add card outside battle
	manager.permanent_add_card("new_card_001", 1, "shop")

	# Verify card added to campaign
	assert_equal(manager.current_snapshot.cards.size(), initial_card_count + 1, "Card should be added to campaign")
	assert_true(manager.current_snapshot.cards.has("new_card_001"), "New card should be in campaign")


## Test: Permanent add card during battle
func test_permanent_add_card_during_battle():
	manager.initialize_campaign("hero_001")
	manager.start_battle()

	var initial_campaign_count = manager.current_snapshot.cards.size()
	var initial_battle_count = manager.current_battle_snapshot.get_total_card_count()

	# Add card during battle
	manager.permanent_add_card("new_card_001", 1, "event")

	# Verify card added to both snapshots
	assert_equal(manager.current_snapshot.cards.size(), initial_campaign_count + 1, "Card should be added to campaign")
	assert_true(manager.current_snapshot.cards.has("new_card_001"), "New card should be in campaign")

	assert_equal(manager.current_battle_snapshot.get_total_card_count(), initial_battle_count + 1, "Card should be added to battle")
	assert_true(manager.current_battle_snapshot.draw_pile.has("new_card_001"), "New card should be in battle draw pile")


## Test: Exhaust card directly
func test_exhaust_card():
	manager.initialize_campaign("hero_001")

	# Add a card
	manager.permanent_add_card("test_card_001", 1, "test")

	# Verify card exists
	assert_true(manager.current_snapshot.cards.has("test_card_001"))

	# Exhaust card
	manager.exhaust_card("test_card_001")

	# Verify card removed
	assert_false(manager.current_snapshot.cards.has("test_card_001"), "Card should be removed after exhaust")


## Test: Serialize campaign
func test_serialize_campaign():
	manager.initialize_campaign("hero_001")
	manager.permanent_add_card("test_card_001", 1, "shop")

	# Serialize
	var serialized = manager.serialize()

	# Verify serialized data
	assert_true(serialized.has("cards"), "Serialized data should have cards")
	assert_true(serialized.has("version"), "Serialized data should have version")
	assert_true(serialized["cards"].has("test_card_001"), "Serialized cards should include added card")


## Test: Deserialize campaign
func test_deserialize_campaign():
	# Create and serialize a manager
	manager.initialize_campaign("hero_001")
	manager.permanent_add_card("test_card_001", 2, "shop")
	var serialized = manager.serialize()

	# Create new manager and deserialize
	var new_manager = CampaignDeckManager.new()
	new_manager.deserialize(serialized)

	# Verify deserialized state
	assert_not_null(new_manager.current_snapshot, "Campaign snapshot should be created")
	assert_equal(new_manager.current_snapshot.cards.size(), manager.current_snapshot.cards.size(), "Card count should match")
	assert_true(new_manager.current_snapshot.cards.has("test_card_001"), "Deserialized should have card")
	assert_equal(new_manager.current_snapshot.cards["test_card_001"]["level"], 2, "Card level should be preserved")


## Test: Get campaign cards
func test_get_campaign_cards():
	manager.initialize_campaign("hero_001")
	manager.permanent_add_card("test_card_001", 1, "test")

	var cards = manager.get_campaign_cards()

	# Verify cards returned
	assert_true(cards.has("test_card_001"), "Should have added card")
	assert_equal(cards["test_card_001"]["source"], "test", "Card source should be correct")


## Test: Is in battle
func test_is_in_battle():
	manager.initialize_campaign("hero_001")

	# Not in battle initially
	assert_false(manager.is_in_battle(), "Should not be in battle initially")

	# Start battle
	manager.start_battle()
	assert_true(manager.is_in_battle(), "Should be in battle after start_battle")

	# End battle
	manager.end_battle()
	assert_false(manager.is_in_battle(), "Should not be in battle after end_battle")


## Test: Campaign snapshot changed signal
func test_campaign_snapshot_changed_signal():
	var signal_emitted = false

	manager.campaign_snapshot_changed.connect(func():
		signal_emitted = true
	)

	manager.initialize_campaign("hero_001")

	assert_true(signal_emitted, "campaign_snapshot_changed signal should be emitted")


## Test: Battle snapshot changed signal
func test_battle_snapshot_changed_signal():
	var signal_count = 0

	manager.battle_snapshot_changed.connect(func():
		signal_count += 1
	)

	manager.initialize_campaign("hero_001")
	manager.start_battle()  # Should emit signal
	manager.end_battle()    # Should emit signal

	assert_equal(signal_count, 2, "battle_snapshot_changed signal should be emitted twice")


## Test: Validate deck size
func test_validate_deck_size():
	# Empty deck should be invalid
	assert_false(manager.validate_deck_size(), "Empty deck should be invalid")

	# Initialize with valid deck
	manager.initialize_campaign("hero_001")
	assert_true(manager.validate_deck_size(), "Initial deck should be valid")


## Test: Multiple battle cycles
func test_multiple_battle_cycles():
	manager.initialize_campaign("hero_001")

	# First battle
	manager.start_battle()
	assert_true(manager.is_in_battle())
	manager.end_battle()
	assert_false(manager.is_in_battle())

	# Second battle
	manager.start_battle()
	assert_true(manager.is_in_battle())
	manager.end_battle()
	assert_false(manager.is_in_battle())

	# Verify campaign still valid
	assert_not_null(manager.current_snapshot, "Campaign snapshot should persist")