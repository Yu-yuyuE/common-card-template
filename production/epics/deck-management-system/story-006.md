# Story: 敌人偷取卡牌机制

> **Epic**: deck-management-system
> **Type**: Logic
> **Status**: Ready
> **Estimate**: 1 hour
> **ADR**: ADR-0020
> **GDD**: design/gdd/cards-design.md (§0-§1)

## Overview

实现敌人偷取卡牌机制，使敌人能够从玩家手牌中偷取卡牌。被偷取的卡牌从 `BattleDeckSnapshot` 中移除，记录在 `stolen_cards` 数组中，战斗结束后不归还且不影响 `CampaignDeckSnapshot`。

## Acceptance Criteria

- [ ] `BattleDeckSnapshot.steal_card(card_id)` 方法正确将卡牌从 `hand_cards` 移至 `stolen_cards` 数组
- [ ] 被偷取的卡牌不放入 `removed_cards` 数组（与普通移除区分）
- [ ] `BattleDeckSnapshot.finalize_battle()` 返回的变更不包含 `stolen_cards`
- [ ] 战斗结束后 `CampaignDeckSnapshot` 仍包含被偷取的卡牌（不永久移除）
- [ ] 敌人系统可以通过接口查询 `stolen_cards` 列表（通过 `current_battle_snapshot.stolen_cards`）
- [ ] 单元测试覆盖所有场景（5+测试用例）

## Dependencies

- Story 002: 战斗层卡组快照基础实现
- Story 003: 卡组管理器集成
- ADR-0020: 卡组两层管理架构
- ADR-0008: 敌人系统架构

## Implementation Notes

- 偷取操作仅在 `BattleDeckSnapshot` 中生效，不修改 `CampaignDeckSnapshot`
- `stolen_cards` 数组是临时状态，战斗结束时自动清空
- 敌人系统需要引用 `current_battle_snapshot` 来查询被偷取的卡牌
- 如果卡牌不在 `hand_cards` 中，偷取操作应该失败（可选：发射错误信号）

## Test Strategy

- Unit test: steal_card removes from hand_cards and adds to stolen_cards
- Unit test: finalize_battle does not return stolen_cards in changes
- Unit test: campaign snapshot unchanged after steal operation
- Integration test: enemy steals card in battle → verify card still in campaign deck after battle ends
- Edge case: steal same card multiple times → should fail or handle gracefully
- Test case: multiple enemies steal multiple cards, verify all in stolen_cards

## Related Files

- src/core/deck-management/BattleDeckSnapshot.gd
- src/core/deck-management/CampaignDeckManager.gd
- tests/unit/deck_management/steal_card_test.gd
- tests/integration/deck_management/enemy_steal_test.gd