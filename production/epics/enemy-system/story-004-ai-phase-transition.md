# Story 004: 决策树与相变条件触发

> **Epic**: 敌人系统
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-009 (强力敌人相变), TR-enemies-design-010
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: 敌人AI行动序列执行器
**ADR Decision Summary**: 提供一层决策系统（Brain），在每个回合前评估环境条件。主要处理：HP<X%的相变。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 条件触发行动必须每场战斗仅触发一次（例如相变）。
- Required: 必须能在回合初检测到相变并替换敌人的行动序列。

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `EnemyAIBrain.evaluate_conditions(enemy: EnemyData)`。
- [ ] 相变触发（如 `HP<40%`）：如果敌人具有相变规则，且当前血量低于阈值，并且尚未触发过，则永久替换其 `action_sequence` 为新序列，并重置 `action_index = 0`。
- [ ] 特定条件插入：如复仇将领E044（血量低时插入一次爆发）。本故事建立支持这种动态修改序列或插队的机制。
- [ ] 决策必须在 `get_displayed_action()` 被 UI 调用之前完成，以确保玩家看到的预示是变身后的最新意图。

---

## Implementation Notes

*Derived from ADR-0015 Implementation Guidelines:*

1. 在 `EnemyData` 中增加 `has_transformed: bool = false`。
2. 每次敌人受击导致HP变化时（或在每个回合前的准备阶段），检查其是否满足阈值：
   ```gdscript
   if not enemy.has_transformed and enemy.current_hp <= enemy.max_hp * threshold:
       enemy.action_sequence = enemy.phase2_sequence
       enemy.action_index = 0
       enemy.has_transformed = true
   ```
3. 这个逻辑由 `EnemyTurnManager` 调度，或者统一在接收到 `damage_dealt` 时检测抛出事件。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体造成伤害的部分（由战斗系统完成）。
- 特效与动画（只发信号，不做显示）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 相变触发重置序列
  - Given: 敌人有一套主序列，并在 `HP<40%` 时触发相变新序列。当前 HP 是 50%。
  - When: 受到伤害使其 HP 降至 30%。回合预处理决策执行。
  - Then: `action_sequence` 变为新序列，`action_index` 置 0。

- **AC-2**: 防重复触发
  - Given: 已完成相变的敌人，HP 再次从 30% 补血回 50% 并再次被打回 30%。
  - When: 再次执行决策评估。
  - Then: 序列不再被重置替换，`has_transformed` 保持 true。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/ai_phase_transition_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
