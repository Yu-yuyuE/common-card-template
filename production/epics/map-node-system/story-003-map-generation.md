# Story: 地图生成算法

> **Type**: Logic
> **Epic**: map-node-system
> **ADR**: ADR-0011
> **Status**: Complete

## Context

每张地图需要按规则生成：12-16层，每层2-3条分叉路径，保证无死路，包含必要节点类型，每5层一个精英节点。

**GDD 来源**：`design/gdd/map-design.md` — 第2节"每幕层数规则"、第3节"节点类型"、第5节"路线与分叉规则"、第7节"节点导航与路径生成"算法步骤1~6、Formulas F1/F4/F5

**依赖 Story**：
- story-001-map-data-structure.md（Status: Complete）— 提供 MapNode、MapGraph、CampaignMap 类型

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 生成地图层数在 [12, 16] 闭区间内 | 单元测试：生成100张地图，断言所有 `layer_count` ∈ [12, 16] |
| AC2 | 每个中间层（非起始层、非Boss层）的每个父节点有2~3个子节点 | 单元测试：生成100张地图，遍历所有中间层节点，断言子节点数 ∈ [2, 3] |
| AC3 | 从起始节点到Boss节点存在至少一条有向路径 | 单元测试：对生成地图执行 DFS，断言 Boss 节点在可达集合内 |
| AC4 | 每张地图包含至少1个 SHOP 节点、至少1个 INN 节点、至少1个 BARRACKS 节点 | 单元测试：生成地图后遍历 `map.nodes`，断言三种类型各 ≥ 1 |
| AC5 | 第5层和第10层（允许 ±1 层容差）各存在至少1个 ELITE 节点 | 单元测试：生成100张地图，检查层5±1和层10±1范围内各含 ≥ 1 个 ELITE 节点 |

## Implementation Notes

### ADR-0011 约束（Feature Layer，必须遵守）

- **禁止完全随机生成节点**——本算法使用权重控制节点类型（GDD F4），符合规范
- **生成结果必须通过可达性验证（DFS，GDD F5）**，不可达则重新生成（最多重试3次）
- **MapGenerator 应为纯逻辑类**，不继承 Node，使用 `class_name MapGenerator extends RefCounted`
- **节点类型枚举**通过 `MapNode.NodeType` 访问（与 story-001 定义一致）
- 禁止跳过可达性验证直接返回地图

### 权重常量（GDD F4）

```gdscript
const WEIGHT_BATTLE:   float = 0.45   # 战斗节点
const WEIGHT_ENCOUNTER: float = 0.25  # 奇遇节点（对应 EVENT）
const WEIGHT_SHOP:     float = 0.10   # 商店节点
const WEIGHT_INN:      float = 0.10   # 酒馆节点
const WEIGHT_BARRACKS: float = 0.10   # 军营节点
# 精英节点由 add_elite_nodes() 强制插入，不参与权重随机
```

### 性能预期

地图生成仅在战役开始时运行一次，不在主游戏循环内执行；整体生成时间预期 <50ms（ADR-0011 地图配置加载约束）。可达性验证失败概率极低，重试次数不超过3次。

### 生成算法

