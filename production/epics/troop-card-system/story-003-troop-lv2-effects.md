# Story 003: 兵种卡升级(Lv2)与附加机制

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (兵种卡效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014
**ADR Decision Summary**: 为 Lv2 兵种增加额外的多次攻击、群体攻击和特殊状态施加逻辑。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 步兵Lv2双击必须是两次独立的伤害结算
- Required: 各种状态施加必须正确调用 C1 状态系统

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] **弓兵 Lv2**：修改为对 **所有敌方目标** 各造成 7 点伤害。
- [ ] **步兵 Lv2**：修改为对目标造成 **两次独立的 6 点伤害**（护甲独立扣除）。
- [ ] **骑兵 Lv2**：保留 5 点伤害和击退，额外向目标施加 **1 层眩晕**（STUN）。
- [ ] **谋士 Lv2**：保留 7 点伤害，额外向目标施加 **1 层随机 Debuff**（从当前所有 Debuff 枚举中随机抽取）。
- [ ] **盾兵 Lv2**：保留 8 点护盾，额外向我方施加 **1 层坚守**（DEFEND）。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `_resolve_troop` 中增加判断：
   ```gdscript
   if get_troop_tier(card_data) >= 2: # 执行 Lv2 逻辑
   ```
2. 步兵双击：调用两次完整的 `take_damage` 管道流程。如果第一次打死，第二下自动跳过（或根据 Edge Case 判断"不溢出到其他敌将"）。
3. 弓兵群攻：遍历 `enemy_entities`，对每个存活的敌将执行伤害。
4. 随机 Debuff：准备一个预设的可用 Debuff 类别列表 `[POISON, WEAK, BLIND...]` 排除消耗型，每次 `randi() % list.size()`。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Lv3 分支卡（36种）的具体特效代码。本系统首先建立机制框架以保证五大基础类的1/2级可玩，剩余的在后续内容扩展时处理或由其他工具批量生成。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 步兵双击独立计算护甲
  - Given: 敌人 HP=20, 护甲=4。打出步兵 Lv2 (2段 6点)
  - When: 结算
  - Then: 第一次 6-4=2 点伤害（护甲耗尽）。第二次完整 6点。敌人 HP 剩余 20 - 8 = 12。

- **AC-2**: 弓兵群攻
  - Given: 场上 3 个敌人
  - When: 打出弓兵 Lv2
  - Then: 每个敌人都经历一次受击管道，受到 7 基础值的伤害计算。

- **AC-3**: 状态附加
  - Given: 玩家打出骑兵 Lv2，盾兵 Lv2。
  - When: 结算
  - Then: 目标被推到后排且获得眩晕；玩家获得 8 点护盾和 1 层坚守。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_cards/troop_lv2_effects_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (基础特效), C1 (状态系统接口)
- Unlocks: 无
