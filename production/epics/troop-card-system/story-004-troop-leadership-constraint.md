# Story 004: 统帅值约束与卡组管理

> **Epic**: 兵种卡系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09
> **Completed**: 2026-04-12

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (统帅上限)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: N/A (集成逻辑)
**ADR Decision Summary**: 提供基于武将统帅值的约束计算，决定军营节点能否获取新的兵种卡。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 卡组中兵种卡总数 ≤ 武将统帅值。超额必须拒绝添加。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 `can_add_troop_card(deck_cards: Array) -> bool` 函数，读取 `HeroManager` 中当前武将的统帅值（3~6）。
- [ ] 验证无论Lv1、Lv2还是Lv3的兵种卡，每张始终仅占 1 个统帅槽。
- [ ] 实现 `get_troop_branch_options(card_id)` 返回对应基础兵种的全部Lv3分支列表。
- [ ] 提供逻辑保证一张卡升级到Lv3后无法继续升级。

---

## Implementation Notes

*Derived from Architecture Patterns:*

1. 在 `CardManager` 或 `DeckManager` 中添加校验逻辑：遍历 `deck_cards`，统计 `type == TROOP` 的数量。
2. 比较 `count < HeroManager.get_current_hero().leadership`。
3. `get_troop_branch_options` 通过静态字典映射或查找卡牌库中 `base_troop_type == x && tier == 3` 的所有卡ID返回。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 军营节点的 UI 交互和弹窗（在UI层实现）。此处只提供业务判定逻辑。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 统帅槽上限验证
  - Given: 武将统帅值为 3，卡组中已有 3 张兵种卡（2张Lv1，1张Lv3）。
  - When: 调用 `can_add_troop_card`
  - Then: 返回 false。

- **AC-2**: 升级不占用额外槽位
  - Given: 武将统帅值为 3，卡组中有 2 张兵种卡，其中一张从 Lv2 升为 Lv3。
  - When: 升级完成后，重新统计统帅槽占用
  - Then: 占用数量依然为 2，此时 `can_add_troop_card` 返回 true。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_leadership_constraint_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: HeroManager
- Unlocks: 无
