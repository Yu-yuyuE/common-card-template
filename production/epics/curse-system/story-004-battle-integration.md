# Story: 诅咒卡战斗集成

Type: Integration
Epic: curse-system
> **ADR**: ADR-0007
Estimate: 1 day
Status: Ready

## Context

诅咒卡在战斗中需要正确处理三种类型的触发逻辑：抽到触发型立即结算、常驻牌库型持续生效、常驻手牌型占位管理。与 CardBattleSystem 紧密集成。

**依赖**：
- ADR-0007 (Card Battle System) - 战斗中的抽牌/弃牌/手牌位管理

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 抽到触发型被抽入手牌时立即触发效果 | 战斗测试：抽到毒药时 HP 立即减少 |
| AC2 | 常驻牌库型在牌库/弃牌堆中持续生效 | 数值测试：2张韬晦在牌库中 MaxHP-6 |
| AC3 | 常驻手牌型占用手牌位，费用足够可丢弃 | 战斗测试：手持泥泞，1费可丢弃，0费不可 |
| AC4 | 抽到触发型触发后进入弃牌堆正常循环 | 战斗测试：毒药触发后进入弃牌堆 |
| AC5 | 常驻手牌型战斗结束自动进入弃牌堆 | 战斗测试：战斗结束时泥泞进入弃牌堆 |
| AC6 | 诅咒卡不可主动打出 | UI测试：诅咒卡无打出按钮 |

## Implementation Notes

### 与 C2 集成点

1. **抽牌时** (CardBattleSystem.draw_card)：
   - 检查是否为诅咒卡
   - 若为抽到触发型：立即触发效果 → 进入弃牌堆
   - 若为常驻牌库型：记录在手牌，效果持续
   - 若为常驻手牌型：占用手牌位，等待玩家操作

2. **每回合开始时** (BattleRound.start)：
   - 重新计算 ActivePersistentCurses
   - 应用常驻牌库型持续效果（如 MaxHP 削减）

3. **战斗结束时** (BattleRound.end)：
   - 手牌中所有卡（包括常驻手牌型）进入弃牌堆

### 持续效果计算

```gdscript
func calculate_persistent_effects() -> Dictionary:
    var curse_count = count_cards_in_locations(
        [CardLocation.LIBRARY, CardLocation.DISCARD_PILE, CardLocation.HAND],
        {curse_type: CurseType.PERSISTENT_LIBRARY}
    )

    return {
        "max_hp_reduction": curse_count * 3,  # 韬晦：每张 MaxHP-3
        # 其他常驻效果...
    }
```

## QA Test Cases

1. **test_draw_trigger_curse_execution** - 抽到触发型立即执行
2. **test_persistent_library_effect_calculation** - 常驻牌库型效果计算
3. **test_persistent_hand_slot_management** - 常驻手牌型占位
4. **test_curse_card_cannot_be_played** - 诅咒卡不可打出

## Out of Scope
- 视觉特效与音效 (Visual/Audio FX)
- UI 界面显示 (由后续独立 UI Story 负责)


## Test Evidence
- **位置**: `tests/unit/`
- **要求**: 所有验收标准必须有对应的自动化单元测试覆盖。

