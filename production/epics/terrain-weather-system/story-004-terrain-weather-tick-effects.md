# Story 004: 每回合结束的持续环境效果

> **Epic**: 地形天气系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/terrain-weather-system.md`
**Requirement**: TR-terrain-weather-system-007 (对战斗的影响)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: 地形天气系统架构
**ADR Decision Summary**: 提供 `tick_terrain_effects()` 和 `tick_weather_effects()` 供战斗系统在回合结束时调用。处理如中毒叠加、灼烧传播等效果。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须实现每回合结束的地形/天气持续效果 tick_terrain_effects() 和 tick_weather_effects()

---

## Acceptance Criteria

*From GDD `design/gdd/terrain-weather-system.md`, scoped to this story:*

- [ ] 实现 `tick_terrain_effects()`。若为森林(FOREST)，对全体单位施加 1 层中毒(POISON)。若为沙漠(DESERT)，对全体单位施加 1 层灼烧(BURN)。
- [ ] 实现 `tick_weather_effects()`。
  - 若为风天(WIND)：遍历所有处于灼烧的单位，向其相邻未灼烧单位传播 1 层灼烧。
  - 若为雨天(RAIN)：全体处于灼烧的单位，额外移除 1 层灼烧（如果已有灼烧）。

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

1. 需要 `BattleManager` 或外部注入实体列表来遍历目标单位。
2. 风天的传播逻辑 `_spread_burn()`:
   - 先记录下所有当前有灼烧的单位列表（快照），避免一边传播一边检测导致无限蔓延。
   - 对每个有灼烧的敌人，找到其相邻单位（比如利用 `enemy.position` 属性差值为1），如果相邻单位没有灼烧，则施加 1 层。
3. 雨天的额外削减逻辑 `_reduce_burn_extra()`:
   - `StatusManager.remove_status(target, BURN)` 如果层数大于1，则重新施加 `layers - 1` 层。由于 ADR 中建议这么写以绕过 API 限制，这里可根据实际 StatusManager 接口（比如是否有直接减层数的API）灵活实现。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 真实的回合结束触发点（由 C2 卡牌战斗系统回合机管理）。这里仅提供供人调用的 tick 函数。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 森林全体中毒
  - Given: `current_terrain` 是 FOREST，且场上存活玩家和2个敌人。
  - When: 调用 `tick_terrain_effects()`
  - Then: 玩家和2个敌人分别增加 1 层 POISON。

- **AC-2**: 雨天削弱灼烧
  - Given: 敌人身上有 3 层 BURN。天气是 RAIN。
  - When: 调用 `tick_weather_effects()`
  - Then: 敌人身上的 BURN 变为 2 层。

- **AC-3**: 风天灼烧传播
  - Given: 敌人1有灼烧，敌人2(相邻)无灼烧。天气是 WIND。
  - When: 调用 `tick_weather_effects()`
  - Then: 敌人2获得 1 层灼烧。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/terrain_weather/terrain_weather_tick_effects_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, C1 状态效果系统
- Unlocks: 无
