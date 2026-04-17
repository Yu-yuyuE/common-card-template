extends GdUnitTestSuite

# 测试覆盖：TroopActions 兵种卡牌行动处理
# - 返回 1 个成功事件
# - action_type 固定为 "TROOP"
# - action_id / caster 正确绑定
# - event.target 固定为 null（兵种召唤无需指定目标）
# - 有目标传入时也不绑定 target（兵种无目标语义）

# ---------------------------------------------------------------------------
# 测试辅助工厂
# ---------------------------------------------------------------------------

func _make_troop_card(id: String) -> CardData:
	var card := CardData.new(id)
	card.type = CardData.CardType.TROOP
	card.name = "测试兵种_%s" % id
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

# ---------------------------------------------------------------------------
# 正常路径
# ---------------------------------------------------------------------------

func test_troop_execute_returns_one_event() -> void:
	# Arrange
	var actions := TroopActions.new()
	var card := _make_troop_card("TR0001")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_int(events.size()).is_equal(1)

func test_troop_execute_event_is_success() -> void:
	# Arrange
	var actions := TroopActions.new()
	var card := _make_troop_card("TR0001")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_bool(events[0].success).is_true()

func test_troop_execute_sets_action_type_to_troop() -> void:
	# Arrange
	var actions := TroopActions.new()
	var card := _make_troop_card("TR0001")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_str(events[0].action_type).is_equal("TROOP")

func test_troop_execute_binds_action_id_from_card() -> void:
	# Arrange
	var actions := TroopActions.new()
	var card := _make_troop_card("TR_CAVALRY")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_str(events[0].action_id).is_equal("TR_CAVALRY")

func test_troop_execute_binds_caster_from_context() -> void:
	# Arrange
	var actions := TroopActions.new()
	var card := _make_troop_card("TR0001")
	var caster := BattleEntity.new("commander", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_that(events[0].caster).is_same(caster)

func test_troop_execute_target_is_always_null() -> void:
	# Arrange：兵种召唤无目标语义，event.target 应固定为 null
	var actions := TroopActions.new()
	var card := _make_troop_card("TR0001")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert
	assert_object(events[0].target).is_null()

func test_troop_execute_target_null_even_when_targets_provided() -> void:
	# Arrange：即使上下文中传入了目标列表，兵种召唤也不绑定 target
	var actions := TroopActions.new()
	var card := _make_troop_card("TR0001")
	var caster := BattleEntity.new("player", true)
	var enemy := BattleEntity.new("enemy_1", false)
	var ctx := _make_context(caster, [enemy] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert：兵种无目标语义，target 依然为 null
	assert_object(events[0].target).is_null()

func test_troop_execute_message_contains_card_name() -> void:
	# Arrange
	var actions := TroopActions.new()
	var card := _make_troop_card("TR0001")
	var caster := BattleEntity.new("player", true)
	var ctx := _make_context(caster, [] as Array[BattleEntity])

	# Act
	var events := actions.execute(card, ctx)

	# Assert：消息包含卡牌名称
	assert_str(events[0].message).contains(card.name)
