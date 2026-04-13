# Story 002: 敌人行动库(71种)数据加载

Epic: 敌人系统
Estimate: 1 day
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-13

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-004, TR-enemies-design-009
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 定义具体的Action类型并从 `enemy_actions.csv` 加载，存入内存供查询。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持71种行动的数据解析

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 定义行动数据结构，能存储行动名称、级别（A/B/C）、基础伤害、状态施加（种类与层数）、冷却回合、目标类型等。
- [ ] 实现 `EnemyManager._load_action_database()` 解析 `assets/data/enemy_actions.csv`。
- [ ] 提供 `_get_action_data(action_id: String)` 方法进行 O(1) 查询。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. CSV 字段包含：编号, 行动名, 级别, 效果描述, 目标, 数值参考, 冷却回合, 条件触发等。
2. 提取出关键的解析逻辑，例如 `数值参考` 列可能写着 "伤害10~14 + 眩晕×1"，可以解析成 `damage_min`, `damage_max`, `status_type`, `status_layers`（或直接使用强类型配置，避免过于复杂的正则解析）。建议在实际项目开发中规范化 CSV 的机读格式。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体行动的效果执行（由 Story 006 处理，本故事仅负责读取和提供数据结构）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 行动加载
  - Given: Mock 的 `enemy_actions.csv`
  - When: 系统启动
  - Then: 能够通过 `_get_action_data("A01")` 获取到普通劈砍的配置。

- **AC-2**: 解析异常处理
  - Given: 错误的行动ID
  - When: `_get_action_data("Z99")`
  - Then: 返回空的或安全的默认字典，不导致崩溃。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/action_data_loading_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (数据模型基础设施)
- Unlocks: Story 004 (行动意图公示)
