# Story 004: 状态持续伤害计算（DoT）

Epic: 状态效果系统
Estimate: 1 day
Status: Done
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: TR-status-design-004 (状态伤害计算), TR-status-design-006 (穿透护盾/走护盾)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: 状态效果系统架构
**ADR Decision Summary**: `tick_status` 时先结算持续伤害。根据 `penetrates_shield` 布尔值决定是直接扣减 HP 还是先扣护盾再溢出。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 状态伤害必须区分穿透护盾和走护盾两种类型
- Required: 必须支持与ResourceManager集成修改真实HP/护盾

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [x] DoT伤害计算公式：`DotDamage = StatusLayers × DamagePerLayer`
- [x] 穿透护盾（中毒D1、剧毒D2、瘟疫D10、重伤D12、冻伤D13）：伤害直接通过ResourceManager调用扣减HP，护盾保持不变
- [x] 走护盾（灼烧D9）：伤害先扣护盾，若护盾不足则溢出扣除HP
- [x] 每造成一次状态伤害，需发射 `status_damage_dealt(target, damage, category)` 信号
- [x] 结算顺序：同一回合内，先结算DoT伤害，然后再执行层数-1消耗（已在Story 003规划）

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

1. 在 `tick_status(target)` 的遍历中，首先处理伤害：
   ```gdscript
   if status.damage_per_layer > 0:
       var total_damage = status.layers * status.damage_per_layer
       _apply_damage(target, total_damage, status)
   ```
2. 实现 `_apply_damage(target, damage, status)` 方法。
3. 依赖 `ResourceManager.modify_resource()` 方法：
   - 穿透：`modify_resource(HP, -damage)`
   - 不穿透：先获取护盾并抵挡，剩余值 `modify_resource(HP, -remaining_damage)`
4. 注意冻伤（FROSTBITE）不是回合末触发，而是"每次出牌HP-1"，应通过暴露特定接口给战斗系统调用，或作为特殊事件响应（可在此实现 `trigger_frostbite()`）。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: 回合结束的层数消耗（已处理）
- Story 005: 攻击时百分比伤害修正（怒气/虚弱等）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 穿透护盾伤害结算 (中毒)
  - Given: 目标HP=50, 护盾=10, 拥有3层中毒(每层4伤)
  - When: 调用 tick_status(target)
  - Then: 造成12点穿透伤害。目标HP变为38, 护盾仍为10。发出伤害信号。

- **AC-2**: 走护盾伤害结算 (灼烧) 完全吸收
  - Given: 目标HP=50, 护盾=20, 拥有3层灼烧(每层5伤)
  - When: 调用 tick_status(target)
  - Then: 造成15点伤害。护盾变为5, HP仍为50。发出伤害信号。

- **AC-3**: 走护盾伤害结算 (灼烧) 溢出
  - Given: 目标HP=50, 护盾=5, 拥有2层灼烧(每层5伤)
  - When: 调用 tick_status(target)
  - Then: 造成10点伤害。护盾变为0, HP变为45 (溢出5点)。

- **AC-4**: 冻伤触发
  - Given: 目标有 2层 冻伤
  - When: 触发冻伤效果（出牌）
  - Then: HP直接 -1，层数不减少（层数由回合末统一消耗）

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/status_system/status_dot_damage_test.gd` — must exist and pass

**Status**: [x] Implemented in StatusManager.on_round_start_dot() - tests in status_manager_test.gd

---

## Dependencies

- Depends on: Story 003 (回合结束机制), F2 资源管理系统 (ResourceManager)
- Unlocks: 无
