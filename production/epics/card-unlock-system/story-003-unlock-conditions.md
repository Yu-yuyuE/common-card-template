# Story 003: 战役结算与新卡解锁规则

> **Epic**: 卡牌解锁系统
> **Status**: Ready
> **Layer**: Meta
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/cards-design.md`
**Requirement**: `TR-cards-design-001`

**ADR Governing Implementation**: ADR-0004: Card Data Format
**ADR Decision Summary**: 读取卡牌数据判定归属组别。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 无特殊表现层约束，纯数据逻辑层判定

---

## Acceptance Criteria

- [ ] 实现规则：任意州地图通关后，根据玩家累计通关次数，批量解锁对应批次的“待开启通用卡”
- [ ] 实现规则：在指定十三州地图通关后（且使用对应武将生涯），解锁该州的“十三州专属卡”
- [ ] 若对应通关次数/州地图条件的所有卡牌已全解锁，不触发新解锁或报错

---

## Implementation Notes

实现结算函数 `process_campaign_victory(campaign_data: Dictionary)`。
其中 `campaign_data` 应当包含：当前通关总次数 `total_victories`，当前通关的州地图 `map_region`，当前使用的武将 `hero_id`。
通过查表将满足条件的卡牌 ID 数组抽出，循环调用 `unlock_card(id)`。

---

## Out of Scope

- 掉落池过滤。

---

## QA Test Cases

- **AC-1**: 首通通用卡解锁
  - Given: 玩家通关次数为 0
  - When: 模拟完成第一次通关 `process_campaign_victory`
  - Then: 解锁约 25 张指定的第一批次通用卡
- **AC-2**: 专属州卡牌解锁
  - Given: 玩家在“荆州”地图通关，武将匹配
  - When: 模拟完成通关
  - Then: “荆州”相关的 30 张专属卡解锁状态变为 `true`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/card_unlock/unlock_conditions_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: None