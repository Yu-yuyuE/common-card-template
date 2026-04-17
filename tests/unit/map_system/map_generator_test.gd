## map_generator_test.gd
## MapGenerator 单元测试套件
##
## 覆盖范围：
##   - AC1: 生成地图层数在 [12, 16] 闭区间内（100次采样）
##   - AC2: 每个中间层父节点子节点数∈[2, 3]（100次采样）
##   - AC3: 从起始节点到Boss节点存在有向路径（DFS验证）
##   - AC4: 每张地图包含至少1个 SHOP、INN、BARRACKS
##   - AC5: 第5层和第10层（±1容差）各存在至少1个 ELITE 节点（100次采样）
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite

# ============================================================
# 测试辅助常量
# ============================================================

const SAMPLE_COUNT: int = 100
const HERO_ID: String = "test_hero"
const CAMPAIGN_ID: String = "test_campaign"
const MAP_ID: String = "test_map"

# ============================================================
# 测试辅助方法
# ============================================================

## 从 map.nodes 中收集指定 layer 的节点列表。
## [br]layer 编码于 position.y（与 MapGenerator._create_node 对应）。
func _get_nodes_at_layer(map: CampaignMap, layer: int) -> Array[MapNode]:
	var result: Array[MapNode] = []
	for node: MapNode in map.nodes.values():
		if int(node.position.y) == layer:
			result.append(node)
	return result


## 检查指定层范围内是否有指定类型的节点。
## [br]min_layer / max_layer 均为含边界。
func _has_node_type_in_layers(
		map: CampaignMap,
		target_type: MapNode.NodeType,
		min_layer: int,
		max_layer: int) -> bool:
	for node: MapNode in map.nodes.values():
		if node.node_type == target_type:
			var layer: int = int(node.position.y)
			if layer >= min_layer and layer <= max_layer:
				return true
	return false


## 检查 Boss 是否从 start_node_id 可达（DFS）。
func _is_boss_reachable(map: CampaignMap, graph: MapGraph) -> bool:
	if map.start_node_id.is_empty() or map.boss_node_id.is_empty():
		return false
	var visited_set: Dictionary = {}
	var stack: Array[String] = [map.start_node_id]
	while not stack.is_empty():
		var current_id: String = stack.pop_back()
		if current_id == map.boss_node_id:
			return true
		if visited_set.has(current_id):
			continue
		visited_set[current_id] = true
		for child_id: String in graph.get_children(current_id):
			if not visited_set.has(child_id):
				stack.append(child_id)
	return false


## 为测试重建与地图配套的 MapGraph（通过 node.prerequisites 还原边）。
## MapGenerator 内部持有 graph，但 generate_map 只返回 CampaignMap。
## 此处通过 prerequisites 字段重建边关系，用于可达性断言。
func _rebuild_graph(map: CampaignMap) -> MapGraph:
	var graph := MapGraph.new()
	graph.root_node_id = map.start_node_id
	for node: MapNode in map.nodes.values():
		graph.add_node(node)
	# 通过 prerequisites 反向构建出边
	for node: MapNode in map.nodes.values():
		for parent_id: String in node.prerequisites:
			# add_edge 会再次写入 prerequisites（重复无害，因为 MapGraph 应幂等）
			# 直接操作 edges 字典以避免重复追加 prerequisites
			if not graph.edges.has(parent_id):
				graph.edges[parent_id] = []
			var edge_list: Array = graph.edges[parent_id]
			if not edge_list.has(node.node_id):
				edge_list.append(node.node_id)
	return graph


## 从地图推断总层数（Boss 节点所在层 + 1）。
func _get_layer_count(map: CampaignMap) -> int:
	var boss_node: MapNode = map.get_boss_node()
	if boss_node == null:
		return 0
	return int(boss_node.position.y) + 1


# ============================================================
# AC1 — 层数范围验证
# ============================================================

## AC1：100次采样，层数全部在 [12, 16] 闭区间内。
func test_map_generator_layer_count_within_range() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act / Assert
	for i: int in range(SAMPLE_COUNT):
		var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
		assert_that(map).is_not_null()
		var layer_count: int = _get_layer_count(map)
		assert_int(layer_count).is_between(12, 16)


## AC1 边界：单次生成后地图节点数大于0。
func test_map_generator_generates_non_empty_map() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	assert_bool(map.nodes.size() > 0).is_true()


