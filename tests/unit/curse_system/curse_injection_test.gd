## curse_injection_test.gd
## 诅咒注入机制单元测试（简化版 - Story 4-6）
## 验证诅咒卡获得复用了标准卡牌管理流程
## 作者: Claude Code
## 创建日期: 2026-04-13

class_name CurseInjectionTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 测试用的 CurseManager 实例
var _curse_manager: CurseManager

## 测试用的 CardManager 实例
var _card_manager: CardManager

## 测试用的 CurseInjectionSystem 实例
var _injection_system: CurseInjectionSystem

# ==================== 测试生命周期 ====================

func before_test() -> void:
	# 创建 CurseManager
	_curse_manager = CurseManager.new()
	_curse_manager._ready()

	# 创建 CardManager
	_card_manager = CardManager.new()

	# 创建 CurseInjectionSystem
	_injection_system = CurseInjectionSystem.new(_card_manager, _curse_manager)

	# 添加到场景树
	add_child(_curse_manager)
	add_child(_card_manager)
	add_child(_injection_system)


func after_test() -> void:
	# 清理测试实例
	if _injection_system and is_instance_valid(_injection_system):
		_injection_system.queue_free()
	if _curse_manager and is_instance_valid(_curse_manager):
		_curse_manager.queue_free()
	if _card_manager and is_instance_valid(_card_manager):
		_card_manager.queue_free()

	_injection_system = null
	_curse_manager = null
	_card_manager = null


# ==================== AC-1: 敌人行动注入到弃牌堆 ====================

## AC-1: 敌人行动注入诅咒卡到弃牌堆
## Given: 玩家弃牌堆为空
## When: 敌人行动注入诅咒卡
## Then: 诅咒卡出现在弃牌堆，触发 card_drawn 事件
func test_enemy_action_injection_to_discard_pile() -> void:
	# Arrange: 确保弃牌堆为空
	_card_manager.discard_pile.clear()

	# 使用测试用的诅咒卡ID（假设已存在）
	var test_curse_id = "curse_plague"

	# Act: 敌人行动注入诅咒卡
	var success = _injection_system.inject_curse_by_enemy_action(test_curse_id)

	# Assert: 验证注入成功
	assert_true(success, "敌人行动注入诅咒卡应成功")

	# 验证弃牌堆中有1张卡
	assert_int(_card_manager.discard_pile.size()).is_equal(1)

	# 验证是诅咒卡
	var injected_card = _card_manager.discard_pile[0]
	assert_not_null(injected_card)
	assert_string(injected_card.data.card_id).is_equal(test_curse_id)
	# 验证诅咒卡标记
	assert_true(injected_card.is_curse, "注入的卡应标记为诅咒卡")
	assert_int(injected_card.curse_source).is_equal(CurseInjectionSystem.InjectionSource.ENEMY_ACTION)


# ==================== AC-2: 地图事件注入到牌库 ====================

## AC-2: 地图事件注入诅咒卡到牌库
## Given: 玩家抽牌堆为空
## When: 地图事件注入诅咒卡
## Then: 诅咒卡出现在抽牌堆
func test_map_event_injection_to_library() -> void:
	# Arrange: 确保抽牌堆为空
	_card_manager.draw_pile.clear()

	var test_curse_id = "curse_plague"

	# Act: 地图事件注入诅咒卡
	var success = _injection_system.inject_curse_by_map_event(test_curse_id)

	# Assert: 验证注入成功
	assert_true(success, "地图事件注入诅咒卡应成功")

	# 验证抽牌堆中有1张卡
	assert_int(_card_manager.draw_pile.size()).is_equal(1)

	# 验证是诅咒卡
	var injected_card = _card_manager.draw_pile[0]
	assert_not_null(injected_card)
	assert_string(injected_card.data.card_id).is_equal(test_curse_id)


# ==================== AC-3: 卡牌效果注入到手牌 ====================

