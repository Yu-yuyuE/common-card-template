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
## 移除区：移出本场战斗的卡牌（如某些诅咒/特殊效果）
var removed_cards: Array[Card] = []
## 消耗区：使用后进入消耗区，本局游戏无法再使用的卡牌
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


## 检查是否可以添加兵种卡（统帅值约束）
## 参数：deck_cards - 当前卡组中的所有卡牌
## 返回：true=可以添加，false=已达到统帅上限
func can_add_troop_card(deck_cards: Array) -> bool:
	if battle_manager == null:
		return true

	# 获取当前武将的统帅值
	var current_hero_name: String = battle_manager.player_entity.id
	if current_hero_name == "":
		push_warning("CardManager: 未设置当前武将，使用默认统帅值3")
		current_hero_name = "曹操"  # 默认武将

	var leadership: int = 3
	if battle_manager.hero_manager != null:
		leadership = battle_manager.hero_manager.get_leadership(current_hero_name)

	# 统计当前卡组中兵种卡数量（只计算type == TROOP的卡）
	var troop_count: int = 0
	for card in deck_cards:
		if card.is_troop_card():
			troop_count += 1

	# 检查是否超过统帅上限
	return troop_count < leadership


## 获取指定兵种的基础Lv3分支选项
## 参数：base_card_id - 基础兵种卡ID（如"TroopCard"）
## 返回：分支列表，每个元素为字典包含id、name、effect
func get_troop_branch_options(base_card_id: String) -> Array[Dictionary]:
	# 首先找到基础兵种类型
	var troop_type: int = TroopCard.TroopType.INFANTRY  # 默认

	# 根据卡ID映射到兵种类型（实际实现可能更复杂）
	# 这里简化处理：假设卡ID对应兵种类型
	match base_card_id:
		"TroopCard":
			# 这里需要从CardData中获取实际类型，但当前实现没有直接关联
			# 为简化，返回所有兵种的分支选项
			return TroopBranchRegistry.get_branch_options(TroopCard.TroopType.INFANTRY)
		"CavalryCard":
			troop_type = TroopCard.TroopType.CAVALRY
		"ArcherCard":
			troop_type = TroopCard.TroopType.ARCHER
		"StrategistCard":
			troop_type = TroopCard.TroopType.STRATEGIST
		"ShieldCard":
			troop_type = TroopCard.TroopType.SHIELD
		_:
			return []

	return TroopBranchRegistry.get_branch_options(troop_type)


## 检查兵种卡是否已达到最大等级（Lv3）
## 参数：card - 兵种卡实例
## 返回：true=已是Lv3，false=还可以升级
func is_troop_card_max_level(card: TroopCard) -> bool:
	return TroopBranchRegistry.is_max_level(card)

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

## 强制加牌：被动技能或卡牌效果将一张牌直接加入手牌。
## 若加入后超出手牌上限，超出部分（末尾）立即移入弃牌堆。
## @param card: 要加入手牌的卡牌实例
func force_add_card(card: Card) -> void:
	hand_cards.append(card)
	card_drawn.emit(card)
	# TODO: D4 诅咒联动，检查 card_drawn 事件触发诅咒
	_enforce_hand_limit()

## 手牌溢出检查：超出上限的末尾牌移入弃牌堆
func _enforce_hand_limit() -> void:
	var limit := get_hand_limit()
	while hand_cards.size() > limit:
		var overflow: Card = hand_cards.pop_back()
		discard_pile.append(overflow)
		hand_full_discarded.emit(overflow)

## 洗牌：将弃牌堆移入抽牌堆并打乱
func _shuffle_discard_to_draw() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile.shuffle()
	deck_shuffled.emit()

## 战斗结束：将移除区的卡牌放回抽牌堆（胜利结算用）
func return_removed_cards_to_deck() -> void:
	draw_pile.append_array(removed_cards)
	removed_cards.clear()
