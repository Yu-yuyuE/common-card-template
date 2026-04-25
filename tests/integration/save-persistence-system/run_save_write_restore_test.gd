## run_save_write_restore_test.gd
## RunSaveManager 集成测试套件
##
## 覆盖 Story 7-4 全部验收标准：
##   AC1 — test_run_save_restores_full_state
##   AC2 — test_battle_crash_restores_pre_battle_state
##   AC3 — test_two_heroes_saves_independent
##   AC4 — test_map_structure_persists
##
## 额外测试：
##   test_missing_fields_filled_with_defaults
##   test_save_stub_called_with_hero_id
##   test_empty_load_returns_empty_dict
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# 辅助：构建注入了内存桩的 RunSaveManager
# ---------------------------------------------------------------------------

## 创建带内存存档桩的管理器。
## 返回 [mgr, store_ref]；store_ref[0] 为 Dictionary，键为 hero_id。
func _make_manager() -> Array:
	var store_ref: Array = [{}]
	var mgr := RunSaveManager.new()
	mgr.save_stub = func(hero_id: String, data: Dictionary) -> bool:
		store_ref[0][hero_id] = data
		return true
	mgr.load_stub = func(hero_id: String) -> Dictionary:
		return store_ref[0].get(hero_id, {})
	mgr.has_save_stub = func(hero_id: String) -> bool:
		return store_ref[0].has(hero_id)
	return [mgr, store_ref]


# ---------------------------------------------------------------------------
# AC1 — save_run 后 load_run 应还原完整状态
# ---------------------------------------------------------------------------

## AC1：resources / campaignDeck / equipment / map / currentNode 完整还原
func test_run_save_restores_full_state() -> void:
	var r := _make_manager()
	var mgr: RunSaveManager = r[0]

	var data: Dictionary = {
		"resources": {
			"hp": 45,
			"maxHp": 50,
			"provisions": 120,
			"gold": 500,
			"actionPoints": 3,
			"maxActionPoints": 4,
		},
		"campaignDeck": {
			"version": 1,
			"cards": {"card_001": 2, "card_002": 1},
		},
		"equipment": [{"id": "EQ001", "slot": "weapon"}],
		"map": {
			"campaignId": "c1",
			"currentMap": 2,
			"currentNode": 5,
			"mapStructure": {},
			"visitedNodes": [1, 2, 3],
		},
		"battleState": null,
	}

	var ok: bool = mgr.save_run("cao_cao", data)
	assert_bool(ok).is_true()

	var loaded: Dictionary = mgr.load_run("cao_cao")

	# resources
	assert_int(loaded["resources"]["hp"]).is_equal(45)
	assert_int(loaded["resources"]["gold"]).is_equal(500)
	assert_int(loaded["resources"]["provisions"]).is_equal(120)
	assert_int(loaded["resources"]["actionPoints"]).is_equal(3)

	# campaignDeck
	assert_int(loaded["campaignDeck"]["version"]).is_equal(1)
	assert_int(loaded["campaignDeck"]["cards"]["card_001"]).is_equal(2)

	# equipment
	assert_int(loaded["equipment"].size()).is_equal(1)
	assert_str(loaded["equipment"][0]["id"]).is_equal("EQ001")

	# map / currentNode
	assert_int(loaded["map"]["currentNode"]).is_equal(5)
	assert_int(loaded["map"]["currentMap"]).is_equal(2)
	assert_str(loaded["map"]["campaignId"]).is_equal("c1")
	assert_int(loaded["map"]["visitedNodes"].size()).is_equal(3)


# ---------------------------------------------------------------------------
# AC2 — 战斗中崩溃恢复：load_run 后 battleState 为 null
# ---------------------------------------------------------------------------

## AC2：save_run 时 battleState 非 null → load_run 后 battleState 强制为 null
func test_battle_crash_restores_pre_battle_state() -> void:
	var r := _make_manager()
	var mgr: RunSaveManager = r[0]

	var data: Dictionary = {
		"battleState": {
			"enemyId": "enemy_001",
			"turn": 3,
			"playerHp": 30,
		},
	}

	mgr.save_run("cao_cao", data)
	var loaded: Dictionary = mgr.load_run("cao_cao")

	assert_object(loaded["battleState"]).is_null()


# ---------------------------------------------------------------------------
# AC3 — 两位武将存档互相独立
# ---------------------------------------------------------------------------

