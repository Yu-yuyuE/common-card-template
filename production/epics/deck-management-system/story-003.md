# Story: 卡组管理器集成

> **Epic**: deck-management-system
> **Type**: Logic
> **Status**: Ready
> **Estimate**: 2 hours
> **ADR**: ADR-0020
> **GDD**: design/gdd/cards-design.md (§0-§1)

## Overview

实现战役层卡组管理器，作为卡组两层架构的核心协调者。负责创建和管理战役层快照、在战斗开始时初始化战斗层快照、在战斗结束时回写变更。

## Acceptance Criteria

- [ ] 创建 `CampaignDeckManager` 类继承 `Node`
- [ ] 维护 `current_snapshot: CampaignDeckSnapshot` 当前战役层快照
- [ ] 维护 `current_battle_snapshot: BattleDeckSnapshot` 当前战斗层快照（可为null）
- [ ] 实现 `initialize_campaign(hero_id)` 方法初始化新战役并加载武将初始卡组
- [ ] 实现 `start_battle()` 方法从战役层快照创建战斗层快照
- [ ] 实现 `end_battle()` 方法处理战斗结束回写并销毁战斗层快照
- [ ] 实现 `serialize()` 和 `deserialize(data)` 方法用于存档系统
- [ ] 发射 `campaign_snapshot_changed` 和 `battle_snapshot_changed` 信号
- [ ] 在 `end_battle()` 中正确处理 `exhaust_cards` 回写到战役层
- [ ] 所有操作都有单元测试覆盖（8+测试用例）

## Dependencies

- Story 001: 战役层卡组快照基础实现
- Story 002: 战斗层卡组快照基础实现
- ADR-0020: 卡组两层管理架构
- ADR-0005: 存档序列化方案
- ADR-0007: 卡牌战斗系统架构

## Implementation Notes

- 战斗开始时必须调用 `BattleDeckSnapshot.initialize_from_campaign()`
- 战斗结束时必须正确处理 `exhaust_cards`（永久消耗卡牌）
- `serialize()` 和 `deserialize()` 必须与存档系统集成
- 信号必须在快照变更时发射，供UI系统订阅

## Test Strategy

- Unit tests for all public methods
- Test case: initialize_campaign loads correct initial deck for hero
- Test case: start_battle creates battle snapshot with correct cards
- Test case: end_battle processes exhaust_cards and clears battle snapshot
- Test case: serialize and deserialize preserve full campaign state
- Integration test: full battle cycle (start → play → end) with state verification
- Test case: signals are emitted at correct times

## Related Files

- src/core/deck-management/CampaignDeckManager.gd
- tests/unit/deck_management/campaign_deck_manager_test.gd
- tests/integration/deck_management/battle_cycle_test.gd