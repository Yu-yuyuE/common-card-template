# Story 003: 状态回合结束结算机制

Epic: 状态效果系统
Estimate: 1 day
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: TR-status-design-005 (回合结束消耗)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: 状态效果系统架构
**ADR Decision Summary**: 提供 `tick_status(target)` 方法在回合结束时调用，消耗层数，处理移除。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 回合结束时必须调用tick_status()处理状态消耗和持续伤害
- Forbidden: 禁止不按需计算状态造成性能浪费

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [ ] 实现 `tick_status(target)` 方法
- [ ] 持续型状态在调用时层数减 1
- [ ] 消耗型状态在 `tick_status` 时也层数减1（GDD要求：每回合末-1层，不论Buff还是Debuff，消耗型触发时直接移除但在未触发时每回合也会-1层吗？不，消耗型触发后消失。为了安全起见，所有状态在回合结束时若没有特殊声明都-1层，直至0移除）。注：根据ADR-0006，消耗型状态在 `tick_status` 时消耗1层。
- [ ] 状态层数降为 0 时，自动从目标身上移除并发送 `status_removed` 信号
- [ ] 处理过程必须使用列表副本迭代，防止在遍历时修改引发字典越界错误

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

1. 在 `tick_status(target: Node)` 中，获取目标身上的状态副本。
2. 先执行持续伤害计算（此部分由 Story 004 完成，本故事留空或只写遍历）。
3. 执行层数消耗：`status.layers -= 1`
4. 如果 `status.layers <= 0`，将其加入 `to_remove` 列表。
5. 遍历结束后，对 `to_remove` 列表中的每个类别调用 `remove_status()`。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: 状态持续伤害计算（DoT）
- 消耗型状态的触发消耗（例如被攻击时反击-1层，属于触发逻辑，由战斗系统通过 remove_status 主动调用）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 正常层数消耗
  - Given: 目标有 3层 中毒
  - When: 调用 tick_status(target)
  - Then: 目标中毒变为 2层
  - Edge cases: 多种状态同时存在时，全部正常 -1

- **AC-2**: 层数归零自动移除
  - Given: 目标有 1层 破甲
  - When: 调用 tick_status(target)
  - Then: 目标失去破甲状态，发出 status_removed 信号
  - Edge cases: 目标有1层和2层两个不同状态，1层的移除，2层的变为1层

- **AC-3**: 遍历安全性验证
  - Given: 目标有1层中毒
  - When: 调用 tick_status(target) 导致状态在遍历时被移除
  - Then: 不抛出数组越界(Array iteration)或字典修改错误

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/status_system/status_tick_consumption_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (基础增删改)
- Unlocks: Story 004 (持续伤害计算需要依赖tick遍历)
