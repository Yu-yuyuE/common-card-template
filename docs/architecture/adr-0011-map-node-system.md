# ADR-0011: 地图节点系统架构

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Feature / Map |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0003 (资源变更通知机制), ADR-0005 (存档序列化方案) |
| **Enables** | 战役进度管理、节点导航 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 依赖场景管理和资源管理 |

## Context

### Problem Statement
游戏战役由树形结构的地图节点组成：
- **节点类型**: 战斗、商店、酒馆、军营、事件、精英战斗、BOSS
- **连接关系**: 节点间有前置依赖（前置节点通过后才能访问）
- **资源消耗**: 移动到不同节点消耗不同粮草(2-8)
- **进度保存**: 节点访问状态需要持久化

### Constraints
- **数据结构**: 树形结构，支持多分支路线
- **性能**: 节点查找 < 1ms
- **存档**: 访问状态需要保存到 Run Save

### Requirements
- 支持节点类型配置（战斗/商店/酒馆/军营/事件/精英/BOSS）
- 支持前置节点依赖判断
- 支持粮草消耗计算
- 支持节点访问状态记录

## Decision

### 方案: 树形节点图 + 导航管理器

```
地图系统架构:
┌─────────────────────────────────────────────────────────────┐
│  MapGraph (数据结构)                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ nodes: Dictionary<node_id, MapNode>                │   │
│  │ edges: Dictionary<node_id, Array<String>>          │   │
│  │ root: String (起始节点ID)                           │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  MapNavigator (导航逻辑)                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ current_node: String                                │   │
│  │ visited_nodes: Array<String>                        │   │
│  │ available_nodes: Array<String> (可到达节点)         │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  MapRenderer (可视化)                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 节点位置、连线绘制                                   │   │
│  │ 节点状态显示(已访问/当前/可到达/锁定)              │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 核心数据结构

```gdscript
# map_node.gd
class_name MapNode extends RefCounted

enum NodeType {
    BATTLE,      # 普通战斗
    ELITE,       # 精英战斗
    BOSS,        # BOSS战斗
    SHOP,        # 商店
    INN,         # 酒馆
    BARRACKS,    # 军营
    EVENT        # 随机事件
}

var node_id: String           # 节点唯一ID
var node_type: NodeType       # 节点类型
var position: Vector2         # 在地图上的位置
var prerequisites: Array[String]  # 前置节点ID列表
var provisions_cost: int      # 到达该节点的粮草消耗
var available: bool = false   # 是否可访问
var visited: bool = false     # 是否已访问

# 地图图结构
class_name MapGraph extends RefCounted:
    var nodes: Dictionary = {}      # node_id -> MapNode
    var edges: Dictionary = {}      # node_id -> Array[node_id] (出边)
    var root_node_id: String = ""

    func add_node(node: MapNode):
        nodes[node.node_id] = node

    func add_edge(from_id: String, to_id: String):
        if not edges.has(from_id):
            edges[from_id] = []
        edges[from_id].append(to_id)

    func get_available_nodes(visited: Array[String], current_node: String) -> Array[MapNode]:
        var result: Array[MapNode] = []
        for node_id in nodes:
            var node = nodes[node_id]
            if node.visited or node.node_id == current_node:
                continue
            # 检查前置节点是否都已访问
            var all_prereqs_met = true
            for prereq in node.prerequisites:
                if not prereq in visited:
                    all_prereqs_met = false
                    break
            if all_prereqs_met:
                result.append(node)
        return result
```

### 地图导航管理器

```gdscript
# map_navigator.gd
class_name MapNavigator extends Node

signal node_changed(from_node: String, to_node: String)
signal node_visited(node_id: String)
signal all_nodes_completed()

var graph: MapGraph
var current_node_id: String = ""
var visited_nodes: Array[String] = []

func _ready():
    graph = _load_map_graph()

