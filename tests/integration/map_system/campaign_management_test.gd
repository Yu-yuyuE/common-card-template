## campaign_management_test.gd
## CampaignManager 集成测试套件
##
## 覆盖范围（9 个测试）：
##   1. test_campaign_structure_constants         — 常量值验证
##   2. test_on_boss_defeated_advances_map        — Boss 击败推进地图索引
##   3. test_on_boss_defeated_last_map_advances_campaign — 最后一张地图推进战役
##   4. test_on_boss_defeated_emits_all_nodes_completed_signal — 信号发出
##   5. test_on_boss_defeated_last_campaign_emits_game_completed — 最后战役通关
##   6. test_start_new_campaign_calls_save_meta_stub  — 存档桩被调用
##   7. test_start_new_campaign_calls_clear_run_stub  — 清档桩被调用
##   8. test_save_campaign_progress_returns_valid_dict — 序列化格式正确
##   9. test_load_campaign_progress_restores_state    — 反序列化恢复状态
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# 辅助：构建一个注入了桩函数的 CampaignManager
# ---------------------------------------------------------------------------

## 创建一个带测试桩的 CampaignManager，返回 [mgr, call_log] 两个值。
## call_log 字典记录桩的调用情况：
##   call_log["save_meta"]  : Array — 每次调用 save_meta_stub 追加 {key, value}
##   call_log["clear_run"]  : int   — clear_run_stub 被调用的次数
func _make_manager() -> Array:
	var call_log: Dictionary = {
		"save_meta": [] as Array,
		"clear_run": 0,
	}
	var mgr := CampaignManager.new()
	mgr.save_meta_stub = func(key: String, value: Variant) -> void:
		call_log["save_meta"].append({"key": key, "value": value})
	mgr.clear_run_stub = func() -> void:
		call_log["clear_run"] = call_log["clear_run"] + 1
	return [mgr, call_log]


# ---------------------------------------------------------------------------
# 1. 常量值验证
# ---------------------------------------------------------------------------

func test_campaign_structure_constants() -> void:
	# Arrange & Act
	var mgr := CampaignManager.new()

	# Assert — 结构常量须与 GDD 一致
	assert_int(CampaignManager.MAPS_PER_CAMPAIGN).is_equal(3)
	assert_int(CampaignManager.TOTAL_CAMPAIGNS).is_equal(3)
	# 确认实例也可访问（非 class-only）
	assert_int(mgr.MAPS_PER_CAMPAIGN).is_equal(3)
	assert_int(mgr.TOTAL_CAMPAIGNS).is_equal(3)


# ---------------------------------------------------------------------------
# 2. on_boss_defeated 在中间地图时推进 map_index
# ---------------------------------------------------------------------------

func test_on_boss_defeated_advances_map() -> void:
	# Arrange
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	mgr.current_campaign_index = 0
	mgr.current_map_index = 0  # 第 1 张地图

	# Act
	mgr.on_boss_defeated()

	# Assert — 地图索引前进 1，战役索引不变
	assert_int(mgr.current_map_index).is_equal(1)
	assert_int(mgr.current_campaign_index).is_equal(0)


# ---------------------------------------------------------------------------
# 3. 最后一张地图 Boss 击败时推进战役
# ---------------------------------------------------------------------------

func test_on_boss_defeated_last_map_advances_campaign() -> void:
	# Arrange：当前在第 1 个战役的最后一张地图（index = MAPS_PER_CAMPAIGN-1）
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	mgr.current_campaign_index = 0
	mgr.current_map_index = CampaignManager.MAPS_PER_CAMPAIGN - 1

	# Act
	mgr.on_boss_defeated()

	# Assert — 地图索引归零，战役索引前进 1
	assert_int(mgr.current_map_index).is_equal(0)
	assert_int(mgr.current_campaign_index).is_equal(1)


# ---------------------------------------------------------------------------
# 4. on_boss_defeated 发出 all_nodes_completed 信号
# ---------------------------------------------------------------------------

