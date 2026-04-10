# Story 001: 基础兵种卡（Lv1）核心逻辑

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (Lv1效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 在 `BattleManager` 的出牌框架中集成。调用 `DamageCalculator` 执行所有修正。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 兵种卡打出后必须移动到弃牌堆。
- Required: 兵种卡伤害必须受到护甲和状态的共同修正。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现基础 5 种兵种卡（弓兵/步兵/骑兵/谋士/盾兵）Lv1 的效果结算。
- [ ] 弓兵 Lv1: 对任意目标造成 7点伤害（受护甲影响）。
- [ ] 步兵 Lv1: 对目标造成 8点伤害。
- [ ] 骑兵 Lv1: 对目标造成 5点伤害，触发**击退**逻辑（推至后排或互换位置）。击退逻辑在同卡牌效果前执行（此处无后续状态，所以就是打完伤害+击退）。
- [ ] 谋士 Lv1: 对任意目标造成 7点伤害。
- [ ] 盾兵 Lv1: 我方获得 8点护盾。若已有护盾则累加。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `BattleManager._resolve_troop(card_data, target_pos)` 中：
   ```gdscript
   var base_damage = card_data.lv1_damage
   var troop_type = card_data.troop_type # infantry/cavalry/archer/strategist/shield
   
   if troop_type == "shield":
       ResourceManager.modify_resource(ResourceManager.ResourceType.SHIELD, 8)
       return
       
   if troop_type == "cavalry":
       _execute_knockback(target_pos)
       
   var final_damage = DamageCalculator.calculate_damage(base_damage, troop_type, ...)
   enemy.take_damage(final_damage, false)
   ```
2. 击退 `_execute_knockback(target_idx)`：
   - 如果目标已经在后排，无效果。
   - 如果目标在前排，找到同列后排，如果没有，直接移过去；如果有，互换位置。（需要与战场阵型管理器配合，本故事可先发信号或 mock）。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Lv2、Lv3的升级与更复杂的效果（如眩晕、双击）。
- 统帅值上限校验（在入组选卡时）。
- 地形天气的乘数获取（由环境系统提供，Story 003 集成）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 盾兵累加护盾
  - Given: 我方已有 5 护盾
  - When: 打出盾兵 Lv1
  - Then: 护盾增加到 13。

- **AC-2**: 骑兵击退
  - Given: 前排有敌人A，后排有敌人B。
  - When: 用骑兵攻击敌人A
  - Then: A受到伤害，并且A和B互换位置。

- **AC-3**: 基础伤害调用
  - Given: 打出步兵 Lv1
  - When: 结算
  - Then: 调用 DamageCalculator 获取并造成 8点 基础衍生伤害。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_lv1_logic_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: ADR-0014 (管线), C2 (出牌框架)
- Unlocks: Story 002
