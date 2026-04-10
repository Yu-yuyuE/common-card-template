# Story 004: 掉落池与商店过滤集成

> **Epic**: 卡牌解锁系统
> **Status**: Ready
> **Layer**: Meta
> **Type**: Integration
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/cards-design.md`
**Requirement**: `TR-cards-design-001`

**ADR Governing Implementation**: ADR-0004 (Card Data Format), ADR-0012 (Shop System)
**ADR Decision Summary**: 为全局系统提供可获取的合法卡池。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须使用集中式的卡牌管理与查找。商店商品刷新机制必须遵循过滤。

---

## Acceptance Criteria

- [ ] 战斗奖励（卡牌掉落）请求候选池时，仅返回 `is_card_unlocked() == true` 的卡牌
- [ ] 商店系统（`ShopManager`）执行批次刷新 `_generate_batch()` 时，仅从已解锁的池子中抽取
- [ ] 军营系统候选兵种卡生成时，仅从已解锁的兵种卡池中抽取

---

## Implementation Notes

这是最核心的应用场景：在 `CardManager` 或掉落生成器中，提供包装好的方法，例如 `get_available_attack_cards()`，该方法内部应用 `CardUnlockManager` 的过滤器。其他系统必须调用这个过滤后的方法，而不是直接获取全体卡牌字典。

---

## Out of Scope

- 具体的战斗奖励掉率、商店价格计算（属于其各自模块）。

---

## QA Test Cases

- **AC-1**: 掉落池过滤验证
  - Given: 某张卡 `AC0200` 设置为未解锁
  - When: 获取合法攻击卡掉落池 `get_available_attack_cards()`
  - Then: 列表中绝不包含 `AC0200`
- **AC-2**: 商店商品生成验证
  - Given: `SC0080` 设置为未解锁
  - When: 商店系统刷新 100 批次商品
  - Then: 没有任何一批次包含 `SC0080`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/card_unlock/reward_pool_filter_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: None