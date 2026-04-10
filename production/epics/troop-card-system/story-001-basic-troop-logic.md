# Story 001: 基础兵种卡（Lv1）核心逻辑

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (兵种卡Lv1/Lv2/Lv3效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 统一的伤害管道，处理基础的护盾+坚守机制和骑兵击退位置操作机制。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须通过 BattleManager 或相关执行类正确解析这5个基础卡牌效果。
- Required: 兵种卡打出后必须进弃牌堆，不永久移除（除非分支特殊说明）。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 弓兵 (1费): 对任意目标造成 7 点伤害。
- [ ] 步兵 (0费): 对目标造成 8 点伤害。
- [ ] 骑兵 (1费): 对目标造成 5 点伤害，并附带 **击退** (Knockback) 操作。
- [ ] 谋士 (1费): 对任意目标造成 7 点伤害。
- [ ] 盾兵 (1费): 获得 8 点护盾，护盾池累加且优先于坚守减伤后扣减（调用已在战斗系统实现的 take_damage）。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `BattleManager._resolve_troop(card_data, target_pos)` 中处理这五类兵种。
2. `击退`：在 `BattleManager` 里添加一个逻辑，将目标实体的数组位置交换（比如如果是前排则移至后排），此举可能涉及到 `enemy_entities` 数组重排或仅修改每个实体的 `position` 标记（具体依赖 Map/Battle 系统的坐标管理），若仅是标记，修改目标对象的 `is_backrow = true`，如果该位置已有敌人，则与它互换。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 地形天气的伤害修正（ Story 003 处理）。
- 高级（Lv2）附加效果（ Story 002 处理）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 基础伤害执行
  - Given: 玩家手牌中有 Lv1步兵（0费）。
  - When: 玩家对敌人A打出步兵卡。
  - Then: 敌人A失去8点HP/护甲，卡牌进入弃牌堆。

- **AC-2**: 骑兵击退逻辑
  - Given: 敌人A在前排，后排为空。
  - When: 玩家对A打出骑兵卡。
  - Then: A受到5点伤害，并移动至后排。

- **AC-3**: 盾兵加盾
  - Given: 玩家护盾为5
  - When: 玩家打出盾兵卡
  - Then: 玩家护盾增加至13。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/basic_troop_logic_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 卡牌战斗系统 (C2)
- Unlocks: Story 002, Story 003
