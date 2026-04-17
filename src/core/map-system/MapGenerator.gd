## MapGenerator — 战役地图生成器
##
## 按照 ADR-0011 规范，以权重控制的随机策略生成多层树形战役地图。
## 生成失败时最多重试 MAX_RETRIES 次，确保地图满足可达性与必要节点要求。
##
## 使用示例：
##   var gen := MapGenerator.new()
##   var map := gen.generate_map("liu_bei", "campaign_01", "map_01")
##   if map:
##       print("地图生成成功，节点数：", map.nodes.size())
##
## 依赖：MapNode、MapGraph、CampaignMap（无全局单例依赖）
class_name MapGenerator extends RefCounted

# ============================================================
# 权重常量（GDD F4）
# ============================================================

## 普通战斗节点权重
const WEIGHT_BATTLE: float = 0.45
## 随机事件节点权重
const WEIGHT_ENCOUNTER: float = 0.25
## 商店节点权重
const WEIGHT_SHOP: float = 0.10
## 酒馆节点权重
const WEIGHT_INN: float = 0.10
## 军营节点权重
const WEIGHT_BARRACKS: float = 0.10

## 可达性验证失败时的最大重试次数
const MAX_RETRIES: int = 3

## 地图层数最小值（含）
const LAYER_COUNT_MIN: int = 12
## 地图层数最大值（含）
const LAYER_COUNT_MAX: int = 16

## 每个父节点的最小子节点数
const BRANCH_MIN: int = 2
## 每个父节点的最大子节点数
const BRANCH_MAX: int = 3

## 精英节点目标层（第一个）
const ELITE_LAYER_FIRST: int = 5
## 精英节点目标层间隔
const ELITE_LAYER_INTERVAL: int = 5

# ============================================================
# 公共 API
# ============================================================

## 生成完整战役地图。失败时最多重试 MAX_RETRIES 次。
## [br]
## [br]hero_id: 英雄唯一标识符
## [br]campaign_id: 战役唯一标识符
## [br]map_id: 地图唯一标识符
## [br]返回生成好的 [CampaignMap]。
## [br][b]注意：[/b] 全部 [constant MAX_RETRIES] 次重试均失败时返回 [code]null[/code]，
## 调用方必须检查返回值。正常情况下重试失败概率极低（可达性验证极少失败）。
func generate_map(hero_id: String, campaign_id: String, map_id: String) -> CampaignMap:
	for attempt: int in range(MAX_RETRIES):
		var result: CampaignMap = _attempt_generate(hero_id, campaign_id, map_id)
		if result != null:
			return result
	push_error("MapGenerator: 地图生成失败，已重试 %d 次（hero=%s campaign=%s map=%s）" % [
		MAX_RETRIES, hero_id, campaign_id, map_id
	])
	return null


# ============================================================
# 内部方法
# ============================================================

## 执行一次完整地图生成尝试。
## 返回验证通过的 CampaignMap，或返回 null 表示本次失败。
func _attempt_generate(hero_id: String, campaign_id: String, map_id: String) -> CampaignMap:
	var map := CampaignMap.new()
	map.hero_id = hero_id
	map.campaign_id = campaign_id
	map.map_id = map_id

	var graph := MapGraph.new()

	# 随机决定总层数（[LAYER_COUNT_MIN, LAYER_COUNT_MAX]）
	var layer_count: int = randi_range(LAYER_COUNT_MIN, LAYER_COUNT_MAX)

	# 1. 构建层次结构
	_generate_layers(map, graph, layer_count)

	# 2. 注入精英节点
	_add_elite_nodes(map, graph, layer_count)

	# 3. 确保必要节点（SHOP / INN / BARRACKS）
	_ensure_mandatory_nodes(map, graph, layer_count)

	# 4. 可达性验证
	if not _verify_reachability(map, graph):
		return null

	return map


