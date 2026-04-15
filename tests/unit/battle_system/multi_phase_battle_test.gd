extends GdUnitTestSuite

# Story 5-9: 多阶段战斗与胜负判定
# AC-1: 阶段切换资源继承（手牌保留/护盾清零/AP回满/新敌人）
# AC-2: 玩家死亡失败判定
# AC-3: 胜利结算 removed_cards 回归 draw_pile

# ---------------------------------------------------------------------------
# 测试辅助
# ---------------------------------------------------------------------------

func _make_rm(hp: int = 50, max_ap: int = 4) -> ResourceManager:
	var rm := ResourceManager.new()
	rm.init_hero(hp, max_ap)
	return rm

func _make_card_data(n: int) -> Array[CardData]:
	var arr: Array[CardData] = []
	for i in range(n):
		arr.append(CardData.new("card_%d" % i))
	return arr

# 构建一个2阶段战斗配置：各阶段1个敌人，平铺排列
func _two_phase_config(rm: ResourceManager) -> Dictionary:
	return {
		"stage_count": 2,
		"enemies": [
			{"id": "enemy_s1", "hp": 5, "shield": 0, "max_shield": 5, "ap": 1},
			{"id": "enemy_s2", "hp": 5, "shield": 0, "max_shield": 5, "ap": 1},
		],
		"deck": _make_card_data(5),
	}

# ---------------------------------------------------------------------------
# AC-1: 阶段切换资源继承
# ---------------------------------------------------------------------------

func test_ac1_phase_transition_preserves_hand_clears_shield_resets_ap() -> void:
	# Arrange: 2 阶段战斗
	var rm := _make_rm(50, 4)
	var bm := BattleManager.new()
	bm.setup_battle(_two_phase_config(rm), rm)
	# 此时已进入 PLAYER_PLAY 阶段，手牌已抽满（最多5张）
	# 模拟玩家打出一些牌，手牌剩 3 张
	while bm.card_manager.hand_cards.size() > 3:
		bm.card_manager.hand_cards.pop_back()
	var hand_size_before := bm.card_manager.hand_cards.size()
	# 给玩家加护盾
	bm.player_entity.shield = 10
	# 消耗一些AP
	bm.player_entity.action_points = 1

	# 击败第一阶段所有敌人
	for e in bm.enemy_entities:
		e.current_hp = 0

	# Act: 触发阶段检查 → 应切换到第2阶段
	bm._check_phase()

	# Assert: 手牌保留
	assert_int(bm.card_manager.hand_cards.size()).is_equal(hand_size_before)
	# 护盾清零
	assert_int(bm.player_entity.shield).is_equal(0)
	# AP 回满
	assert_int(bm.player_entity.action_points).is_equal(bm.player_entity.max_action_points)
	# 当前阶段变为 2
	assert_int(bm.current_stage).is_equal(2)
	# 新一批敌人已生成
	assert_bool(bm.enemy_entities.size() > 0).is_true()

func test_ac1_new_enemies_generated_in_stage_2() -> void:
	var rm := _make_rm(50, 4)
	var bm := BattleManager.new()
	bm.setup_battle(_two_phase_config(rm), rm)
	# 记录第一阶段敌人ID
	var stage1_id := bm.enemy_entities[0].id
	# 全灭第一阶段
	for e in bm.enemy_entities:
		e.current_hp = 0
	bm._check_phase()
	# 第二阶段敌人ID应不同
	assert_str(bm.enemy_entities[0].id).is_not_equal(stage1_id)

# ---------------------------------------------------------------------------
# AC-2: 玩家死亡失败判定
# ---------------------------------------------------------------------------

func test_ac2_player_death_triggers_battle_fail() -> void:
	# Arrange
	var rm := _make_rm(50, 4)
	var bm := BattleManager.new()
	bm.setup_battle({"enemies": [{"id": "e1", "hp": 10}]}, rm)
	# 玩家HP归零
	bm.player_entity.current_hp = 0
	# 记录战斗结束时的phase（失败后应为NONE）
	var phase_after := bm.current_phase

	# Act
	bm._check_phase()

	# Assert: 战斗结束（NONE 阶段）
	assert_int(bm.current_phase).is_equal(BattleManager.BattlePhase.NONE)

func test_ac2_player_death_wins_over_enemy_death_same_check() -> void:
	# 设计规则：玩家HP归零 → 失败优先，即使敌人同回合也归零
	var rm := _make_rm(50, 4)
	var bm := BattleManager.new()
	bm.setup_battle({"stage_count": 1, "enemies": [{"id": "e1", "hp": 10}]}, rm)
	bm.player_entity.current_hp = 0
	for e in bm.enemy_entities:
		e.current_hp = 0
	# Act
	bm._check_phase()
	# Assert: 仍是失败（NONE）
	assert_int(bm.current_phase).is_equal(BattleManager.BattlePhase.NONE)

# ---------------------------------------------------------------------------
# AC-3: 胜利结算 removed_cards 回归 draw_pile
# ---------------------------------------------------------------------------

func test_ac3_removed_cards_return_to_draw_pile_on_victory() -> void:
	# Arrange: 单阶段战斗，removed_cards 中预先放 2 张
	var rm := _make_rm(50, 4)
	var bm := BattleManager.new()
	bm.setup_battle({"stage_count": 1, "enemies": [{"id": "e1", "hp": 10}], "deck": _make_card_data(3)}, rm)
	# 往 removed_cards 放 2 张
	bm.card_manager.removed_cards.append(Card.new(CardData.new("removed_1", 1, true)))
	bm.card_manager.removed_cards.append(Card.new(CardData.new("removed_2", 1, true)))
	var draw_before := bm.card_manager.draw_pile.size()
	# 击败所有敌人
	for e in bm.enemy_entities:
		e.current_hp = 0

	# Act
	bm._check_phase()

	# Assert: removed_cards 清空，draw_pile 增加 2 张
	assert_int(bm.card_manager.removed_cards.size()).is_equal(0)
	assert_int(bm.card_manager.draw_pile.size()).is_equal(draw_before + 2)

func test_ac3_victory_ends_battle_phase_none() -> void:
	var rm := _make_rm(50, 4)
	var bm := BattleManager.new()
	bm.setup_battle({"stage_count": 1, "enemies": [{"id": "e1", "hp": 10}]}, rm)
	for e in bm.enemy_entities:
		e.current_hp = 0
	bm._check_phase()
	assert_int(bm.current_phase).is_equal(BattleManager.BattlePhase.NONE)

# ---------------------------------------------------------------------------
# 边缘情况：单阶段战斗直接胜利（不需要切换）
# ---------------------------------------------------------------------------

func test_single_stage_victory_no_extra_stage_transition() -> void:
	var rm := _make_rm(50, 4)
	var bm := BattleManager.new()
	bm.setup_battle({"stage_count": 1, "enemies": [{"id": "e1", "hp": 10}]}, rm)
	assert_int(bm.total_stages).is_equal(1)
	for e in bm.enemy_entities:
		e.current_hp = 0
	bm._check_phase()
	# 只有1阶段，胜利后直接结束，不应切换到第2阶段
	assert_int(bm.current_stage).is_equal(1)
	assert_int(bm.current_phase).is_equal(BattleManager.BattlePhase.NONE)
