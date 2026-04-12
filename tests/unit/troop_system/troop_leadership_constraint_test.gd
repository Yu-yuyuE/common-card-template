## troop_leadership_constraint_test.gd
## 统帅值约束与卡组管理集成测试 (Story 4-4)
## 验证兵种卡数量不超过武将统帅值，升级不占用额外槽位
## 作者: Claude Code
## 创建日期: 2026-04-12

class_name TroopLeadershipConstraintTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 测试用的 BattleManager 实例
var _battle_manager: BattleManager

## 测试用的 HeroManager 实例
var _hero_manager: HeroManager

## 测试用的 ResourceManager 实例
var _resource_manager: ResourceManager

## 测试用的 CardManager 实例
var _card_manager: CardManager

## 测试用的 Mock EnemyManager 节点
var _mock_enemy_manager: Node

# ==================== 测试生命周期 ====================

func before_test() -> void:
	# 创建 ResourceManager
	_resource_manager = ResourceManager.new()
	_resource_manager._ready()

	# 创建 HeroManager
	_hero_manager = HeroManager.new()
	_hero_manager._ready()

	# 创建 CardManager
	_card_manager = CardManager.new()
	_card_manager.battle_manager = _battle_manager
	_card_manager.hero_manager = _hero_manager

	# 创建 BattleManager
	_battle_manager = BattleManager.new()
	_battle_manager.hero_manager = _hero_manager
	_battle_manager.resource_manager = _resource_manager
	_battle_manager.card_manager = _card_manager
	_battle_manager.player_entity = BattleEntity.new("曹操", true)  # 统帅值6

	# 添加到场景树
	add_child(_resource_manager)
	add_child(_hero_manager)
	add_child(_battle_manager)


func after_test() -> void:
	# 清理测试实例
	if _battle_manager and is_instance_valid(_battle_manager):
		_battle_manager.queue_free()
	if _resource_manager and is_instance_valid(_resource_manager):
		_resource_manager.queue_free()
	if _hero_manager and is_instance_valid(_hero_manager):
		_hero_manager.queue_free()
	if _card_manager and is_instance_valid(_card_manager):
		_card_manager.queue_free()
	if _mock_enemy_manager and is_instance_valid(_mock_enemy_manager):
		_mock_enemy_manager.queue_free()
	_battle_manager = null
	_resource_manager = null
	_hero_manager = null
	_card_manager = null
	_mock_enemy_manager = null


# ==================== AC-1: 统帅槽上限验证 ====================

## AC-1: 统帅值为3时，3张兵种卡后不能再添加
## Given: 武将统帅值为 3，卡组中已有 3 张兵种卡（2张Lv1，1张Lv3）
## When: 调用 can_add_troop_card
## Then: 返回 false
func test_leadership_limit_reached() -> void:
	# Arrange: 设置武将为统帅值3的夏侯惇
	_battle_manager.player_entity.id = "夏侯惇"
	# 确保HeroManager正确加载了统帅值
	assert_int(_hero_manager.get_leadership("夏侯惇")).is_equal(3)

	# 创建3张兵种卡
	var card1 = Card.new(CardData.new("TroopCard", 1, "步兵卡", 1))
	card1._is_troop_card = true
	card1._troop_type = TroopCard.TroopType.INFANTRY

	var card2 = Card.new(CardData.new("TroopCard", 1, "骑兵卡", 1))
	card2._is_troop_card = true
	card2._troop_type = TroopCard.TroopType.CAVALRY

	var card3 = Card.new(CardData.new("TroopCard", 1, "弓兵卡", 1))
	card3._is_troop_card = true
	card3._troop_type = TroopCard.TroopType.ARCHER
	card3._current_level = 3  # 模拟Lv3卡

	# 添加到卡组
	_card_manager.hand_cards.append(card1)
	_card_manager.hand_cards.append(card2)
	_card_manager.hand_cards.append(card3)

	# Act: 检查是否可以添加第4张兵种卡
	var can_add = _card_manager.can_add_troop_card(_card_manager.hand_cards)

	# Assert: 应该返回false，因为已达到统帅上限
	assert_false(can_add, "当统帅值为3且已有3张兵种卡时，不应允许添加第4张卡")