# ============================================================
# AC2 — 分支数验证
# ============================================================

## AC2：100次采样，所有中间层每个父节点的子节点数均在 [2, 3] 内。
func test_map_generator_branch_count_within_range() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act / Assert
	for _i: int in range(SAMPLE_COUNT):
		var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
		assert_that(map).is_not_null()

		var layer_count: int = _get_layer_count(map)
		var graph: MapGraph = _rebuild_graph(map)

		# 验证层 0 ~ layer_count-3（每个父节点在中间层的子节点数）
		# 注意：最后一层中间节点统一连到 Boss，不参与分支计数
		for layer: int in range(0, layer_count - 2):
			var layer_nodes: Array[MapNode] = _get_nodes_at_layer(map, layer)
			for parent: MapNode in layer_nodes:
				var children: Array[String] = graph.get_children(parent.node_id)
				# 过滤掉指向 Boss 层的边（Boss 层节点不算分支）
				var middle_children: Array[String] = []
				for child_id: String in children:
					var child_node: MapNode = map.get_node(child_id)
					if child_node != null and child_node.node_type != MapNode.NodeType.BOSS:
						middle_children.append(child_id)
				if not middle_children.is_empty():
					assert_int(middle_children.size()).is_between(2, 3)


# ============================================================
# AC3 — 可达性验证
# ============================================================

## AC3：单次生成后，DFS 验证 Boss 从起始节点可达。
func test_map_generator_boss_is_reachable() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	var graph: MapGraph = _rebuild_graph(map)
	assert_bool(_is_boss_reachable(map, graph)).is_true()


## AC3：起始节点存在且 ID 不为空。
func test_map_generator_start_node_exists() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	assert_str(map.start_node_id).is_not_empty()
	assert_that(map.get_start_node()).is_not_null()


# ============================================================
# AC4 — 必要节点验证
# ============================================================

## AC4：生成地图包含 SHOP、INN、BARRACKS 各至少1个（综合验证）。
func test_map_generator_mandatory_nodes_present() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	assert_bool(map.has_mandatory_nodes()).is_true()


## AC4：单独验证 SHOP 节点存在。
func test_map_generator_shop_node_present() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	var found: bool = false
	for node: MapNode in map.nodes.values():
		if node.node_type == MapNode.NodeType.SHOP:
			found = true
			break
	assert_bool(found).is_true()


## AC4：单独验证 INN 节点存在。
func test_map_generator_inn_node_present() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	var found: bool = false
	for node: MapNode in map.nodes.values():
		if node.node_type == MapNode.NodeType.INN:
			found = true
			break
	assert_bool(found).is_true()


## AC4：单独验证 BARRACKS 节点存在。
func test_map_generator_barracks_node_present() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	var found: bool = false
	for node: MapNode in map.nodes.values():
		if node.node_type == MapNode.NodeType.BARRACKS:
			found = true
			break
	assert_bool(found).is_true()


# ============================================================
# AC5 — 精英节点分布验证
# ============================================================

## AC5：100次采样，第5层（±1）和第10层（±1）各存在至少1个 ELITE 节点。
func test_map_generator_elite_nodes_at_layer5_and_10() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act / Assert
	for _i: int in range(SAMPLE_COUNT):
		var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
		assert_that(map).is_not_null()

		var layer_count: int = _get_layer_count(map)

		# 第5层 ±1（层数足够时才检查）
		if layer_count >= 6:
			var elite_near_5: bool = _has_node_type_in_layers(
				map, MapNode.NodeType.ELITE, 4, 6)
			assert_bool(elite_near_5).is_true()

		# 第10层 ±1（层数足够时才检查）
		if layer_count >= 11:
			var elite_near_10: bool = _has_node_type_in_layers(
				map, MapNode.NodeType.ELITE, 9, 11)
			assert_bool(elite_near_10).is_true()


## AC5：单次生成后，地图中存在至少1个 ELITE 节点。
func test_map_generator_has_elite_nodes() -> void:
	# Arrange
	var gen := MapGenerator.new()
	# Act
	var map: CampaignMap = gen.generate_map(HERO_ID, CAMPAIGN_ID, MAP_ID)
	# Assert
	assert_that(map).is_not_null()
	var has_elite: bool = false
	for node: MapNode in map.nodes.values():
		if node.node_type == MapNode.NodeType.ELITE:
			has_elite = true
			break
	assert_bool(has_elite).is_true()
