# Story: 事件选项机制

> **Type**: Logic
> **Epic**: event-system
> **ADR**: ADR-0016
> **Status**: Ready

## Context

约30%的事件有2~3个选项，每个选项有不同的后果。选项之间应无绝对优劣，期望收益相近。

**依赖**：
- ADR-0016 (UI Data Binding) - UI数据显示绑定

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 有选项事件展示2~3个选项供玩家选择 | UI测试：触发EV-D01显示2个选项 |
| AC2 | 选择选项后执行对应后果 | 功能测试：选A执行A后果，选B执行B后果 |
| AC3 | 无选项事件不显示选项界面，直接结算 | UI测试：触发EV-A04直接结算 |
| AC4 | 玩家不选择时默认无后果或强制选择 | 边界测试：尝试关闭不选择 |

## Implementation Notes

### 选项数据结构

```gdscript
class EventOption:
    var option_text: String
    var consequences: Array[ConsequenceData]
    var is_default: bool = false  # 默认选项

class EventData:
    # ... 前面定义的数据 ...
    var options: Array[EventOption] = []  # 有选项事件专用
```

### 选项处理流程

```gdscript
class EventOptionHandler:

    func show_options(event: EventData) -> void:
        if event.options.is_empty():
            # 无选项事件，直接执行后果
            execute_consequences(event.consequences)
            return

        # 显示选项UI
        UI.show_event_options(event.options)

    func on_option_selected(option: EventOption):
        # 执行选中选项的后果
        execute_consequences(option.consequences)

    func execute_consequences(consequences: Array[ConsequenceData]):
        for consequence in consequences:
            EventConsequenceExecutor.execute(consequence)
```

### 选项收益设计原则

```
// 选项之间应无绝对优劣，期望收益相近
// 高收益选项 = 伴随更高风险或更多损失

示例：谋士来投
  选项A（接纳）：获得高级技能卡（≈75金）+ 触发战斗（风险）
  选项B（婉拒）：+30金币（稳定收益）
```

## QA Test Cases

1. **test_option_display** - 选项显示
2. **test_option_selection_execution** - 选择后执行后果
3. **test_no_option_direct_execution** - 无选项直接执行
4. **test_option_balanced_design** - 选项收益平衡
