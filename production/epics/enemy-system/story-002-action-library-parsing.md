# Story 002: 敌人行动库与解析

> **Epic**: 敌人系统
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-004, TR-enemies-design-009
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: 敌人AI行动序列执行器
**ADR Decision Summary**: 定义71种行动的数据结构 `EnemyAction`，从 CSV 中读取并建立一个静态的库供执行时提取。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持71种行动的数据封装。
- Forbidden: 禁止硬编码100个状态机，必须数据驱动。

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 定义 `EnemyAction` 数据类，包含：id, type, target, damage, effect_status, layers, cooldown 等字段。
- [ ] 从 `assets/data/enemy_actions.csv` 加载解析 71 种 A/B/C 类行动。
- [ ] 将行动数据按 `action_id` 映射到全局字典供后续查询调用。
- [ ] 特别需要解析字段：是否带"蓄力"(charge)、对谁施加什么状态、是否召唤等特殊标识。

---

## Implementation Notes

*Derived from ADR-0015 Implementation Guidelines:*

1. `EnemyAction` 使用简单的 Dictionary 或 RefCounted 类。
2. 动作分类可通过字符串 `action.type` 标识：`"attack"`, `"buff"`, `"debuff"`, `"heal"`, `"special"`, `"curse"`。
3. `target` 字段支持 `"player"`, `"self"`, `"all_allies"`, `"random_ally"`。
4. 解析后，给 `EnemyManager` 增加一个 `_get_action_data(action_id: String) -> EnemyAction` 接口。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 实际在战斗场景中产生伤害或施加状态的逻辑（属于执行器）。
- 行动决定与优先级的选取（属于决策树）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 行动库加载数量
  - Given: `enemy_actions.csv` 拥有 71 条合法数据
  - When: 系统启动加载库
  - Then: `_action_database` 键值对总数为 71。

- **AC-2**: 复杂动作解析
  - Given: CSV 中某条动作同时有物理伤害和添加 Debuff（如 C16 鬼神之怒）
  - When: 提取该 ID 的配置
  - Then: 返回的对象能正确标识 `damage=12`，且附带 `status="broken"`, `layers=1`。

- **AC-3**: 查无此行动
  - Given: 传入非法的 `action_id` = "X99"
  - When: 调用 `_get_action_data("X99")`
  - Then: 优雅返回 null 或默认空操作，不崩溃。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/action_library_parsing_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 无
- Unlocks: Story 003, Story 006