## 生成地图层次结构（内部使用）。
## [br]
## 层 0：单一起始 BATTLE 节点。
## 层 1 ~ layer_count-2：中间层，每个父节点生成 BRANCH_MIN~BRANCH_MAX 个子节点。
## 层 layer_count-1：单一 BOSS 节点，所有末层中间节点连接到此节点。
## [br]
## [br]map: 目标 CampaignMap
## [br]graph: 目标 MapGraph
## [br]layer_count: 总层数（含起始层和 Boss 层）
func _generate_layers(map: CampaignMap, graph: MapGraph, layer_count: int) -> void:
	# --- 层 0：起始节点 ---
	var start_node: MapNode = _create_node("start_0", MapNode.NodeType.BATTLE, 0)
	map.add_node(start_node)
	graph.add_node(start_node)
	map.start_node_id = "start_0"
	graph.root_node_id = "start_0"

	# 追踪当前层的父节点 ID 列表（用于下一层边的连接）
	var current_layer_ids: Array[String] = ["start_0"]

	# --- 层 1 ~ layer_count-2：中间层 ---
	var last_middle_layer: int = layer_count - 2
	for layer: int in range(1, last_middle_layer + 1):
		var next_layer_ids: Array[String] = []
		var node_index: int = 0

		for parent_id: String in current_layer_ids:
			var branch_count: int = randi_range(BRANCH_MIN, BRANCH_MAX)
			for _b: int in range(branch_count):
				var node_id: String = "node_%d_%d" % [layer, node_index]
				var node_type: MapNode.NodeType = _select_node_type_by_weight()
				var child_node: MapNode = _create_node(node_id, node_type, layer)

				map.add_node(child_node)
				graph.add_node(child_node)
				graph.add_edge(parent_id, node_id)

				next_layer_ids.append(node_id)
				node_index += 1

		current_layer_ids = next_layer_ids

	# --- 最终层：Boss 节点 ---
	var boss_layer: int = layer_count - 1
	var boss_id: String = "boss_%d" % boss_layer
	var boss_node: MapNode = _create_node(boss_id, MapNode.NodeType.BOSS, boss_layer)

	map.add_node(boss_node)
	graph.add_node(boss_node)
	map.boss_node_id = boss_id

	# 所有最后一层中间节点 -> Boss
	for parent_id: String in current_layer_ids:
		graph.add_edge(parent_id, boss_id)


## 确保必要节点存在：SHOP / INN / BARRACKS 各至少1个（内部使用）。
## [br]
## 若缺少某类型，在中间层随机选一个普通节点，强制修改其类型。
## [br]
## [br]map: 目标 CampaignMap
## [br]_graph: 保留参数，供后续扩展使用（当前未使用）
## [br]_layer_count: 保留参数，供后续扩展使用（当前未使用）
func _ensure_mandatory_nodes(map: CampaignMap, _graph: MapGraph, _layer_count: int) -> void:
	var mandatory_types: Array[MapNode.NodeType] = [
		MapNode.NodeType.SHOP,
		MapNode.NodeType.INN,
		MapNode.NodeType.BARRACKS,
	]

	# 收集中间层所有可替换节点（排除 ELITE、BOSS、起始节点）
	var replaceable: Array[MapNode] = []
	for node: MapNode in map.nodes.values():
		if node.node_type != MapNode.NodeType.ELITE \
				and node.node_type != MapNode.NodeType.BOSS \
				and node.node_id != map.start_node_id:
			replaceable.append(node)

	for target_type: MapNode.NodeType in mandatory_types:
		# 检查是否已存在此类型
		var already_exists: bool = false
		for node: MapNode in map.nodes.values():
			if node.node_type == target_type:
				already_exists = true
				break

		if already_exists:
			continue

		# 从可替换节点中随机选一个（排除已是目标类型的节点）
		var candidates: Array[MapNode] = []
		for node: MapNode in replaceable:
			if node.node_type != target_type \
					and node.node_type != MapNode.NodeType.SHOP \
					and node.node_type != MapNode.NodeType.INN \
					and node.node_type != MapNode.NodeType.BARRACKS:
				candidates.append(node)

		if candidates.is_empty():
			# 无候选时放宽条件：允许替换任何非 ELITE/BOSS 的中间节点
			for node: MapNode in replaceable:
				if node.node_type != MapNode.NodeType.ELITE \
						and node.node_type != MapNode.NodeType.BOSS:
					candidates.append(node)

		if candidates.is_empty():
			push_warning("MapGenerator._ensure_mandatory_nodes: 无法插入 %d 类型节点" % target_type)
			continue

		var chosen: MapNode = candidates[randi() % candidates.size()]
		chosen.node_type = target_type
		# 从可替换池中移除，避免同一节点被多次替换
		replaceable.erase(chosen)


