# Story 006: 扩展分支（Lv3）谋盾效果实现

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (Lv3 效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014
**ADR Decision Summary**: 补充谋士与盾兵、以及所有遗留特色弓兵的效果。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 铁甲步兵必须能够施加强制攻击(嘲讽)状态。
- Required: 沙漠盾卫等必须带有清自己Debuff的功能。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 `沙漠盾卫` (盾兵)：沙漠地形下清除我方所有灼烧层。Lv2施加坚守。
- [ ] 实现 `铁甲步兵` (盾兵)：2费。我方获得 10护盾，施加"强制攻击"(嘲讽)状态 2回合。如果在结束时护盾仍存，获得1层坚守。
- [ ] 实现 `关城守弩` (弓兵)：关隘地形下从单体改为全体伤害。
- [ ] 实现 `寒地猎手` (弓兵)：无视雪地全体伤害 -20%（通过设置免除乘数衰减标签）。
- [ ] （涵盖其余谋士/弓兵的骨架，并在配置表中予以预留）。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 嘲讽（强制攻击）状态：需要在 `StatusManager` 新增 `TAUNT` 状态，并且在敌人 AI 寻找目标 (`target = "player"`) 时，验证玩家是否有 `TAUNT`（目前1v3只有玩家一个友方，所以嘲讽实际上是防召唤物受损，或者防同伴？注：游戏是 1 主将 vs 多敌将，没有其他我方实体。所以嘲讽的意义是什么？GDD 15条指出："在多武将局面下主动吸收敌方火力"，可能暗示后续会扩展多武将或召唤物，本故事先实装 `TAUNT` 状态挂在玩家身上即可）。
2. 沙漠盾卫清灼烧：`StatusManager.remove_status(player, BURN)`。
3. 雪地免疫惩罚：在 `DamageCalculator` 收到此特定卡 ID 时，如果是雪地弓兵，跳过惩罚因子（返回 1.0）。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体的多玩家同盟机制（暂无，只挂状态）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 沙漠盾卫清火
  - Given: 玩家有 3 层 BURN。
  - When: 在 DESERT 场地下打出 沙漠盾卫。
  - Then: 玩家的 BURN 状态变为 0，且增加对应护盾。

- **AC-2**: 寒地猎手免罚
  - Given: 处于 SNOW 场地。
  - When: 打出 寒地猎手 (弓兵)。
  - Then: 伤害计算时不遭受弓兵在雪地（如果有）或特定的 -20% 衰减。

- **AC-3**: 铁甲步兵
  - Given: 打出 铁甲步兵
  - When: 结算完成
  - Then: 玩家增加 10 护盾，并且获得 TAUNT 状态 2 层。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_lv3_strategist_shield_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004
- Unlocks: 无
