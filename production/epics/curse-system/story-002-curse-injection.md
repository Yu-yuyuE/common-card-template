# Story: 诅咒卡注入机制

> **Type**: Logic
> **Epic**: curse-system
> **ADR**: ADR-0007, ADR-0008
> **Status**: Ready

## Context

诅咒卡通过多种来源注入玩家卡组：敌人行动、地图事件、卡牌效果、司马懿初始卡组。每种来源的注入时机和位置不同，需要统一的注入接口。

**依赖**：
- ADR-0007 (Card Battle System) - 注入后由 C2 管理卡牌位置
- ADR-0008 (Enemy System) - 敌人 B/C 类行动调用注入接口

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 敌人行动注入诅咒卡到玩家弃牌堆 | 集成测试：触发敌人B类行动，检查玩家弃牌堆 |
| AC2 | 地图事件注入诅咒卡到玩家牌库 | 集成测试：触发负面事件，检查玩家牌库 |
| AC3 | 卡牌效果注入诅咒卡到指定位置 | 单元测试：模拟注入调用，验证目标位置 |
| AC4 | 司马懿初始卡组预置2张韬晦 | 配置测试：司马懿开局牌组验证 |
| AC5 | 注入时触发 OnCurseInjected 事件 | 集成测试：监听事件确认触发 |

## Implementation Notes

### 注入接口设计

```gdscript
class_name CurseSystem extends Node

enum InjectionSource {
    ENEMY_ACTION,
    MAP_EVENT,
    CARD_EFFECT,
    HERO_INITIAL_DECK
}

enum InjectionLocation {
    DISCARD_PILE,
    LIBRARY,
    HAND
}

func inject_curse_card(
    card_id: String,
    source: InjectionSource,
    location: InjectionLocation
) -> void:
    # 调用 C2 的卡牌注入接口
    # 记录注入来源用于日志
    # 触发 OnCurseInjected 信号
```

### 注入规则

- 敌人行动注入 → 弃牌堆（下次洗牌进入牌库）
- 地图事件注入 → 牌库（立即生效）
- 卡牌效果注入 → 按卡牌文本定义
- 司马懿初始 → 牌库（预置，不触发注入事件）

## QA Test Cases

1. **test_enemy_action_injection** - 敌人行动注入到弃牌堆
2. **test_map_event_injection** - 事件注入到牌库
3. **test_hero_initial_curse_setup** - 司马懿初始2张韬晦
4. **test_injection_event_hook** - 注入事件触发验证
