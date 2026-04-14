# Story: 消耗品处理

> **Epic**: deck-management-system
> **Type**: Logic
> **Status**: Ready
> **Estimate**: 1 hour
> **ADR**: ADR-0020
> **GDD**: design/gdd/cards-design.md (§0-§1)

## Overview

实现"消耗品"机制，使标注为"消耗品"的卡牌在使用后从战役层永久移除，本场战役后续战斗不可再用。消耗的卡牌在战斗结束时通过 `exhaust_cards` 列表回写到战役层进行移除。

## Acceptance Criteria

- [ ] `BattleDeckSnapshot.play_card()` 正确支持 `to_exhaust=true` 参数，将卡牌放入 `exhaust_cards` 数组
- [ ] `CampaignDeckManager.end_battle()` 正确处理 `exhaust_cards` 列表，从 `CampaignDeckSnapshot` 中移除所有消耗卡牌
- [ ] 在 `CampaignDeckManager` 中实现 `exhaust_card(card_id)` 方法用于直接消耗卡牌（非战斗场景）
- [ ] 消耗的卡牌在战役层快照中被正确移除，版本号递增
- [ ] 发射 `campaign_snapshot_changed` 信号
- [ ] 单元测试覆盖所有场景（5+测试用例）

## Dependencies

- Story 001: 战役层卡组快照基础实现
- Story 002: 战斗层卡组快照基础实现
- Story 003: 卡组管理器集成
- ADR-0020: 卡组两层管理架构

## Implementation Notes

- 消耗品优先级高于"永久加入卡组"（见GDD边缘情况）
- 战斗中的消耗操作仅在 `BattleDeckSnapshot` 中标记，战斗结束时才回写到战役层
- 直接消耗（非战斗场景）立即修改 `CampaignDeckSnapshot`
- 必须确保版本号递增和信号发射

## Test Strategy

- Unit test: play card with to_exhaust=true → card in exhaust_cards array
- Unit test: end_battle processes exhaust_cards → cards removed from campaign snapshot
- Unit test: exhaust_card directly removes from campaign snapshot
- Integration test: use consumable card in battle → verify not available in next battle
- Edge case: card marked both "永久加入卡组" and "消耗品" → "消耗品" priority wins

## Related Files

- src/core/deck-management/CampaignDeckManager.gd
- src/core/deck-management/BattleDeckSnapshot.gd
- tests/unit/deck_management/exhaust_card_test.gd
- tests/integration/deck_management/consumable_card_test.gd