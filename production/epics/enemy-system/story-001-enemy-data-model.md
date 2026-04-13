# Story 001: 敌人数据模型与CSV加载

> **Epic**: 敌人系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-13

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-002, TR-enemies-design-003, TR-enemies-design-005
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 采用集中式EnemyManager管理敌人数据，使用枚举区分职业和级别，从CSV加载100名敌人的基础属性。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持5种敌人职业和3种级别
- Required: 必须从CSV配置加载数据

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 定义 `EnemyClass` 枚举：INFANTRY(步兵), CAVALRY(骑兵), ARCHER(弓兵), STRATEGIST(谋士), SHIELD(盾兵)
- [ ] 定义 `EnemyTier` 枚举：NORMAL(普通), ELITE(精英), POWERFUL(强力)
- [ ] 定义 `EnemyData` 类：id, name, enemy_class, tier, max_hp, current_hp, armor, action_sequence, action_index, is_alive, cooldown_actions
- [ ] 实现 `EnemyManager` 的 `_load_enemy_data()` 方法，能够解析 `assets/data/enemies.csv` 并将数据存入字典。
- [ ] 能根据CSV中的字符串正确映射到 `EnemyClass` 和 `EnemyTier`。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. `EnemyData` 是一个 `RefCounted` 类。
2. CSV 字段：编号, 名称, 级别, 职业, 历史职业背景, 主要州郡, HP, 护甲, 行动序列（主）, 相变触发, 地形联动, 速度
3. `EnemyManager._load_enemy_data()` 解析后填充 `_enemies` 字典。
4. 提供 `get_enemy(enemy_id)` 方法获取。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 加载并解析具体的行动效果数据（Story 002）。
- 在回合内的行动索引流转（Story 003）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 职业和级别解析
  - Given: Mock CSV 行 `"E001", "黄巾力士", "普通敌人", "步兵"...`
  - When: `_load_enemy_data()`
  - Then: 解析出的 EnemyData `tier` 为 `NORMAL`，`enemy_class` 为 `INFANTRY`。

- **AC-2**: 序列解析
  - Given: CSV中序列列为 `"A04→A01→A01"`（或逗号分隔）
  - When: `_load_enemy_data()`
  - Then: `action_sequence` 数组应包含 3 个元素：`["A04", "A01", "A01"]`

- **AC-3**: 护甲与HP初始值
  - Given: CSV中 HP=`22`, 护甲=`0`
  - When: 解析
  - Then: `max_hp=22`, `current_hp=22`, `armor=0`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/enemy_data_loading_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 无
- Unlocks: Story 002 (行动库加载)
