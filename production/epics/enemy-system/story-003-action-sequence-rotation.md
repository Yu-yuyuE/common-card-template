# Story 003: 敌人固定行动序列轮转机制

Epic: 敌人系统
Estimate: 1 day
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-13

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-001, TR-enemies-design-006
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 提供 `get_next_action()`，推进 action_index，并处理冷却期间的备用行动选择。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 敌人行动必须按固定序列循环，确保可预测性
- Required: 必须支持冷却机制和备用行动选择
- Forbidden: 禁止随机行动选择违背可预测原则

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `EnemyManager.get_next_action(enemy_id)`。
- [ ] 每次调用时，`action_index` + 1 并对序列长度取模（循环）。
- [ ] 当查找到的行动在冷却中时，自动使用序列中的第一个非冷却行动作为 `_get_backup_action()`。
- [ ] 眩晕（STUN）状态下，跳过行动，但行动序列计数器照常推进。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. 需要检查敌人的 `is_alive` 和是否处于眩晕状态。
2. 对于眩晕：`StatusManager.has_status_type(target, StatusCategory.STUN)`，如果是，推进 `action_index` 但返回空行动（跳过）。
3. 记录冷却：虽然冷却登记是在执行时做（Story 006），但在获取时需要读取 `cooldown_actions` 字典判断是否可用。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 实际执行并更新冷却（在执行器中做，Story 005/006）。
- 相变触发（相变改变了整个序列，属于执行逻辑Story 006）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 序列顺序轮转
  - Given: 行动序列 `["A01", "A04", "B01"]`
  - When: 连续调用3次 `get_next_action`
  - Then: 依次返回 A01, A04, B01，第四次返回 A01。

- **AC-2**: 冷却替代
  - Given: 序列 `["C05", "A01"]`，且 C05 在冷却字典中。
  - When: 轮到 `C05` 时调用。
  - Then: 实际返回 `A01` 的数据，`action_index` 仍向前推进。

- **AC-3**: 眩晕推进
  - Given: 序列 `["A01", "A02"]`，轮到A01。敌人有眩晕状态。
  - When: 调用获取。
  - Then: 返回跳过标识（空字典），但下一次轮到时必定是 A02。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/action_sequence_rotation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (数据模型)
- Unlocks: Story 005 (执行器)
