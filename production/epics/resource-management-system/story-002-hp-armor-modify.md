# Story 002: HP/护盾修改与Signal通知

> **Epic**: 资源管理系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: 资源变更通知机制
**ADR Decision Summary**: 所有资源变化通过modify_resource()统一接口，触发resource_changed信号携带old_value、new_value、delta参数。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 所有资源变化必须通过ResourceManager统一接口
- Required: 资源变化时必须触发resource_changed信号，携带旧值、新值、变化量参数
- Forbidden: 禁止ResourceManager直接知道所有回调者

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md`, scoped to this story:*

- [ ] HP归零时立即触发战斗失败，不允许负值HP继续战斗
- [ ] 护盾正确先于HP吸收伤害；超出部分溢出扣HP
- [ ] HP恢复来源（酒馆/卡牌/事件）不超过武将HP上限
- [ ] modify_resource()接口修改HP和护盾，触发resource_changed信号
- [ ] Signal参数正确：resource_type, old_value, new_value, delta

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. 实现 `modify_resource(type: ResourceType, delta: int, allow_overflow: bool = false) -> bool`
2. HP修改逻辑：
   ```gdscript
   var old = resources[HP]
   var new_val = clamp(resources[HP] + delta, 0, max_values[HP])
   resources[HP] = new_val
   resource_changed.emit(ResourceType.HP, old, new_val, delta)
   if new_val <= 0:
       EventBus.game_over.emit(false)
   ```
3. 护盾修改逻辑：
   - 护盾上限由武将类型决定（默认=MaxHP，曹仁=MaxHP+30，张角无上限）
   - 护盾变化触发resource_changed信号
4. 伤害结算公式（F1）：
   ```gdscript
   var damage_to_hp = max(0, incoming_damage - current_armor)
   var new_armor = max(0, current_armor - incoming_damage)
   var new_hp = current_hp - damage_to_hp
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 资源数据结构初始化
- Story 003: 护盾跨战斗清零
- Story 007: UI响应resource_changed信号

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: HP归零触发战斗失败
  - Given: 当前HP=5
  - When: 受到10点伤害（modify_resource(HP, -10)）
  - Then: resources[HP] == 0，EventBus.game_over被触发（victory=false）
  - Edge cases: HP恰好归零（delta=-HP）

- **AC-2**: 护盾吸收伤害
  - Given: HP=50, 护盾=10
  - When: 受到8点伤害
  - Then: 护盾=2, HP=50（护盾吸收全部）
  - Edge cases: 护盾恰好归零

- **AC-3**: 护盾溢出扣HP
  - Given: HP=50, 护盾=10
  - When: 受到15点伤害
  - Then: 护盾=0, HP=45（护盾吸收10，溢出5扣HP）
  - Edge cases: 伤害>护盾+HP

- **AC-4**: HP恢复上限检查
  - Given: MaxHP=50, 当前HP=30
  - When: 恢复30HP（modify_resource(HP, +30)）
  - Then: HP=50（不超过上限）
  - Edge cases: 恢复值恰好到上限

- **AC-5**: Signal参数正确
  - Given: 当前HP=50
  - When: 受到10点伤害
  - Then: resource_changed信号触发，参数为(HP, 50, 40, -10)
  - Edge cases: delta为正数（恢复）

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/resource_management/hp_armor_modify_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（ResourceManager初始化）
- Unlocks: Story 003（护盾生命周期），Story 007（UI响应）
