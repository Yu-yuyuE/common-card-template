## MapNavigator — 战役地图导航管理器
##
## 管理玩家在 MapGraph 中的移动。负责前置节点检查、粮草消耗、
## 访问历史记录，以及 Boss 击败后的粮草恢复。
##
## 使用示例：
##   var navigator := MapNavigator.new()
##   navigator.graph = my_map_graph
##   navigator.current_node_id = graph.root_node_id
##   if navigator.can_navigate_to("node_02"):
##       navigator.navigate_to("node_02", current_layer)
class_name MapNavigator extends Node

## 从一个节点移动到另一个节点时发出（在导航成功后）
signal node_changed(from_node: String, to_node: String)

## 一个节点被首次访问时发出
signal node_visited(node_id: String)

## 地图上所有节点均已访问时发出（由 on_boss_defeated 触发）
signal all_nodes_completed()

## 到达普通/精英/商店/酒馆/军营/事件节点的基础粮草消耗
const CARGO_COST_BASE: int = 2

## 到达 Boss 节点固定消耗的粮草量
const CARGO_COST_BOSS: int = 10

## 击败 Boss 后恢复的粮草量
const CARGO_REWARD_BOSS: int = 50

## 当前绑定的地图图结构
var graph: MapGraph

## 玩家当前所在节点的 ID
var current_node_id: String = ""

## 已访问节点的 ID 列表（按访问顺序排列）
var visited_nodes: Array[String] = []


# ---------------------------------------------------------------------------
# 资源接口（可在测试中 override，解耦 ResourceManager 单例）
# ---------------------------------------------------------------------------

## 读取当前粮草数量。可在子类或测试 Mock 中 override。
func _get_provisions() -> int:
	return ResourceManager.get_resource(ResourceManager.ResourceType.PROVISIONS)


## 扣除指定数量的粮草。可在子类或测试 Mock 中 override。
## [br]amount: 要扣除的正整数粮草量
func _consume_provisions(amount: int) -> void:
	ResourceManager.modify_resource(ResourceManager.ResourceType.PROVISIONS, -amount)


## 恢复指定数量的粮草。可在子类或测试 Mock 中 override。
## [br]amount: 要恢复的正整数粮草量
func _restore_provisions(amount: int) -> void:
	ResourceManager.modify_resource(ResourceManager.ResourceType.PROVISIONS, amount)


# ---------------------------------------------------------------------------
# 公共 API
# ---------------------------------------------------------------------------

## 计算移动到指定节点所需的粮草消耗。
##
## Boss 节点固定返回 CARGO_COST_BOSS（10）。
## 其他节点按公式：BaseCost + Random(0, floor(layer × 0.5)) 计算。
##
## [br]node: 目标 MapNode 实例
## [br]layer: 目标节点所在层数（1~15）
## [br]返回：本次移动所需的粮草整数值
func calculate_move_cost(node: MapNode, layer: int) -> int:
	if node.node_type == MapNode.NodeType.BOSS:
		return CARGO_COST_BOSS
	var max_extra: int = int(layer * 0.5)
	return CARGO_COST_BASE + randi() % (max_extra + 1)


## 检查是否可以导航到目标节点。
##
## 满足以下全部条件才返回 true：
## - graph 已设置且目标节点存在
## - 目标节点的所有前置节点均已访问
## - 当前粮草 >= 目标节点的 provisions_cost
##
## [br]target_node_id: 目标节点 ID
## [br]返回：可以导航则返回 true，否则 false
func can_navigate_to(target_node_id: String) -> bool:
	if graph == null:
		return false
	var target: MapNode = graph.get_node(target_node_id)
	if target == null:
		return false
	# 检查前置节点
	for prereq_id: String in target.prerequisites:
		if not visited_nodes.has(prereq_id):
			return false
	# 检查粮草
	if _get_provisions() < target.provisions_cost:
		return false
	return true


## 执行导航：移动到目标节点，扣除粮草，更新访问历史。
##
## 导航成功的条件与 can_navigate_to() 相同。
## 成功后：发出 node_changed 与 node_visited 信号。
##
## [br]target_node_id: 目标节点 ID
## [br]layer: 目标节点所在层数，用于计算粮草消耗（GDD F1 公式）
## [br]返回：导航成功返回 true，前置未满足或粮草不足返回 false
func navigate_to(target_node_id: String, layer: int) -> bool:
	if not can_navigate_to(target_node_id):
		return false

	var target: MapNode = graph.get_node(target_node_id)
	var cost: int = calculate_move_cost(target, layer)
	_consume_provisions(cost)

	var from_id: String = current_node_id
	current_node_id = target_node_id
	target.visited = true

	if not visited_nodes.has(target_node_id):
		visited_nodes.append(target_node_id)

	node_changed.emit(from_id, target_node_id)
	node_visited.emit(target_node_id)

	return true


## Boss 击败后调用：恢复 CARGO_REWARD_BOSS（50）点粮草，
## 并触发 all_nodes_completed 信号（表示本关卡战役完成）。
func on_boss_defeated() -> void:
	_restore_provisions(CARGO_REWARD_BOSS)
	all_nodes_completed.emit()
