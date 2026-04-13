# Story 002: 地形天气一次性初始化效果

Epic: 地形天气系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/terrain-weather-system.md`
**Requirement**: TR-terrain-weather-system-007 (对战斗的影响)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: 地形天气系统架构
**ADR Decision Summary**: 在 `setup_battle` 时，根据当前设定的地形和天气，调用状态系统或直接修改护甲以实施一次性环境影响。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须在特定地形下自动施加初始状态效果

---

## Acceptance Criteria

*From GDD `design/gdd/terrain-weather-system.md`, scoped to this story:*

- [ ] 在 `setup_battle` 尾部调用 `_apply_terrain_init_effects()` 和 `_apply_weather_init_effects()`。
- [ ] 水域 (WATER)：战斗开始时给所有单位（玩家和所有存活敌人）施加 1 层滑倒 (SLIP)。
- [ ] 关隘 (PASS)：战斗开始时给敌方（所有存活敌人）增加 10 点护甲 + 2 层坚守 (DEFEND)。
- [ ] 雪地 (SNOW)：战斗开始时给玩家施加 2 层冻伤 (FROSTBITE)。
- [ ] 雾天 (FOG)：战斗开始时给所有单位施加 2 层盲目 (BLIND)。

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

1. 依靠 `StatusManager` 执行状态施加：
   ```gdscript
   StatusManager.apply_status(BattleManager.player_entity, StatusManager.StatusCategory.FROSTBITE, 2, "terrain_snow")
   ```
2. 需要获取所有的单位列表。如果系统耦合良好，可通过 `BattleManager.player_entity` 和 `BattleManager.enemy_entities` 拿到。为保证解耦和测试，可以注入 `player_node` 和 `enemy_nodes`，或者通过 `get_tree().get_nodes_in_group("battle_entities")`，ADR中采用直接引用 `BattleManager`。
3. 增加护甲可以直接修改敌人的 `armor` 字段或调用 `enemy.take_damage(-10)` 的护盾部分。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 持续效果如沙漠每回合灼烧（属于回合末结算故事）。
- 伤害乘数修正计算（属于修正接口故事）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 水域全体滑倒
  - Given: 初始化战斗，地形传入 "water"。
  - When: `setup_battle` 完成。
  - Then: 玩家和场上所有存活敌人获得 1 层 SLIP 状态。

- **AC-2**: 关隘守军优势
  - Given: 初始化战斗，地形传入 "pass"。
  - When: `setup_battle` 完成。
  - Then: 只有敌方获得 10 护甲和 2 层 DEFEND。玩家无影响。

- **AC-3**: 雾天致盲
  - Given: 战斗以 "fog" 天气开始。
  - When: `setup_battle` 完成。
  - Then: 全体单位获得 2 层 BLIND 状态。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/terrain_weather/terrain_weather_init_effects_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (基础结构), C1状态效果系统 (StatusManager)
- Unlocks: 无
