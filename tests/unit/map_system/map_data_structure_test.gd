## map_data_structure_test.gd
## 地图数据结构单元测试套件
##
## 覆盖范围：
##   - AC1: 验证7种 NodeType 枚举值完整定义
##   - AC2: 树形父子节点关系通过 prerequisites 正确建立
##   - AC3: CampaignMap 必要字段全部存在且可读写
##   - AC4: MapNode 所有字段存在，初始值正确（visited=false, available=false）
##   - MapGraph 添加节点与边后可正确查询
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite

# ============================================================
# AC1 — NodeType 枚举完整性
# ============================================================

func test_all_node_types_defined_battle_exists() -> void:
	# Arrange / Act / Assert
	assert_int(MapNode.NodeType.BATTLE).is_equal(0)


func test_all_node_types_defined_seven_values() -> void:
	# Arrange
	var all_types: Array[int] = [
		MapNode.NodeType.BATTLE,
		MapNode.NodeType.ELITE,
		MapNode.NodeType.BOSS,
		MapNode.NodeType.SHOP,
		MapNode.NodeType.INN,
		MapNode.NodeType.BARRACKS,
		MapNode.NodeType.EVENT,
	]
	# Assert：必须恰好7种，且值各不相同
	assert_int(all_types.size()).is_equal(7)
	for i: int in range(all_types.size()):
		for j: int in range(all_types.size()):
			if i != j:
				assert_bool(all_types[i] != all_types[j]).is_true()


# ============================================================
# AC4(部分) — MapNode 字段完整性
# ============================================================

func test_map_node_fields_complete_node_id_exists() -> void:
	# Arrange
	var node := MapNode.new()
	# Act
	node.node_id = "test_node"
	# Assert
	assert_str(node.node_id).is_equal("test_node")


func test_map_node_fields_complete_node_type_exists() -> void:
	# Arrange
	var node := MapNode.new()
	# Act
	node.node_type = MapNode.NodeType.SHOP
	# Assert
	assert_int(node.node_type).is_equal(MapNode.NodeType.SHOP)


func test_map_node_fields_complete_position_exists() -> void:
	# Arrange
	var node := MapNode.new()
	# Act
	node.position = Vector2(100.0, 200.0)
	# Assert
	assert_that(node.position).is_equal(Vector2(100.0, 200.0))


func test_map_node_fields_complete_prerequisites_exists() -> void:
	# Arrange
	var node := MapNode.new()
	# Act
	node.prerequisites.append("parent_01")
	# Assert
	assert_int(node.prerequisites.size()).is_equal(1)
	assert_str(node.prerequisites[0]).is_equal("parent_01")


func test_map_node_fields_complete_provisions_cost_exists() -> void:
	# Arrange
	var node := MapNode.new()
	# Act
	node.provisions_cost = 3
	# Assert
	assert_int(node.provisions_cost).is_equal(3)


# ============================================================
# AC4 — MapNode 初始状态
# ============================================================

func test_map_node_initial_state_visited_is_false() -> void:
	# Arrange / Act
	var node := MapNode.new()
	# Assert
	assert_bool(node.visited).is_false()


func test_map_node_initial_state_available_is_false() -> void:
	# Arrange / Act
	var node := MapNode.new()
	# Assert
	assert_bool(node.available).is_false()


func test_map_node_initial_state_provisions_cost_is_zero() -> void:
	# Arrange / Act
	var node := MapNode.new()
	# Assert
	assert_int(node.provisions_cost).is_equal(0)


func test_map_node_initial_state_prerequisites_is_empty() -> void:
	# Arrange / Act
	var node := MapNode.new()
	# Assert
	assert_int(node.prerequisites.size()).is_equal(0)


# ============================================================
# MapGraph — 添加节点与边
# ============================================================

func test_map_graph_add_node_and_edge_node_queryable() -> void:
	# Arrange
	var graph := MapGraph.new()
	var node := MapNode.new()
	node.node_id = "n1"
	node.node_type = MapNode.NodeType.BATTLE
	# Act
	graph.add_node(node)
	# Assert
	assert_that(graph.get_node("n1")).is_not_null()
	assert_str(graph.get_node("n1").node_id).is_equal("n1")


func test_map_graph_add_node_and_edge_unknown_node_returns_null() -> void:
	# Arrange
	var graph := MapGraph.new()
	# Act / Assert
	assert_that(graph.get_node("nonexistent")).is_null()


