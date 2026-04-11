# Story 001: F2+C1 资源与状态联动集成测试

> **Epic**: 集成测试
> **Status**: Backlog
> **Layer**: Integration
> **Type**: Integration
> **Manifest Version**: 2026-04-11

## Context

**GDD**: `design/gdd/resource-management-system.md` 和 `design/gdd/status-design.md`
**Requirement**: TR-resource-management-system-003, TR-status-design-003

**ADR Governing Implementation**: ADR-0003 (资源变更) 和 ADR-0006 (状态效果)

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须通过ResourceManager和StatusManager的信号联动测试
- Required: 必须验证资源变动触发状态效果的自动结算

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md` 和 `design/gdd/status-design.md`，跨系统整合：*

- [ ] 当ResourceManager的HP减少（如因伤害）时，StatusManager必须自动触发 `status_applied` 信号（用于中毒Debuff）
- [ ] 当ResourceManager的HP增加（如通过治疗）时，StatusManager必须自动触发 `status_removed` 信号（用于治疗Buff）
- [ ] 持续伤害（DOT）必须根据ResourceManager的当前HP变化进行动态结算
- [ ] 护盾（Armor）的增减必须影响Debuff的穿透判定（如Poison的`penetrates_shield`属性）
- [ ] 所有联动必须通过信号机制，禁止直接调用或轮询

---

## Implementation Notes

*Derived from ADR-0003 and ADR-0006 Implementation Guidelines:*

1. 在 `ResourceManager.gd` 的 `modify_resource()` 中，当HP减少时，向 `StatusManager` 发送 `damage_dealt` 事件
2. 在 `StatusManager.gd` 中，监听 `damage_dealt` 信号，根据当前状态（如Poison）计算DOT伤害
3. 在 `StatusManager` 中，根据资源变化（如HP > 80%）自动移除 `HEALING` Buff
4. 在 `StatusManager` 中，根据护盾值变化更新 `penetrates_shield` 的有效性

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 卡牌对资源的直接影响（Story 002-005）
- 敌人AI对资源的影响（Story 003-004）
- UI对状态的可视化（Story 007）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Integration stories — test spec]:**

- **AC-1**: 毒性持续伤害（Poison）
  - Given: ResourceManager当前HP=50，StatusManager施加了 `POISON`（层数=3，每层伤害=4，穿透护盾=true）
  - When: ResourceManager被攻击，HP减少至40
  - Then: StatusManager在下一个回合前结算，扣除12点HP（3×4），并发出 `status_applied` 信号
  - Edge cases: 如果护盾>12，应扣除护盾后HP不变；如果护盾<12，应扣除护盾并扣除剩余伤害到HP

- **AC-2**: 治疗Buff自动移除
  - Given: ResourceManager当前HP=85（上限100），StatusManager施加了 `HEALING`（+5/回合）
  - When: ResourceManager通过治疗恢复至95
  - Then: StatusManager自动移除 `HEALING` 状态，并发出 `status_removed` 信号

- **AC-3**: 护盾穿透
  - Given: ResourceManager当前护盾=10，StatusManager施加了 `POISON`（穿透护盾=true）
  - When: 毒性结算，伤害=15
  - Then: 护盾被消耗至0，HP被扣除5

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/resource_status_integration_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (资源数据结构), Story 001 (状态数据结构)
- Unlocks: Story 002 (C2+C3 战斗循环集成测试)
