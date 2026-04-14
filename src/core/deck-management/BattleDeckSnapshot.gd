# === BattleDeckSnapshot.gd ===
#
# Implements the temporary deck state for a single battle.
# This snapshot is created from CampaignDeckSnapshot at battle start and destroyed at battle end.
# All changes here do not affect the campaign layer (unless explicitly marked permanent).
#
# ADR-0020: 卡组两层管理架构
# GDD: design/gdd/cards-design.md (§0-§1)
#
# Implements:
# - Story 002: 战斗层卡组快照基础实现
#

class_name BattleDeckSnapshot extends RefCounted

## Data Structure
# Source version for synchronization check
var source_version: int = 0

# Battle zones
var draw_pile: Array[String] = []      # Cards available to draw
var hand_cards: Array[String] = []     # Cards in player's hand
var discard_pile: Array[String] = []   # Cards played this battle
var removed_cards: Array[String] = []  # Cards removed this battle (return to deck after battle)
var exhaust_cards: Array[String] = []  # Cards permanently consumed

# Temporary states (cleared after battle)
var temporary_upgrades: Dictionary = {}  # card_id -> {temp_level, temp_effects}
var stolen_cards: Array[String] = []      # Cards stolen by enemies

## Signals
# Emitted whenever the battle deck state changes
signal snapshot_updated()


## Methods

## Initialize from campaign snapshot
# campaign_snapshot: The source CampaignDeckSnapshot
func initialize_from_campaign(campaign_snapshot: CampaignDeckSnapshot) -> void:
	source_version = campaign_snapshot.version

	# Copy all cards to draw pile
	draw_pile = campaign_snapshot.get_all_card_ids()
	# Shuffle the draw pile
	draw_pile.shuffle()

	# Clear other zones
	hand_cards.clear()
	discard_pile.clear()
	removed_cards.clear()
	exhaust_cards.clear()

	# Clear temporary states
	temporary_upgrades.clear()
	stolen_cards.clear()

	snapshot_updated.emit()


## Draw cards from draw pile to hand
# count: Number of cards to draw
# Returns: Array of drawn card IDs
func draw_cards(count: int) -> Array[String]:
	var drawn: Array[String] = []

	for i in range(count):
		# If draw pile is empty, shuffle discard pile into it
		if draw_pile.is_empty():
			_shuffle_discard_to_draw()

		# Draw a card if available
		if not draw_pile.is_empty():
			var card_id = draw_pile.pop_front()
			hand_cards.append(card_id)
			drawn.append(card_id)

	snapshot_updated.emit()
	return drawn


## Play a card from hand
# card_id: The card to play
# to_removed: If true, card goes to removed_cards (will return after battle)
# to_exhaust: If true, card goes to exhaust_cards (permanent consumption)
func play_card(card_id: String, to_removed: bool = false, to_exhaust: bool = false) -> void:
	var idx = hand_cards.find(card_id)
	if idx < 0:
		push_warning("Attempted to play card not in hand: " + card_id)
		return

	# Remove from hand
	hand_cards.remove_at(idx)

	# Place in appropriate zone
	if to_exhaust:
		exhaust_cards.append(card_id)
	elif to_removed:
		removed_cards.append(card_id)
	else:
		discard_pile.append(card_id)

	snapshot_updated.emit()


## Steal a card from hand (enemy action)
# card_id: The card to steal
func steal_card(card_id: String) -> void:
	var idx = hand_cards.find(card_id)
	if idx < 0:
		push_warning("Attempted to steal card not in hand: " + card_id)
		return

	# Remove from hand and add to stolen cards
	hand_cards.remove_at(idx)
	stolen_cards.append(card_id)

	# Note: stolen cards are NOT added to removed_cards
	# They will not return to the deck after battle ends

	snapshot_updated.emit()


## Apply temporary upgrade (only for this battle)
# card_id: The card to upgrade
# temp_level: Temporary level boost
# temp_effects: Dictionary of temporary effects
func temporary_upgrade(card_id: String, temp_level: int, temp_effects: Dictionary) -> void:
	temporary_upgrades[card_id] = {
		"temp_level": temp_level,
		"temp_effects": temp_effects
	}
	snapshot_updated.emit()


## Shuffle discard pile into draw pile
func _shuffle_discard_to_draw() -> void:
	draw_pile.append_array(discard_pile)
	draw_pile.shuffle()
	discard_pile.clear()


## Finalize battle and return changes to be written back to campaign layer
# Returns: Dictionary containing changes (exhaust_cards, source_version)
func finalize_battle() -> Dictionary:
	# Return only changes that affect the campaign layer
	return {
		"exhaust_cards": exhaust_cards.duplicate(),  # These cards are permanently consumed
		"source_version": source_version
	}


## Get the total number of cards in the battle deck (all zones combined)
# Returns: Total card count
func get_total_card_count() -> int:
	return draw_pile.size() + hand_cards.size() + discard_pile.size() + removed_cards.size() + exhaust_cards.size() + stolen_cards.size()


## Get all cards currently in the player's possession (not stolen or exhausted)
# Returns: Array of card IDs
func get_active_cards() -> Array[String]:
	var result: Array[String] = []
	result.append_array(draw_pile)
	result.append_array(hand_cards)
	result.append_array(discard_pile)
	result.append_array(removed_cards)
	return result