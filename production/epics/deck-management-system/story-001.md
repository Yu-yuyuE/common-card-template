# Story: 战役层卡组快照基础实现

> **Epic**: deck-management-system
> **Type**: Logic
> **Status**: Ready
> **Estimate**: 2 hours
> **ADR**: ADR-0020
> **GDD**: design/gdd/cards-design.md (§0-§1)

## Overview

实现战役层卡组快照数据结构，作为卡组状态的权威数据源。该快照将在战役期间持久化，并在战斗开始时被复制到战斗层快照。

## Acceptance Criteria

- [ ] 创建 `CampaignDeckSnapshot` 类继承 `RefCounted`
- [ ] 实现 `cards` 字典存储卡牌信息（card_id -> {level, special_attrs, is_permanent, source}）
- [ ] 实现 `version` 整数用于同步检查
- [ ] 实现 `add_card(card_id, level, source)` 方法添加卡牌到战役层
- [ ] 实现 `remove_card(card_id)` 方法从战役层移除卡牌
- [ ] 实现 `upgrade_card(card_id)` 方法升级卡牌等级（1→2）
- [ ] 实现 `get_all_card_ids()` 方法返回所有卡牌ID列表
- [ ] 实现 `serialize()` 方法返回可序列化字典
- [ ] 实现 `deserialize(data)` 静态方法从字典重建快照
- [ ] 在每次修改后递增版本号并触发 `snapshot_updated` 信号
- [ ] 所有操作都有单元测试覆盖（10+测试用例）

## Dependencies

- ADR-0020: 卡组两层管理架构
- ADR-0005: 存档序列化方案

## Implementation Notes

- 数据结构必须与 ADR-0020 中定义的完全一致
- 所有卡牌变更必须通过方法调用，禁止直接修改字典
- 版本号递增是同步机制的核心，必须正确实现
- 信号必须在每次变更后发射

## Test Strategy

- Unit tests for all public methods
- Test case: add 3 cards, remove 1, upgrade 1, verify final state
- Test case: serialize and deserialize, verify state preservation
- Test case: version number increments correctly on each operation
- Test case: signal emissions are triggered on all modifications

## Related Files

- src/core/deck-management/CampaignDeckSnapshot.gd
- tests/unit/deck_management/campaign_deck_snapshot_test.gd