## AC-3: 卡牌效果注入诅咒卡到手牌
## Given: 玩家手牌未满
## When: 卡牌效果注入诅咒卡
## Then: 诅咒卡出现在手牌
func test_card_effect_injection_to_hand() -> void:
	# Arrange: 确保手牌未满（手牌上限5张）
	_card_manager.hand_cards.clear()

	var test_curse_id = "curse_plague"

	# Act: 卡牌效果注入诅咒卡到手牌
	var success = _injection_system.inject_curse_by_card_effect(test_curse_id)

	# Assert: 验证注入成功
	assert_true(success, "卡牌效果注入诅咒卡应成功")

	# 验证手牌中有1张卡
	assert_int(_card_manager.hand_cards.size()).is_equal(1)

	# 验证是诅咒卡
	var injected_card = _card_manager.hand_cards[0]
	assert_not_null(injected_card)
	assert_string(injected_card.data.card_id).is_equal(test_curse_id)


## AC-3-扩展: 手牌满时注入会弃置一张卡
func test_card_effect_injection_to_full_hand() -> void:
	# Arrange: 填满手牌（5张）
	_card_manager.hand_cards.clear()
	for i in range(5):
		var card = Card.new(CardData.new("Card%d" % i, 1, "测试卡%d" % i, 1))
		_card_manager.hand_cards.append(card)

	var test_curse_id = "curse_plague"

	# Act: 卡牌效果注入诅咒卡到手牌
	var success = _injection_system.inject_curse_by_card_effect(test_curse_id)

	# Assert: 验证注入成功
	assert_true(success, "手牌满时注入应成功并弃置一张卡")

	# 验证手牌仍有5张卡（注入1张，弃置1张）
	assert_int(_card_manager.hand_cards.size()).is_equal(5)

	# 验证最后一张是诅咒卡
	var injected_card = _card_manager.hand_cards[4]
	assert_not_null(injected_card)
	assert_string(injected_card.data.card_id).is_equal(test_curse_id)


# ==================== AC-4: 司马懿初始卡组预置 ====================

## AC-4: 司马懿初始卡组预置2张韬晦
## Given: 抽牌堆为空
## When: 初始化卡组时调用武将初始注入
## Then: 抽牌堆中有2张韬晦
func test_hero_initial_deck_injection() -> void:
	# Arrange: 清空抽牌堆
	_card_manager.draw_pile.clear()

	var test_curse_id = "curse_taohui"  # 韬晦诅咒卡ID

	# Act: 为武将初始卡组注入2张韬晦
	var success1 = _injection_system.inject_curse_by_hero_initial_deck(test_curse_id)
	var success2 = _injection_system.inject_curse_by_hero_initial_deck(test_curse_id)

	# Assert: 验证两次注入都成功
	assert_true(success1 and success2, "武将初始卡组注入应成功")

	# 验证抽牌堆中有2张卡
	assert_int(_card_manager.draw_pile.size()).is_equal(2)

	# 验证都是诅咒卡
	for card in _card_manager.draw_pile:
		assert_not_null(card)
		assert_string(card.data.card_id).is_equal(test_curse_id)


# ==================== AC-5: 使用标准卡牌获得事件 ====================

## AC-5: 注入时触发标准 card_drawn 事件
## Given: 监听 card_drawn 信号
## When: 注入诅咒卡
## Then: 信号被触发，参数包含诅咒卡
func test_injection_triggers_card_drawn_event() -> void:
	# Arrange: 清空所有区域
	_card_manager.discard_pile.clear()
	_card_manager.draw_pile.clear()
	_card_manager.hand_cards.clear()

	var event_count: int = 0
	var last_card: Card = null

	# 监听 card_drawn 事件
	_card_manager.card_drawn.connect(func(card: Card) -> void:
		event_count += 1
		last_card = card
	)

	var test_curse_id = "curse_plague"

	# Act: 注入诅咒卡（敌人行动 → 弃牌堆）
	var success = _injection_system.inject_curse_by_enemy_action(test_curse_id)

	# Assert: 验证注入成功
	assert_true(success, "注入应成功")

	# 验证事件触发1次
	assert_int(event_count).is_equal(1)

	# 验证事件参数是诅咒卡
	assert_not_null(last_card)
	assert_string(last_card.data.card_id).is_equal(test_curse_id)
	assert_true(last_card.is_curse, "事件中的卡应标记为诅咒卡")


