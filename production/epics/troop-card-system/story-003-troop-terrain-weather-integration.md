# Story 003: 兵种地形天气联动执行

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-002 (地形×天气联动)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 集成 `TerrainWeatherManager` 的修正结果，在出牌框架里执行。特别是动态的费用变化。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 出牌时实时判断当前地形天气并进行费用和伤害的乘算。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 调用 `TerrainWeatherManager.get_cavalry_cost_modifier()`，如果是沙漠，骑兵卡的实际 `cost` 下降 1 (最低为0)。UI上应当也能获取此值渲染。
- [ ] 如果是雾天，对于弓兵类（包含谋士远程），由于受到盲目（BLIND）影响（D1在初始化时加了状态），这里无需特制计算，但要验证状态管理系统能正确响应。此处补充：雨天时，灼烧效果的额外削弱（D1已做），确保弓兵类在雨天的某些负面（如 ×0.5，GDD指引：天气修正对弓兵雨天为 ×0.5）。
- [ ] 调用 `DamageCalculator` 时正确传入当前地形和天气名称。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `play_card()` 的费用检查阶段：
   ```gdscript
   var final_cost = card.cost
   if card.troop_type == "cavalry":
       final_cost = max(0, card.cost + TerrainWeatherManager.get_cavalry_cost_modifier())
   if player.action_points < final_cost: return false
   ```
2. 注意 GDD 中：弓兵在雨天伤害 ×0.5。需要在 `DamageCalculator.gd` 的 `WEATHER_MODIFIERS` 里面加上 `rain: {"archer": 0.5}` 的规则（并调用）。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 地形初始附带的中毒、滑倒（D1 地形天气系统负责）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 沙漠减费
  - Given: `current_terrain` = DESERT
  - When: 准备打出 1 费骑兵卡
  - Then: 检查发现仅需消耗 0 费，玩家AP从 3 变为 3。

- **AC-2**: 弓兵雨天衰减
  - Given: `current_weather` = RAIN
  - When: 打出 1 费弓兵卡 (7伤)
  - Then: DamageCalculator 乘以 0.5，返回 3.5 取整为 4 点伤害。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_terrain_weather_integration_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: D1 地形系统, C2 战斗系统
- Unlocks: 无
