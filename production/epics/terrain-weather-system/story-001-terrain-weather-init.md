# Story 001: 地形天气数据结构与初始化接口

Epic: 地形天气系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/terrain-weather-system.md`
**Requirement**: TR-terrain-weather-system-001 (7种地形), TR-terrain-weather-system-002 (4种天气), TR-terrain-weather-system-003 (地形固定)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: 地形天气系统架构
**ADR Decision Summary**: 定义 7 种地形和 4 种天气的枚举，通过 `TerrainWeatherManager` 进行集中式状态存储和管理。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须使用集中式TerrainWeatherManager管理地形和天气状态
- Required: 必须在战斗初始化时调用setup_battle(terrain_str, weather_str)设置环境

---

## Acceptance Criteria

*From GDD `design/gdd/terrain-weather-system.md`, scoped to this story:*

- [ ] 定义 `Terrain` 枚举：PLAIN, MOUNTAIN, FOREST, WATER, DESERT, PASS, SNOW
- [ ] 定义 `Weather` 枚举：CLEAR, WIND, RAIN, FOG
- [ ] 实现 `TerrainWeatherManager` 单例节点
- [ ] 提供内部解析方法 `_parse_terrain(string) -> Terrain` 和 `_parse_weather(string) -> Weather`
- [ ] 实现 `setup_battle(terrain_str: String, weather_str: String)` 接口设置当前状态，并重置天气切换记录和冷却。
- [ ] 发射 `terrain_changed(new_terrain)` 和 `weather_changed(new_weather)` 信号

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

1. 在 `TerrainWeatherManager.gd` 中定义所有基础结构。
2. 添加 `current_terrain` 和 `current_weather` 属性。
3. `setup_battle` 里清除 `weather_cooldowns` 字典和 `weather_change_history` 数组，然后赋值 current_terrain 和 current_weather。
4. 本故事不实现具体的效果，只建立可用的基础框架供战斗系统（C2）和状态系统（C1）互相联动。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体在 `setup_battle` 中触发的一次性效果（如水域滑倒），将在 Story 002 中处理。
- 回合末持续效果与天气切换机制。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 基础数据结构与解析
  - Given: `TerrainWeatherManager` 节点已加载
  - When: 调用 `_parse_terrain("mountain")` 和 `_parse_weather("fog")`
  - Then: 返回对应的枚举值 `Terrain.MOUNTAIN` 和 `Weather.FOG`。

- **AC-2**: 战斗初始设置
  - Given: 一场新战斗开始，传入 "desert" 和 "clear"
  - When: 调用 `setup_battle("desert", "clear")`
  - Then: `current_terrain` 更新为 DESERT，`current_weather` 更新为 CLEAR。并清理历史字典。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/terrain_weather/terrain_weather_init_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 无
- Unlocks: Story 002, Story 003, Story 005
