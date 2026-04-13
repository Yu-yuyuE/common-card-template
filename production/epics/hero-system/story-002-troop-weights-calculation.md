# Story 002: 兵种倾向与出现权重算法

Epic: 武将系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/heroes-design.md`
**Requirement**: TR-heroes-design-008 (兵种倾向)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 提供 `get_troop_weights(hero_id)` 供军营节点抽取兵种卡时使用。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须实现兵种倾向权重计算get_troop_weights(hero_id)。

---

## Acceptance Criteria

*From GDD `design/gdd/heroes-design.md`, scoped to this story:*

- [ ] 实现 `get_troop_weights(hero_id: String) -> Dictionary`。
- [ ] 返回的字典包含 5 个兵种类型（步兵/骑兵/弓兵/谋士/盾兵）的浮点数权重。
- [ ] 基准权重 = 1.0（即非倾向兵种为 0.5）。
- [ ] 如果兵种属于该武将的 `primary_troops`（主修，最多2项），权重为 2.0。
- [ ] 如果兵种属于该武将的 `secondary_troop`（次修，1项），权重为 1.0 (原基准1.0由于被定义为"非倾向0.5"，GDD F3 明确：次修为1.0，主修为2.0，非倾向为0.5。我们需要严格遵守 GDD 的数值定义)。
- [ ] 计算逻辑稳定，不存在某个枚举没被赋值的情况。

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

1. 在 `HeroManager.gd` 中：
   ```gdscript
   func get_troop_weights(hero_id: String) -> Dictionary:
       var weights = {
           TroopType.INFANTRY: 0.5,
           TroopType.CAVALRY: 0.5,
           TroopType.ARCHER: 0.5,
           TroopType.STRATEGIST: 0.5,
           TroopType.SHIELD: 0.5
       }
       # 覆盖对应项目
       var hero = get_hero(hero_id)
       weights[hero.secondary_troop] = 1.0
       for t in hero.primary_troops:
           weights[t] = 2.0
       return weights
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 军营节点实际利用这组权重做加权随机抽取（交由具体的军营/地图系统 Epic）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 曹操倾向权重验证
  - Given: `cao_cao` 主修 步/骑，次修 谋。
  - When: 调用 `get_troop_weights("cao_cao")`
  - Then: 返回 `{INFANTRY: 2.0, CAVALRY: 2.0, STRATEGIST: 1.0, ARCHER: 0.5, SHIELD: 0.5}`。

- **AC-2**: 不存在武将处理
  - Given: `invalid_hero` ID
  - When: 调用 `get_troop_weights("invalid_hero")`
  - Then: 返回一个安全的空字典 `{}` 或所有值默认 `1.0`（建议返回空字典由调用方处理或统一返回1.0）。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/hero_system/troop_weights_calculation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
