## delete_run_save_test.gd
## RunSaveManager.delete_run() 单元测试套件
##
## 覆盖 Story 7-5（story-002-delete-run-save-on-campaign-end）验收标准：
##   AC1 — 战役结束（胜利或死亡）后 Run Save 文件被删除
##
## 测试函数：
##   1. test_delete_run_calls_stub             — delete_run 调用 delete_run_stub
##   2. test_delete_run_returns_true_on_success — stub 返回 true → delete_run 返回 true
##   3. test_delete_run_returns_false_on_failure — stub 返回 false → delete_run 返回 false
##   4. test_delete_run_passes_correct_hero_id  — stub 收到正确 hero_id
##   5. test_delete_nonexistent_run_returns_false — 默认 stub（无存档）返回 false
##   6. test_delete_run_after_save_removes_record — save 后 delete，has_run_save 应为 false
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# 辅助：构建带完整内存桩的 RunSaveManager
# ---------------------------------------------------------------------------

## 创建带内存存档桩（save/load/has/delete）的管理器。
## [br][return] [mgr, store_ref] — store_ref[0] 为内存存档 Dictionary
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
	mgr.delete_run_stub = func(hero_id: String) -> bool:
		if store_ref[0].has(hero_id):
			store_ref[0].erase(hero_id)
			return true
		return false
	return [mgr, store_ref]


# ---------------------------------------------------------------------------
# AC1 — delete_run 调用 stub 并传递调用
# ---------------------------------------------------------------------------

## delete_run_stub 在 delete_run() 被调用时触发
func test_delete_run_calls_stub() -> void:
	var call_count: Array = [0]
	var mgr := RunSaveManager.new()
	mgr.delete_run_stub = func(_hero_id: String) -> bool:
		call_count[0] += 1
		return true

	mgr.delete_run("cao_cao")

	assert_int(call_count[0]).is_equal(1)


# ---------------------------------------------------------------------------
# AC1 — 成功删除时返回 true
# ---------------------------------------------------------------------------

## delete_run_stub 返回 true → delete_run 返回 true（存档已删除）
func test_delete_run_returns_true_on_success() -> void:
	var mgr := RunSaveManager.new()
	mgr.delete_run_stub = func(_hero_id: String) -> bool:
		return true

	var result: bool = mgr.delete_run("cao_cao")

	assert_bool(result).is_true()


# ---------------------------------------------------------------------------
# AC1 — 删除失败时返回 false（不崩溃）
# ---------------------------------------------------------------------------

## delete_run_stub 返回 false → delete_run 返回 false（不抛异常）
func test_delete_run_returns_false_on_failure() -> void:
	var mgr := RunSaveManager.new()
	mgr.delete_run_stub = func(_hero_id: String) -> bool:
		return false

	var result: bool = mgr.delete_run("cao_cao")

	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC1 — delete_run 传入正确 hero_id
# ---------------------------------------------------------------------------

## delete_run_stub 收到的 hero_id 应与调用时传入一致
func test_delete_run_passes_correct_hero_id() -> void:
	var received_id: Array = [""]
	var mgr := RunSaveManager.new()
	mgr.delete_run_stub = func(hero_id: String) -> bool:
		received_id[0] = hero_id
		return true

	mgr.delete_run("liu_bei")

	assert_str(received_id[0]).is_equal("liu_bei")


# ---------------------------------------------------------------------------
# AC1 — 默认 stub（无存档）返回 false
# ---------------------------------------------------------------------------

## 未注入 delete_run_stub 时，默认实现应返回 false（不崩溃）
func test_delete_nonexistent_run_returns_false() -> void:
	var mgr := RunSaveManager.new()
	# 使用默认 delete_run_stub（no-op，返回 false）

	var result: bool = mgr.delete_run("ghost_hero")

	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC1 — 存档后删除：has_run_save 应为 false
# ---------------------------------------------------------------------------

## save_run 后调用 delete_run，has_run_save 应返回 false（存档已移除）
func test_delete_run_after_save_removes_record() -> void:
	var r := _make_manager()
	var mgr: RunSaveManager = r[0]

	# 先保存
	mgr.save_run("cao_cao", {"resources": {"hp": 45, "maxHp": 50,
		"provisions": 100, "gold": 200, "actionPoints": 3, "maxActionPoints": 4}})
	assert_bool(mgr.has_run_save("cao_cao")).is_true()

	# 删除（战役结束）
	var deleted: bool = mgr.delete_run("cao_cao")
	assert_bool(deleted).is_true()

	# 验证已不存在
	assert_bool(mgr.has_run_save("cao_cao")).is_false()
