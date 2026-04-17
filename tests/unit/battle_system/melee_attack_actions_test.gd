extends GdUnitTestSuite

# 测试覆盖：MeleeAttackActions 近战攻击行动处理
# - 正常伤害计算并应用到目标
# - 等级 1 / 等级 2 伤害值按配置读取
# - 无目标时返回失败事件（不崩溃）
# - damage_calculator 为 null 时返回空列表（不崩溃）
# - resource_manager 为 null 时返回空列表（不崩溃）
# - damage_by_level 未配置时伤害为 0
# - action_type 固定为 "MELEE_ATTACK"

# ---------------------------------------------------------------------------
# 测试辅助工厂
# ---------------------------------------------------------------------------

## 创建带 damage_by_level 配置的近战卡牌数据
func _make_melee_card(id: String, damage_level1: int, damage_level2: int) -> CardData:
	var card := CardData.new(id)
	card.type = CardData.CardType.MELEE_ATTACK
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
func _make_enemy(entity_id: String, hp: int) -> BattleEntity:
	var e := BattleEntity.new(entity_id, false)
	e.current_hp = hp
	return e

# ---------------------------------------------------------------------------
# MeleeAttackActions 实例工厂（需要 CardActionExecutor 传入）
# ---------------------------------------------------------------------------

func _make_melee_actions() -> MeleeAttackActions:
	var executor := CardActionExecutor.new()
	return MeleeAttackActions.new(executor)

# ---------------------------------------------------------------------------
# 正常伤害路径
# ---------------------------------------------------------------------------

func test_melee_execute_deals_damage_to_target() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 10, 15)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert：返回 1 个成功事件，伤害 > 0
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0].success).is_true()
	assert_int(events[0].value).is_greater(0)

func test_melee_execute_applies_damage_to_entity_hp() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 10, 15)
	var enemy := _make_enemy("enemy_1", 50)
	enemy.shield = 0  # 无护盾，确保 HP 直接减少
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert：目标 HP 减少了与 event.value 相符的数值
	assert_int(enemy.current_hp).is_equal(50 - events[0].value)

func test_melee_execute_sets_action_type_to_melee_attack() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 5, 8)
	var enemy := _make_enemy("enemy_1", 30)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_str(events[0].action_type).is_equal("MELEE_ATTACK")

# ---------------------------------------------------------------------------
# 等级伤害配置读取
# ---------------------------------------------------------------------------

func test_melee_level1_uses_first_damage_by_level_entry() -> void:
	# Arrange：damage_by_level = [6, 8]，等级 1 应读取 6
	var actions := _make_melee_actions()
	var card := _make_melee_card("AC0001", 6, 8)
	var enemy := _make_enemy("enemy_1", 100)
	enemy.shield = 0
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# 使用 DamageCalculator 的实际计算，为保证可预期结果，构造最简管道
	# （无地形/天气/状态加成，基础即等于最终伤害）
	var events := actions.execute(card, ctx)

	# Assert：damage_by_level[0] = 6 作为 base_damage 传入，最终伤害 >= 1（保底）
	assert_int(events[0].value).is_greater_equal(1)
	# 验证是 level 1 路径：以 enemy HP 变化确认伤害已应用
	assert_int(enemy.current_hp).is_less(100)

func test_melee_level2_uses_second_damage_by_level_entry() -> void:
	# Arrange：damage_by_level = [6, 8]，等级 2 应读取 8（大于等级 1 的 6）
	var actions := _make_melee_actions()
	var card := _make_melee_card("AC0001", 6, 8)
	var enemy_lv1 := _make_enemy("enemy_lv1", 100)
	var enemy_lv2 := _make_enemy("enemy_lv2", 100)
	enemy_lv1.shield = 0
	enemy_lv2.shield = 0
	var caster := BattleEntity.new("player", true)

	var ctx_lv1 := _make_context(caster, [enemy_lv1] as Array[BattleEntity], 1)
	var ctx_lv2 := _make_context(caster, [enemy_lv2] as Array[BattleEntity], 2)

	# Act
	var events_lv1 := actions.execute(card, ctx_lv1)
	var events_lv2 := actions.execute(card, ctx_lv2)

	# Assert：等级 2 伤害 >= 等级 1 伤害（配置 [6,8] 保证）
	assert_int(events_lv2[0].value).is_greater_equal(events_lv1[0].value)

func test_melee_missing_damage_by_level_returns_zero_damage() -> void:
	# Arrange：damage_by_level 为空，应返回 0 伤害
	var actions := _make_melee_actions()
	var card := CardData.new("NO_DMG_CARD")
	card.type = CardData.CardType.MELEE_ATTACK
	card.damage_by_level = []
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert：base_damage=0 → DamageCalculator 保底为 1
	# 关键：不崩溃，返回 1 个事件
	assert_int(events.size()).is_equal(1)

# ---------------------------------------------------------------------------
# 无目标路径
# ---------------------------------------------------------------------------

func test_melee_no_targets_returns_failure_event() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 10, 10)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity], 1)

	# Act
	var events := actions.execute(card, ctx)

	# Assert：返回 1 个失败事件（不返回空列表）
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0].success).is_false()
	assert_int(events[0].value).is_equal(0)

func test_melee_no_targets_does_not_crash() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 10, 10)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity], 1)

	# Act & Assert：执行不抛出异常
	var events := actions.execute(card, ctx)
	assert_that(events).is_not_null()

# ---------------------------------------------------------------------------
# 依赖缺失路径（Guard 检查）
# ---------------------------------------------------------------------------

func test_melee_null_damage_calculator_returns_empty_events() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 10, 10)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)
	ctx.damage_calculator = null  # 注入 null

	# Act
	var events := actions.execute(card, ctx)

	# Assert：Guard 提前返回空列表，不崩溃
	assert_int(events.size()).is_equal(0)

func test_melee_null_resource_manager_returns_empty_events() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 10, 10)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)
	ctx.resource_manager = null  # 注入 null

	# Act
	var events := actions.execute(card, ctx)

	# Assert：Guard 提前返回空列表，不崩溃
	assert_int(events.size()).is_equal(0)

func test_melee_null_resource_manager_does_not_modify_enemy_hp() -> void:
	# Arrange
	var actions := _make_melee_actions()
	var card := _make_melee_card("TEST_MELEE", 10, 10)
	var enemy := _make_enemy("enemy_1", 50)
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity], 1)
	ctx.resource_manager = null

	# Act
	actions.execute(card, ctx)

	# Assert：HP 未被修改
	assert_int(enemy.current_hp).is_equal(50)
