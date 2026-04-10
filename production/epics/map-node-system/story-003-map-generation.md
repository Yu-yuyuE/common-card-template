# Story: 地图生成算法

> **Type**: Logic
> **Epic**: map-node-system
> **ADR**: ADR-0011
> **Status**: Ready

## Context

每张地图需要按规则生成：12-16层，每层2-3条分叉路径，保证无死路，包含必要节点类型，每5层一个精英节点。

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 地图层数12-16层 | 数据验证：生成地图检查层数 |
| AC2 | 每层2-3条分叉路径 | 数据验证：检查节点分支数 |
| AC3 | 保证从起点到Boss可达 | 算法验证：DFS验证路径存在 |
| AC4 | 每幕包含1个商店/1个酒馆/1个军营 | 数据验证：遍历节点类型 |
| AC5 | 每5层一个精英节点 | 数据验证：检查精英分布 |

## Implementation Notes

### 生成算法

```gdscript
class MapGenerator:

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
        var start_node = create_node("start", NodeType.BATTLE, 0)
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
        var boss_node = create_node("boss", NodeType.BOSS, layer_count - 1)
        map.nodes[boss_node.node_id] = boss_node
        for last_node in current_layer_nodes:
            last_node.child_nodes.append(boss_node.node_id)
            boss_node.parent_nodes.append(last_node.node_id)

    func select_node_type_by_weight() -> NodeType:
        var rand = randf()
        if rand < 0.45:
            return NodeType.BATTLE
        elif rand < 0.70:
            return NodeType.ENCOUNTER
        elif rand < 0.80:
            return NodeType.SHOP
        elif rand < 0.90:
            return NodeType.INN
        else:
            return NodeType.BARRACKS

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

1. **test_layer_count** - 层数范围
2. **test_branch_count** - 分叉数量
3. **test_path_reachability** - 路径可达
4. **test_mandatory_nodes** - 必要节点存在
5. **test_elite_distribution** - 精英节点分布