# ==================== AC-2: 升级不占用额外槽位 ====================

## AC-2: 升级到Lv3后统帅槽占用数量不变
## Given: 武将统帅值为 3，卡组中有 2 张兵种卡，其中一张从 Lv2 升为 Lv3
## When: 升级完成后，重新统计统帅槽占用
## Then: 占用数量依然为 2，此时 can_add_troop_card 返回 true
func test_upgrade_does_not_increase_slot() -> void:
	# Arrange: 设置武将为统帅值3的夏侯惇
	_battle_manager.player_entity.id = "夏侯惇"
	assert_int(_hero_manager.get_leadership("夏侯惇")).is_equal(3)

	# 创建2张兵种卡
	var card1 = Card.new(CardData.new("TroopCard", 1, "步兵卡", 1))
	card1._is_troop_card = true
	card1._troop_type = TroopCard.TroopType.INFANTRY
	card1._current_level = 2  # 模拟Lv2卡

	var card2 = Card.new(CardData.new("TroopCard", 1, "骑兵卡", 1))
	card2._is_troop_card = true
	card2._troop_type = TroopCard.TroopType.CAVALRY
	card2._current_level = 1  # 模拟Lv1卡

	# 添加到卡组
	_card_manager.hand_cards.append(card1)
	_card_manager.hand_cards.append(card2)

	# Act: 升级卡1到Lv3
	card1._current_level = 3

	# 检查升级后能否添加新卡
	var can_add_after_upgrade = _card_manager.can_add_troop_card(_card_manager.hand_cards)

	# Assert: 升级后统帅槽占用仍为2，应能添加第3张卡
	assert_true(can_add_after_upgrade, "升级到Lv3后统帅槽占用数量应不变，仍可添加第3张卡")


# ==================== AC-3: 不同统帅值验证 ====================

## AC-3: 统帅值为6时可以添加6张兵种卡
## Given: 武将统帅值为 6，卡组中已有 5 张兵种卡
## When: 调用 can_add_troop_card
## Then: 返回 true
func test_leadership_6_can_add_6_cards() -> void:
	# Arrange: 设置武将为统帅值6的曹操
	_battle_manager.player_entity.id = "曹操"
	assert_int(_hero_manager.get_leadership("曹操")).is_equal(6)

	# 创建5张兵种卡
	for i in range(5):
		var card = Card.new(CardData.new("TroopCard", 1, "兵种卡%d" % i, 1))
		card._is_troop_card = true
		card._troop_type = TroopCard.TroopType.INFANTRY
		_card_manager.hand_cards.append(card)

	# Act: 检查是否可以添加第6张兵种卡
	var can_add = _card_manager.can_add_troop_card(_card_manager.hand_cards)

	# Assert: 应该返回true，因为未达到统帅上限
	assert_true(can_add, "当统帅值为6且只有5张兵种卡时，应允许添加第6张卡")


# ==================== AC-4: 非兵种卡不计入统帅槽 ====================

