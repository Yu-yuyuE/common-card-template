extends GdUnitTestSuite

# 测试覆盖：SkillActions 技能卡牌行动处理
# - 返回 1 个成功事件
# - action_type 固定为 "SKILL"
# - action_id / caster 正确绑定
# - 有目标时 event.target 指向第一个目标
# - 无目标时 event.target 为 null（不崩溃）

# ---------------------------------------------------------------------------
# 测试辅助工厂
# ---------------------------------------------------------------------------

func _make_skill_card(id: String) -> CardData:
	var card := CardData.new(id)
	card.type = CardData.CardType.SKILL
	card.name = "测试技能_%s" % id
	return card

func _make_context(
	caster: BattleEntity,
	targets: Array[BattleEntity]
) -> CardActionExecutor.CardSpecialContext:
	var ctx := CardActionExecutor.CardSpecialContext.new()
	ctx.caster = caster
	ctx.targets = targets
	ctx.card_level = 1
	return ctx

func _make_enemy(entity_id: String) -> BattleEntity:
	return BattleEntity.new(entity_id, false)

# ---------------------------------------------------------------------------
# 正常路径（有目标）
# ---------------------------------------------------------------------------

func test_skill_execute_returns_one_event() -> void:
	# Arrange
	var actions := SkillActions.new()
	var card := _make_skill_card("SK0001")
	var enemy := _make_enemy("enemy_1")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_int(events.size()).is_equal(1)

func test_skill_execute_event_is_success() -> void:
	# Arrange
	var actions := SkillActions.new()
	var card := _make_skill_card("SK0001")
	var enemy := _make_enemy("enemy_1")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_bool(events[0].success).is_true()

func test_skill_execute_sets_action_type_to_skill() -> void:
	# Arrange
	var actions := SkillActions.new()
	var card := _make_skill_card("SK0001")
	var enemy := _make_enemy("enemy_1")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_str(events[0].action_type).is_equal("SKILL")

func test_skill_execute_binds_action_id_from_card() -> void:
	# Arrange
	var actions := SkillActions.new()
	var card := _make_skill_card("SK_HEAL")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_str(events[0].action_id).is_equal("SK_HEAL")

func test_skill_execute_binds_caster_from_context() -> void:
	# Arrange
	var actions := SkillActions.new()
	var card := _make_skill_card("SK0001")
	var caster := BattleEntity.new("player_hero", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_that(events[0].caster).is_same(caster)

func test_skill_execute_with_target_binds_first_target() -> void:
	# Arrange
	var actions := SkillActions.new()
	var card := _make_skill_card("SK0001")
	var enemy := _make_enemy("enemy_1")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert：target 指向传入的第一个目标
	assert_that(events[0].target).is_same(enemy)

# ---------------------------------------------------------------------------
# 无目标路径
# ---------------------------------------------------------------------------

func test_skill_execute_with_no_targets_succeeds_without_crash() -> void:
	# Arrange：技能卡可以无目标（如自我增益）
	var actions := SkillActions.new()
	var card := _make_skill_card("SK_BUFF")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert：仍返回 1 个成功事件，target 为 null
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0].success).is_true()
	assert_object(events[0].target).is_null()
