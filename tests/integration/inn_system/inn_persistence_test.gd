## inn_persistence_test.gd
## InnPersistenceManager 集成测试套件
##
## 覆盖 Story inn-system-002 全部验收标准：
##   1. test_mark_visited_and_serialize         — AC1: 标记后序列化包含正确键值
##   2. test_serialize_both_flags               — AC1: 双标记（歇息+强化）均正确
##   3. test_deserialize_restores_state         — AC2: deserialize 后可正确取回状态
##   4. test_revisit_updates_state              — AC2: 重访（再次 mark_visited）覆盖旧值
##   5. test_unknown_node_returns_default       — AC2/AC3: 未访问节点返回默认值
##   6. test_empty_save_returns_false           — AC3: 空字典 deserialize 返回 false
##   7. test_corrupted_save_returns_false       — AC3: 损坏存档 deserialize 返回 false
##   8. test_corrupted_save_defaults_unvisited  — AC3: 损坏后 get_node_state 返回默认
##   9. test_save_stub_called_on_mark_visited   — save_stub 在 mark_visited 时被调用
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# 辅助：构建注入了桩函数的 InnPersistenceManager
# ---------------------------------------------------------------------------

## 创建一个带内存存档桩的管理器。
## 返回 [mgr, store_ref]，store_ref 为存储字典容器（Array 以便闭包引用）。
func _make_manager() -> Array:
	var store_ref: Array = [{}]  # 用 Array 包裹，让闭包可修改
	var mgr := InnPersistenceManager.new()
	mgr.save_stub = func(data: Dictionary) -> void:
		store_ref[0] = data
	mgr.load_stub = func() -> Dictionary:
		return store_ref[0]
	return [mgr, store_ref]


# ---------------------------------------------------------------------------
# 1. AC1 — 单标记保存
# ---------------------------------------------------------------------------

## mark_visited() 后 serialize() 应包含 visited_nodes 键且值正确
func test_mark_visited_and_serialize() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]

	mgr.mark_visited("node_001", true, false)

	var data: Dictionary = mgr.serialize()
	assert_bool(data.has("visited_nodes")).is_true()

	var nodes: Dictionary = data["visited_nodes"]
	assert_bool(nodes.has("node_001")).is_true()
	assert_bool(nodes["node_001"]["rest_used"]).is_true()
	assert_bool(nodes["node_001"]["fortify_used"]).is_false()


# ---------------------------------------------------------------------------
# 2. AC1 — 双标记均使用
# ---------------------------------------------------------------------------

## 歇息和强化均标记为已用时，两个字段应都为 true
func test_serialize_both_flags() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]

	mgr.mark_visited("node_002", true, true)

	var nodes: Dictionary = mgr.serialize()["visited_nodes"]
	assert_bool(nodes["node_002"]["rest_used"]).is_true()
	assert_bool(nodes["node_002"]["fortify_used"]).is_true()


# ---------------------------------------------------------------------------
# 3. AC2 — deserialize 恢复状态（模拟跨实例加载）
# ---------------------------------------------------------------------------

## 存档数据通过 deserialize() 加载后，get_node_state 应还原正确值
func test_deserialize_restores_state() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]
	var store_ref: Array = r[1]

	# 在第一个实例中标记
	mgr.mark_visited("node_003", false, true)

	# 创建第二个实例，从 store_ref 中恢复（模拟重新加载）
	var mgr2 := InnPersistenceManager.new()
	var ok: bool = mgr2.deserialize(store_ref[0])

	assert_bool(ok).is_true()
	var state: Dictionary = mgr2.get_node_state("node_003")
	assert_bool(state["rest_used"]).is_false()
	assert_bool(state["fortify_used"]).is_true()


# ---------------------------------------------------------------------------
# 4. AC2 — 重访节点不重置（后续 mark_visited 覆盖旧值）
# ---------------------------------------------------------------------------

## 同一节点两次 mark_visited 时，第二次值应覆盖第一次
func test_revisit_updates_state() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]

	# 第一次访问：仅歇息
	mgr.mark_visited("node_004", true, false)
	# 第二次重访：歇息+强化均用
	mgr.mark_visited("node_004", true, true)

	var state: Dictionary = mgr.get_node_state("node_004")
	assert_bool(state["rest_used"]).is_true()
	assert_bool(state["fortify_used"]).is_true()


# ---------------------------------------------------------------------------
# 5. AC2/AC3 — 未访问节点返回默认值
# ---------------------------------------------------------------------------

## 从未标记的节点 get_node_state 应返回 {rest_used: false, fortify_used: false}
func test_unknown_node_returns_default() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]

	var state: Dictionary = mgr.get_node_state("never_visited_node")
	assert_bool(state["rest_used"]).is_false()
	assert_bool(state["fortify_used"]).is_false()


# ---------------------------------------------------------------------------
# 6. AC3 — 空字典 deserialize 返回 false
# ---------------------------------------------------------------------------

## deserialize({}) 应返回 false 且状态为空
func test_empty_save_returns_false() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]

	var ok: bool = mgr.deserialize({})
	assert_bool(ok).is_false()


# ---------------------------------------------------------------------------
# 7. AC3 — 损坏存档（非 Dictionary 的 visited_nodes）返回 false
# ---------------------------------------------------------------------------

## visited_nodes 值为字符串（损坏格式）时，deserialize 应返回 false
func test_corrupted_save_returns_false() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]

	var corrupt: Dictionary = {"visited_nodes": "CORRUPT_STRING"}
	var ok: bool = mgr.deserialize(corrupt)
	assert_bool(ok).is_false()


# ---------------------------------------------------------------------------
# 8. AC3 — 损坏存档后，get_node_state 降级为默认未访问
# ---------------------------------------------------------------------------

## 损坏存档 deserialize 后，get_node_state 应返回全 false 默认值
func test_corrupted_save_defaults_unvisited() -> void:
	var r := _make_manager()
	var mgr: InnPersistenceManager = r[0]

	mgr.deserialize({"visited_nodes": "CORRUPT_STRING"})

	var state: Dictionary = mgr.get_node_state("node_999")
	assert_bool(state["rest_used"]).is_false()
	assert_bool(state["fortify_used"]).is_false()


# ---------------------------------------------------------------------------
# 9. save_stub 调用验证
# ---------------------------------------------------------------------------

## mark_visited() 必须触发 save_stub 调用（保证实时持久化）
func test_save_stub_called_on_mark_visited() -> void:
	var call_count: int = 0
	var mgr := InnPersistenceManager.new()
	mgr.save_stub = func(_data: Dictionary) -> void:
		call_count += 1

	mgr.mark_visited("node_010", true, false)

	assert_int(call_count).is_equal(1)
