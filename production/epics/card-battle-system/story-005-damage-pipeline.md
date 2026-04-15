# Story 005: 伤害计算管线

Epic: 卡牌战斗系统
Estimate: 4 hours
Status: Complete
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-007 (伤害计算), TR-card-battle-system-010 (伤害公式)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 伤害计算必须遵循：基础伤害×地形系数×天气系数×状态系数。护盾优先吸收，溢出扣除HP。无视护甲直接扣HP。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 计算过程必须为分步乘法累计模式。
- Required: 伤害必须采用护盾优先，溢出扣HP的公式。最终伤害最小值必须为1。

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md`, scoped to this story:*

- [ ] 实现 `DamageCalculator` 类或在 BattleManager 中实现分步伤害管道。
- [ ] 公式：`最终伤害 = max(1, round(BaseDamage × TerrainMod × WeatherMod × BuffMod × DebuffMod))`
- [ ] 实现 `take_damage(damage, penetrate)` 在 `BattleEntity` 中：
  - 如果 `penetrate == true`，跳过护盾直接扣除 HP。
  - 如果 `penetrate == false`，护盾优先抵挡，剩余值扣除 HP。
- [ ] 如果 HP <= 0，确保不再出现负数。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `BattleEntity.take_damage()`:
   ```gdscript
   func take_damage(damage: int, penetrate_shield: bool = false) -> int:
       var actual = damage
       if not penetrate_shield and shield > 0:
           var blocked = min(shield, damage)
           shield -= blocked
           actual -= blocked
       if actual > 0:
           current_hp = max(0, current_hp - actual)
       return actual
   ```
2. 基础的地形、天气、状态系数获取可以进行 Mock 返回 1.0（具体的地形天气实现由地形天气Epic负责，此处只需预留调用接口并跑通乘法公式）。
3. `_resolve_attack` (在 Story 004 创建的框架里) 填入此管线的调用，并调用敌人的 `take_damage`，然后发射 `damage_dealt` 信号。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 地形天气系数的具体常数表配置（交由 TerrainWeatherSystem Epic）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 护盾优先抵挡
  - Given: 敌人 HP=20, Shield=10
  - When: 受到 15 点正常伤害
  - Then: 敌人 Shield=0, HP=15。返回实际造成的最终穿透伤害 5。

- **AC-2**: 无视护甲直接扣HP
  - Given: 敌人 HP=20, Shield=10
  - When: 受到 15 点无视护甲伤害 (penetrate=true)
  - Then: 敌人 Shield=10 (不变), HP=5。

- **AC-3**: 伤害分步计算
  - Given: 基础伤害=10, 假设Mock地形系数=1.5, 天气=1.0, 状态=1.0
  - When: 管道计算
  - Then: 最终伤害 = 15。

- **AC-4**: 保底伤害
  - Given: 经过所有减免后计算结果为 0
  - When: 取 max(1, round(dmg))
  - Then: 最终伤害为 1。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle_system/damage_pipeline_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (结算框架)
- Unlocks: 无
