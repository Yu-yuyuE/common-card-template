# Story 002: 高级兵种卡（Lv2）升级机制与效果

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 提供基于卡牌当前 `upgradeCount` 判断层级的方法，并在 `_resolve_troop` 中处理增强的范围、多段攻击、附加状态等。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须根据 `upgradeCount` 处理不同的卡牌效果（Lv1/Lv2）。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 弓兵 Lv2: 范围从单体变为**所有敌方目标**各造成 7 点伤害（独立扣除每个人的护盾）。
- [ ] 步兵 Lv2: 对单体造成 **6点伤害，攻击两次**。确保每次独立计算敌人的护甲扣除。
- [ ] 骑兵 Lv2: 造成 5 点伤害，击退，并附加 **1层眩晕**。
- [ ] 谋士 Lv2: 造成 7 点伤害，并施加 **1个随机Debuff** (从合法Debuff池中随机抽取1种施加1层)。
- [ ] 盾兵 Lv2: 获得 8 点护盾，附加 **1层坚守**。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `BattleManager._resolve_troop` 中判断 `card_data.upgrade_count == 1`：
2. 步兵双击：使用一个两次迭代的循环 `for i in 2: enemy.take_damage(6)`。
3. 弓兵群攻：遍历 `enemy_entities` 数组，对每个活着的敌人 `take_damage(7)`。
4. 谋士随机Debuff：创建一个允许被随机的 `Debuff` 常量数组（不含强力Debuff如眩晕等，除非有特殊设计，这里根据GDD"合法Debuff池"即可），然后 `StatusManager.apply_status(enemy, random_debuff, 1)`。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体铁匠铺如何触发升级（属于军营/铁匠铺节点系统）。此处只认 `upgrade_count` 字段。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 弓兵Lv2群攻
  - Given: 战场有3名存活敌人，手牌有一张Lv2弓兵卡
  - When: 打出卡牌（目标任意）
  - Then: 3名敌人都分别失去 7 点血/盾。

- **AC-2**: 步兵Lv2双击破甲
  - Given: 敌人有 4 点护盾。手牌有一张Lv2步兵卡（2次6点伤害）。
  - When: 打出卡牌。
  - Then: 第一次攻击破盾剩 2 伤害（HP-2），第二次攻击直扣 HP 6 点。总计 HP 减少 8。

- **AC-3**: 盾兵Lv2坚守
  - Given: 玩家无状态，手牌有Lv2盾兵卡
  - When: 打出卡牌
  - Then: 玩家获得 8 点护盾并增加 1 层 `DEFEND` 状态。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/advanced_troop_logic_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
