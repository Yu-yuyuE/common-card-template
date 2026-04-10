# Story: 事件后果执行

> **Type**: Logic
> **Epic**: event-system
> **ADR**: ADR-0003, ADR-0009
> **Status**: Ready

## Context

事件后果分为4类：资源变化、战斗触发、卡组变化、天气修改。每类后果需要调用对应系统接口执行。

**依赖**：
- ADR-0003 (Resource Notification) - 资源变更通知
- ADR-0009 (Terrain Weather System) - 天气修改

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 资源变化正确执行（金币±20~100、粮草±10~50、HP±5~20） | 功能测试：触发后果验证数值变化 |
| AC2 | 战斗触发正确发起战斗 | 功能测试：触发战斗事件进入战斗场景 |
| AC3 | 卡组变化：获得/移除/升级卡牌正确执行 | 功能测试：触发卡组变化事件验证 |
| AC4 | 天气修改在下一场战斗生效 | 功能测试：触发天气事件后经过非战斗节点进入战斗，验证天气 |

## Implementation Notes

### 后果执行接口

```gdscript
enum ConsequenceType {
    RESOURCE,      # 资源变化
    BATTLE,        # 战斗触发
    DECK_CHANGE,   # 卡组变化
    WEATHER        # 天气修改
}

class EventConsequenceExecutor:

    func execute(consequence: ConsequenceData):
        match consequence.type:
            ConsequenceType.RESOURCE:
                execute_resource_change(consequence)
            ConsequenceType.BATTLE:
                execute_battle_trigger(consequence)
            ConsequenceType.DECK_CHANGE:
                execute_deck_change(consequence)
            ConsequenceType.WEATHER:
                execute_weather_change(consequence)

    func execute_resource_change(consequence: ConsequenceData):
        match consequence.target:
            "gold":
                ResourceSystem.modify_gold(consequence.value)
            "food":
                ResourceSystem.modify_food(consequence.value)
            "hp":
                ResourceSystem.modify_hp(consequence.value)

    func execute_battle_trigger(consequence: ConsequenceData):
        # 调用 C2 发起战斗
        BattleSystem.start_event_battle(consequence.enemy_config)

    func execute_deck_change(consequence: ConsequenceData):
        match consequence.value:
            "add_card":
                CardSystem.add_random_card(consequence.card_pool)
            "remove_card":
                CardSystem.remove_player_choice()
            "upgrade_card":
                CardSystem.upgrade_player_choice()

    func execute_weather_change(consequence: ConsequenceData):
        # 设置下一场战斗的强制天气
        WeatherSystem.set_next_battle_weather(consequence.target)
```

## QA Test Cases

1. **test_resource_change_gold** - 金币变化
2. **test_resource_change_food** - 粮草变化
3. **test_resource_change_hp** - HP变化
4. **test_battle_trigger** - 战斗触发
5. **test_deck_change_add** - 获得卡牌
6. **test_deck_change_remove** - 移除卡牌
7. **test_deck_change_upgrade** - 升级卡牌
8. **test_weather_change** - 天气修改
