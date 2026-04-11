## 卡牌管理器（Node或RefCounted）
## 负责战斗中的牌库（抽牌堆、手牌、弃牌堆、移除区、消耗区）管理与流转逻辑。
class_name CardManager extends RefCounted

signal card_drawn(card: Card)
signal card_discarded(card: Card)
signal deck_shuffled()
signal hand_full_discarded(card: Card)

## 抽牌堆：待抽取的卡牌
var draw_pile: Array[Card] = []
## 手牌区：当前玩家持有的卡牌
var hand_cards: Array[Card] = []
## 弃牌堆：已使用并弃置的卡牌
var discard_pile: Array[Card] = []
## 移除区：永久移出游戏的卡牌（如某些诅咒/特殊效果）
var removed_cards: Array[Card] = []
## 消耗区：使用后进入消耗区，本回合无法再使用的卡牌
var exhaust_cards: Array[Card] = []

var battle_manager: Node # 引入BattleManager的引用以获取玩家信息

func _init(p_battle_manager: Node = null) -> void:
	battle_manager = p_battle_manager

## 初始化抽牌堆，传入初始的一套 CardData
func initialize_deck(initial_cards: Array[CardData]) -> void:
	draw_pile.clear()
	hand_cards.clear()
	discard_pile.clear()
	removed_cards.clear()
	exhaust_cards.clear()
	
	for data in initial_cards:
		draw_pile.append(Card.new(data))
	
	draw_pile.shuffle()

## 获取玩家的手牌上限
func get_hand_limit() -> int:
	var limit = 5
	if battle_manager != null and battle_manager.player_entity != null:
		if battle_manager.player_entity.id == "yuan_shao":
			limit = 6
	return limit

## 回合开始时补齐手牌至上限
func fill_hand_to_limit() -> void:
	var limit = get_hand_limit()
	var to_draw = maxi(0, limit - hand_cards.size())
	if to_draw > 0:
		draw_cards(to_draw)

## 尝试从抽牌堆抽取 count 张卡
func draw_cards(count: int) -> void:
	var limit = get_hand_limit()
	for i in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				# 抽牌堆和弃牌堆都为空，无法再抽，直接退出
				break
			else:
				# 弃牌堆洗入抽牌堆
				_shuffle_discard_to_draw()
		
		# 若此时 draw_pile 仍为空，直接跳出（双空保护，已在前段处理）
		var card: Card = draw_pile.pop_front()
		
		# 手牌上限检查 (AC-5: 手牌溢出机制)
		if hand_cards.size() >= limit:
			discard_pile.append(card)
			hand_full_discarded.emit(card)
		else:
			hand_cards.append(card)
			card_drawn.emit(card)
			# TODO: D4 诅咒联动，检查 card_drawn 事件触发诅咒

## 弃牌：将某张卡从手牌移入弃牌堆
func discard_card(card: Card) -> void:
	var index = hand_cards.find(card)
	if index != -1:
		hand_cards.remove_at(index)
		discard_pile.append(card)
		card_discarded.emit(card)

## 卡牌打出后的流转：根据其属性决定进入弃牌、消耗还是移除区
func exhaust_or_discard_played_card(card: Card) -> void:
	var index = hand_cards.find(card)
	if index != -1:
		hand_cards.remove_at(index)
		if card.data and card.data.remove_after_use:
			removed_cards.append(card)
		elif card.data and card.data.exhaust:
			exhaust_cards.append(card)
		else:
			discard_pile.append(card)

		# 此处也可以发射相应的 card_removed 等信号，视后续需求定

## 洗牌：将弃牌堆移入抽牌堆并打乱
func _shuffle_discard_to_draw() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile.shuffle()
	deck_shuffled.emit()
