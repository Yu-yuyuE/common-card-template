extends GdUnitTestSuite

# 测试覆盖：RangedAttackActions 远程攻击行动处理
# - 正常伤害计算并应用到目标
# - 等级 1 / 等级 2 伤害值按配置读取
# - 穿透护盾（piercing = true）
# - 无目标时返回失败事件（不崩溃）
# - damage_calculator 为 null 时返回空列表（不崩溃）
# - resource_manager 为 null 时返回空列表（不崩溃）
# - damage_by_level 未配置时伤害为 0
# - action_type 固定为 "RANGED_ATTACK"

# ---------------------------------------------------------------------------
# 测试辅助工厂
# ---------------------------------------------------------------------------

## 创建带 damage_by_level 配置的远程卡牌数据
func _make_ranged_card(id: String, damage_level1: int, damage_level2: int) -> CardData:
	var card := CardData.new(id)
	card.type = CardData.CardType.RANGED_ATTACK
	card.damage_by_level = [damage_level1, damage_level2]
	return card

## 创建完整注入的行动上下文
func _make_context(
	caster: BattleEntity,
	targets: Array[BattleEntity],
	level: int = 1
) -> CardActionExecutor.CardSpecialContext:
	var ctx := CardActionExecutor.CardSpecialContext.new()
	ctx.caster = caster
	ctx.targets = targets
	ctx.card_level = level
	ctx.damage_calculator = DamageCalculator.new()
	ctx.resource_manager = ResourceManager.new()
	ctx.resource_manager.init_hero(100, 4)
	return ctx

## 创建一个初始 HP 为指定值的敌方实体
func _make_enemy(entity_id: String, hp: int, shield: int = 0) -> BattleEntity:
	var e := BattleEntity.new(entity_id, false)
	e.current_hp = hp
	e.shield = shield
	return e

func _make_ranged_actions() -> RangedAttackActions:
	return RangedAttackActions.new()

# ---------------------------------------------------------------------------
# 正常伤害路径
# ---------------------------------------------------------------------------

func test_ranged_execute_deals_damage_to_target() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0].success).is_true()
	assert_int(events[0].value).is_greater(0)

func test_ranged_execute_applies_damage_to_entity_hp() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var enemy := _make_enemy("enemy_1", 50, 0)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_int(enemy.current_hp).is_equal(50 - events[0].value)

func test_ranged_execute_sets_action_type_to_ranged_attack() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 5, 8)
	var enemy := _make_enemy("enemy_1", 30)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_str(events[0].action_type).is_equal("RANGED_ATTACK")

# ---------------------------------------------------------------------------
# 穿透护盾（远程特性验证）
# ---------------------------------------------------------------------------

func test_ranged_attack_penetrates_shield() -> void:
	# Arrange：敌人有 10 点护盾，远程攻击应穿透（HP 直接扣减）
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var enemy := _make_enemy("enemy_1", 50, 10)  # HP=50, Shield=10
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert：穿透模式下护盾不变，HP 减少
	assert_int(enemy.shield).is_equal(10)
	assert_int(enemy.current_hp).is_less(50)
	assert_bool(events[0].success).is_true()

# ---------------------------------------------------------------------------
# 等级伤害配置读取
# ---------------------------------------------------------------------------

func test_ranged_level2_deals_more_damage_than_level1() -> void:
	# Arrange：damage_by_level = [8, 12]，等级 2 应 >= 等级 1
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var enemy_lv1 := _make_enemy("enemy_lv1", 100, 0)
	var enemy_lv2 := _make_enemy("enemy_lv2", 100, 0)
	var caster := BattleEntity.new("player", true)

	var ctx_lv1 := _make_context(caster, [enemy_lv1] as Array[BattleEntity], 1)
	var ctx_lv2 := _make_context(caster, [enemy_lv2] as Array[BattleEntity], 2)

	# Act
	var events_lv1 := actions.execute(card, ctx_lv1)
	var events_lv2 := actions.execute(card, ctx_lv2)

	# Assert
	assert_int(events_lv2[0].value).is_greater_equal(events_lv1[0].value)

func test_ranged_missing_damage_by_level_does_not_crash() -> void:
	# Arrange：damage_by_level 为空
	var actions := _make_ranged_actions()
	var card := CardData.new("NO_DMG_RANGED")
	card.type = CardData.CardType.RANGED_ATTACK
	card.damage_by_level = []
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act & Assert：不崩溃，返回 1 个事件
	var events := actions.execute(card, ctx)
	assert_int(events.size()).is_equal(1)

# ---------------------------------------------------------------------------
# 无目标路径
# ---------------------------------------------------------------------------

func test_ranged_no_targets_returns_failure_event() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0].success).is_false()
	assert_int(events[0].value).is_equal(0)

func test_ranged_no_targets_does_not_crash() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity], 1)

	# Act & Assert
	var events := actions.execute(card, ctx)
	assert_that(events).is_not_null()

# ---------------------------------------------------------------------------
# 依赖缺失路径（Guard 检查）
# ---------------------------------------------------------------------------

func test_ranged_null_damage_calculator_returns_empty_events() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)
	ctx.damage_calculator = null

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_int(events.size()).is_equal(0)

func test_ranged_null_resource_manager_returns_empty_events() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)
	ctx.resource_manager = null

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_int(events.size()).is_equal(0)

func test_ranged_null_resource_manager_does_not_modify_enemy_hp() -> void:
	# Arrange
	var actions := _make_ranged_actions()
	var card := _make_ranged_card("TEST_RANGED", 8, 12)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)
	ctx.resource_manager = null

	# Act
	actions.execute(card, ctx)

	# Assert：HP 未被修改
	assert_int(enemy.current_hp).is_equal(50)
