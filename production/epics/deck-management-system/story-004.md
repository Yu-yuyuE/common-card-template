# Story: 永久加入卡组机制

> **Epic**: deck-management-system
> **Type**: Logic
> **Status**: Ready
> **Estimate**: 1 hour
> **ADR**: ADR-0020
> **GDD**: design/gdd/cards-design.md (§0-§1)

## Overview

实现"永久加入卡组"机制，允许特定卡牌效果（如奖励、事件）同时修改战役层和战斗层快照，使卡牌在本场战斗后继续保留在卡组中。

## Acceptance Criteria

- [ ] 在 `CampaignDeckManager` 中实现 `permanent_add_card(card_id, level, source)` 方法
- [ ] 调用 `CampaignDeckSnapshot.add_card()` 将卡牌添加到战役层
- [ ] 如果正在战斗中（`current_battle_snapshot != null`），同时将卡牌加入战斗层抽牌堆
- [ ] 发射 `campaign_snapshot_changed` 信号
- [ ] 如果正在战斗中，同时发射 `battle_snapshot_changed` 信号
- [ ] 单元测试覆盖所有场景（5+测试用例）

## Dependencies

- Story 001: 战役层卡组快照基础实现
- Story 002: 战斗层卡组快照基础实现
- Story 003: 卡组管理器集成
- ADR-0020: 卡组两层管理架构

## Implementation Notes

- 必须先添加到战役层，再添加到战斗层
- 如果不在战斗中，只修改战役层
- `source` 参数必须正确传递（"shop", "event", "reward"等）
- 双快照的原子性更新是核心要求

## Test Strategy

- Unit test: permanent_add_card when not in battle → only campaign snapshot updated
- Unit test: permanent_add_card when in battle → both snapshots updated
- Unit test: verify signals are emitted correctly
- Integration test: receive "永久加入卡组" card from event → verify persistence after battle ends
- Test case: add multiple permanent cards in sequence

## Related Files

- src/core/deck-management/CampaignDeckManager.gd
- tests/unit/deck_management/permanent_add_test.gd
- tests/integration/deck_management/event_reward_test.gd