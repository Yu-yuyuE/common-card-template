# Story 005: 状态伤害修正系数（Modifiers）

Epic: 状态效果系统
Estimate: 1 day
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: TR-status-design-007 (状态效果对伤害的修正)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: 状态效果系统架构
**ADR Decision Summary**: 提供 `calculate_damage_modifier` 和 `calculate_incoming_damage` 方法供战斗系统在计算伤害时调用，进行百分比乘算。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 状态效果修正必须在所有基础修正之后应用
- Required: 最终伤害不能为负数，最小值必须为1（若未被闪避/免疫）

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [ ] 实现攻击方伤害修正：怒气(FURY) 伤害+25%，虚弱(WEAK) 伤害-25%
- [ ] 实现受击方伤害修正：坚守(DEFEND) 受到伤害-25%，破甲(BROKEN) 受到伤害+25%，恐惧(FEAR) 额外伤害=层数
- [ ] 实现盲目(BLIND)逻辑：50%概率直接返回伤害 0 (闪避)
- [ ] 多个修正叠加时采用连乘机制（例如：基础 × 0.75 × 1.25）
- [ ] 最终返回的伤害值经过四舍五入或向下取整（按引擎标准 `int()`），最小为1点（除非被闪避=0）

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

1. 在 `StatusManager` 中实现：
   ```gdscript
   func calculate_damage_modifier(target: Node, base_damage: int) -> int
   func calculate_incoming_damage(target: Node, incoming_damage: int) -> int
   ```
2. 注意GDD要求：破甲(BROKEN) 受伤+25%，这应当放在 `calculate_incoming_damage` 里面。
3. 盲目闪避逻辑使用 `randf() > 0.5` 判断。如果在 `calculate_incoming_damage` 阶段计算，如果触发闪避直接返回 0。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 地形和天气的伤害修正（由 TerrainWeatherManager 计算，这里只负责状态那一部分）
- 战斗系统的全套公式整合（这由战斗系统Epic调用本模块的返回值来完成）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 攻击方修正 (怒气与虚弱)
  - Given: 攻击方拥有怒气(FURY)，基础伤害 10
  - When: 调用 calculate_damage_modifier
  - Then: 10 * 1.25 = 12 (整型)
  - Edge cases: 同时拥有怒气和虚弱 (互斥机制保证不可能，但若强制存在则为 10 * 1.25 * 0.75 = 9)

- **AC-2**: 受击方修正 (破甲)
  - Given: 受击方拥有破甲(BROKEN)，传入伤害 10
  - When: 调用 calculate_incoming_damage
  - Then: 10 * 1.25 = 12

- **AC-3**: 受击方修正 (坚守+恐惧)
  - Given: 受击方拥有坚守(DEFEND)和3层恐惧(FEAR)，传入伤害 10
  - When: 调用 calculate_incoming_damage
  - Then: 坚守(-25%) = 7，加上恐惧层数(3) = 10。最终伤害10。(注意乘法和加法的顺序，按代码实现：先乘后加)

- **AC-4**: 盲目闪避判定
  - Given: 目标拥有盲目(BLIND)
  - When: 多次调用 calculate_incoming_damage(target, 10)
  - Then: 结果应约有50%的概率返回0，另外50%返回正常伤害。可以通过Mock RNG或大量测试验证。

- **AC-5**: 最小伤害保底
  - Given: 经过减伤计算后，非闪避状态的伤害 < 1
  - When: 调用 calculate_incoming_damage(target, 1) + DEFEND
  - Then: 结果保底返回 1

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/status_system/status_damage_modifier_test.gd` — must exist and pass

**Status**: [x] Created — tests/unit/status_system/status_damage_modifier_test.gd (14 unit tests)
Interfaces added to StatusManager: calculate_damage_modifier(), calculate_incoming_damage(), calculate_incoming_damage_with_rng()

---

## Dependencies

- Depends on: Story 001 (数据结构)
- Unlocks: 无
