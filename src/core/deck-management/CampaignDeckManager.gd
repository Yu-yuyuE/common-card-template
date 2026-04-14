# === CampaignDeckManager.gd ===
#
# Manages the lifecycle of campaign and battle deck snapshots.
# Coordinates between the campaign layer (persistent) and battle layer (temporary).
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 003: 卡组管理器集成
#

class_name CampaignDeckManager extends Node

## Current State
var current_snapshot: CampaignDeckSnapshot = null
var current_battle_snapshot: BattleDeckSnapshot = null

## Signals
signal campaign_snapshot_changed()
signal battle_snapshot_changed()


## Lifecycle Methods

func _ready():
	# Initialize empty campaign snapshot
	current_snapshot = CampaignDeckSnapshot.new()


## Campaign Management

## Initialize a new campaign with hero's initial deck
# hero_id: The hero's unique identifier
func initialize_campaign(hero_id: String) -> void:
	# Create new campaign snapshot
	current_snapshot = CampaignDeckSnapshot.new()

	# Load hero's initial deck
	var initial_deck = _load_initial_deck(hero_id)
	for card_id in initial_deck:
		current_snapshot.add_card(card_id, 1, "initial")

	campaign_snapshot_changed.emit()


## Start a battle by creating a battle snapshot from campaign snapshot
func start_battle() -> void:
	if current_snapshot == null:
		push_error("Cannot start battle without campaign snapshot")
		return

	# Create battle snapshot from campaign
	current_battle_snapshot = BattleDeckSnapshot.new()
	current_battle_snapshot.initialize_from_campaign(current_snapshot)

	battle_snapshot_changed.emit()


## End the battle and write back changes to campaign layer
func end_battle() -> void:
	if current_battle_snapshot == null:
		push_warning("No battle snapshot to end")
		return

	# Get changes from battle
	var changes = current_battle_snapshot.finalize_battle()

	# Process exhaust cards (permanent removal)
	for card_id in changes["exhaust_cards"]:
		current_snapshot.remove_card(card_id)

	# Destroy battle snapshot
	current_battle_snapshot = null

	battle_snapshot_changed.emit()
	campaign_snapshot_changed.emit()


## Permanent Add Card Mechanism

## Permanently add a card to both campaign and battle snapshots
# card_id: The card's unique identifier
# level: The card's level (default 1)
# source: Where the card came from ("shop", "event", "reward", "effect")
func permanent_add_card(card_id: String, level: int = 1, source: String = "effect") -> void:
	# Add to campaign snapshot
	current_snapshot.add_card(card_id, level, source)

	# If in battle, also add to battle snapshot
	if current_battle_snapshot != null:
		current_battle_snapshot.draw_pile.append(card_id)
		current_battle_snapshot.snapshot_updated.emit()

	campaign_snapshot_changed.emit()


## Exhaust Card Mechanism

## Permanently remove a card from campaign (direct consumption outside battle)
# card_id: The card's unique identifier
func exhaust_card(card_id: String) -> void:
	current_snapshot.remove_card(card_id)
	campaign_snapshot_changed.emit()


## Serialization (for save system integration)

## Serialize the campaign snapshot for saving
# Returns: Dictionary containing serialized data
func serialize() -> Dictionary:
	if current_snapshot == null:
		push_warning("Serializing null campaign snapshot")
		return {}
	return current_snapshot.serialize()


## Deserialize the campaign snapshot from saved data
# data: Dictionary containing serialized data
func deserialize(data: Dictionary) -> void:
	current_snapshot = CampaignDeckSnapshot.deserialize(data)
	campaign_snapshot_changed.emit()


## Get available cards for deck building / display
# Returns: Dictionary of card_id -> card_data
func get_campaign_cards() -> Dictionary:
	if current_snapshot == null:
		return {}
	return current_snapshot.cards.duplicate()


## Check if currently in battle
# Returns: true if battle snapshot exists
func is_in_battle() -> bool:
	return current_battle_snapshot != null


## Helper Methods

## Load initial deck for a hero
# hero_id: The hero's unique identifier
# Returns: Array of card IDs
# TODO: Replace with actual data loading from CSV/JSON
func _load_initial_deck(hero_id: String) -> Array[String]:
	# Placeholder implementation - will be replaced with actual hero deck loading
	# For now, return a default starter deck
	return ["strike_001", "strike_002", "defend_001", "defend_002", "bash_001"]


## Validate deck size
# Returns: true if deck size is valid
func validate_deck_size() -> bool:
	if current_snapshot == null:
		return false

	var deck_size = current_snapshot.cards.size()
	# Assuming minimum deck size is 5 and maximum is 30
	return deck_size >= 5 and deck_size <= 30