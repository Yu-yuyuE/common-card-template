## map_navigator_test.gd
## MapNavigator 单元测试套件
##
## 覆盖范围：
##   - AC1: 前置节点未全部访问时 can_navigate_to() 返回 false
##   - AC2: calculate_move_cost() 在 [2, 2+floor(layer×0.5)] 闭区间内
##   - AC3: 粮草不足时 can_navigate_to() 返回 false
##   - AC4: navigate_to() 成功后节点标记为已访问
##   - AC5: on_boss_defeated() 恢复 50 粮草并发出 all_nodes_completed
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# MockNavigator：override 资源接口，隔离 ResourceManager 单例
# ---------------------------------------------------------------------------
class MockNavigator extends MapNavigator:
	## 当前模拟粮草数量
	var mock_provisions: int = 100
	## 累计已消耗的粮草（用于断言）
	var provisions_consumed: int = 0
	## 累计已恢复的粮草（用于断言）
	var provisions_restored: int = 0

	func _get_provisions() -> int:
		return mock_provisions

	func _consume_provisions(amount: int) -> void:
		mock_provisions -= amount
		provisions_consumed += amount

	func _restore_provisions(amount: int) -> void:
		mock_provisions += amount
		provisions_restored += amount


# ---------------------------------------------------------------------------
# 辅助方法
# ---------------------------------------------------------------------------

## 创建一个带有指定属性的 MapNode
func _make_node(
		id: String,
		type: MapNode.NodeType = MapNode.NodeType.BATTLE,
		cost: int = 2,
		prereqs: Array[String] = []
) -> MapNode:
	var node := MapNode.new()
	node.node_id = id
	node.node_type = type
	node.provisions_cost = cost
	node.prerequisites = prereqs
	return node


## 创建一个包含根节点的最小图，并返回配置好的 MockNavigator
func _make_navigator_with_graph() -> MockNavigator:
	var graph := MapGraph.new()
	var root := _make_node("root")
	graph.add_node(root)
	graph.root_node_id = "root"

	var nav := MockNavigator.new()
	nav.graph = graph
	nav.current_node_id = "root"
	# 根节点视为已访问（玩家起始位置）
	nav.visited_nodes.append("root")
	root.visited = true
	return nav


# ---------------------------------------------------------------------------
# AC1 — 前置节点检查
# ---------------------------------------------------------------------------

func test_navigator_prerequisites_not_met_returns_false() -> void:
	# Arrange
	var nav := _make_navigator_with_graph()
	var prereq_node := _make_node("prereq_01")
	var target_node := _make_node("target_01", MapNode.NodeType.BATTLE, 2, ["prereq_01"] as Array[String])
	nav.graph.add_node(prereq_node)
	nav.graph.add_node(target_node)
	# prereq_01 未被访问

	# Act
	var result: bool = nav.can_navigate_to("target_01")

	# Assert
	assert_bool(result).is_false()


func test_navigator_all_prerequisites_met_returns_true() -> void:
	# Arrange
	var nav := _make_navigator_with_graph()
	var prereq_node := _make_node("prereq_02")
	prereq_node.visited = true
	var target_node := _make_node("target_02", MapNode.NodeType.BATTLE, 2, ["prereq_02"] as Array[String])
	nav.graph.add_node(prereq_node)
	nav.graph.add_node(target_node)
	nav.visited_nodes.append("prereq_02")

	# Act
	var result: bool = nav.can_navigate_to("target_02")

	# Assert
	assert_bool(result).is_true()


# ---------------------------------------------------------------------------
# AC2 — calculate_move_cost 范围验证
# ---------------------------------------------------------------------------

func test_navigator_calculate_move_cost_non_boss_within_range() -> void:
	# Arrange
	var nav := MockNavigator.new()
	var node := _make_node("battle_node", MapNode.NodeType.BATTLE)
	var layer: int = 10
	var min_cost: int = 2
	var max_cost: int = 2 + int(layer * 0.5)  # = 7

	# Act & Assert — 运行 1000 次统计覆盖随机区间
	for i: int in range(1000):
		var cost: int = nav.calculate_move_cost(node, layer)
		assert_int(cost).is_greater_equal(min_cost)
		assert_int(cost).is_less_equal(max_cost)


func test_navigator_calculate_move_cost_layer1_always_base_cost() -> void:
	# Arrange：layer=1 时 max_extra=0，应固定返回 2
	var nav := MockNavigator.new()
	var node := _make_node("node_l1", MapNode.NodeType.BATTLE)
	var layer: int = 1

	# Act & Assert
	for i: int in range(100):
		var cost: int = nav.calculate_move_cost(node, layer)
		assert_int(cost).is_equal(2)


func test_navigator_calculate_move_cost_boss_fixed_ten() -> void:
	# Arrange
	var nav := MockNavigator.new()
	var boss_node := _make_node("boss_01", MapNode.NodeType.BOSS)

	# Act & Assert — Boss 节点固定返回 10，与层数无关
	for layer: int in [1, 5, 10, 15]:
		var cost: int = nav.calculate_move_cost(boss_node, layer)
		assert_int(cost).is_equal(10)


