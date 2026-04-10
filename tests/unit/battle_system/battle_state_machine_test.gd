extends GdUnitTestSuite

func test_ac1_state_machine_flow() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 4)
	
	var phases_emitted = []
	bm.phase_changed.connect(func(phase):
		phases_emitted.append(phase)
	)
	
	var stage_config = {
		"enemies": [
			{"id": "e1", "hp": 20, "ap": 1}
		]
	}
	
	bm.setup_battle(stage_config, rm)
	
	# setup_battle 末尾会调用 _start_player_turn()，经历 START -> DRAW -> PLAY
	assert_int(bm.current_phase).is_equal(BattleManager.BattlePhase.PLAYER_PLAY)
	phases_emitted.clear()
	
	# Act: 模拟玩家点击结束回合
	bm.end_player_turn()
	
	# Assert: 因为有活着的敌人，阶段流转会是 PLAYER_END -> ENEMY_TURN -> PHASE_CHECK -> PLAYER_START -> PLAYER_DRAW -> PLAYER_PLAY
	assert_array(phases_emitted).contains_exactly([
		BattleManager.BattlePhase.PLAYER_END,
		BattleManager.BattlePhase.ENEMY_TURN,
		BattleManager.BattlePhase.PHASE_CHECK,
		BattleManager.BattlePhase.PLAYER_START,
		BattleManager.BattlePhase.PLAYER_DRAW,
		BattleManager.BattlePhase.PLAYER_PLAY
	])
	assert_int(bm.current_phase).is_equal(BattleManager.BattlePhase.PLAYER_PLAY)

func test_ac2_enemy_skips_dead_targets() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 4)
	
	var stage_config = {
		"enemies": [
			{"id": "e1", "hp": 10},
			{"id": "e2", "hp": 10},
			{"id": "e3", "hp": 10}
		]
	}
	bm.setup_battle(stage_config, rm)
	
	# 手动将第二个敌人 HP 设为 0 (模拟已死)
	bm.enemy_entities[1].current_hp = 0
	
	var actions = []
	bm.enemy_action_mock_triggered.connect(func(eid):
		actions.append(eid)
	)
	
	# Act
	bm.end_player_turn()
	
	# Assert: e2 被跳过
	assert_array(actions).contains_exactly(["e1", "e3"])

func test_ac3_signals_emitted() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 4)
	
	var turn_signals = []
	var phase_signals = []
	
	bm.turn_started.connect(func(is_player): turn_signals.append(is_player))
	bm.phase_changed.connect(func(phase): phase_signals.append(phase))
	
	var stage_config = {
		"enemies": [{"id": "e1", "hp": 10}]
	}
	
	# Act
	bm.setup_battle(stage_config, rm)
	
	# Assert
	assert_array(turn_signals).contains_exactly([true]) # 第一轮玩家回合开始
	assert_array(phase_signals).contains_exactly([
		BattleManager.BattlePhase.PLAYER_START,
		BattleManager.BattlePhase.PLAYER_DRAW,
		BattleManager.BattlePhase.PLAYER_PLAY
	])
