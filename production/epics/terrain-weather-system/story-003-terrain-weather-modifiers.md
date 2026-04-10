# Story 003: 伤害修正系数与费用调整接口

> **Epic**: 地形天气系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/terrain-weather-system.md`
**Requirement**: TR-terrain-weather-system-005 (28种组合), TR-terrain-weather-system-007 (对战斗的影响)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: 地形天气系统架构
**ADR Decision Summary**: 提供 `get_terrain_modifier()`, `get_weather_modifier()`, `get_cavalry_cost_modifier()` 接口供卡牌战斗系统调用。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须提供get_terrain_modifier(card_category)接口返回地形修正系数
- Required: 必须提供get_weather_modifier(card_category)接口返回天气修正系数

---

## Acceptance Criteria

*From GDD `design/gdd/terrain-weather-system.md`, scoped to this story:*

- [ ] 实现 `get_terrain_modifier(card_category: String) -> float`
  - 骑兵卡 ("cavalry")：平原 返回 1.5，山地 返回 0.5，其他返回 1.0
  - 灼烧伤害 ("burn")：森林 返回 1.5，雪地 返回 0.5，其他返回 1.0
- [ ] 实现 `get_weather_modifier(card_category: String) -> float`
  - 返回 1.0（目前GDD中天气不直接影响伤害乘数，保留扩展性）
- [ ] 实现 `get_cavalry_cost_modifier() -> int`
  - 沙漠 返回 -1，其他返回 0
- [ ] 提供辅助查询接口：`is_terrain_favorable(card_category)` 和 `is_terrain_unfavorable(card_category)`。

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

1. 在 `TerrainWeatherManager` 中添加对应的访问器方法。
2. 这些接口需容忍非法或不认识的 `card_category` 参数，默认安全返回 1.0 或 0。
3. `card_category` 取决于兵种卡系统的枚举（目前假设为传入字符串 `"infantry", "cavalry", "archer", "burn"` 等）。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 计算全量最终伤害。此模块只提供乘数，不执行计算。
- 扣减骑兵卡费用的实际行为（由 C2 卡牌战斗系统中的出牌框架执行）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 骑兵修正
  - Given: `current_terrain` 是 PLAIN
  - When: 调用 `get_terrain_modifier("cavalry")`
  - Then: 返回 1.5。如果地形是 MOUNTAIN 则返回 0.5。如果是 FOREST 则返回 1.0。

- **AC-2**: 灼烧伤害修正
  - Given: `current_terrain` 是 FOREST
  - When: 调用 `get_terrain_modifier("burn")`
  - Then: 返回 1.5。如果是 SNOW 则返回 0.5。

- **AC-3**: 骑兵费用在沙漠
  - Given: `current_terrain` 是 DESERT
  - When: 调用 `get_cavalry_cost_modifier()`
  - Then: 返回 -1。如果在 PLAIN 返回 0。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/terrain_weather/terrain_weather_modifiers_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: C2 卡牌战斗系统的伤害管线