# ---------------------------------------------------------------------------
# AC3 — 粮草不足阻止导航
# ---------------------------------------------------------------------------

func test_navigator_insufficient_provisions_returns_false() -> void:
	# Arrange
	var nav := _make_navigator_with_graph()
	nav.mock_provisions = 5
	var expensive_node := _make_node("expensive_01", MapNode.NodeType.BATTLE, 8)
	nav.graph.add_node(expensive_node)
	# expensive_01 无前置节点，但粮草不足

	# Act
	var result: bool = nav.can_navigate_to("expensive_01")

	# Assert
	assert_bool(result).is_false()


func test_navigator_exact_provisions_allows_navigation() -> void:
	# Arrange：粮草恰好等于消耗，应允许导航
	var nav := _make_navigator_with_graph()
	nav.mock_provisions = 8
	var node := _make_node("exact_cost_01", MapNode.NodeType.BATTLE, 8)
	nav.graph.add_node(node)

	# Act
	var result: bool = nav.can_navigate_to("exact_cost_01")

	# Assert
	assert_bool(result).is_true()


# ---------------------------------------------------------------------------
# AC4 — navigate_to() 标记已访问
# ---------------------------------------------------------------------------

func test_navigator_navigate_to_marks_node_visited() -> void:
	# Arrange
	var nav := _make_navigator_with_graph()
	nav.mock_provisions = 100
	var target := _make_node("next_01", MapNode.NodeType.BATTLE, 2)
	nav.graph.add_node(target)
	nav.graph.add_edge("root", "next_01")

	# Act
	var success: bool = nav.navigate_to("next_01", 4)

	# Assert
	assert_bool(success).is_true()
	assert_bool(target.visited).is_true()
	assert_array(nav.visited_nodes).contains(["next_01"])


func test_navigator_navigate_to_updates_current_node_id() -> void:
	# Arrange
	var nav := _make_navigator_with_graph()
	nav.mock_provisions = 100
	var target := _make_node("next_02", MapNode.NodeType.BATTLE, 2)
	nav.graph.add_node(target)
	nav.graph.add_edge("root", "next_02")

	# Act
	nav.navigate_to("next_02", 4)

	# Assert
	assert_str(nav.current_node_id).is_equal("next_02")


func test_navigator_navigate_to_consumes_provisions() -> void:
	# Arrange：使用 Boss 节点（固定消耗 10，避免随机性）
	var nav := _make_navigator_with_graph()
	nav.mock_provisions = 100
	var boss := _make_node("boss_nav", MapNode.NodeType.BOSS, 10)
	nav.graph.add_node(boss)
	nav.graph.add_edge("root", "boss_nav")

	# Act
	nav.navigate_to("boss_nav", 5)

	# Assert
	assert_int(nav.provisions_consumed).is_equal(10)
	assert_int(nav.mock_provisions).is_equal(90)


func test_navigator_navigate_to_fails_without_prerequisites() -> void:
	# Arrange：目标有前置且前置未访问，navigate_to 应返回 false
	var nav := _make_navigator_with_graph()
	nav.mock_provisions = 100
	var locked := _make_node("locked_01", MapNode.NodeType.BATTLE, 2, ["missing_prereq"] as Array[String])
	nav.graph.add_node(locked)

	# Act
	var success: bool = nav.navigate_to("locked_01", 3)

	# Assert
	assert_bool(success).is_false()
	assert_array(nav.visited_nodes).not_contains(["locked_01"])


func test_navigator_navigate_to_emits_node_changed_signal() -> void:
	# Arrange
	var nav := _make_navigator_with_graph()
	nav.mock_provisions = 100
	var target := _make_node("signal_target", MapNode.NodeType.BATTLE, 2)
	nav.graph.add_node(target)
	nav.graph.add_edge("root", "signal_target")
	var monitor := monitor_signals(nav)

	# Act
	nav.navigate_to("signal_target", 2)

	# Assert
	assert_signal(monitor).is_emitted("node_changed")


# ---------------------------------------------------------------------------
# AC5 — on_boss_defeated() 粮草恢复与 signal
# ---------------------------------------------------------------------------

func test_navigator_on_boss_defeated_restores_provisions() -> void:
	# Arrange
	var nav := MockNavigator.new()
	nav.mock_provisions = 30

	# Act
	nav.on_boss_defeated()

	# Assert
	assert_int(nav.provisions_restored).is_equal(50)
	assert_int(nav.mock_provisions).is_equal(80)


func test_navigator_on_boss_defeated_emits_all_nodes_completed() -> void:
	# Arrange
	var nav := MockNavigator.new()
	var monitor := monitor_signals(nav)

	# Act
	nav.on_boss_defeated()

	# Assert
	assert_signal(monitor).is_emitted("all_nodes_completed")
