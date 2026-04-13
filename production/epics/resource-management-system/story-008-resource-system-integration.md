# Story 008: 资源系统综合集成

Epic: 资源管理系统
Estimate: 1 day
Status: Ready
Layer: Foundation
Type: Integration
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-001`, `TR-resource-management-system-002`

**ADR Governing Implementation**: ADR-0003: Resource Notification
**ADR Decision Summary**: 必须采用集中式资源管理+Signal广播模式，所有资源变化必须通过ResourceManager统一接口，资源变化时必须触发resource_changed信号。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 采用标准 GDScript 与 Node 机制。

**Control Manifest Rules (this layer)**:
- Required: 必须采用双层通信架构：场景内使用Node Signal，全局使用EventBus
- Required: 必须使用强类型Signal `resource_changed(resource_type: String, old_value: int, new_value: int, delta: int)`
- Forbidden: 禁止使用纯EventBus进行所有通信(过度工程化)
- Guardrail: Signal emit开销：< 0.001ms

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md`, scoped to this story:*

- [ ] 跨回合集成：战斗内的回合流转，AP的正确累积，护盾跨回合保留，以及战斗结束时的AP和护盾清零
- [ ] 跨场景/系统集成：伤害计算溢出（护盾破裂进入HP扣除）、粮草耗尽后的移动惩罚（扣除等量HP），触发战斗失败（Game Over）
- [ ] UI集成：资源更新时通过 Signal (如 `resource_changed`) 广播并确保能够被外层系统正确捕获。

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

编写集成测试，在一个测试函数内模拟：
1. 玩家受到攻击，护盾破裂，HP减少
2. 玩家结束回合，护盾保留，AP清空或部分累积
3. 战斗结束，护盾和AP清空
4. 地图移动，粮草耗尽，触发扣除HP
5. 验证这些过程中发出的 Signal 是否正确。

**无需编写复杂的 UI 代码，核心是写一个能被 `/team-qa` 认可的 `tests/integration/resource_management/resource_integration_test.gd`**。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: 真正的 UI 组件编写和数据绑定
- Status System: Buff 和 Debuff 的详细层数计算

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 跨回合集成
  - Given: 玩家在战斗中，有护盾和部分 AP
  - When: 战斗结束触发
  - Then: 护盾清零，AP清零，HP和粮草保持不变
  - Edge cases: AP本来就是0的情况

- **AC-2**: 跨系统伤害与移动惩罚
  - Given: 粮草为 0，HP 为 10
  - When: 执行地图节点移动（耗费2点）
  - Then: HP 变为 8
  - Edge cases: 移动耗费 10点，导致 HP 变为 0，需发出死亡/失败信号。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/resource_management/resource_integration_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002, 003, 004, 005, 006
- Unlocks: None