## 在每 ELITE_LAYER_INTERVAL 层（第5、10层等，±1层容差）插入 ELITE 节点（内部使用）。
## [br]
## 如果目标层 ±1 范围内已有 ELITE 节点则跳过；否则在目标层随机选一个 BATTLE 节点改为 ELITE。
## [br]
## [br]map: 目标 CampaignMap
## [br]graph: 目标 MapGraph（当前未使用，保留签名以备扩展）
## [br]layer_count: 总层数
func _add_elite_nodes(map: CampaignMap, graph: MapGraph, layer_count: int) -> void:
	# 遍历所有精英目标层（5, 10, 15, ...），不超过最后中间层
	var last_middle_layer: int = layer_count - 2
	var target_layer: int = ELITE_LAYER_FIRST
	while target_layer <= last_middle_layer:
		# 检查 [target_layer-1, target_layer+1] 范围内是否已有 ELITE
		var min_check: int = max(1, target_layer - 1)
		var max_check: int = min(last_middle_layer, target_layer + 1)
		var has_elite: bool = _has_node_type_in_range(map, MapNode.NodeType.ELITE, min_check, max_check)

		if not has_elite:
			# 在目标层随机选一个 BATTLE 节点改为 ELITE
			var candidates: Array[MapNode] = []
			for node: MapNode in map.nodes.values():
				if node.node_type == MapNode.NodeType.BATTLE and _get_node_layer(node) == target_layer:
					candidates.append(node)

			if not candidates.is_empty():
				var chosen: MapNode = candidates[randi() % candidates.size()]
				chosen.node_type = MapNode.NodeType.ELITE
			else:
				push_warning("MapGenerator._add_elite_nodes: 第 %d 层无可替换节点用于 ELITE（该层节点已被 SHOP/INN/BARRACKS 占满）" % target_layer)

		target_layer += ELITE_LAYER_INTERVAL


## 按权重随机选择节点类型（不包含 ELITE / BOSS）。
## [br]
## 权重来自 GDD F4：BATTLE=0.45, ENCOUNTER/EVENT=0.25, SHOP=0.10, INN=0.10, BARRACKS=0.10。
## [br]
## 返回随机选中的 [enum MapNode.NodeType]。
func _select_node_type_by_weight() -> MapNode.NodeType:
	var roll: float = randf()
	var cumulative: float = 0.0

	cumulative += WEIGHT_BATTLE
	if roll < cumulative:
		return MapNode.NodeType.BATTLE

	cumulative += WEIGHT_ENCOUNTER
	if roll < cumulative:
		return MapNode.NodeType.EVENT

	cumulative += WEIGHT_SHOP
	if roll < cumulative:
		return MapNode.NodeType.SHOP

	cumulative += WEIGHT_INN
	if roll < cumulative:
		return MapNode.NodeType.INN

	# 剩余概率 -> BARRACKS
	return MapNode.NodeType.BARRACKS


## DFS 验证从 start_node_id 可以到达 boss_node_id（内部使用）。
## [br]
## 返回 [code]true[/code] 表示可达；否则返回 [code]false[/code]。
## [br]
## [br]map: 目标 CampaignMap
## [br]graph: 持有边关系的 MapGraph
func _verify_reachability(map: CampaignMap, graph: MapGraph) -> bool:
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


## 创建节点辅助方法。
## [br]
## [br]node_id: 节点唯一标识符
## [br]node_type: 节点类型枚举
## [br]layer: 节点所在层索引（写入 position.y，x=0 作为占位）
## [br]返回配置好的 [MapNode] 实例。
func _create_node(node_id: String, node_type: MapNode.NodeType, layer: int) -> MapNode:
	var node := MapNode.new()
	node.node_id = node_id
	node.node_type = node_type
	# 将 layer 编码进 position.y，便于测试和可视化（x 由 UI 层布局决定）
	node.position = Vector2(0.0, float(layer))
	return node


# ============================================================
# 私有辅助方法
# ============================================================

## 检查 map.nodes 中指定层范围内是否存在指定类型的节点。
## [br]
## [br]map: 目标 CampaignMap
## [br]target_type: 要查找的节点类型
## [br]min_layer: 层范围下限（含）
## [br]max_layer: 层范围上限（含）
func _has_node_type_in_range(
		map: CampaignMap,
		target_type: MapNode.NodeType,
		min_layer: int,
		max_layer: int) -> bool:
	for node: MapNode in map.nodes.values():
		if node.node_type == target_type:
			var layer: int = _get_node_layer(node)
			if layer >= min_layer and layer <= max_layer:
				return true
	return false


## 从节点的 position.y 还原层索引（与 _create_node 的编码对应）。
## [br]
## [br]node: 要查询的 MapNode
## [br]返回层索引（整数）。
func _get_node_layer(node: MapNode) -> int:
	return int(node.position.y)
