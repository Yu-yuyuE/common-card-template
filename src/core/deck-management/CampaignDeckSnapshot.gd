# === CampaignDeckSnapshot.gd ===
#
# Implements the authoritative deck state for the campaign level.
# This snapshot is persisted across battles and represents the player's permanent deck.
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 001: 战役层卡组快照基础实现
#

class_name CampaignDeckSnapshot extends RefCounted

## Data Structure
# Map of card_id -> {level, special_attrs, is_permanent, source, added_at}
var cards: Dictionary = {}

# Version number for synchronization with BattleDeckSnapshot
var version: int = 0

## Signals
# Emitted whenever the campaign deck state changes
signal snapshot_updated()


## Methods

## Initialize the snapshot
func _init():
	# Initialize empty deck
	cards = {}
	version = 0

## Add a card to the campaign deck
# card_id: The unique identifier of the card
# level: The card's level (1 or 2)
# source: Where the card came from ("shop", "event", "reward", "initial")
func add_card(card_id: String, level: int = 1, source: String = "unknown") -> void:
	# Validate input
	if card_id == "":
		push_error("Cannot add card with empty ID")
		return

	# Create card data
	cards[card_id] = {
		"level": level,
		"special_attrs": [],
		"is_permanent": true,
		"source": source,
		"added_at": Time.get_ticks_msec()
	}

	# Increment version and emit signal
	version += 1
	snapshot_updated.emit()


## Remove a card from the campaign deck
# card_id: The unique identifier of the card
func remove_card(card_id: String) -> void:
	if not cards.has(card_id):
		push_warning("Attempted to remove non-existent card: " + card_id)
		return

	cards.erase(card_id)
	version += 1
	snapshot_updated.emit()


## Upgrade a card's level (1 -> 2)
# card_id: The unique identifier of the card
# Returns: true if upgrade succeeded, false if card doesn't exist or is already level 2
func upgrade_card(card_id: String) -> bool:
	if not cards.has(card_id):
		return false

	if cards[card_id]["level"] >= 2:
		return false

	cards[card_id]["level"] = 2
	version += 1
	snapshot_updated.emit()
	return true


## Get all card IDs in the campaign deck
# Returns: Array of all card IDs
func get_all_card_ids() -> Array[String]:
	var result: Array[String] = []
	for card_id in cards:
		result.append(card_id)
	return result


## Serialize the snapshot for saving
# Returns: Dictionary containing serialized data
func serialize() -> Dictionary:
	return {
		"cards": cards.duplicate(),
		"version": version
	}


## Deserialize the snapshot from saved data
# data: Dictionary containing serialized data
# Returns: New CampaignDeckSnapshot instance
static func deserialize(data: Dictionary) -> CampaignDeckSnapshot:
	var snapshot = CampaignDeckSnapshot.new()
	snapshot.cards = data.get("cards", {})
	snapshot.version = data.get("version", 0)
	return snapshot