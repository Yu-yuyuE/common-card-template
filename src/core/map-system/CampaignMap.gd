## CampaignMap — 完整战役地图数据类
##
## 组合 MapGraph 与战役元数据（hero_id / campaign_id / map_id）。
## 提供节点增删、起点/Boss节点快捷访问等便捷方法。
## 本类为纯数据层，不触发任何信号，不依赖全局单例。
##
## 使用示例：
##   var cm := CampaignMap.new()
##   cm.hero_id     = "liu_bei"
##   cm.campaign_id = "campaign_01"
##   cm.map_id      = "map_01"
##   cm.add_node(start_node)
##   cm.start_node_id = start_node.node_id
##   var start := cm.get_start_node()
class_name CampaignMap extends RefCounted

## 英雄唯一标识符（关联英雄数据）
var hero_id: String = ""

## 战役唯一标识符
var campaign_id: String = ""

## 地图唯一标识符（同一战役可有多张地图）
var map_id: String = ""

## node_id -> MapNode，所有节点的扁平字典（便于 O(1) 查找）
var nodes: Dictionary = {}

## 起始节点 ID
var start_node_id: String = ""

## Boss 节点 ID
var boss_node_id: String = ""


## 将节点加入 nodes 字典。若 node_id 已存在则覆盖。
## [br]node: 要加入的 MapNode 实例
func add_node(node: MapNode) -> void:
	nodes[node.node_id] = node


## 按 node_id 获取节点；节点不存在时返回 null。
## [br]node_id: 要查询的节点 ID
func get_node(node_id: String) -> MapNode:
	if nodes.has(node_id):
		return nodes[node_id] as MapNode
	return null


## 获取起始节点；start_node_id 未设置或节点不存在时返回 null。
func get_start_node() -> MapNode:
	return get_node(start_node_id)


## 获取 Boss 节点；boss_node_id 未设置或节点不存在时返回 null。
func get_boss_node() -> MapNode:
	return get_node(boss_node_id)


## 地图节点生成权重常量（供地图生成器使用，本 story 范围内仅定义）
const WEIGHT_BATTLE: float = 0.45
const WEIGHT_ENCOUNTER: float = 0.25
const WEIGHT_SHOP: float = 0.10
const WEIGHT_INN: float = 0.10
const WEIGHT_BARRACKS: float = 0.10


## 验证地图是否包含所有必要节点类型（AC3）。
## [br]
## 检查 nodes 字典中是否至少包含：
## - 1 个 SHOP（商店）
## - 1 个 INN（酒馆）
## - 1 个 BARRACKS（军营）
## [br]
## 返回 [code]true[/code] 当三种类型均至少存在1个；否则返回 [code]false[/code]。
## [br]
## 使用示例：
##   if not campaign_map.has_mandatory_nodes():
##       push_error("地图缺少必要节点，无法开始战役")
func has_mandatory_nodes() -> bool:
	var has_shop: bool = false
	var has_inn: bool = false
	var has_barracks: bool = false
	for node: MapNode in nodes.values():
		match node.node_type:
			MapNode.NodeType.SHOP:
				has_shop = true
			MapNode.NodeType.INN:
				has_inn = true
			MapNode.NodeType.BARRACKS:
				has_barracks = true
	return has_shop and has_inn and has_barracks
