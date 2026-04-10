# Story: 酒馆状态持久化

> **Type**: Integration
> **Epic**: inn-system
> **ADR**: ADR-0005
> **Status**: Ready

## Context

酒馆节点已访问状态和强化次数需要持久化保存。跨存档加载后应正确恢复状态。

**依赖**：
- ADR-0005 (Save Serialization) - 存档持久化

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 酒馆访问状态正确保存（歇息/强化使用标记） | 存档测试：保存后重载验证状态 |
| AC2 | 重访同一酒馆时状态正确恢复 | 功能测试：重访验证不重置 |
| AC3 | 存档损坏时默认视为"未访问" | 边界测试：损坏存档加载后正常 |

## Implementation Notes

### 持久化数据结构

```gdscript
class InnSaveData:
    var visited_nodes: Dictionary = {}  # {node_id: {rest_used: bool, fortify_used: bool}}

    func serialize() -> Dictionary:
        return {
            "visited_nodes": visited_nodes
        }

    func deserialize(data: Dictionary):
        visited_nodes = data.get("visited_nodes", {})

    func mark_visited(node_id: String, rest_used: bool, fortify_used: bool):
        visited_nodes[node_id] = {
            "rest_used": rest_used,
            "fortify_used": fortify_used
        }

    func get_node_state(node_id: String) -> Dictionary:
        return visited_nodes.get(node_id, {
            "rest_used": false,
            "fortify_used": false
        })
```

### 与 F1 集成

```gdscript
class InnPersistenceManager:

    func save_inn_state(node_id: String, state: InnNodeState):
        var save_data = SaveSystem.get_save_data()
        save_data.inn_data.mark_visited(node_id, state.is_rest_used, state.is_fortify_used)
        SaveSystem.save()

    func load_inn_state(node_id: String) -> InnNodeState:
        var save_data = SaveSystem.get_save_data()
        var state_data = save_data.inn_data.get_node_state(node_id)

        var state = InnNodeState.new()
        state.is_rest_used = state_data.get("rest_used", false)
        state.is_fortify_used = state_data.get("fortify_used", false)
        return state
```

## QA Test Cases

1. **test_inn_state_save** - 状态保存
2. **test_inn_state_load** - 状态加载
3. **test_inn_state_revisit** - 重访状态正确
4. **test_corrupted_save_default** - 损坏存档默认未访问
