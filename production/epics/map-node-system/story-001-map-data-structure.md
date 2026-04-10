# Story: 地图数据结构与节点类型

> **Type**: Logic
> **Epic**: map-node-system
> **ADR**: ADR-0011
> **Status**: Ready

## Context

地图节点系统需要定义树形地图数据结构。包含6种节点类型：战斗、精英战斗、BOSS、商店、酒馆、军营、奇遇。数据结构需要支持节点导航、状态追踪和持久化。

**依赖**：
- ADR-0011 (Map Node System) - MapGraph + MapNavigator

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 6种节点类型正确定义（战斗/精英/BOSS/商店/酒馆/军营/奇遇） | 单元测试：验证节点类型枚举 |
| AC2 | 树形数据结构支持父子节点关系 | 单元测试：验证节点树结构 |
| AC3 | 每张地图包含至少1个商店/1个酒馆/1个军营 | 数据验证：遍历生成地图 |
| AC4 | 节点包含：ID、类型、位置、连接、状态 | 单元测试：检查节点数据结构 |

## Implementation Notes

### 节点类型定义

```gdscript
enum NodeType {
    BATTLE,      # 普通战斗
    ELITE,       # 精英战斗
    BOSS,        # Boss战斗
    SHOP,        # 商店节点
    INN,         # 酒馆节点
    BARRACKS,    # 军营节点
    ENCOUNTER    # 奇遇/事件节点
}

class MapNode:
    var node_id: String
    var node_type: NodeType
    var position: Vector2
    var parent_nodes: Array[String]
    var child_nodes: Array[String]

    # 状态
    var is_visited: bool = false
    var is_completed: bool = false
    var terrain: String
    var weather: String
```

### 地图数据结构

```gdscript
class CampaignMap:
    var hero_id: String
    var campaign_id: int
    var map_id: int  # 1~3 (起/承/转)
    var nodes: Dictionary  # {node_id: MapNode}
    var start_node_id: String
    var boss_node_id: String
    var current_terrain: String
    var current_weather: String

    # 地图生成规则
    const MIN_LAYERS = 12
    const MAX_LAYERS = 16
    const BOSS_LAYER = 15

    # 节点权重
    const WEIGHT_BATTLE = 0.45
    const WEIGHT_ENCOUNTER = 0.25
    const WEIGHT_SHOP = 0.10
    const WEIGHT_INN = 0.10
    const WEIGHT_BARRACKS = 0.10
```

## QA Test Cases

1. **test_all_node_types_defined** - 验证6种节点类型
2. **test_tree_structure** - 树形结构正确
3. **test_mandatory_nodes** - 必要节点存在
4. **test_node_data_fields** - 节点数据结构完整
