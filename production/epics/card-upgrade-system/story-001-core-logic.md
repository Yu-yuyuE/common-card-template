# Story 001: 卡牌升级核心逻辑与状态持久化

> **Epic**: 卡牌升级系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-10

## Context

**GDD**: `design/gdd/card-upgrade-system.md`
**Requirement**: `TR-card-upgrade-001`

**ADR Governing Implementation**: ADR-0005: Save Serialization
**ADR Decision Summary**: 升级状态持久化

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 每张卡牌仅可升级一次（Lv1 → Lv2）
- Required: 需持久化卡牌的升级状态
- Forbidden: 诅咒卡不可升级

---

## Acceptance Criteria

- [ ] 逻辑层方法：提供检查卡牌是否可升级的接口（是否为Lv1，是否非诅咒卡）
- [ ] 逻辑层方法：提供执行卡牌升级的接口，并将卡牌标记为Lv2
- [ ] 存档层：升级状态记录 `CardUpgradeRecord` 能够随战役进度正确保存和读取
- [ ] 逻辑层方法：卡组中多张同名卡能够独立记录升级状态（按实例ID）

---

## Implementation Notes

新建 `card_upgrade_manager.gd` 作为纯逻辑的核心单例（或在现有相关Manager中实现）。
实现 `can_upgrade(card)` 校验条件，以及 `upgrade_card(card)` 变更卡牌等级。
确保与战役进度保存系统 (F1) 集成，战役中记录并保存哪些特定的卡牌实例被升级过。由于可能有同名卡，必须依赖实例级的唯一ID进行持久化追踪。

---

## Out of Scope

- 商店界面的展示与交互。
- 战斗中Lv2效果的实际加载。
- 卡牌具体Lv2数据的配置。

---

## QA Test Cases

- **AC-1**: 卡牌可升级判定
  - Given: 一张Lv1普通卡、一张Lv2普通卡、一张诅咒卡
  - When: 调用 `can_upgrade` 检查
  - Then: 仅Lv1普通卡返回true
- **AC-2**: 独立升级状态记录
  - Given: 卡组中有两张同名的Lv1骑兵卡（ID相同，实例不同）
  - When: 升级其中一张
  - Then: 一张变为Lv2，另一张仍为Lv1，并正确存入战役记录

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/card_upgrade_system/core_logic_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Unlocks: Story 002, Story 003
