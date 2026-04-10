# Story: 事件抽取与前置条件

> **Type**: Logic
> **Epic**: event-system
> **ADR**: ADR-0002, ADR-0011
> **Status**: Ready

## Context

事件触发时根据权重随机抽取，需检查前置条件和已触发记录。同地图内已触发事件不重复触发。

**依赖**：
- ADR-0002 (System Communication) - 信号通信
- ADR-0011 (Map Node System) - 地图节点触发

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 按权重随机抽取事件，权重1~3 | 数值测试：统计触发概率符合权重分布 |
| AC2 | 前置条件不满足的事件不进入抽取池 | 功能测试：粮草<30时 EV-C01 不触发 |
| AC3 | 同地图已触发事件不重复抽取 | 功能测试：同一地图触发后不再出现 |
| AC4 | 可用事件池为空时回退到全库抽取 | 边界测试：触发50次后仍可触发 |

## Implementation Notes

### 抽取逻辑

```gdscript
class EventSelector:
    var triggered_events: Dictionary = {}  # {map_id: [event_ids]}

    func select_event(map_id: String, player_state: Dictionary) -> EventData:
        var available = get_available_events(map_id, player_state)
        if available.is_empty():
            # 回退：忽略前置条件从全库抽取
            available = get_all_events_except(map_id)

        return weighted_random_select(available)

    func get_available_events(map_id: String, player_state: Dictionary) -> Array[EventData]:
        var result: Array[EventData] = []
        var triggered = triggered_events.get(map_id, [])

        for event in all_events:
            # 排除已触发
            if event.event_id in triggered:
                continue

            # 检查前置条件
            if not check_prerequisites(event.prerequisites, player_state):
                continue

            result.append(event)

        return result

    func weighted_random_select(events: Array[EventData]) -> EventData:
        var total_weight = 0
        for e in events:
            total_weight += e.weight

        var rand = randf() * total_weight
        var cumulative = 0

        for e in events:
            cumulative += e.weight
            if rand <= cumulative:
                return e

        return events[0]  # 兜底
```

### 权重公式

```
EventProbability(e) = BaseWeight(e) / ΣBaseWeight(available)
```

## QA Test Cases

1. **test_weighted_selection** - 按权重随机抽取
2. **test_prerequisite_filter** - 前置条件过滤
3. **test_no_repeat_in_map** - 同地图不重复
4. **test_empty_pool_fallback** - 空池回退
