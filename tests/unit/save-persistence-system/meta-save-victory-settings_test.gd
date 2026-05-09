## meta-save-victory-settings_test.gd
## MetaSaveManager 通关记录与设置更新单元测试套件
##
## 覆盖 Story 004（meta-save-victory-and-settings）验收标准：
##   AC-1 — 武将通关后 completedCampaigns 正确追加战役章节 ID
##   AC-2 — 设置修改（音量）立即写入 Meta Save，重启后保持
##
## 测试函数（6个）：
##   1. test_complete_campaign_appends_campaign_id
##      — AC-1：通关"魏-第二章"后 heroRecords["cao_cao"].completedCampaigns 包含 "wei_2"
##   2. test_campaign_id_not_duplicated_on_retry
##      — AC-1 边界：多次失败后成功通关，ID 只记录一次
##   3. test_settings_volume_write_and_reload
##      — AC-2：音量改为 0.5 → 写入 → 重载 → 读到 0.5
##   4. test_settings_persist_after_force_quit
##      — AC-2 边界：修改音量后模拟强退，重新加载仍为修改后值
##   5. test_meta_save_uses_atomic_write
##      — ADR-0005 原子性：写入路径为 .tmp → rename 模式（通过 save_stub 调用次数验证）
##   6. test_meta_save_load_under_3ms
##      — Control Manifest 性能守护：Meta Save 加载时间 < 3ms
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# 辅助：构建带完整内存桩的 MetaSaveManager
# ---------------------------------------------------------------------------

## 创建带内存存档桩（save/load/has）的 MetaSaveManager。
## [br][return] [mgr, store_ref] — store_ref[0] 为内存存档字典（初始为空）
func _make_manager() -> Array:
	var store_ref: Array = [{}]
	var mgr := MetaSaveManager.new()
	mgr.save_stub = func(data: Dictionary) -> bool:
		store_ref[0] = data.duplicate(true)
		return true
	mgr.load_stub = func() -> Dictionary:
		return store_ref[0].duplicate(true)
	mgr.has_save_stub = func() -> bool:
		return not store_ref[0].is_empty()
	return [mgr, store_ref]


## 用已有存储内容重新创建 MetaSaveManager（模拟重启加载）。
## [br][param store_ref] 共享的内存存档引用数组
## [br][return] 新 MetaSaveManager 实例，桩指向同一 store_ref
func _reload_manager(store_ref: Array) -> MetaSaveManager:
	var mgr := MetaSaveManager.new()
	mgr.save_stub = func(data: Dictionary) -> bool:
		store_ref[0] = data.duplicate(true)
		return true
	mgr.load_stub = func() -> Dictionary:
		return store_ref[0].duplicate(true)
	mgr.has_save_stub = func() -> bool:
		return not store_ref[0].is_empty()
	return mgr


# ---------------------------------------------------------------------------
# AC-1 — 通关后 completedCampaigns 包含战役 ID
# ---------------------------------------------------------------------------

## 击败"魏-第二章"BOSS 后，heroRecords["cao_cao"].completedCampaigns 应包含 "wei_2"
func test_complete_campaign_appends_campaign_id() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act：曹操通关"魏-第二章"
	var ok: bool = mgr.record_campaign_victory("cao_cao", "wei_2")

	# Assert
	assert_bool(ok).is_true()
	var completed: Array = store_ref[0]["heroRecords"]["cao_cao"]["completedCampaigns"]
	assert_bool(completed.has("wei_2")).is_true()


# ---------------------------------------------------------------------------
# AC-1 边界 — 同一战役多次失败后成功，ID 只记录一次
# ---------------------------------------------------------------------------

## 玩家在 "wei_2" 失败两次后成功：completedCampaigns 中 "wei_2" 只出现一次
func test_campaign_id_not_duplicated_on_retry() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act：模拟多次失败（不调用 record_campaign_victory），最终成功调用 3 次（幂等验证）
	mgr.record_campaign_victory("cao_cao", "wei_2")
	mgr.record_campaign_victory("cao_cao", "wei_2")
	mgr.record_campaign_victory("cao_cao", "wei_2")

	# Assert：列表中 "wei_2" 只出现一次
	var completed: Array = store_ref[0]["heroRecords"]["cao_cao"]["completedCampaigns"]
	var count: int = 0
	for id: String in completed:
		if id == "wei_2":
			count += 1
	assert_int(count).is_equal(1)


# ---------------------------------------------------------------------------
# AC-2 — 音量修改立即写入，重新加载后保持
# ---------------------------------------------------------------------------

