# Story: 战斗层卡组快照基础实现

> **Epic**: deck-management-system
> **Type**: Logic
> **Status**: Ready
> **Estimate**: 2 hours
> **ADR**: ADR-0020
> **GDD**: design/gdd/cards-design.md (§0-§1)

## Overview

实现战斗层卡组快照数据结构，作为单场战斗的临时状态工作副本。该快照在战斗开始时从战役层复制，在战斗结束时被销毁，所有临时状态不会影响战役层。

## Acceptance Criteria

- [ ] 创建 `BattleDeckSnapshot` 类继承 `RefCounted`
- [ ] 实现 `source_version` 字段记录来源战役快照版本
- [ ] 实现5个战斗区域：`draw_pile`、`hand_cards`、`discard_pile`、`removed_cards`、`exhaust_cards`
- [ ] 实现临时状态数组：`temporary_upgrades`、`stolen_cards`
- [ ] 实现 `initialize_from_campaign(campaign_snapshot)` 方法从战役层复制卡牌到抽牌堆
- [ ] 实现 `draw_cards(count)` 方法从抽牌堆抽取卡牌到手牌
- [ ] 实现 `play_card(card_id, to_removed, to_exhaust)` 方法打出卡牌到合适区域
- [ ] 实现 `steal_card(card_id)` 方法敌人偷取手牌
- [ ] 实现 `temporary_upgrade(card_id, temp_level, temp_effects)` 方法临时升级
- [ ] 实现 `finalize_battle()` 方法战斗结束时返回需要回写的变更
- [ ] 实现内部 `_shuffle_discard_to_draw()` 洗牌方法
- [ ] 所有操作都有单元测试覆盖（10+测试用例）

## Dependencies

- Story 001: 战役层卡组快照基础实现
- ADR-0020: 卡组两层管理架构
- ADR-0007: 卡牌战斗系统架构

## Implementation Notes

- `initialize_from_campaign()` 必须在复制卡片后立即打乱抽牌堆
- 抽牌堆为空时自动将弃牌堆洗回抽牌堆
- 敌人偷取的卡牌放入 `stolen_cards` 数组，不放入 `removed_cards`
- 临时升级仅存数据结构，不修改实际卡牌属性
- `finalize_battle()` 返回的数据仅包含需要回写到战役层的变更

## Test Strategy

- Unit tests for all public methods
- Test case: initialize from campaign, verify all cards in draw_pile and shuffled
- Test case: draw 5 cards, verify hand_cards size and draw_pile changes
- Test case: play card to exhaust, removed, discard piles
- Test case: steal card, verify it's in stolen_cards not removed_cards
- Test case: finalize_battle returns correct changes
- Test case: multiple draw operations trigger shuffle correctly

## Related Files

- src/core/deck-management/BattleDeckSnapshot.gd
- tests/unit/deck_management/battle_deck_snapshot_test.gd