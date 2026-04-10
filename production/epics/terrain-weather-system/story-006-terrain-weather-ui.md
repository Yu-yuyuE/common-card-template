# Story 006: 地形天气UI标识与提示

> **Epic**: 地形天气系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/terrain-weather-system.md`
**Requirement**: 战场UI显示环境标签 (Player Fantasy 读图博弈感)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: 地形天气系统架构
**ADR Decision Summary**: 地形固定但需在入场时显示，天气动态变化时通过信号驱动UI同步更新。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须能在 UI 上直观反映当前地形和天气，以便玩家进行决策。

---

## Acceptance Criteria

*From GDD `design/gdd/terrain-weather-system.md`, scoped to this story:*

- [ ] 战斗主界面（HUD右上角或顶部）包含地形和天气的显示组件（如 `Label` 和 `TextureRect`）。
- [ ] 游戏启动战斗时（`setup_battle` 调用后），UI正确显示传入的地形和天气。
- [ ] UI 监听 `TerrainWeatherManager.weather_changed` 信号，在天气动态切换时，更新图标/文字，并可选播放简单的闪烁或颜色变换动画以提示玩家。

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

1. 在 `BattleHUD` 或独立 `EnvironmentUI.gd` 脚本中连接信号：
   ```gdscript
   TerrainWeatherManager.weather_changed.connect(_on_weather_changed)
   ```
2. 需要调用本地化系统(Localization) 获取对应枚举的显示名称：
   ```gdscript
   var text = LocalizationManager.get_text("terrain." + str(terrain_enum))
   ```
3. 这个故事仅实现 UI 组件的连通，美术资产由后续填充。可以用占位图标替代。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 下雨、下雪等全屏视觉粒子特效（VFX）。此故事仅限顶部环境标签图标和文字的变更。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 初始显示
  - Setup: 进入配置为"关隘"和"雾天"的战斗。
  - Verify: 顶部UI对应显示关隘和雾天图标及文字。
  - Pass condition: 信息与底层状态同步，且显示了正确的本地化文本。

- **AC-2**: 动态切换更新
  - Setup: 使用卡牌将天气由"雾天"改为"晴天"。
  - Verify: UI上的天气图标和文字立即变更为"晴天"，无重启要求。
  - Pass condition: 用户能立刻注意到天气的转变。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/terrain-weather-ui-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 005
- Unlocks: 无
