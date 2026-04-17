# Story: 节点导航与粮草消耗

> **Type**: Logic
> **Epic**: map-node-system
> **ADR**: ADR-0011, ADR-0003
> **Status**: Complete

## Context

节点导航需要实现 `MapNavigator` 类，处理前置节点检查、粮草消耗与节点状态追踪。

**GDD 来源**：`design/gdd/map-design.md` — 第3节"节点导航与路径生成"规则7、第3节"资源消耗机制"规则8、Formulas F1/F3

关键规则摘录：
- 移动前必须检查所有前置节点（prerequisites）是否已访问
- 移动到非Boss节点消耗 `BaseCost + Random(0, Layer × 0.5)` 粮草（BaseCost=2，Layer=当前层数1~15）
- 移动到Boss节点消耗10粮草
- 粮草不足时拒绝移动
- Boss战胜利后恢复50粮草（由外部调用 `on_boss_defeated()`，不在 `navigate_to()` 内发放）

**依赖 Story**：
- story-001-map-data-structure.md（Status: Complete）— 提供 MapNode、MapGraph、CampaignMap 类型

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 前置节点未全部访问时，`can_navigate_to()` 返回 false | 单元测试：创建有前置节点的目标节点，不满足条件时断言返回 false |
| AC2 | `calculate_move_cost(node, layer)` 对非Boss节点返回 [2, 2+layer×0.5] 闭区间内的整数 | 单元测试：固定层数，运行1000次断言所有返回值在合法区间内（统计覆盖） |
| AC3 | 当前粮草 < 节点消耗时，`can_navigate_to()` 返回 false | 单元测试：mock ResourceManager，粮草=5，目标节点 provisions_cost=8，断言返回 false |
| AC4 | `navigate_to()` 成功后，目标节点 visited=true 且出现在 visited_nodes 中 | 单元测试：导航成功后检查节点状态和 visited_nodes 数组 |
| AC5 | `on_boss_defeated()` 调用后，ResourceManager.PROVISIONS 增加50 | 单元测试：mock ResourceManager，调用 on_boss_defeated()，断言 modify_resource 以 +50 被调用 |

## Implementation Notes

### ADR-0011 关键约束（必须遵守）

来自 `docs/architecture/adr-0011-map-node-system.md` Decision 节：

```gdscript
# map_navigator.gd
class_name MapNavigator extends Node

# 必须声明这三个 signal（ADR-0011 规定）
signal node_changed(from_node: String, to_node: String)
signal node_visited(node_id: String)
signal all_nodes_completed()

var graph: MapGraph
var current_node_id: String = ""
var visited_nodes: Array[String] = []
```

`navigate_to()` 返回 **bool**（不是 Dictionary）：
- `true` = 导航成功
- `false` = 前置节点未满足 或 粮草不足

### ADR-0003 资源接口（必须使用 ResourceManager，不得用 ResourceSystem）

```gdscript
# 读取粮草
var provisions: int = ResourceManager.get_resource(ResourceManager.ResourceType.PROVISIONS)

# 扣除粮草
ResourceManager.modify_resource(ResourceManager.ResourceType.PROVISIONS, -cost)

# Boss战胜利后补充粮草（在 on_boss_defeated() 中调用）
ResourceManager.modify_resource(ResourceManager.ResourceType.PROVISIONS, CARGO_REWARD_BOSS)
```

### 粮草消耗计算（严格按 GDD F1 公式）

```gdscript
const CARGO_COST_BASE: int = 2
const CARGO_COST_BOSS: int = 10
const CARGO_REWARD_BOSS: int = 50

## 计算移动到指定节点的粮草消耗。
## [br]node: 目标节点[br]layer: 当前层数（1~15）
func calculate_move_cost(node: MapNode, layer: int) -> int:
    if node.node_type == MapNode.NodeType.BOSS:
        return CARGO_COST_BOSS
    # GDD F1: BaseCost + Random(0, Layer × 0.5)
    var max_extra: int = int(layer * 0.5)
    return CARGO_COST_BASE + randi() % (max_extra + 1)
```

> ⚠️ 不要用 `randi_range(2, 8)`——那忽略了层数因素，与 GDD F1 不符。
> 层1消耗 2~2，层5消耗 2~4，层10消耗 2~7，层15消耗 2~9。

### Boss战胜利粮草恢复时机

`navigate_to()` 仅负责**移动**（扣除粮草、标记访问）。
Boss战胜利后的奖励由**外部**（BattleManager 或 GameState）在战斗结束后调用：

```gdscript
func on_boss_defeated() -> void:
    ResourceManager.modify_resource(
        ResourceManager.ResourceType.PROVISIONS,
        CARGO_REWARD_BOSS
    )
```

这样测试可以单独验证，不依赖战斗系统。

## Out of Scope

- 地图 UI 渲染和节点可视化（MapRenderer，后续 story）
- `visited_nodes` 持久化到存档（story-004-campaign-management.md 范围）
- Boss 战斗系统本身（card-battle-system 范围）
- 地图生成算法（story-003-map-generation.md 范围）
- `MapGraph.get_available_nodes()` 的实现（已在 story-001 范围内，本 story 调用即可）

## Estimate

约 **0.5 天 / 4 小时**（Logic story，纯 GDScript 数据逻辑，无 UI）

## Test Evidence

`tests/unit/map_system/map_navigator_test.gd`

## QA Test Cases

1. **test_map_navigator_can_navigate_to_returns_false_when_prerequisites_unmet** — AC1
2. **test_map_navigator_calculate_move_cost_boss_returns_10** — AC2 Boss分支
3. **test_map_navigator_calculate_move_cost_normal_within_range** — AC2 正常节点（1000次采样）
4. **test_map_navigator_can_navigate_to_returns_false_when_insufficient_provisions** — AC3
5. **test_map_navigator_navigate_to_marks_node_visited** — AC4
6. **test_map_navigator_on_boss_defeated_restores_provisions** — AC5

## Completion Notes
**Completed**: 2026-04-16
**Criteria**: 5/5 passing
**Deviations**: None
**Test Evidence**: Logic story — `tests/unit/map_system/map_navigator_test.gd`（14 个测试函数，覆盖 AC1~AC5 全部标准，MockNavigator 解耦 ResourceManager 单例）
**Code Review**: Skipped — Lean mode
