# Story: 战役进度管理

> **Type**: Integration
> **Epic**: map-node-system
> **ADR**: ADR-0005（存档序列化）, ADR-0011（地图节点系统）
> **TR-ID**: TR-map-design-001, TR-save-persistence-system-001
> **Manifest Version**: 2026-04-09
> **Estimate**: 0.5d（4h）
> **Status**: Complete

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

## Completion Notes

**Completed**: 2026-04-20
**Criteria**: 4/4 passing
**Deviations**: None（load_campaign_progress 返回 bool 已修正，save_meta_stub 默认桩测试时注入替换）
**Test Evidence**: Integration — tests/integration/map_system/campaign_management_test.gd（9个测试函数）
**Code Review**: Skipped — Lean mode

## Out of Scope

- UI 层（战役选择界面、进度显示）— 由后续 UI story 实现
- 实际 SaveSystem 文件 I/O — 本 story 使用桩接口（stub），7-4 再接真实 SaveManager
- 战役内具体地图内容生成 — 由 map-generation story（6-3）负责
- Hero 选择与解锁逻辑 — 由 hero-system epic 负责

## Performance Notes

N/A — 本 story 为纯逻辑/数据管理，无游戏循环热路径，无性能预算约束。战役进度读写仅在战役开始/结束时触发，非帧级调用。

## Test Evidence

**Type**: Integration
**Required**: `tests/integration/map_system/campaign_management_test.gd`
（或等价路径 `tests/unit/map_system/campaign_management_test.gd`，按实现复杂度决定归属）
**Coverage**: 所有 AC 均须有对应测试函数（test_campaign_structure / test_boss_completed_signal / test_meta_save_on_campaign_end / test_run_clear_on_campaign_end / test_campaign_progress_persistence）