## AC-4: 非兵种卡不计入统帅值约束
## Given: 武将统帅值为 3，卡组中有 2 张兵种卡和 2 张非兵种卡
## When: 调用 can_add_troop_card
## Then: 返回 true（仍可添加1张兵种卡）
func test_non_troop_cards_not_counted() -> void:
	# Arrange: 设置武将为统帅值3的夏侯惇
	_battle_manager.player_entity.id = "夏侯惇"
	assert_int(_hero_manager.get_leadership("夏侯惇")).is_equal(3)

	# 创建2张兵种卡
	var troop_card1 = Card.new(CardData.new("TroopCard", 1, "步兵卡", 1))
	troop_card1._is_troop_card = true
	troop_card1._troop_type = TroopCard.TroopType.INFANTRY

	var troop_card2 = Card.new(CardData.new("TroopCard", 1, "骑兵卡", 1))
	troop_card2._is_troop_card = true
	troop_card2._troop_type = TroopCard.TroopType.CAVALRY

	# 创建2张非兵种卡
	var attack_card = Card.new(CardData.new("AttackCard", 1, "攻击卡", 1))
	attack_card._is_troop_card = false

	var spell_card = Card.new(CardData.new("SpellCard", 1, "法术卡", 1))
	spell_card._is_troop_card = false

	# 添加到卡组
	_card_manager.hand_cards.append(troop_card1)
	_card_manager.hand_cards.append(troop_card2)
	_card_manager.hand_cards.append(attack_card)
	_card_manager.hand_cards.append(spell_card)

	# Act: 检查是否可以添加第3张兵种卡
	var can_add = _card_manager.can_add_troop_card(_card_manager.hand_cards)

	# Assert: 应该返回true，因为非兵种卡不计入统帅槽
	assert_true(can_add, "非兵种卡不应计入统帅槽占用，仍可添加第3张兵种卡")


# ==================== AC-5: 空卡组验证 ====================

## AC-5: 空卡组时可以添加兵种卡
## Given: 武将统帅值为 3，卡组为空
## When: 调用 can_add_troop_card
## Then: 返回 true
func test_empty_deck_can_add_card() -> void:
	# Arrange: 设置武将为统帅值3的夏侯惇
	_battle_manager.player_entity.id = "夏侯惇"
	assert_int(_hero_manager.get_leadership("夏侯惇")).is_equal(3)

	# Act: 检查是否可以添加兵种卡（空卡组）
	var can_add = _card_manager.can_add_troop_card(_card_manager.hand_cards)

	# Assert: 应该返回true
	assert_true(can_add, "空卡组时应允许添加兵种卡")


# ==================== AC-6: 获取分支选项验证 ====================

## AC-6: 获取弓兵Lv3分支选项
## Given: 调用 get_troop_branch_options("ArcherCard")
## When: 获取分支列表
## Then: 返回6个分支选项
func test_get_archer_branch_options() -> void:
	# Arrange: 使用弓兵卡ID
	var branch_options = _card_manager.get_troop_branch_options("ArcherCard")

	# Assert: 弓兵应有6个Lv3分支
	assert_int(branch_options.size()).is_equal(6)

	# 验证分支ID和名称
	var expected_names = ["连弩兵", "火矢兵", "投石兵", "弩车兵", "火兵", "猎人"]
	for i in range(6):
		assert_string(branch_options[i]["name"]).is_equal(expected_names[i])


# ==================== AC-7: 检查Lv3卡是否可再升级 ====================

## AC-7: 检查Lv3兵种卡是否不能再升级
## Given: 卡为Lv3
## When: 调用 is_troop_card_max_level
## Then: 返回 true
func test_is_max_level_lv3() -> void:
	# Arrange: 创建Lv3兵种卡
	var lv3_card = Card.new(CardData.new("TroopCard", 1, "兵种卡", 1))
	lv3_card._is_troop_card = true
	lv3_card._current_level = 3

	# Act: 检查是否已达到最大等级
	var is_max = _card_manager.is_troop_card_max_level(lv3_card)

	# Assert: 应该返回true
	assert_true(is_max, "Lv3兵种卡不应再升级")


# ==================== AC-8: 检查Lv2卡是否可升级 ====================

## AC-8: 检查Lv2兵种卡是否可以升级
## Given: 卡为Lv2
## When: 调用 is_troop_card_max_level
## Then: 返回 false
func test_is_max_level_lv2() -> void:
	# Arrange: 创建Lv2兵种卡
	var lv2_card = Card.new(CardData.new("TroopCard", 1, "兵种卡", 1))
	lv2_card._is_troop_card = true
	lv2_card._current_level = 2

	# Act: 检查是否已达到最大等级
	var is_max = _card_manager.is_troop_card_max_level(lv2_card)

	# Assert: 应该返回false
	assert_false(is_max, "Lv2兵种卡可以升级到Lv3")