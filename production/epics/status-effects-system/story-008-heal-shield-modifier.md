# Story 008: 治疗与护盾修正系数（流血/生锈）

Epic: 状态效果系统
Estimate: 1 day
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-12

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: TR-status-design-008 (状态效果对治疗和护盾的修正)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: 状态效果系统架构
**ADR Decision Summary**: 提供 `calculate_heal_modifier` 和 `calculate_shield_modifier` 方法供资源管理系统在计算治疗和护盾时调用，进行百分比修正。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 治疗和护盾修正必须在基础值计算之后应用
- Required: 修正后的最小治疗/护盾量为1（若基础值>=1）
- Required: 流血和生锈属于不同类状态，遵循互斥规则（后加覆盖前者）

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [ ] 实现流血(BLEEDING)修正：所有治疗量×0.5
- [ ] 实现生锈(RUST)修正：所有护盾量×0.5
- [ ] 治疗修正应用时机：在资源管理系统执行HP恢复前调用
- [ ] 护盾修正应用时机：在资源管理系统执行护盾增加前调用
- [ ] 流血与生锈遵循状态互斥规则（不同类Debuff，后施加的覆盖先前的）
- [ ] 修正计算结果向下取整（使用 `int()` 转换），最小值为1（若基础值>=2）

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

1. 在 `StatusManager` 中实现：
   ```gdscript
   func calculate_heal_modifier(target: Node, base_heal: int) -> int
   func calculate_shield_modifier(target: Node, base_shield: int) -> int
   ```

2. 治疗修正逻辑：
   ```gdscript
   func calculate_heal_modifier(target: Node, base_heal: int) -> int:
       if not _status_map.has(target):
           return base_heal
       
       var modifier = 1.0
       if get_status(target, StatusCategory.BLEEDING) > 0:
           modifier *= 0.5
       
       return int(base_heal * modifier)
   ```

3. 护盾修正逻辑：
   ```gdscript
   func calculate_shield_modifier(target: Node, base_shield: int) -> int:
       if not _status_map.has(target):
           return base_shield
       
       var modifier = 1.0
       if get_status(target, StatusCategory.RUST) > 0:
           modifier *= 0.5
       
       return int(base_shield * modifier)
   ```

4. 与 ResourceManager 集成：
   - ResourceManager 在执行 `modify_resource(HP, amount)` 时，若 amount > 0（治疗），先调用 StatusManager.calculate_heal_modifier
   - ResourceManager 在执行 `modify_resource(SHIELD, amount)` 时，若 amount > 0（护盾），先调用 StatusManager.calculate_shield_modifier

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 状态叠加与互斥规则（由 Story 002 处理）
- 状态施加与移除逻辑（由 Story 001 处理）
- 资源管理系统的具体实现（由资源管理 Epic 处理，本 story 只提供修正接口）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 流血状态减少治疗量
  - Given: 目标拥有流血(BLEEDING)状态
  - When: 调用 calculate_heal_modifier(target, 10)
  - Then: 返回 5 (10 × 0.5)
  - Edge cases: 基础治疗为1 → 返回0（int(1*0.5)=0）

- **AC-2**: 生锈状态减少护盾量
  - Given: 目标拥有生锈(RUST)状态
  - When: 调用 calculate_shield_modifier(target, 10)
  - Then: 返回 5 (10 × 0.5)
  - Edge cases: 基础护盾为1 → 返回0（int(1*0.5)=0）

- **AC-3**: 无状态时正常返回
  - Given: 目标无流血状态
  - When: 调用 calculate_heal_modifier(target, 10)
  - Then: 返回 10

- **AC-4**: 流血与生锈互斥规则
  - Given: 目标拥有流血状态
  - When: 施加生锈状态
  - Then: 流血状态被移除，生锈状态生效（调用 calculate_heal_modifier 返回正常值，calculate_shield_modifier 返回修正值）

- **AC-5**: 多次施加同类状态刷新
  - Given: 目标拥有2层流血
  - When: 施加3层流血
  - Then: 流血层数更新为3（取较高值）

- **AC-6**: 治疗与护盾修正独立生效
  - Given: 目标拥有流血状态（理论上与生锈互斥，但若因特殊原因同时存在）
  - When: 分别调用 calculate_heal_modifier(target, 10) 和 calculate_shield_modifier(target, 10)
  - Then: 治疗返回5，护盾返回10（流血不影响护盾）

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/status_system/status_heal_shield_modifier_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (数据结构), Story 002 (状态叠加与互斥)
- Unlocks: Story 007 (UI绑定需要显示流血/生锈状态)