func test_map_graph_add_node_and_edge_children_queryable() -> void:
	# Arrange
	var graph := MapGraph.new()
	var parent := MapNode.new()
	parent.node_id = "parent"
	var child := MapNode.new()
	child.node_id = "child"
	graph.add_node(parent)
	graph.add_node(child)
	# Act
	graph.add_edge("parent", "child")
	# Assert
	var children: Array[String] = graph.get_children("parent")
	assert_int(children.size()).is_equal(1)
	assert_str(children[0]).is_equal("child")


func test_map_graph_add_node_and_edge_node_count_correct() -> void:
	# Arrange
	var graph := MapGraph.new()
	var n1 := MapNode.new()
	n1.node_id = "n1"
	var n2 := MapNode.new()
	n2.node_id = "n2"
	# Act
	graph.add_node(n1)
	graph.add_node(n2)
	# Assert
	assert_int(graph.node_count()).is_equal(2)


# ============================================================
# AC3 — CampaignMap 字段完整性
# ============================================================

func test_campaign_map_fields_hero_id_writable() -> void:
	# Arrange
	var cm := CampaignMap.new()
	# Act
	cm.hero_id = "liu_bei"
	# Assert
	assert_str(cm.hero_id).is_equal("liu_bei")


func test_campaign_map_fields_campaign_id_writable() -> void:
	# Arrange
	var cm := CampaignMap.new()
	# Act
	cm.campaign_id = "campaign_01"
	# Assert
	assert_str(cm.campaign_id).is_equal("campaign_01")


func test_campaign_map_fields_map_id_writable() -> void:
	# Arrange
	var cm := CampaignMap.new()
	# Act
	cm.map_id = "map_01"
	# Assert
	assert_str(cm.map_id).is_equal("map_01")


func test_campaign_map_fields_start_node_id_writable() -> void:
	# Arrange
	var cm := CampaignMap.new()
	# Act
	cm.start_node_id = "start"
	# Assert
	assert_str(cm.start_node_id).is_equal("start")


func test_campaign_map_fields_boss_node_id_writable() -> void:
	# Arrange
	var cm := CampaignMap.new()
	# Act
	cm.boss_node_id = "boss"
	# Assert
	assert_str(cm.boss_node_id).is_equal("boss")


func test_campaign_map_fields_nodes_dict_accepts_add_node() -> void:
	# Arrange
	var cm := CampaignMap.new()
	var node := MapNode.new()
	node.node_id = "n1"
	# Act
	cm.add_node(node)
	# Assert
	assert_bool(cm.nodes.has("n1")).is_true()


# ============================================================
# CampaignMap 便捷方法
# ============================================================

func test_campaign_map_get_start_node_returns_correct_node() -> void:
	# Arrange
	var cm := CampaignMap.new()
	var start := MapNode.new()
	start.node_id = "start_01"
	start.node_type = MapNode.NodeType.BATTLE
	cm.add_node(start)
	cm.start_node_id = "start_01"
	# Act
	var result: MapNode = cm.get_start_node()
	# Assert
	assert_that(result).is_not_null()
	assert_str(result.node_id).is_equal("start_01")


func test_campaign_map_get_boss_node_returns_correct_node() -> void:
	# Arrange
	var cm := CampaignMap.new()
	var boss := MapNode.new()
	boss.node_id = "boss_01"
	boss.node_type = MapNode.NodeType.BOSS
	cm.add_node(boss)
	cm.boss_node_id = "boss_01"
	# Act
	var result: MapNode = cm.get_boss_node()
	# Assert
	assert_that(result).is_not_null()
	assert_int(result.node_type).is_equal(MapNode.NodeType.BOSS)


func test_campaign_map_get_node_unknown_returns_null() -> void:
	# Arrange
	var cm := CampaignMap.new()
	# Act / Assert
	assert_that(cm.get_node("ghost")).is_null()


# ============================================================
# AC2 — 树形父子节点关系（prerequisites）
# ============================================================

func test_prerequisites_tree_structure_single_parent() -> void:
	# Arrange
	var graph := MapGraph.new()
	var root := MapNode.new()
	root.node_id = "root"
	var child := MapNode.new()
	child.node_id = "child"
	graph.add_node(root)
	graph.add_node(child)
	# Act
	graph.add_edge("root", "child")
	# Assert：child 的前置节点应包含 root
	var child_node: MapNode = graph.get_node("child")
	assert_int(child_node.prerequisites.size()).is_equal(1)
	assert_str(child_node.prerequisites[0]).is_equal("root")