func test_on_boss_defeated_emits_all_nodes_completed_signal() -> void:
	# Arrange
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	mgr.current_campaign_index = 0
	mgr.current_map_index = 0
	var monitor := monitor_signals(mgr)

	# Act
	mgr.on_boss_defeated()

	# Assert
	assert_signal(monitor).is_emitted("all_nodes_completed")


# ---------------------------------------------------------------------------
# 5. 最后一个战役最后一张地图 Boss 击败时发出 game_completed
# ---------------------------------------------------------------------------

func test_on_boss_defeated_last_campaign_emits_game_completed() -> void:
	# Arrange：置于最后一个战役的最后一张地图
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	mgr.current_campaign_index = CampaignManager.TOTAL_CAMPAIGNS - 1
	mgr.current_map_index = CampaignManager.MAPS_PER_CAMPAIGN - 1
	var monitor := monitor_signals(mgr)

	# Act
	mgr.on_boss_defeated()

	# Assert — 游戏通关信号必须发出
	assert_signal(monitor).is_emitted("game_completed")
	# 战役索引超出范围（表示已通关）
	assert_int(mgr.current_campaign_index).is_equal(CampaignManager.TOTAL_CAMPAIGNS)


# ---------------------------------------------------------------------------
# 6. start_new_campaign 调用 save_meta_stub
# ---------------------------------------------------------------------------

func test_start_new_campaign_calls_save_meta_stub() -> void:
	# Arrange
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	var call_log: Dictionary = result[1]

	# Act
	mgr.start_new_campaign("liu_bei")

	# Assert — save_meta_stub 至少被调用 1 次，且包含 hero_id 记录
	var saved: Array = call_log["save_meta"]
	assert_int(saved.size()).is_greater(0)

	# 验证 hero_id 已被写入
	var has_hero_key: bool = false
	for entry: Dictionary in saved:
		if entry["key"] == "hero_id" and entry["value"] == "liu_bei":
			has_hero_key = true
			break
	assert_bool(has_hero_key).is_true()


# ---------------------------------------------------------------------------
# 7. start_new_campaign 调用 clear_run_stub
# ---------------------------------------------------------------------------

func test_start_new_campaign_calls_clear_run_stub() -> void:
	# Arrange
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	var call_log: Dictionary = result[1]

	# Act
	mgr.start_new_campaign("cao_cao")

	# Assert — clear_run_stub 恰好被调用 1 次
	assert_int(call_log["clear_run"]).is_equal(1)


# ---------------------------------------------------------------------------
# 8. save_campaign_progress 返回合法字典
# ---------------------------------------------------------------------------

func test_save_campaign_progress_returns_valid_dict() -> void:
	# Arrange
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	mgr.current_campaign_index = 1
	mgr.current_map_index = 2

	# Act
	var data: Dictionary = mgr.save_campaign_progress()

	# Assert — 字典包含两个必要键，值与状态一致
	assert_bool(data.has("campaign_index")).is_true()
	assert_bool(data.has("map_index")).is_true()
	assert_int(int(data["campaign_index"])).is_equal(1)
	assert_int(int(data["map_index"])).is_equal(2)


# ---------------------------------------------------------------------------
# 9. load_campaign_progress 恢复状态
# ---------------------------------------------------------------------------

func test_load_campaign_progress_restores_state() -> void:
	# Arrange
	var result := _make_manager()
	var mgr: CampaignManager = result[0]
	# 初始值不同，确保是从数据中恢复的
	mgr.current_campaign_index = 0
	mgr.current_map_index = 0
	var saved_data: Dictionary = {
		"campaign_index": 2,
		"map_index": 1,
	}

	# Act
	var ok: bool = mgr.load_campaign_progress(saved_data)

	# Assert — 返回 true 且状态完全从字典中恢复
	assert_bool(ok).is_true()
	assert_int(mgr.current_campaign_index).is_equal(2)
	assert_int(mgr.current_map_index).is_equal(1)
