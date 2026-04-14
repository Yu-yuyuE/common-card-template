# === campaign_deck_snapshot_test.gd ===
#
# Unit tests for CampaignDeckSnapshot class
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 001: 战役层卡组快照基础实现
#
# Using GdUnit4 testing framework
#

extends "res://tests/gdunit4.gd"

# Import the class being tested
var CampaignDeckSnapshot = preload("res://src/core/deck-management/CampaignDeckSnapshot.gd")


## Test Setup

func setup():
	# Create a new instance for each test
	global snapshot = CampaignDeckSnapshot.new()


## Test: Initialize empty deck
func test_initialize_empty_deck():
	# Verify initial state
	assert_equal(snapshot.cards.size(), 0, "Deck should be empty initially")
	assert_equal(snapshot.version, 0, "Version should start at 0")


## Test: Add card
func test_add_card():
	# Add a card
	snapshot.add_card("card_001", 1, "initial")

	# Verify card was added
	assert_true(snapshot.cards.has("card_001"), "Card should be in deck")
	var card_data = snapshot.cards["card_001"]
	assert_equal(card_data["level"], 1, "Card level should be 1")
	assert_equal(card_data["source"], "initial", "Card source should be 'initial'")
	assert_true(card_data["is_permanent"], "Card should be permanent")
	assert_equal(snapshot.version, 1, "Version should increment after add")


## Test: Add multiple cards
func test_add_multiple_cards():
	snapshot.add_card("card_001", 1, "initial")
	snapshot.add_card("card_002", 1, "shop")
	snapshot.add_card("card_003", 1, "reward")

	assert_equal(snapshot.cards.size(), 3, "Should have 3 cards")
	assert_true(snapshot.cards.has("card_001"))
	assert_true(snapshot.cards.has("card_002"))
	assert_true(snapshot.cards.has("card_003"))
	assert_equal(snapshot.version, 3, "Version should increment for each add")


## Test: Remove card
func test_remove_card():
	# Add a card first
	snapshot.add_card("card_001", 1, "initial")

	# Remove the card
	snapshot.remove_card("card_001")

	# Verify card was removed
	assert_false(snapshot.cards.has("card_001"), "Card should be removed")
	assert_equal(snapshot.version, 2, "Version should increment after remove")


## Test: Remove non-existent card
func test_remove_nonexistent_card():
	# Should not crash when removing non-existent card
	snapshot.remove_card("nonexistent")
	assert_equal(snapshot.version, 0, "Version should not increment when removing non-existent card")


## Test: Upgrade card
func test_upgrade_card():
	# Add a card
	snapshot.add_card("card_001", 1, "initial")

	# Upgrade card
	assert_true(snapshot.upgrade_card("card_001"), "Upgrade should succeed")

	# Verify upgrade
	assert_equal(snapshot.cards["card_001"]["level"], 2, "Card level should be 2 after upgrade")
	assert_equal(snapshot.version, 2, "Version should increment after upgrade")


## Test: Upgrade already level 2 card
func test_upgrade_level2_card():
	# Add and upgrade card
	snapshot.add_card("card_001", 1, "initial")
	snapshot.upgrade_card("card_001")

	# Try to upgrade again
	assert_false(snapshot.upgrade_card("card_001"), "Upgrade should fail for level 2 card")
	assert_equal(snapshot.cards["card_001"]["level"], 2, "Card level should remain 2")
	assert_equal(snapshot.version, 2, "Version should not increment on failed upgrade")


## Test: Upgrade non-existent card
func test_upgrade_nonexistent_card():
	assert_false(snapshot.upgrade_card("nonexistent"), "Upgrade should fail for non-existent card")
	assert_equal(snapshot.version, 0, "Version should not increment on failed upgrade")


## Test: Get all card IDs
func test_get_all_card_ids():
	snapshot.add_card("card_001", 1, "initial")
	snapshot.add_card("card_002", 1, "shop")
	snapshot.add_card("card_003", 1, "reward")

	var ids = snapshot.get_all_card_ids()
	assert_equal(ids.size(), 3, "Should return 3 card IDs")
	assert_true(ids.has("card_001"))
	assert_true(ids.has("card_002"))
	assert_true(ids.has("card_003"))


## Test: Serialize snapshot
func test_serialize_snapshot():
	snapshot.add_card("card_001", 2, "initial")
	snapshot.add_card("card_002", 1, "shop")

	var serialized = snapshot.serialize()

	assert_equal(serialized["version"], 2, "Serialized version should match")
	assert_true(serialized["cards"].has("card_001"))
	assert_true(serialized["cards"].has("card_002"))
	assert_equal(serialized["cards"]["card_001"]["level"], 2, "Card level should be preserved")


## Test: Deserialize snapshot
func test_deserialize_snapshot():
	# Create a snapshot, serialize it, then deserialize
	snapshot.add_card("card_001", 1, "initial")
	snapshot.add_card("card_002", 2, "shop")

	var serialized = snapshot.serialize()
	var deserialized = CampaignDeckSnapshot.deserialize(serialized)

	# Verify deserialized snapshot matches original
	assert_equal(deserialized.version, 2, "Deserialized version should match")
	assert_equal(deserialized.cards.size(), 2, "Deserialized should have 2 cards")
	assert_true(deserialized.cards.has("card_001"))
	assert_true(deserialized.cards.has("card_002"))
	assert_equal(deserialized.cards["card_001"]["level"], 1, "Card level should be preserved")
	assert_equal(deserialized.cards["card_002"]["level"], 2, "Card level should be preserved")


## Test: Signal emission
func test_snapshot_updated_signal():
	var signal_emitted = false

	# Connect to signal
	snapshot.snapshot_updated.connect(func():
		signal_emitted = true
	)

	# Trigger change
	snapshot.add_card("card_001", 1, "initial")

	# Verify signal was emitted
	assert_true(signal_emitted, "snapshot_updated signal should be emitted")


## Test: Duplicate card IDs
func test_duplicate_card_id():
	# Add a card
	snapshot.add_card("card_001", 1, "initial")

	# Add same card again (should overwrite)
	snapshot.add_card("card_001", 2, "shop")

	# Verify card was updated
	assert_equal(snapshot.cards["card_001"]["level"], 2, "Card level should be updated")
	assert_equal(snapshot.version, 2, "Version should increment")
	assert_equal(snapshot.cards.size(), 1, "Should still have only one card")