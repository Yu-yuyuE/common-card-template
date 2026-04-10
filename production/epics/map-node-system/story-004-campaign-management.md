# Story: 战役进度管理

> **Type**: Integration
> **Epic**: map-node-system
> **ADR**: ADR-0005
> **Status**: Ready

## Context

每位武将5场战役，每场3张小地图。战役结束后保留Meta Save，清除Run Save。Boss击败后触发AllNodesCompleted信号。

**依赖**：
- ADR-0005 (Save Serialization) - 存档持久化

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 每位武将5场战役，每场3张小地图 | 配置验证：检查战役结构 |
| AC2 | Boss击败后触发AllNodesCompleted信号 | 功能测试：Boss战后检查信号 |
| AC3 | 战役结束后保存Meta Save，清除Run Save | 存档测试：战役结束后验证存档 |
| AC4 | 战役进度正确持久化和恢复 | 存档测试：保存重载后验证进度 |

## Implementation Notes

### 战役管理

```gdscript
class CampaignManager:

    const CAMPAIGNS_PER_HERO = 5
    const MAPS_PER_CAMPAIGN = 3

    var current_hero_id: String
    var current_campaign: int = 1
    var current_map: int = 1

    # 信号
    signal AllNodesCompleted(hero_id: String, campaign: int)
    signal CampaignCompleted(hero_id: String)
    signal GameCompleted(hero_id: String)

    func on_boss_defeated():
        var map = get_current_map()
        mark_map_completed(map.map_id)

        if current_map < MAPS_PER_CAMPAIGN:
            # 进入下一张地图
            current_map += 1
            load_map(current_map)
        elif current_campaign < CAMPAIGNS_PER_HERO:
            # 进入下一场战役
            current_campaign += 1
            current_map = 1
            start_new_campaign()
        else:
            # 全部完成
            GameCompleted.emit(current_hero_id)

    func mark_map_completed(map_id: int):
        var map = get_map(current_hero_id, current_campaign, map_id)
        map.is_completed = true
        AllNodesCompleted.emit(current_hero_id, current_campaign)

    func start_new_campaign():
        # 战役结束时保存Meta，清除Run
        SaveSystem.save_meta()
        SaveSystem.clear_run()

    func save_campaign_progress():
        var data = {
            "hero_id": current_hero_id,
            "campaign": current_campaign,
            "map": current_map,
            "visited_nodes": get_visited_nodes(),
            "cargo": ResourceSystem.get_current_cargo()
        }
        SaveSystem.save_run_data(data)

    func load_campaign_progress():
        var data = SaveSystem.load_run_data()
        if data.is_empty():
            return false

        current_hero_id = data.get("hero_id")
        current_campaign = data.get("campaign", 1)
        current_map = data.get("map", 1)

        restore_visited_nodes(data.get("visited_nodes", []))
        ResourceSystem.set_cargo(data.get("cargo", 150))

        return true
```

## QA Test Cases

1. **test_campaign_structure** - 5战役x3地图结构
2. **test_boss_completed_signal** - Boss击败信号
3. **test_meta_save_on_campaign_end** - 战役结束保存Meta
4. **test_run_clear_on_campaign_end** - 战役结束清除Run
5. **test_campaign_progress_persistence** - 进度持久化
