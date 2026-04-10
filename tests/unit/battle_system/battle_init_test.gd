extends GdUnitTestSuite

# AC-1: 1v3战场初始化
# AC-2: 玩家资源同步
# AC-3: 信号发射

func test_ac1_ac2_ac3_battle_initialization() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 4)
	rm.apply_damage(5, true) # HP=45
	
	var signal_received = false
	var stages = 0
	var enemies = []
	bm.battle_started.connect(func(total: int, ens: Array[BattleEntity]):
		signal_received = true
		stages = total
		enemies = ens
	)
	
	var stage_config = {
		"stage_count": 2,
		"enemies": [
			{"id": "e1", "hp": 20, "ap": 1},
			{"id": "e2", "hp": 25, "ap": 1},
			{"id": "e3", "hp": 30, "ap": 2},
			{"id": "e4", "hp": 100, "ap": 5} # 应该被丢弃
		]
	}
	
	bm.setup_battle(stage_config, rm)
	
	# AC-1: 1v3战场初始化，只取前3个敌人
	assert_int(bm.enemy_entities.size()).is_equal(3)
	assert_str(bm.enemy_entities[0].id).is_equal("e1")
	assert_str(bm.enemy_entities[2].id).is_equal("e3")
	
	# AC-2: 玩家资源同步
	assert_int(bm.player_entity.current_hp).is_equal(45)
	assert_int(bm.player_entity.max_hp).is_equal(50)
	assert_int(bm.player_entity.max_action_points).is_equal(4)
	assert_int(bm.player_entity.action_points).is_equal(4)
	assert_int(bm.player_entity.shield).is_equal(0)
	
	# AC-3: 信号发射
	assert_bool(signal_received).is_true()
	assert_int(stages).is_equal(2)
	assert_int(enemies.size()).is_equal(3)

func test_ac1_edge_case_one_enemy() -> void:
	var bm = BattleManager.new()
	var rm = ResourceManager.new()
	rm.init_hero(50, 3)
	
	var stage_config = {
		"enemies": [
			{"id": "solo_boss", "hp": 100, "ap": 3}
		]
	}
	
	bm.setup_battle(stage_config, rm)
	assert_int(bm.enemy_entities.size()).is_equal(1)
	assert_str(bm.enemy_entities[0].id).is_equal("solo_boss")