## AC3：分别保存 "cao_cao" 和 "liu_bei"，各自 load_run 不互相影响
func test_two_heroes_saves_independent() -> void:
	var r := _make_manager()
	var mgr: RunSaveManager = r[0]

	var cao_data: Dictionary = {
		"resources": {
			"hp": 40, "maxHp": 50, "provisions": 100,
			"gold": 300, "actionPoints": 3, "maxActionPoints": 4,
		},
	}
	var liu_data: Dictionary = {
		"resources": {
			"hp": 25, "maxHp": 40, "provisions": 80,
			"gold": 150, "actionPoints": 2, "maxActionPoints": 3,
		},
	}

	mgr.save_run("cao_cao", cao_data)
	mgr.save_run("liu_bei", liu_data)

	var cao_loaded: Dictionary = mgr.load_run("cao_cao")
	var liu_loaded: Dictionary = mgr.load_run("liu_bei")

	# 各自 HP 正确
	assert_int(cao_loaded["resources"]["hp"]).is_equal(40)
	assert_int(liu_loaded["resources"]["hp"]).is_equal(25)

	# 各自金币正确
	assert_int(cao_loaded["resources"]["gold"]).is_equal(300)
	assert_int(liu_loaded["resources"]["gold"]).is_equal(150)

	# heroId 互不干扰
	assert_str(cao_loaded["heroId"]).is_equal("cao_cao")
	assert_str(liu_loaded["heroId"]).is_equal("liu_bei")


# ---------------------------------------------------------------------------
# AC4 — mapStructure 完整持久化
# ---------------------------------------------------------------------------

## AC4：mapStructure 含节点类型+连接关系 → load_run 后完全一致
func test_map_structure_persists() -> void:
	var r := _make_manager()
	var mgr: RunSaveManager = r[0]

	var map_structure: Dictionary = {
		"nodes": {
			"1": {"type": "battle", "connections": [2, 3]},
			"2": {"type": "inn",    "connections": [4]},
			"3": {"type": "event",  "connections": [4]},
			"4": {"type": "boss",   "connections": []},
		},
	}

	var data: Dictionary = {
		"map": {
			"campaignId": "c1",
			"currentMap": 1,
			"currentNode": 1,
			"mapStructure": map_structure,
			"visitedNodes": [1],
		},
	}

	mgr.save_run("cao_cao", data)
	var loaded: Dictionary = mgr.load_run("cao_cao")

	var loaded_structure: Dictionary = loaded["map"]["mapStructure"]
	assert_bool(loaded_structure.has("nodes")).is_true()

	var nodes: Dictionary = loaded_structure["nodes"]
	assert_int(nodes.size()).is_equal(4)
	assert_str(nodes["1"]["type"]).is_equal("battle")
	assert_int(nodes["1"]["connections"].size()).is_equal(2)
	assert_str(nodes["2"]["type"]).is_equal("inn")
	assert_str(nodes["4"]["type"]).is_equal("boss")
	assert_int(nodes["4"]["connections"].size()).is_equal(0)


# ---------------------------------------------------------------------------
# 推荐测试 1 — 残缺字典 load_run 后含完整键
# ---------------------------------------------------------------------------

## 残缺字典（仅含 resources）save/load 后，所有默认键都存在
func test_missing_fields_filled_with_defaults() -> void:
	var r := _make_manager()
	var mgr: RunSaveManager = r[0]

	var partial: Dictionary = {
		"resources": {
			"hp": 10, "maxHp": 50, "provisions": 0,
			"gold": 0, "actionPoints": 1, "maxActionPoints": 4,
		},
	}

	mgr.save_run("cao_cao", partial)
	var loaded: Dictionary = mgr.load_run("cao_cao")

	assert_bool(loaded.has("version")).is_true()
	assert_bool(loaded.has("heroId")).is_true()
	assert_bool(loaded.has("campaignDeck")).is_true()
	assert_bool(loaded.has("equipment")).is_true()
	assert_bool(loaded.has("map")).is_true()
	assert_bool(loaded.has("battleState")).is_true()
	assert_bool(loaded.has("triggeredEvents")).is_true()
	assert_bool(loaded.has("campaignEnded")).is_true()


# ---------------------------------------------------------------------------
# 推荐测试 2 — save_stub 被调用且传入正确 hero_id
# ---------------------------------------------------------------------------

## save_run 调用时，save_stub 必须收到正确的 hero_id
func test_save_stub_called_with_hero_id() -> void:
	var received_id: Array = [""]
	var mgr := RunSaveManager.new()
	mgr.save_stub = func(hero_id: String, _data: Dictionary) -> bool:
		received_id[0] = hero_id
		return true

	mgr.save_run("liu_bei", {})

	assert_str(received_id[0]).is_equal("liu_bei")


# ---------------------------------------------------------------------------
# 推荐测试 3 — load_stub 返回 {} 时 load_run 返回空字典
# ---------------------------------------------------------------------------

## load_stub 返回 {} → load_run 应直接返回 {}，不补全默认值
func test_empty_load_returns_empty_dict() -> void:
	var mgr := RunSaveManager.new()
	# 默认 load_stub 返回 {}，无需额外注入

	var result: Dictionary = mgr.load_run("ghost_hero")

	assert_bool(result.is_empty()).is_true()
