# Story 002: 状态叠加与互斥规则

Epic: 状态效果系统
Estimate: 1 day
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: TR-status-design-003 (同类叠加/不同类互斥)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: 状态效果系统架构
**ADR Decision Summary**: 同类状态刷新取最高层数，不同类状态（如同为Debuff）互斥并覆盖原有状态。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 纯逻辑运算。

**Control Manifest Rules (this layer)**:
- Required: 同类状态必须叠加层数，不同类状态必须互斥
- Forbidden: 禁止状态组合未经测试导致bug

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [ ] 当目标施加已有同类状态时，层数合并累加（例如：2层中毒 + 2层中毒 = 4层中毒）
- [ ] 特殊：施加"剧毒"时覆盖"中毒"（合并层数），反之亦然，视为互斥覆盖
- [ ] 当目标施加不同类状态时（例如：已有中毒，新施加破甲），旧状态被移除，新状态生效
- [ ] Buff 仅与 Debuff 互斥（即施加 Buff 会清除 Debuff？注：GDD指出"不同类互斥：后加覆盖前者"。需仔细遵循GDD规则：同为DEBUFF类别不同时互斥覆盖；同为BUFF类别不同时互斥覆盖）
- [ ] 触发互斥覆盖时不触发被覆盖状态的 `status_removed` 效果（静默移除，但需发送信号更新UI）

*(勘误：根据GDD：施加新状态时：如果是同类(category)，叠加层数；如果是不同类(不同category)，互斥覆盖，移除现有状态施加新状态。即目标同一时间只能有一种Buff和一种Debuff。)*

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

1. 在 `apply_status()` 方法中实现 `_handle_exclusive()` 逻辑。
2. 同类判断（category 相同）：`existing.layers += new_status.layers`，然后触发 `status_refreshed` 信号（GDD规定中毒+中毒=叠加，不是刷新取高值！注：ADR和GDD有冲突，以GDD 4.状态叠加规则为准："同类状态：层数叠加。两次施加2层中毒=4层"）。
3. 互斥判断：如果 `new_status.category != existing.category`，且 `new_status.type == existing.type`，则互斥覆盖。
4. 特别注意GDD中明确：Buff只与Debuff互斥吗？GDD写着"不同类状态：互斥，后加覆盖前者"。即同一个单位只能同时拥有1个Buff和1个Debuff（若施加Debuff覆盖旧Debuff）。需严格按GDD代码块实现。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 基础增删改
- Story 006: 免疫状态（IMMUNE阻止所有Debuff，放在特殊交互实现）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 同类叠加
  - Given: 目标有 2层 中毒 (POISON)
  - When: 再次施加 3层 中毒
  - Then: 目标最终拥有 5层 中毒，发出 `status_refreshed` 信号
  - Edge cases: 施加 0 层时无影响

- **AC-2**: 不同类互斥覆盖 (Debuff覆盖Debuff)
  - Given: 目标有 3层 中毒
  - When: 施加 2层 破甲 (BROKEN)
  - Then: 中毒被移除，目标获得 2层 破甲。发出中毒移除和破甲施加信号
  - Edge cases: 灼烧(BURN)覆盖中毒(POISON)

- **AC-3**: 不同类互斥覆盖 (Buff覆盖Buff)
  - Given: 目标有 2层 坚守 (DEFEND)
  - When: 施加 1层 怒气 (FURY)
  - Then: 坚守被移除，获得 1层 怒气
  - Edge cases: 消耗型Buff覆盖持续型Buff

- **AC-4**: Buff 与 Debuff 共存
  - Given: 目标有 2层 怒气 (Buff)
  - When: 施加 3层 破甲 (Debuff)
  - Then: 目标同时拥有怒气和破甲
  - Edge cases: 两者均正确触发UI信号

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/status_system/status_stacking_exclusive_test.gd` — must exist and pass

**Status**: [x] Created — tests/unit/status_system/status_stacking_exclusive_test.gd (14 unit tests)

---

## Dependencies

- Depends on: Story 001 (基础增删改)
- Unlocks: 无