func test_prerequisites_tree_structure_two_parents() -> void:
	# Arrange（菱形结构：两个父节点汇聚到同一子节点）
	var graph := MapGraph.new()
	var p1 := MapNode.new()
	p1.node_id = "p1"
	var p2 := MapNode.new()
	p2.node_id = "p2"
	var child := MapNode.new()
	child.node_id = "child"
	graph.add_node(p1)
	graph.add_node(p2)
	graph.add_node(child)
	# Act
	graph.add_edge("p1", "child")
	graph.add_edge("p2", "child")
	# Assert
	var child_node: MapNode = graph.get_node("child")
	assert_int(child_node.prerequisites.size()).is_equal(2)
	assert_bool(child_node.prerequisites.has("p1")).is_true()
	assert_bool(child_node.prerequisites.has("p2")).is_true()


func test_prerequisites_tree_structure_root_has_no_prerequisites() -> void:
	# Arrange
	var graph := MapGraph.new()
	var root := MapNode.new()
	root.node_id = "root"
	graph.add_node(root)
	graph.root_node_id = "root"
	# Act / Assert：根节点没有前置节点
	var root_node: MapNode = graph.get_node("root")
	assert_int(root_node.prerequisites.size()).is_equal(0)


func test_prerequisites_tree_structure_chain_three_levels() -> void:
	# Arrange（A -> B -> C 链式结构）
	var graph := MapGraph.new()
	var a := MapNode.new()
	a.node_id = "A"
	var b := MapNode.new()
	b.node_id = "B"
	var c := MapNode.new()
	c.node_id = "C"
	graph.add_node(a)
	graph.add_node(b)
	graph.add_node(c)
	# Act
	graph.add_edge("A", "B")
	graph.add_edge("B", "C")
	# Assert
	assert_int((graph.get_node("B") as MapNode).prerequisites.size()).is_equal(1)
	assert_str((graph.get_node("B") as MapNode).prerequisites[0]).is_equal("A")
	assert_int((graph.get_node("C") as MapNode).prerequisites.size()).is_equal(1)
	assert_str((graph.get_node("C") as MapNode).prerequisites[0]).is_equal("B")


# ============================================================
# AC3 — 必要节点验证（has_mandatory_nodes）
# ============================================================

func test_campaign_map_has_mandatory_nodes_passes_when_all_present() -> void:
	# Arrange
	var cm := CampaignMap.new()
	var shop := MapNode.new()
	shop.node_id = "shop_01"
	shop.node_type = MapNode.NodeType.SHOP
	var inn := MapNode.new()
	inn.node_id = "inn_01"
	inn.node_type = MapNode.NodeType.INN
	var barracks := MapNode.new()
	barracks.node_id = "barracks_01"
	barracks.node_type = MapNode.NodeType.BARRACKS
	cm.add_node(shop)
	cm.add_node(inn)
	cm.add_node(barracks)
	# Act
	var result: bool = cm.has_mandatory_nodes()
	# Assert
	assert_bool(result).is_true()


func test_campaign_map_has_mandatory_nodes_fails_when_shop_missing() -> void:
	# Arrange
	var cm := CampaignMap.new()
	var inn := MapNode.new()
	inn.node_id = "inn_01"
	inn.node_type = MapNode.NodeType.INN
	var barracks := MapNode.new()
	barracks.node_id = "barracks_01"
	barracks.node_type = MapNode.NodeType.BARRACKS
	cm.add_node(inn)
	cm.add_node(barracks)
	# Act
	var result: bool = cm.has_mandatory_nodes()
	# Assert
	assert_bool(result).is_false()


func test_campaign_map_has_mandatory_nodes_fails_when_inn_missing() -> void:
	# Arrange
	var cm := CampaignMap.new()
	var shop := MapNode.new()
	shop.node_id = "shop_01"
	shop.node_type = MapNode.NodeType.SHOP
	var barracks := MapNode.new()
	barracks.node_id = "barracks_01"
	barracks.node_type = MapNode.NodeType.BARRACKS
	cm.add_node(shop)
	cm.add_node(barracks)
	# Act
	var result: bool = cm.has_mandatory_nodes()
	# Assert
	assert_bool(result).is_false()


func test_campaign_map_has_mandatory_nodes_fails_when_barracks_missing() -> void:
	# Arrange
	var cm := CampaignMap.new()
	var shop := MapNode.new()
	shop.node_id = "shop_01"
	shop.node_type = MapNode.NodeType.SHOP
	var inn := MapNode.new()
	inn.node_id = "inn_01"
	inn.node_type = MapNode.NodeType.INN
	cm.add_node(shop)
	cm.add_node(inn)
	# Act
	var result: bool = cm.has_mandatory_nodes()
	# Assert
	assert_bool(result).is_false()


func test_campaign_map_has_mandatory_nodes_fails_when_empty() -> void:
	# Arrange
	var cm := CampaignMap.new()
	# Act
	var result: bool = cm.has_mandatory_nodes()
	# Assert
	assert_bool(result).is_false()
