# Story 006: 敌人具体行动结算路由

> **Epic**: 敌人系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-13

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-009
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008, ADR-0015
**ADR Decision Summary**: 根据获得的 Action 对象的 `type` 分发到对应的执行函数 `_execute_attack`, `_execute_buff`, `_execute_debuff` 等。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须按照规定的效果分别结算（扣血、加状态等）。
- Required: 执行时记录进入冷却字典的行动。

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `execute_action(enemy_id, battle_manager, action_dict)`。
- [ ] 对于 `attack`: 调用玩家或友军的 `take_damage`（如果有穿甲参数，传给 `penetrate`）。
- [ ] 对于 `buff/debuff`: 调用 `StatusManager.apply_status` 施加。单次行动只施加一种状态。
- [ ] 每次执行后，如果有冷却时间设定，存入 `cooldown_actions[action_id]`。
- [ ] 相变机制检查：执行前检查自身血量，如果满足相变阈值（如HP<40%），替换整个 `action_sequence` 为新阶段序列，重置 `action_index`（且每场仅触发1次）。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. 需要 `BattleManager` (或者解耦为 Signal 驱动) 执行攻击。目前以传递对象引用的方式实现。
2. 相变触发检查：每次轮到行动前，`if current_hp / max_hp < threshold and not has_phased:` 执行相变，并立即使用新序列的第一招。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 诅咒的加入与发牌，召唤援军（均在 Story 007 处理）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 攻击路由结算
  - Given: 行动为 "造成10点伤害并穿甲"
  - When: 执行
  - Then: 玩家直接扣减10HP（或触发战斗系统API执行）。

- **AC-2**: 状态施加
  - Given: 行动为 "施加2层破甲"
  - When: 执行
  - Then: `StatusManager` 被调用给目标加上了对应层数。

- **AC-3**: 相变触发
  - Given: 敌人有一相变阈值 HP<40%，当前正在第二步。
  - When: 被攻击血量降到 35%，轮到它的回合开始执行时。
  - Then: 放弃原本的序列，切换为相变后的狂暴序列，并执行新序列的第一招。同时标记已相变。

- **AC-4**: 冷却更新
  - Given: 行动执行带有 2回合冷却。
  - When: 执行完毕。
  - Then: `cooldown_actions` 被添加记录，每次轮流时递减。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/action_execution_router_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (包含具体的数值解析), C2 卡牌战斗系统 (需提供 take_damage)
- Unlocks: Story 007
