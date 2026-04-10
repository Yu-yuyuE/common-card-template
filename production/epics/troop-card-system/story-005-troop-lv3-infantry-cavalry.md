# Story 005: 扩展分支（Lv3）步骑弓效果实现

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (Lv3 效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 为特定的几十种分支卡实现路由逻辑，重点实现步兵、骑兵、弓兵的几张特色卡。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持地形天气与分支卡特殊规则（如"直击"）的正确结合。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 `虎贲卫` (步兵)：10伤。如果目标有 `SLIP` 滑倒状态，额外 5伤并移除 1层滑倒。（水域联动）
- [ ] 实现 `山地步兵` (步兵)：0费。6伤 + 1滑倒。如果是 `MOUNTAIN` 山地，改为 10伤 + 1减甲。
- [ ] 实现 `游侠` (步兵)：0费。直击(无视护甲)全体 4伤。如果是 `FOREST` 森林且目标有灼烧，对该目标直击 7伤。
- [ ] 实现 `轻骑兵` (骑兵)：0费。4伤，下两回合结束各 4伤。`PLAIN` 平原伤害均 +50%。
- [ ] 实现 `火骑兵` (骑兵)：2费。对前排所有敌将 6伤 + 2灼烧 + 击退。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `BattleManager._resolve_troop` 增加具体 `card_id` 的匹配：
   ```gdscript
   match card_id:
       "huben": 
           var has_slip = StatusManager.has_status(enemy, SLIP)
           enemy.take_damage(10, false)
           if has_slip:
               enemy.take_damage(5, false)
               StatusManager.remove_status(enemy, SLIP) # 扣1层
   ```
2. 注意"直击"使用 `take_damage(dmg, true)` 穿透护盾。
3. "轻骑兵"的延迟伤害可以复用一个新的特殊 StatusEffect (比如 `DELAY_DAMAGE_4`)，在回合末结算；或在 `BattleManager` 里维持一个延迟伤害队列。为了不滥用 Status，建议新增一个隐性 Status。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 弓兵的所有 6 个分支，以及谋/盾的分支（太长，弓兵可以在此或者 Story 006 里）。本故事覆盖步/骑核心，其余留给后续。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 虎贲卫滑倒收割
  - Given: 敌人处于 SLIP 状态，无护甲。
  - When: 打出 虎贲卫。
  - Then: 造成 10+5 = 15点伤害。敌人的 SLIP 状态层数减少1。

- **AC-2**: 游侠森林直击
  - Given: 敌人带有护盾 20，并有 BURN 状态。当前地形 FOREST。
  - When: 打出 游侠。
  - Then: 护盾 20 维持不变，直接扣除敌人 7 点 HP。

- **AC-3**: 火骑兵群攻加击退
  - Given: 前排有2个敌人。
  - When: 打出 火骑兵。
  - Then: 2个敌人都受 6 伤，且均加上 2层 BURN，并且都被击退到后排。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_lv3_infantry_cavalry_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: 无
