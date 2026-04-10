# Story: 诅咒净化机制

> **Type**: Logic
> **Epic**: curse-system
> **ADR**: ADR-0005, ADR-0012
> **Status**: Ready

## Context

净化操作将诅咒卡从玩家卡组永久移出。净化可通过商店节点、技能卡、事件奖励三种途径触发。净化后诅咒卡不再出现在本局任何位置。

**依赖**：
- ADR-0005 (Save Serialization) - 净化状态需持久化
- ADR-0012 (Shop System) - 商店节点净化调用接口

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 净化操作将指定诅咒卡移出卡组 | 单元测试：净化后检查卡组不包含该卡 |
| AC2 | 净化后卡组不包含该卡（牌库/弃牌堆/手牌） | 战役测试：净化后3场战斗该卡不出现 |
| AC3 | 净化常驻牌库型后 MaxHP 立即恢复 | 数值测试：净化1张韬晦后 MaxHP 恢复 3 点 |
| AC4 | 净化触发 OnCursePurified 事件 | 集成测试：监听事件确认触发 |
| AC5 | 可指定具体诅咒卡进行净化 | 单元测试：多张诅咒卡时净化指定张 |

## Implementation Notes

### 净化接口设计

```gdscript
class_name CurseSystem extends Node

enum PurificationSource {
    SHOP_NODE,
    SKILL_CARD,
    EVENT_REWARD
}

func purify_curse_card(
    card_id: String,
    source: PurificationSource,
    target_location: int  # 卡牌当前所在位置（手牌/牌库/弃牌堆）
) -> bool:
    # 验证卡牌是否为诅咒卡
    # 从卡组记录中移除
    # 触发 OnCursePurified 信号
    # 更新持久化数据
    # 若为常驻牌库型，立即重新计算 MaxHP
    return true
```

### 净化规则

- 目标：卡牌本身，无论当前位于何处
- 结果：卡牌进入"移出卡组"状态
- 立即生效：净化当回合常驻牌库型效果消除
- 持久化：净化记录需保存到存档

## QA Test Cases

1. **test_purification_removes_from_deck** - 净化后卡组不含该卡
2. **test_persistent_library_purification_effect** - 净化常驻牌库型立即恢复属性
3. **test_purification_event_hook** - 净化事件触发
4. **test_purification_persistence** - 净化状态持久化
