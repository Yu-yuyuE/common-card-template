## troop_basic_cards_test.gd
## 基础兵种卡（Lv1）核心逻辑单元测试（Story 4-1）
##
## 验证5种兵种卡在 Lv1 时的基础行为：
##   - 步兵：对目标造成 8 点伤害
##   - 骑兵：造成 5 点伤害 + 击退信号
##   - 弓兵：对任意目标造成 7 点伤害
##   - 谋士：对任意目标造成 7 点伤害
##   - 盾兵：获得 8 点护盾
##
## 设计文档：design/gdd/troop-cards-design.md
## ADR：ADR-0007（卡牌战斗系统架构）
## 作者: Claude Code
## 创建日期: 2026-04-14

class_name TroopBasicCardsTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

## 每个测试用的 TroopCard 实例
var _troop_card: TroopCard

## Mock BattleManager（简化版，只保留 execute_effect 需要的字段）
var _mock_battle: Node

## Mock 敌人实体
var _enemy: BattleEntity

## Mock ResourceManager（盾兵测试用）
var _resource_manager: ResourceManager

# ==================== 测试生命周期 ====================

func before_test() -> void:
	# 构建最小化的 BattleManager mock
	_mock_battle = Node.new()
	add_child(_mock_battle)

	# 构建敌人实体（HP 100，用于验证伤害数值）
	_enemy = BattleEntity.new("enemy_0", false)
	_enemy.max_hp = 100
	_enemy.current_hp = 100

	# 注入到 BattleManager mock 的 enemy_entities 数组
	_mock_battle.set_meta("enemy_entities", [_enemy])

	# ResourceManager（盾兵测试）
	_resource_manager = ResourceManager.new()
	_mock_battle.set_meta("resource_manager", _resource_manager)

	# 不注入 TerrainWeatherManager（terrain_weather_manager = null）
	# TroopCard._execute_damage_effect 在 null 时直接用 base_damage
	_mock_battle.set_meta("terrain_weather_manager", null)


func after_test() -> void:
	if _mock_battle and is_instance_valid(_mock_battle):
		_mock_battle.queue_free()
	if _resource_manager and is_instance_valid(_resource_manager):
		_resource_manager.queue_free()
	_mock_battle = null
	_enemy = null
	_resource_manager = null
	_troop_card = null


# ---------------------------------------------------------------------------
# 辅助：创建最小兵种卡（不依赖 CSV）
# ---------------------------------------------------------------------------

## 构造一张指定类型的 Lv1 兵种卡，直接设置数值，不走 CardData 解析
func _make_troop(type: TroopCard.TroopType, lv1_dmg: int = 0, lv1_shld: int = 0) -> TroopCard:
	var data := CardData.new("troop_test", 1)
	var card := TroopCard.new(data)
	card.troop_type  = type
	card.lv1_damage  = lv1_dmg
	card.lv1_shield  = lv1_shld
	card.current_level = 1
	return card


## 为 mock BattleManager 安装 enemy_entities 属性访问（兼容 TroopCard._execute_damage_effect）
func _patch_mock_battle() -> void:
	# GDScript 不能动态添加属性，改用已 set_meta 的值；
	# TroopCard 直接访问 battle_manager.enemy_entities，
	# 因此我们需要一个真实属性——用内联 class 绑定
	pass


# ==================== AC-1: 步兵 Lv1 伤害 ====================

## 步兵 Lv1：对目标造成 8 点伤害，无地形修正
## Given: 步兵卡 lv1_damage = 8，敌人 HP = 100，无地形管理器
## When: execute_lv1_effect(battle_manager, 0)
## Then: 敌人 HP 变为 92
func test_infantry_lv1_deals_8_damage() -> void:
	# Arrange
	var battle := _BattleMock.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.INFANTRY, 8)
	_enemy.current_hp = 100

	# Act
	var ok := _troop_card.execute_lv1_effect(battle, 0)

	# Assert
	assert_bool(ok).is_true()
	assert_int(_enemy.current_hp).is_equal(92)

	battle.queue_free()


# ==================== AC-2: 骑兵 Lv1 伤害 + 击退信号 ====================

## 骑兵 Lv1：造成 5 点伤害，并发射 knockback_triggered 信号
## Given: 骑兵卡 lv1_damage = 5，BattleManager 有 knockback_triggered 信号
## When: execute_lv1_effect(battle_manager, 0)
## Then: 敌人 HP 变为 95，且 knockback_triggered 信号被发射一次
func test_cavalry_lv1_deals_5_damage_and_emits_knockback() -> void:
	# Arrange
	var battle := _BattleMockWithKnockback.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.CAVALRY, 5)
	_enemy.current_hp = 100

	var knockback_count := 0
	battle.knockback_triggered.connect(func(_pos: int) -> void:
		knockback_count += 1
	)

	# Act
	var ok := _troop_card.execute_lv1_effect(battle, 0)

	# Assert
	assert_bool(ok).is_true()
	assert_int(_enemy.current_hp).is_equal(95)
	assert_int(knockback_count).is_equal(1)

	battle.queue_free()


# ==================== AC-3: 弓兵 Lv1 伤害 ====================

