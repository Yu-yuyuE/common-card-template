## MapNode — 地图节点数据类
##
## 表示战役地图中的一个节点。节点持有位置、类型、前置条件等信息。
## 由 MapGraph 管理，不直接持有子节点引用（通过 MapGraph.edges 查询）。
##
## 使用示例：
##   var node := MapNode.new()
##   node.node_id = "node_01"
##   node.node_type = MapNode.NodeType.BATTLE
##   node.position = Vector2(100, 200)
##   node.provisions_cost = 2
class_name MapNode extends RefCounted

## 节点类型枚举，定义7种地图事件类型
enum NodeType {
	BATTLE,    ## 普通战斗
	ELITE,     ## 精英战斗
	BOSS,      ## Boss 战斗
	SHOP,      ## 商店
	INN,       ## 酒馆
	BARRACKS,  ## 军营
	EVENT      ## 随机事件
}

## 节点唯一标识符
var node_id: String = ""

## 节点类型，决定触发什么事件
var node_type: NodeType = NodeType.BATTLE

## 节点在地图上的显示坐标（像素）
var position: Vector2 = Vector2.ZERO

## 前置节点 ID 列表；到达本节点前必须先完成所有前置节点
var prerequisites: Array[String] = []

## 到达此节点需要消耗的粮草量
var provisions_cost: int = 0

## 玩家是否已访问过此节点
var visited: bool = false

## 此节点当前是否可选（所有前置节点均已完成）
var available: bool = false