func navigate_to(target_node_id: String) -> bool:
    var target_node = graph.nodes.get(target_node_id)
    if target_node == null:
        push_error("Node not found: " + target_node_id)
        return false

    # 检查是否可访问
    var available = graph.get_available_nodes(visited_nodes, current_node_id)
    var can_reach = false
    for node in available:
        if node.node_id == target_node_id:
            can_reach = true
            break

    if not can_reach:
        push_error("Cannot navigate to node: " + target_node_id)
        return false

    # 检查粮草是否足够
    var provisions = ResourceManager.get_resource(ResourceManager.ResourceType.PROVISIONS)
    if provisions < target_node.provisions_cost:
        push_error("Not enough provisions: need %d, have %d" % [target_node.provisions_cost, provisions])
        return false

    # 消耗粮草
    ResourceManager.modify_resource(
        ResourceManager.ResourceType.PROVISIONS,
        -target_node.provisions_cost
    )

    # 更新状态
    var old_node = current_node_id
    current_node_id = target_node_id
    visited_nodes.append(target_node_id)

    # 触发事件
    node_changed.emit(old_node, target_node_id)
    node_visited.emit(target_node_id)

    # 检查是否通关
    if _is_map_completed():
        all_nodes_completed.emit()

    return true

func get_available_nodes() -> Array[MapNode]:
    return graph.get_available_nodes(visited_nodes, current_node_id)

func _is_map_completed() -> bool:
    for node_id in graph.nodes:
        if not node_id in visited_nodes:
            var node = graph.nodes[node_id]
            if node.node_type != MapNode.NodeType.BOSS:
                return false
    return true
```

### 地图配置示例

```gdscript
# 地图配置文件 (JSON)
# res://config/maps/campaign_1.json
{
    "map_id": "c1",
    "name": "赤壁之战",
    "root_node": "n001",
    "nodes": {
        "n001": {
            "id": "n001",
            "type": "EVENT",
            "position": [100, 300],
            "prerequisites": [],
            "provisions_cost": 0,
            "event_id": "EV001"
        },
        "n002": {
            "id": "n002",
            "type": "BATTLE",
            "position": [250, 200],
            "prerequisites": ["n001"],
            "provisions_cost": 3,
            "enemy_id": "E001"
        },
        "n003": {
            "id": "n003",
            "type": "SHOP",
            "position": [250, 400],
            "prerequisites": ["n001"],
            "provisions_cost": 4
        },
        "n004": {
            "id": "n004",
            "type": "BOSS",
            "position": [400, 300],
            "prerequisites": ["n002", "n003"],
            "provisions_cost": 8,
            "enemy_id": "E100"
        }
    }
}
```

## Alternatives Considered

### Alternative 1: 线性关卡
- **描述**: 只有一条路线，前一个通过才能打后一个
- **优点**: 简单
- **缺点**: 缺乏选择自由
- **未采用原因**: 不符合肉鸽游戏设计

### Alternative 2: 随机生成地图
- **描述**: 每次战役随机生成节点
- **优点**: 高度随机性
- **缺点**: 难以保证平衡
- **未采用原因**: 需要大量测试

### Alternative 3: 预定义树形图 (推荐方案)
- **描述**: 设计师预先定义节点布局和连接
- **优点**: 可控性强、可测试、存档简单
- **采用原因**: 平衡随机性与可控性

## Consequences

### Positive
- **可预测**: 玩家可以看到可选路线
- **可平衡**: 设计师控制节点难度
- **可存档**: 访问状态简单保存
- **可扩展**: 新增节点类型只需添加类型

### Negative
- **重玩性**: 固定地图可能导致重复
  - **缓解**: 多个战役剧本，节点奖励随机

### Risks
- **粮草耗尽**: 玩家无法到达后续节点
  - **缓解**: 酒馆节点补充粮草

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| map-design.md (M1) | 树形地图结构 | MapGraph 树形存储 |
| map-design.md (M1) | 节点类型 | NodeType 枚举定义 |
| map-design.md (M1) | 前置依赖 | prerequisites 检查逻辑 |
| map-design.md (M1) | 粮草消耗 | provisions_cost 配置 |
| map-design.md (M1) | 战役层卡组管理 | 节点变更（商店购买、军营删除、事件获得）更新 CampaignDeckSnapshot |

## Validation Criteria
- [ ] 节点正确显示可访问/锁定状态
- [ ] 前置节点未通过则无法访问
- [ ] 粮草不足时无法导航
- [ ] 访问状态正确保存到存档
- [ ] BOSS击败后显示通关
- [ ] 商店购买/军营删除/事件获得卡牌正确更新战役层卡组

## Related Decisions
- ADR-0001: 场景管理策略 — 地图场景结构
- ADR-0003: 资源变更通知机制 — 粮草消耗通知
- ADR-0005: 存档序列化方案 — 地图进度保存
- ADR-0020: 卡组两层管理架构 — 战役层卡组持久化