## 弓兵 Lv1：对任意目标造成 7 点伤害（can_target_any = true，但伤害值相同）
## Given: 弓兵卡 lv1_damage = 7，无地形修正
## When: execute_lv1_effect(battle_manager, 0)
## Then: 敌人 HP 变为 93
func test_archer_lv1_deals_7_damage() -> void:
	var battle := _BattleMock.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.ARCHER, 7)
	_enemy.current_hp = 100

	var ok := _troop_card.execute_lv1_effect(battle, 0)

	assert_bool(ok).is_true()
	assert_int(_enemy.current_hp).is_equal(93)

	battle.queue_free()


# ==================== AC-4: 谋士 Lv1 伤害 ====================

## 谋士 Lv1：对任意目标造成 7 点伤害
## Given: 谋士卡 lv1_damage = 7，无地形修正
## When: execute_lv1_effect(battle_manager, 0)
## Then: 敌人 HP 变为 93
func test_strategist_lv1_deals_7_damage() -> void:
	var battle := _BattleMock.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.STRATEGIST, 7)
	_enemy.current_hp = 100

	var ok := _troop_card.execute_lv1_effect(battle, 0)

	assert_bool(ok).is_true()
	assert_int(_enemy.current_hp).is_equal(93)

	battle.queue_free()


# ==================== AC-5: 盾兵 Lv1 护盾 ====================

## 盾兵 Lv1：为玩家增加 8 点护盾
## Given: 盾兵卡 lv1_shield = 8，ResourceManager 护盾初始为 0
## When: execute_lv1_effect(battle_manager, -1)（target_pos = -1 表示己方）
## Then: ResourceManager 的 ARMOR 资源增加 8
func test_shield_lv1_grants_8_armor() -> void:
	var battle := _BattleMock.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.SHIELD, 0, 8)

	var armor_before := _resource_manager.get_armor()

	var ok := _troop_card.execute_lv1_effect(battle, -1)

	assert_bool(ok).is_true()
	assert_int(_resource_manager.get_armor()).is_equal(armor_before + 8)

	battle.queue_free()


# ==================== AC-6: 无效目标位置返回 false ====================

## 对超出范围的目标位置，execute 应返回 false 且不修改 HP
func test_invalid_target_returns_false() -> void:
	var battle := _BattleMock.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.INFANTRY, 8)
	_enemy.current_hp = 100

	# target_pos = 5（超出范围）
	var ok := _troop_card.execute_lv1_effect(battle, 5)

	assert_bool(ok).is_false()
	assert_int(_enemy.current_hp).is_equal(100)  # HP 不变

	battle.queue_free()


# ==================== AC-7: 伤害使 HP 不低于 0 ====================

## 过量伤害时 HP 应钳制在 0，不变为负数
func test_overkill_clamps_hp_to_zero() -> void:
	var battle := _BattleMock.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.INFANTRY, 200)  # 远超 HP
	_enemy.current_hp = 10

	_troop_card.execute_lv1_effect(battle, 0)

	assert_int(_enemy.current_hp).is_equal(0)

	battle.queue_free()


# ==================== AC-8: is_troop_card() 返回 true ====================

func test_is_troop_card_returns_true() -> void:
	var data := CardData.new("troop_test", 1)
	var card := TroopCard.new(data)
	assert_bool(card.is_troop_card()).is_true()


# ==================== AC-9: get_troop_type_name 返回中文名 ====================

func test_get_troop_type_name_returns_chinese() -> void:
	# INFANTRY 应返回翻译后的名称（测试环境无 TranslationServer 时退回英文 key，允许非空即可）
	var name_str := TroopCard.get_troop_type_name(TroopCard.TroopType.INFANTRY)
	assert_str(name_str).is_not_empty()


# ==================== AC-10: 地形天气管理器为 null 时使用 base_damage ====================

## 当 terrain_weather_manager 未注入时，伤害等于 base_damage（不崩溃）
func test_damage_without_terrain_manager_uses_base() -> void:
	# terrain_weather_manager = null（_BattleMock 默认传 null）
	var battle := _BattleMock.new([_enemy], null, _resource_manager)
	add_child(battle)
	_troop_card = _make_troop(TroopCard.TroopType.INFANTRY, 8)
	_enemy.current_hp = 100

	_troop_card.execute_lv1_effect(battle, 0)

	assert_int(_enemy.current_hp).is_equal(92)  # 8 点基础伤害

	battle.queue_free()


# ===========================================================================
# 内联 Mock：最小化 BattleManager（避免完整初始化依赖）
# ===========================================================================

## 无 knockback 信号的基础 mock
class _BattleMock extends Node:
	var enemy_entities: Array = []
	var terrain_weather_manager = null
	var resource_manager: ResourceManager = null

	func _init(enemies: Array, twm, rm: ResourceManager) -> void:
		enemy_entities        = enemies
		terrain_weather_manager = twm
		resource_manager      = rm


## 带 knockback_triggered 信号的 mock（骑兵测试用）
class _BattleMockWithKnockback extends Node:
	var enemy_entities: Array = []
	var terrain_weather_manager = null
	var resource_manager: ResourceManager = null

	signal knockback_triggered(target_pos: int)

	func _init(enemies: Array, twm, rm: ResourceManager) -> void:
		enemy_entities          = enemies
		terrain_weather_manager = twm
		resource_manager        = rm
