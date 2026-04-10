# Story 002: 战斗引擎集成与Lv2效果加载

> **Epic**: 卡牌升级系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-10

## Context

**GDD**: `design/gdd/card-upgrade-system.md`
**Requirement**: `TR-card-upgrade-001`

**ADR Governing Implementation**: ADR-0007: Card Battle System
**ADR Decision Summary**: 升级后卡牌效果验证

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 战斗初始化时正确加载Lv2效果
- Required: 保证卡牌的Lv2数据应用后在战斗中正确结算伤害和状态

---

## Acceptance Criteria

- [ ] 战斗初始化：根据 `CardUpgradeRecord`，战斗内生成的卡牌实体若已升级，则其效果数值加载为Lv2数据
- [ ] 规则约束检查：核心代码或工具脚本中提供检验机制，以确保配置表符合"单维度提升"和"取消移除不加数值"原则
- [ ] 战斗结算：升级卡牌在战斗内能够正确打出Lv2效果（如伤害提升、状态层数+1等）

---

## Implementation Notes

修改或扩展卡牌战斗加载逻辑（如卡牌实例化部分）。
进入战斗构建手牌/牌库时，查询 `card_upgrade_manager` 判断该卡牌实例是否在升级记录中。
如果是，修改 `card.level = 2` 并加载对应的 CSV Lv2 列数据（如 `Lv2Power`），替换基础数值。

---

## Out of Scope

- 商店系统升级交互UI。
- 升级费用的扣除逻辑（由商店处理）。

---

## QA Test Cases

- **AC-1**: 战斗初始化应用Lv2
  - Given: 战役记录中某弓兵卡实例已被升级为Lv2
  - When: 进入战斗，生成手牌并抽到该卡
  - Then: 该卡的卡面数值和内部数据属性均匹配Lv2的配置
- **AC-2**: Lv2效果战斗使用结算
  - Given: 手持一张Lv2卡牌
  - When: 对敌人打出该卡
  - Then: 敌人实际受到的伤害和状态影响（如击退+眩晕）符合Lv2的设定数据

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/card_upgrade_system/battle_integration_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
