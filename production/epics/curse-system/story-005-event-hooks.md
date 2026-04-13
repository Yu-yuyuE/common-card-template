# Story: 诅咒事件钩子

Type: Integration
Epic: curse-system
> **ADR**: ADR-0002, ADR-0010
Estimate: 1 day
Status: Ready

## Context

诅咒系统需要向外暴露事件钩子，供其他系统（特别是司马懿被动）监听。核心事件是 OnCurseCardDrawn，每次诅咒卡进入手牌时触发。

**依赖**：
- ADR-0002 (System Communication) - Signal 通信模式
- ADR-0010 (Hero System) - 司马懿被动监听注册

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | OnCurseCardDrawn 在任意诅咒卡进入手牌时触发 | 集成测试：监听信号，抽到诅咒卡时确认触发 |
| AC2 | 重复抽到同一张诅咒卡触发多次信号 | 集成测试：抽到2次毒药，信号触发2次 |
| AC3 | 初始预置的司马懿韬晦不触发 OnCurseInjected | 配置测试：开局检查注入事件未触发 |
| AC4 | 三种诅咒类型都触发 OnCurseCardDrawn | 单元测试：每种类型抽到手牌，验证触发 |
| AC5 | 注入诅咒卡时触发 OnCurseInjected | 集成测试：敌人行动注入后检查事件 |

## Implementation Notes

### 信号定义

```gdscript
class_name CurseSystem extends Node

# 诅咒卡被抽入手牌时触发（三种类型都触发）
signal OnCurseCardDrawn(card_id: String, curse_type: CurseType)

# 诅咒卡被运行期注入时触发（初始预置不触发）
signal OnCurseInjected(card_id: String, source: InjectionSource)

# 诅咒卡被净化移出时触发
signal OnCursePurified(card_id: String, source: PurificationSource)
```

### 触发时机

1. **OnCurseCardDrawn**：
   - 抽牌阶段，任何诅咒卡进入手牌时
   - 包括抽到触发型（触发效果后仍进入手牌结算）
   - 包括常驻牌库型、常驻手牌型

2. **OnCurseInjected**：
   - 敌人行动、地图事件、卡牌效果注入时
   - 司马懿初始卡组预置**不触发**

3. **OnCursePurified**：
   - 任何净化操作执行成功后触发

### 司马懿集成

```gdscript
# 司马懿被动示例
func _on_curse_card_drawn(card_id: String, curse_type: CurseType):
    if hero_id == "hero_sima_yi":
        add_stack("隐忍")  # 每次诅咒卡上手+1层隐忍
```

## QA Test Cases

1. **test_curse_drawn_signal_all_types** - 三种类型都触发信号
2. **test_curse_drawn_signal_repeat** - 重复抽到触发多次
3. **test_injection_signal_triggered** - 注入事件触发
4. **test_purification_signal_triggered** - 净化事件触发
5. **test_sima_yi_passive_integration** - 司马懿被动监听

## Out of Scope
- 视觉特效与音效 (Visual/Audio FX)
- UI 界面显示 (由后续独立 UI Story 负责)


## Test Evidence
- **位置**: `tests/unit/`
- **要求**: 所有验收标准必须有对应的自动化单元测试覆盖。

