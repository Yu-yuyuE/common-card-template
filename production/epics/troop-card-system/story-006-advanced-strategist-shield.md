# Story 006: 扩展分支（Lv3）谋盾效果实现

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014
**ADR Decision Summary**: 为Lv3特种兵分支编写专用的效果处理块。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须能在 `_resolve_troop` 中精准派发特定的分支兵种效果。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 **沙漠盾卫**：打出时清除我方灼烧；Lv2额外施加坚守。
- [ ] 实现 **铁甲步兵 (2费)**: 获得10盾，向自身施加 **强制攻击** (TAUNT) 状态（敌方所有攻击必须指向此武将，持续2回合）。若强制攻击结束有护盾，额外加1层坚守。
- [ ] 实现其他谋士与盾兵的分支特殊逻辑（如毒师、壁垒工兵等，按CSV文档解析对应的组合状态或条件触发）。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 需要与状态系统联动，增加 `TAUNT` (嘲讽/强制攻击) 状态。当敌人 AI 选取目标时（C3），如果玩家队伍（未来可能多武将，当前只有一个主将）有嘲讽目标，必须选择该目标。
2. 沙漠盾卫的净化：`StatusManager.remove_status(player, BURN)`。
3. 铁甲步兵的结束判定：可以在 `tick_status` 或者监听 `status_removed` 信号时，如果移除的是 `TAUNT` 且护盾>0，补充施加坚守。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 敌方 AI 如何强行变更目标（由敌人 AI 执行层在选取目标时适配，本处仅负责给玩家上 TAUNT 状态）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 铁甲步兵强制攻击附带
  - Given: 玩家打出铁甲步兵
  - When: 结算完毕
  - Then: 玩家获得 10 护盾 和 2层 TAUNT 状态。

- **AC-2**: 净化效果
  - Given: 玩家身上有 5 层灼烧
  - When: 打出沙漠盾卫（Lv1）
  - Then: 玩家灼烧被清除，并获得护盾。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/advanced_strategist_shield_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
