# Story: 节点导航与粮草消耗

> **Type**: Logic
> **Epic**: map-node-system
> **ADR**: ADR-0003
> **Status**: Ready

## Context

节点导航需要检查前置节点访问状态和粮草消耗。移动到非Boss节点消耗2-8粮草，Boss节点消耗10粮草。

**依赖**：
- ADR-0003 (Resource Notification) - 资源变更通知

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 移动到节点前检查前置节点是否已访问 | 功能测试：未访问前置节点时阻止移动 |
| AC2 | 移动消耗粮草：非Boss 2-8，Boss 10 | 功能测试：验证粮草扣除 |
| AC3 | 粮草不足时阻止移动 | 功能测试：粮草=5尝试移动消耗8的节点 |
| AC4 | 访问后标记节点为已访问 | 功能测试：访问后检查状态 |
| AC5 | Boss胜利后恢复50粮草 | 功能测试：Boss战后验证粮草恢复 |

## Implementation Notes

### 导航接口

```gdscript
class MapNavigator:

    const CARGO_COST_MIN = 2
    const CARGO_COST_MAX = 8
    const CARGO_COST_BOSS = 10
    const CARGO_REWARD_BOSS = 50

    func can_move_to(target_node_id: String, current_cargo: int) -> Dictionary:
        var node = get_node(target_node_id)

        # 检查前置节点
        if not are_parent_nodes_visited(node):
            return {can_move: false, reason: "前置节点未完成"}

        # 计算消耗
        var cost = calculate_move_cost(node)

        # 检查粮草
        if current_cargo < cost:
            return {can_move: false, reason: "粮草不足", required: cost, available: current_cargo}

        return {can_move: true, cost: cost}

    func move_to(target_node_id: String) -> Dictionary:
        var node = get_node(target_node_id)
        var cost = calculate_move_cost(node)

        # 扣除粮草
        ResourceSystem.modify_cargo(-cost)

        # 标记访问
        mark_node_visited(target_node_id)

        # Boss战后奖励
        if node.node_type == NodeType.BOSS:
            ResourceSystem.modify_cargo(CARGO_REWARD_BOSS)

        return {success: true, cost: cost, reward: node.node_type == NodeType.BOSS ? CARGO_REWARD_BOSS : 0}
```

### 消耗计算

```gdscript
func calculate_move_cost(node: MapNode) -> int:
    if node.node_type == NodeType.BOSS:
        return CARGO_COST_BOSS

    # 随机2-8
    return randi_range(CARGO_COST_MIN, CARGO_COST_MAX)
```

## QA Test Cases

1. **test_parent_visited_check** - 前置节点检查
2. **test_cargo_cost_normal** - 普通节点粮草消耗
3. **test_cargo_cost_boss** - Boss节点粮草消耗
4. **test_insufficient_cargo_block** - 粮草不足阻止移动
5. **test_visited_mark** - 访问标记
6. **test_boss_reward** - Boss战后粮草恢复
