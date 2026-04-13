# Story 004: 兵种卡地形天气联动

Epic: 兵种卡系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-002 (地形×天气联动)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 通过向 `DamageCalculator` 提供兵种分类标签，并调用 `TerrainWeatherManager` 进行乘数累积，处理特定的卡牌联动（如沙漠减费）。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 兵种卡在打出时必须查询D1获取地形/天气修正系数
- Required: 对于具有特殊文本覆盖（如雪地三卡免疫惩罚）的卡牌，必须跳过通用惩罚。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] **沙漠骑兵卡费用修正**：`CardBattleSystem` 在获取手牌可打出状态时，查询 `TerrainWeatherManager.get_cavalry_cost_modifier()`。如果环境是沙漠且卡牌类型是 `CAVALRY`，计算时的有效 cost 减 1（最低为 0）。
- [ ] **骑兵平原/山地修正**：已在 D1 中实现了修正系数，此处确保 C2 调用 `DamageCalculator.calculate_damage()` 时，将卡牌的 `troop_category` ("cavalry", "archer"等) 准确传入。
- [ ] **特殊联动卡覆盖**：对于卡牌带有类似 `ignore_terrain_penalty` 或特殊直击的（如铁甲重骑在关隘免疫伤害-50%），当 `base_type == "iron_cavalry"` 且地形是 `PASS` 时，改写/覆盖传入的 TerrainMod 为 1.0。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 修改或拦截费用查询：
   ```gdscript
   func get_effective_cost(card_data: CardData) -> int:
       var cost = card_data.cost
       if card_data.base_type == "cavalry":
           cost += TerrainWeatherManager.get_cavalry_cost_modifier()
       return max(0, cost)
   ```
2. 伤害计算覆盖（在 `_resolve_troop` 或卡牌效果执行前）：
   ```gdscript
   var terrain_mod = TerrainWeatherManager.get_terrain_modifier(card_data.base_type)
   # 特殊卡免疫惩罚
   if card_data.id == "iron_cavalry" and TerrainWeatherManager.current_terrain == Terrain.PASS:
       terrain_mod = 1.0
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 地形和天气的直接定义（由 D1 Epic 负责）。
- 风天引燃扩散（D1 每回合结算时负责）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 沙漠减费
  - Given: `current_terrain` = DESERT。手里有1张 1费 的普通骑兵卡。
  - When: `get_effective_cost()`
  - Then: 费用显示并消耗 0。

- **AC-2**: 铁甲重骑关隘免疫
  - Given: `current_terrain` = PASS。打出 "铁甲重骑"。
  - When: 执行伤害结算
  - Then: `terrain_mod` 为 1.0，不受到普通骑兵的 0.5 惩罚。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_cards/troop_terrain_interaction_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: D1 (TerrainWeatherManager), C2 (DamageCalculator)
- Unlocks: 无
