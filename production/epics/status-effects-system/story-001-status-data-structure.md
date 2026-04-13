# Story 001: 状态数据结构与基础增删改

Epic: 状态效果系统
Estimate: 1 day
Status: Done
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: TR-status-design-001 (20种状态效果), TR-status-design-002 (7种Buff + 13种Debuff)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: 状态效果系统架构
**ADR Decision Summary**: 采用集中式 StatusManager + 事件驱动模式管理20种状态效果（7Buff+13Debuff），所有状态保存在同一字典并提供统一读写接口。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 纯数据结构管理，使用原生Array/Dictionary API。

**Control Manifest Rules (this layer)**:
- Required: 必须采用集中式StatusManager+事件驱动模式
- Required: 必须支持20种状态（7种Buff + 13种Debuff）
- Forbidden: 禁止分布式状态管理难以统一跟踪
- Forbidden: 禁止组件式状态导致性能开销大

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [x] 定义 StatusType (Buff/Debuff) 和 StatusCategory (包含B1-B7和D1-D13共20种枚举)
- [x] 创建 StatusEffect 数据类，包含: category, type, layers, damage_per_layer, penetrates_shield, is_consumable 字段
- [x] 初始化 StatusManager Autoload（集中式管理节点）
- [x] 提供 apply_status(target, category, layers, source) 基础接口（暂不处理叠加/互斥规则，仅添加至字典）
- [x] 提供 get_status(target, category) 和 remove_status(target, category) 基础接口
- [x] 提供 status_applied 和 status_removed 信号并在对应操作时发射

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

1. 在 `StatusManager.gd` 中定义枚举：
   - BUFF: FURY, SWIFT, BLOCK, DEFEND, COUNTER, PIERCE, IMMUNE
   - DEBUFF: POISON, TOXIC, FEAR, CONFUSION, BLIND, SLIP, BROKEN, WEAK, BURN, PLAGUE, STUN, BLEED, FROSTBITE
2. 在 `_create_status()` 方法中，使用 `match category:` 为20种状态初始化属性参数。
3. 数据存储：使用 `_status_map: Dictionary = {}`，键为 `target` 节点引用，值为 `Array[StatusEffect]`。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 状态叠加与互斥规则（本故事 apply 仅做简单数组 append 即可）
- Story 003: 回合结束时的层数消耗
- Story 004: 状态持续伤害计算

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 20种枚举和数据初始化
  - Given: StatusManager 被加载
  - When: 调用 _create_status(POISON, 3, "test")
  - Then: 返回对象 type=DEBUFF, damage_per_layer=4, penetrates_shield=true
  - Edge cases: 所有20种状态枚举都要测试初始化属性

- **AC-2**: 基础施加与读取
  - Given: 一个空目标节点
  - When: 调用 apply_status(target, FURY, 2)
  - Then: get_status(target, FURY) 返回 2
  - Edge cases: 读取不存在的目标或状态时返回 0

- **AC-3**: 基础移除
  - Given: 目标节点已有 FURY 状态 2层
  - When: 调用 remove_status(target, FURY)
  - Then: get_status(target, FURY) 返回 0
  - Edge cases: 移除不存在的状态返回 false，不抛错

- **AC-4**: 信号发射
  - Given: 目标节点
  - When: 施加并随后移除状态
  - Then: status_applied 和 status_removed 信号必须按顺序发出，参数携带正确
  - Edge cases: 移除不存在状态时不发信号

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/status_system/status_data_structure_test.gd` — must exist and pass

**Status**: [x] Implemented in src/core/StatusManager.gd and src/core/StatusEffect.gd

---

## Dependencies

- Depends on: None
- Unlocks: Story 002 (叠加与互斥规则)
