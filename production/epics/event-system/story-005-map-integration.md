# Story: 事件地图集成与持久化

> **Type**: Integration
> **Epic**: event-system
> **ADR**: ADR-0005, ADR-0011
> **Status**: Ready

## Context

事件通过奇遇节点触发，需要与地图节点系统集成。已触发事件需要持久化保存，防止同地图重复触发。

**依赖**：
- ADR-0005 (Save Serialization) - 事件触发记录持久化
- ADR-0011 (Map Node System) - 地图节点触发

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 奇遇节点触发事件调用事件系统 | 集成测试：进入奇遇节点确认事件触发 |
| AC2 | 已触发事件记录由F1持久化 | 存档测试：保存重载后同图不重复 |
| AC3 | 天气修改跨越非战斗节点传递 | 功能测试：事件→商店→战斗，验证天气 |
| AC4 | 连续天气修改后触发的覆盖前一个 | 功能测试：连续2个天气事件，以最后为准 |

## Implementation Notes

### 与 M1 集成

```gdscript
class EventMapIntegration:

    func _on_encounter_node_entered(map_id: String, node_id: String):
        # 触发事件抽取
        var event = EventSelector.select_event(map_id, PlayerState.get_current())

        # 标记为已触发
        EventSelector.mark_triggered(map_id, event.event_id)

        # 持久化触发记录
        SaveSystem.save_event_trigger(map_id, event.event_id)

        # 显示事件
        if event.options.is_empty():
            EventOptionHandler.show_no_option_event(event)
        else:
            EventOptionHandler.show_options(event)
```

### 天气修改传递

```gdscript
class WeatherModifier:
    var next_battle_weather: String = ""  # 空=无修改

    func set_next_battle_weather(weather: String):
        next_battle_weather = weather

    func get_battle_weather() -> String:
        var weather = next_battle_weather
        next_battle_weather = ""  # 消耗后清空
        return weather if weather != "" else WeatherSystem.get_current_weather()

    # 战斗开始时调用
    func apply_to_battle():
        var weather = get_battle_weather()
        BattleSystem.set_forced_weather(weather)
```

### 持久化接口

```gdscript
# 存档数据结构
class SaveData:
    var triggered_events: Dictionary  # {map_id: [event_ids]}

    func serialize() -> Dictionary:
        return {
            "triggered_events": triggered_events
        }

    func deserialize(data: Dictionary):
        triggered_events = data.get("triggered_events", {})
```

## QA Test Cases

1. **test_encounter_node_triggers_event** - 奇遇节点触发事件
2. **test_event_trigger_persistence** - 触发记录持久化
3. **test_weather_pass_through_non_battle** - 天气跨越非战斗节点
4. **test_weather_override** - 连续天气覆盖