```gdscript
class_name MapGenerator extends RefCounted

    func generate_map(hero_id: String, campaign_id: int, map_id: int) -> CampaignMap:
        var map = CampaignMap.new()
        map.hero_id = hero_id
        map.campaign_id = campaign_id
        map.map_id = map_id

        # 生成层数和节点
        var layer_count = randi_range(12, 16)
        generate_layers(map, layer_count)

        # 确保必要节点
        ensure_mandatory_nodes(map)

        # 精英节点分布
        add_elite_nodes(map)

        # 验证可达性
        if not verify_reachability(map):
            return generate_map(hero_id, campaign_id, map_id)  # 重新生成

        return map

    func generate_layers(map: CampaignMap, layer_count: int):
        var current_layer_nodes = []

        # 起始节点
        var start_node = create_node("start", MapNode.NodeType.BATTLE, 0)
        map.nodes[start_node.node_id] = start_node
        current_layer_nodes.append(start_node)

        # 生成后续层
        for layer in range(1, layer_count):
            var next_layer_nodes = []

            for parent in current_layer_nodes:
                # 每层2-3条分叉
                var branch_count = randi_range(2, 3)

                for i in range(branch_count):
                    var node_type = select_node_type_by_weight()
                    var node = create_node(
                        "node_%d_%d" % [layer, i],
                        node_type,
                        layer
                    )

                    map.nodes[node.node_id] = node
                    parent.child_nodes.append(node.node_id)
                    node.parent_nodes.append(parent.node_id)
                    next_layer_nodes.append(node)

            current_layer_nodes = next_layer_nodes

        # Boss节点
        var boss_node = create_node("boss", MapNode.NodeType.BOSS, layer_count - 1)
        map.nodes[boss_node.node_id] = boss_node
        for last_node in current_layer_nodes:
            last_node.child_nodes.append(boss_node.node_id)
            boss_node.parent_nodes.append(last_node.node_id)

    func select_node_type_by_weight() -> MapNode.NodeType:
        var rand: float = randf()
        if rand < WEIGHT_BATTLE:
            return MapNode.NodeType.BATTLE
        elif rand < WEIGHT_BATTLE + WEIGHT_ENCOUNTER:
            return MapNode.NodeType.EVENT
        elif rand < WEIGHT_BATTLE + WEIGHT_ENCOUNTER + WEIGHT_SHOP:
            return MapNode.NodeType.SHOP
        elif rand < WEIGHT_BATTLE + WEIGHT_ENCOUNTER + WEIGHT_SHOP + WEIGHT_INN:
            return MapNode.NodeType.INN
        else:
            return MapNode.NodeType.BARRACKS

    func verify_reachability(map: CampaignMap) -> bool:
        # DFS验证所有节点可达
        var visited = {}
        var stack = [map.start_node_id]

        while not stack.is_empty():
            var node_id = stack.pop_back()
            if node_id in visited:
                continue
            visited[node_id] = true

            var node = map.nodes[node_id]
            for child_id in node.child_nodes:
                if not child_id in visited:
                    stack.append(child_id)

        # 检查所有非起始节点是否可达
        for node_id in map.nodes:
            if node_id != map.start_node_id and not node_id in visited:
                return false

        return true
```

## QA Test Cases

1. **test_map_generator_layer_count_within_range** — AC1：生成100张地图，断言层数均在 [12, 16] 内
2. **test_map_generator_branch_count_within_range** — AC2：遍历中间层节点，断言每个父节点子节点数 ∈ [2, 3]
3. **test_map_generator_boss_is_reachable** — AC3：DFS 验证 Boss 节点在起始节点可达集合内
4. **test_map_generator_mandatory_nodes_present** — AC4：断言生成地图含 ≥1 SHOP、≥1 INN、≥1 BARRACKS
5. **test_map_generator_elite_nodes_at_layer5_and_10** — AC5：检查层5±1 和层10±1 各含 ≥1 ELITE

## Out of Scope

- 地图 UI 渲染与节点可视化（MapRenderer，后续 story）
- 地图进度持久化到存档（story-004-campaign-management.md 范围）
- 从 CSV/JSON 加载预设地图（story-001 范围，本 story 仅生成算法）
- 酒馆/军营/商店节点的具体功能实现（各自 epic 范围）
- 精英节点和 Boss 节点的战斗内容（card-battle-system 范围）
- `MapNavigator`、`MapGraph` 的修改（story-001/002 范围）

## Estimate

约 **1.0 天 / 8 小时**（Logic story，含随机生成算法、可达性验证、强制节点保证逻辑、覆盖 AC1~AC5 的统计采样测试）

## Test Evidence

`tests/unit/map_system/map_generator_test.gd`

## Completion Notes
**Completed**: 2026-04-17
**Criteria**: 5/5 passing
**Deviations**: ADVISORY — `position.y` 隐式编码层索引（MapNode 无 layer 字段，以 position.y 作为约定；功能等价，脆弱，建议后续 sprint 为 MapNode 补充 layer 字段）
**Test Evidence**: Logic story — `tests/unit/map_system/map_generator_test.gd`（11 个测试函数，覆盖 AC1~AC5 全部标准，100次统计采样验证随机边界）
**Code Review**: Complete — APPROVED WITH SUGGESTIONS（已修复 BLOCKING 参数命名问题）
