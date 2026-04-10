# Story 001: 武将数据结构与CSV解析加载

> **Epic**: 武将系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/heroes-design.md`
**Requirement**: TR-heroes-design-002 (22名武将), TR-heroes-design-003 (4阵营), TR-heroes-design-004 (基础值)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 采用集中式 HeroManager 节点，并由 CSV 文件驱动所有武将的数据解析。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须从CSV配置文件加载武将数据。
- Required: 必须使用集中式HeroManager管理武将数据。
- Forbidden: 禁止分布式武将数据管理。

---

## Acceptance Criteria

*From GDD `design/gdd/heroes-design.md`, scoped to this story:*

- [ ] 定义 `HeroData` 实体类，包含 `id, name, faction, max_hp, cost, leadership, primary_troops, secondary_troop, hand_limit` 等字段。
- [ ] 定义 `Faction` 枚举 (WEI, SHU, WU, YUN)。
- [ ] 实现 `_load_hero_data()` 从 `heroes.csv` 读取至少22个行数据，解析各字段。
- [ ] 提供 `get_hero(id)` 和 `get_heroes_by_faction(faction)` 接口，验证数组大小和具体取值。
- [ ] 正确处理特殊情况：袁绍 (`id="yuan_shao"`) 的 `hand_limit` 为 6，其他武将默认 5。

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

1. 在 `HeroManager.gd` 内定义枚举和类。
2. CSV 格式参考 ADR 中的模板：`id,name,faction,hp,cost,leadership,primary_troops,secondary_troop,passive_id,passive_name,passive_desc,passive_trigger,exclusive_deck`。
3. `primary_troops` 以 `/` 分隔，如 `"infantry/cavalry"`，需要 `String.split()` 转换为枚举。
4. 本故事重点构建数据结构，暂不实现被动的动态注册（Story 003 实现）。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体每个被动技能的绑定函数。
- 生涯地图的复杂展开（暂且将 CSV 里的地图字段作为普通字符串数组存下来即可）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 22武将加载
  - Given: 一个包含22行合规数据的 `heroes.csv`
  - When: `HeroManager._load_hero_data()` 执行
  - Then: 内部 `_heroes` 字典的 `size()` 为 22。

- **AC-2**: 阵营过滤
  - Given: 加载完成的数据
  - When: 调用 `get_heroes_by_faction(Faction.WEI)`
  - Then: 返回的数组大小应等于配置表中曹魏武将的数量（7名）。

- **AC-3**: 袁绍特殊手牌上限
  - Given: `yuan_shao` 被正确加载
  - When: 获取袁绍的 `hand_limit`
  - Then: 返回值为 6，其他普通武将返回 5。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/hero_system/hero_data_loading_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 无
- Unlocks: Story 002, Story 003, Story 004