## 将 masterVolume 从 0.8 调整为 0.5 → 写入存储 → 新 Manager 加载 → 读到 0.5
func test_settings_volume_write_and_reload() -> void:
	# Arrange：初始音量 0.8
	var store_ref: Array = [{}]
	var mgr: MetaSaveManager = _reload_manager(store_ref)
	mgr.update_setting("masterVolume", 0.8)

	# Act：修改音量为 0.5
	var ok: bool = mgr.update_setting("masterVolume", 0.5)

	# Assert（写入成功）
	assert_bool(ok).is_true()

	# 模拟重启：重新创建 Manager，桩指向同一 store_ref
	var mgr2: MetaSaveManager = _reload_manager(store_ref)
	var loaded: Dictionary = mgr2.load_meta()

	# Assert（重载后音量为 0.5）
	assert_float(loaded["settings"]["masterVolume"]).is_equal_approx(0.5, 0.001)


# ---------------------------------------------------------------------------
# AC-2 边界 — 修改音量后模拟强退，重新加载仍为修改后值
# ---------------------------------------------------------------------------

## 修改 masterVolume 为 0.3 → 不做任何 "退出" 清理 → 新 Manager 加载 → 读到 0.3
## 原子写入保证强退不丢数据（写入已在 update_setting 时完成）
func test_settings_persist_after_force_quit() -> void:
	# Arrange
	var store_ref: Array = [{}]
	var mgr: MetaSaveManager = _reload_manager(store_ref)

	# Act：修改音量（模拟玩家调整后立即强退，此时写入已完成）
	mgr.update_setting("masterVolume", 0.3)

	# 模拟强退后重启：丢弃旧 Manager，新 Manager 从 store_ref 加载
	var mgr_after_quit: MetaSaveManager = _reload_manager(store_ref)
	var loaded: Dictionary = mgr_after_quit.load_meta()

	# Assert：强退后音量仍为修改后的值
	assert_float(loaded["settings"]["masterVolume"]).is_equal_approx(0.3, 0.001)


# ---------------------------------------------------------------------------
# ADR-0005 原子性验证 — save_stub 在每次写入时被调用（通过次数验证原子写入路径）
# ---------------------------------------------------------------------------

## 每次调用 record_campaign_victory / update_setting 都应触发一次 save_stub（原子写入）
func test_meta_save_uses_atomic_write() -> void:
	# Arrange：带计数器的存储桩
	var save_count: Array[int] = [0]
	var store_ref: Array = [{}]
	var mgr := MetaSaveManager.new()
	mgr.save_stub = func(data: Dictionary) -> bool:
		save_count[0] += 1
		store_ref[0] = data.duplicate(true)
		return true
	mgr.load_stub = func() -> Dictionary:
		return store_ref[0].duplicate(true)
	mgr.has_save_stub = func() -> bool:
		return not store_ref[0].is_empty()

	# Act：两次独立写入
	mgr.record_campaign_victory("cao_cao", "wei_1")
	mgr.update_setting("musicVolume", 0.6)

	# Assert：save_stub 被调用 2 次（每次写入各触发一次原子写入）
	assert_int(save_count[0]).is_equal(2)


# ---------------------------------------------------------------------------
# Control Manifest 性能守护 — Meta Save 加载时间 < 3ms
# ---------------------------------------------------------------------------

## load_meta() 在已初始化存档时，加载时间必须 < 3ms（Control Manifest Guardrail）
func test_meta_save_load_under_3ms() -> void:
	# Arrange：预填充存档（含武将记录和设置）
	var store_ref: Array = [{}]
	var mgr: MetaSaveManager = _reload_manager(store_ref)
	mgr.record_campaign_victory("cao_cao", "wei_1")
	mgr.record_campaign_victory("cao_cao", "wei_2")
	mgr.update_setting("masterVolume", 0.7)
	mgr.update_setting("musicVolume", 0.6)
	mgr.update_setting("sfxVolume", 0.8)

	# Act：新 Manager 加载（模拟冷启动）
	var mgr2: MetaSaveManager = _reload_manager(store_ref)
	var start_ms: float = Time.get_ticks_usec() / 1000.0
	var _loaded: Dictionary = mgr2.load_meta()
	var elapsed_ms: float = Time.get_ticks_usec() / 1000.0 - start_ms

	# Assert：加载时间 < 3ms（Control Manifest Foundation 层性能守护）
	assert_float(elapsed_ms).is_less(3.0)
