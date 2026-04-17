## MapGraph — 战役地图图结构
##
## 以邻接表形式管理所有地图节点及有向边（父 -> 子）。
## 树形结构：每条边表示"完成 from 节点后可到达 to 节点"。
## 不持有战役元数据（hero_id 等），由 CampaignMap 组合使用。
##
## 使用示例：
##   var graph := MapGraph.new()
##   graph.add_node(node_a)
##   graph.add_node(node_b)
##   graph.add_edge("node_a", "node_b")
##   var children := graph.get_children("node_a")  # ["node_b"]
class_name MapGraph extends RefCounted

## node_id -> MapNode，存储全部节点
var nodes: Dictionary = {}

## node_id -> Array[String]，存储有向出边（父节点 -> 子节点列表）
var edges: Dictionary = {}

## 根节点 ID（起点），由外部在构建地图时设置
var root_node_id: String = ""


## 将一个节点加入图。若 node_id 已存在则覆盖。
## [br]node: 要加入的 MapNode 实例
func add_node(node: MapNode) -> void:
	nodes[node.node_id] = node
	if not edges.has(node.node_id):
		edges[node.node_id] = [] as Array[String]


## 添加有向边：from_id -> to_id，同时在目标节点的 prerequisites 中注册 from_id。
## [br]from_id: 父节点 ID[br]to_id: 子节点 ID
func add_edge(from_id: String, to_id: String) -> void:
	if not edges.has(from_id):
		edges[from_id] = [] as Array[String]
	var out_edges: Array[String] = edges[from_id]
	if not out_edges.has(to_id):
		out_edges.append(to_id)
	# 同步写入目标节点的 prerequisites
	if nodes.has(to_id):
		var target: MapNode = nodes[to_id]
		if not target.prerequisites.has(from_id):
			target.prerequisites.append(from_id)


## 返回指定节点的直接子节点 ID 列表；节点不存在时返回空数组。
## [br]node_id: 父节点 ID
func get_children(node_id: String) -> Array[String]:
	if edges.has(node_id):
		return edges[node_id]
	return [] as Array[String]


## 按 node_id 获取节点，不存在时返回 null。
## [br]node_id: 要查询的节点 ID
func get_node(node_id: String) -> MapNode:
	if nodes.has(node_id):
		return nodes[node_id] as MapNode
	return null


## 返回图中节点总数。
func node_count() -> int:
	return nodes.size()
