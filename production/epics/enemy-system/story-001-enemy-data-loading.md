# Story 001: 敌人数据结构与配置加载

> **Epic**: 敌人系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-002, TR-enemies-design-003, TR-enemies-design-005, TR-enemies-design-009
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 定义 EnemyClass 和 EnemyTier 枚举，在 `EnemyManager` 中构建 100 名敌人的数据结构字典，并从 CSV 初始化解析。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持5种职业和3种级别
- Required: 必须能够根据CSV配置建立数据字典查询

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 定义 `EnemyClass` (步兵/骑兵/弓兵/谋士/盾兵) 和 `EnemyTier` (普通/精英/强力)。
- [ ] 创建 `EnemyData` RefCounted 类，包含基本属性：id, name, hp, armor, speed, sequence, tier, class 等。
- [ ] 实现 `EnemyManager` 内部的 `_load_enemy_data()`。
- [ ] 能正确读取 `assets/data/enemies.csv` 并将 100 个敌人的数据存入内部字典 `_enemies`。
- [ ] 提供基于ID查询、按Tier查询、按Class查询的基础获取接口。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. 使用 FileAccess 和 CSV 读取相关的内置函数解析文件。
2. 对于 `action_sequence` 的解析：读取字符串如 `"A01→A01→A03"`，切分为数组 `["A01", "A01", "A03"]`。
3. 解析相变规则字符串如 `"HP<40%:B01→C01→B14→C12"`，将阈值和新序列结构化保存。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体行动（Action）库的加载和解析（将在 Story 002 中处理）。
- 行动轮换与公示逻辑（将在后续处理）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 枚举与数据加载
  - Given: 一个格式良好的 `enemies.csv` 测试文件包含 2 个条目
  - When: `EnemyManager` 初始化加载
  - Then: 内部 `_enemies` 字典大小为 2，并且能用 ID 取出。

- **AC-2**: 职业和级别解析
  - Given: CSV 填入 "步兵", "精英"
  - When: 读取解析
  - Then: 数据映射到 `EnemyClass.INFANTRY` 和 `EnemyTier.ELITE`。

- **AC-3**: 序列解析
  - Given: 字段 `"A01→B01→C01"`
  - When: 加载后查看对象的 `action_sequence`
  - Then: 数组内元素为 `["A01", "B01", "C01"]`。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/enemy_data_loading_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 没有任何系统级依赖，只依赖 CSV 文件。
- Unlocks: Story 002
