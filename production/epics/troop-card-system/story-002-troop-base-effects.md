# Story 002: 兵种卡基础(Lv1)战斗效果结算

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (兵种卡效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 提供 `_resolve_troop` 框架，在 C2 的打出结算管线中注入兵种卡的五大基础逻辑。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 弓兵/步兵/骑兵/谋士/盾兵 打出时的核心逻辑分发必须在战斗系统统一结算
- Required: 击退逻辑必须按照前排/后排换位执行

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] **弓兵 Lv1**：对任意目标造成 7 点伤害（走护甲）。
- [ ] **步兵 Lv1**：对前排/任意目标造成 8 点伤害。
- [ ] **骑兵 Lv1**：对目标造成 5 点伤害，附带击退。击退规则：目标到后排，若后排有人则互换位置。
- [ ] **谋士 Lv1**：对任意目标造成 7 点伤害。
- [ ] **盾兵 Lv1**：我方获得 8 点护盾。累加至护盾池。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `BattleManager._resolve_troop(card_data, target_pos)` 中根据 `base_type` 进行派发。
2. 击退逻辑 `_apply_knockback(target_pos)`:
   - 检查目标是否在前排（例如位置0，位置1为后排，由战斗战场模型决定）。
   - 如果前排且后排有人，交换 `enemy_entities[0]` 和 `enemy_entities[1]`，并发射 `entity_position_changed` 信号供 UI 更新。
3. 盾兵护盾增加：`player_entity.shield += 8` 并发信号。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Lv2 的双击、群体等进阶逻辑（Story 003）。
- 伤害的各种乘数计算（ADR-0014 已经在 C2 Story 005 中实现，此处只传入基础伤害和分类标签）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 弓兵/步兵/谋士 基础伤害
  - Given: 打出对应的 Lv1 卡
  - When: `_resolve_troop` 结算
  - Then: 目标受到对应基础数值的计算伤害（传入管线前数值分别为 7, 8, 7）。

- **AC-2**: 骑兵 击退换位
  - Given: 前排有敌人 A，后排有敌人 B。
  - When: 打出骑兵 Lv1 瞄准 A。
  - Then: A 受到 5 点伤害，然后 A 和 B 交换在 `enemy_entities` 数组中的位置。

- **AC-3**: 盾兵 护盾累加
  - Given: 玩家已有 5 护盾
  - When: 打出盾兵 Lv1
  - Then: 玩家护盾增加至 13（若未超上限）。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_cards/troop_base_effects_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: C2 卡牌战斗系统 (DamageCalculator, _resolve_attack)
- Unlocks: Story 003