# ==================== 错误处理测试 ====================

## 错误处理: 注入不存在的诅咒卡
func test_injection_nonexistent_curse() -> void:
	# Arrange: 使用不存在的诅咒卡ID
	var nonexistent_id = "curse_nonexistent"

	# Act: 尝试注入
	var success = _injection_system.inject_curse_by_enemy_action(nonexistent_id)

	# Assert: 验证注入失败
	assert_false(success, "注入不存在的诅咒卡应失败")


## 错误处理: CurseManager未初始化
func test_injection_without_curse_manager() -> void:
	# Arrange: 创建没有CurseManager的注入系统
	var isolated_injection_system = CurseInjectionSystem.new(_card_manager, null)
	add_child(isolated_injection_system)

	# Act: 尝试注入
	var success = isolated_injection_system.inject_curse_by_enemy_action("curse_plague")

	# Assert: 验证注入失败
	assert_false(success, "CurseManager未初始化时注入应失败")

	# 清理
	isolated_injection_system.queue_free()


# ==================== 默认规则测试 ====================

## 默认规则: 验证注入规则映射
func test_default_injection_rules() -> void:
	# 敌人行动 → 弃牌堆
	var enemy_location = _injection_system.get_default_injection_location(
		CurseInjectionSystem.InjectionSource.ENEMY_ACTION
	)
	assert_string(enemy_location).is_equal("discard_pile")

	# 地图事件 → 牌库
	var map_location = _injection_system.get_default_injection_location(
		CurseInjectionSystem.InjectionSource.MAP_EVENT
	)
	assert_string(map_location).is_equal("library")

	# 卡牌效果 → 手牌
	var card_location = _injection_system.get_default_injection_location(
		CurseInjectionSystem.InjectionSource.CARD_EFFECT
	)
	assert_string(card_location).is_equal("hand")


# ==================== 卡牌类型标记测试 ====================

## 标记: 注入的诅咒卡正确标记 is_curse 属性
func test_curse_card_flag_set() -> void:
	# Arrange: 清空手牌
	_card_manager.hand_cards.clear()

	var test_curse_id = "curse_plague"

	# Act: 注入诅咒卡到手牌
	_injection_system.inject_curse_by_card_effect(test_curse_id)

	# Assert: 验证手牌中的卡被正确标记
	var injected_card = _card_manager.hand_cards[0]
	assert_true(injected_card.is_curse, "应标记 is_curse = true")
	assert_int(injected_card.curse_source).is_equal(CurseInjectionSystem.InjectionSource.CARD_EFFECT)


# ==================== 跨系统兼容性测试 ====================

## 兼容性: 与 CardManager 标准事件系统协同工作
func test_compatibility_with_card_manager() -> void:
	# Arrange: 清空弃牌堆
	_card_manager.discard_pile.clear()

	var event_data: Dictionary = {"card": null, "source": -1}

	# 监听 card_drawn 事件
	_card_manager.card_drawn.connect(func(card: Card) -> void:
		event_data["card"] = card
		event_data["source"] = card.curse_source if card.has("curse_source") else -1
	)

	var test_curse_id = "curse_plague"

	# Act: 注入诅咒卡
	_injection_system.inject_curse_by_enemy_action(test_curse_id)

	# Assert: 验证事件数据正确
	assert_not_null(event_data["card"], "card_drawn 事件应传递卡牌")
	assert_string(event_data["card"].data.card_id).is_equal(test_curse_id)
	assert_int(event_data["source"]).is_equal(CurseInjectionSystem.InjectionSource.ENEMY_ACTION)
