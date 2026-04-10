# Story 003: 兵种地形天气联动执行

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-002 (兵种卡地形×天气联动)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 地形修正和天气修正在卡牌打出时从 TerrainWeatherSystem 获取并动态应用于基础伤害/费用。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 伤害修正计算必须遵循 `基础×地形×天气×状态` 的管道。
- Required: 骑兵卡在沙漠地形必须获得费用 -1（最低为0）。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 调用 `TerrainWeatherManager.get_terrain_modifier()` 应用于所有兵种卡的基础伤害计算。
- [ ] 骑兵在平原获得 x1.5，山地 x0.5 加成/惩罚（向下取整，至少为1）。
- [ ] 骑兵卡打出时，通过 `TerrainWeatherManager.get_cavalry_cost_modifier()` 动态计算其当前费用（仅沙漠-1）。
- [ ] 弓兵在雨天或雾天（若因盲目）有伤害/命中衰减，这里确保 ADR-0014 的管线接收到此影响。
- [ ] 特殊卡牌"直击"（穿透）和兵种的基础伤害应合并入管线。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `play_card` 验证费用前，使用 `var actual_cost = max(0, card.cost + TerrainWeatherManager.get_cavalry_cost_modifier())` 进行可用性验证。
2. 传递给 `DamageCalculator` 时，将地形、天气参数传入。
3. 本故事将原先在 C2 卡牌战斗系统写死的 mock 取值替换为真实的 `TerrainWeatherManager` 调用。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 扩展分支卡牌特有的免疫地形惩罚（如铁甲重骑免疫关隘），将在 Story 005 处理。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 骑兵地形伤害
  - Given: 战场处于平原（PLAIN）地形，玩家有一张 Lv1 骑兵卡（5基础伤害）。
  - When: 玩家打出该卡。
  - Then: 获取到 1.5 的修正，最终造成 `int(5 * 1.5) = 7` 点伤害。

- **AC-2**: 骑兵沙漠费用减免
  - Given: 战场处于沙漠（DESERT）地形，玩家只有 0 点 AP。有一张 Lv1 骑兵卡（原1费）。
  - When: 试图打出骑兵卡。
  - Then: 费用验证通过，成功打出且扣除 0 点 AP。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_terrain_interaction_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: D1 地形天气系统, Story 001
- Unlocks: 无
