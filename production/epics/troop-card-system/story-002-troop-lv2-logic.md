# Story 002: 高级兵种卡（Lv2）升级机制与效果

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (Lv2效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 提供 `CardTier(card)` 辅助判断，实现各兵种的高级复合逻辑。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 卡牌升级后必须保留原卡身份与标签。
- Required: 步兵的双击必须独立计算护甲。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 `CardTier` 判断逻辑 (upgradeCount == 1 为 Lv2)。
- [ ] 弓兵 Lv2: 遍历所有存活敌方，每人各受 7点 独立伤害计算。
- [ ] 步兵 Lv2: 对单一目标调用两次 `take_damage(6)`，两次独立扣减护甲。
- [ ] 骑兵 Lv2: 击退后，给目标施加 1层眩晕 (STUN)。
- [ ] 谋士 Lv2: 造成7点伤害，随机从当前定义的负面状态池中抽取1个，施加 1层。
- [ ] 盾兵 Lv2: 获得 8点护盾，外加施加 1层坚守 (DEFEND) 状态给玩家。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. `BattleManager` 中根据卡牌数据的 `upgradeCount` 走不同分支，或将 `lv2_damage`, `lv2_effect` 定义在数据结构里。
2. 步兵双击：
   ```gdscript
   enemy.take_damage(calc_damage(6, ...))
   if enemy.is_alive:
       enemy.take_damage(calc_damage(6, ...))
   ```
3. 谋士随机 Debuff：
   ```gdscript
   var pool = [POISON, FEAR, BLIND, SLIP, BROKEN, WEAK, BURN] # 排除强力如眩晕或按需求
   var rand_debuff = pool[randi() % pool.size()]
   StatusManager.apply_status(enemy, rand_debuff, 1)
   ```
4. 骑兵眩晕：在 `_execute_knockback` 之后调用 `StatusManager.apply_status(enemy, STUN, 1)`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Lv3 分支效果（Story 005, 006）。
- 地形联动附加影响（Story 003）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 步兵双击独立破甲
  - Given: 敌人护甲 = 4，HP = 10。
  - When: 步兵 Lv2 (6伤x2)
  - Then: 第一次打 6，破 4甲，掉 2HP。第二次打 6，掉 6HP。敌人剩余 2HP，护甲 0。

- **AC-2**: 弓兵全体伤害
  - Given: 场上 3名存活敌人。
  - When: 弓兵 Lv2
  - Then: 3 名敌人各自计算 7点 伤害。

- **AC-3**: 盾兵复合同步
  - Given: 玩家无状态
  - When: 盾兵 Lv2
  - Then: 玩家获得 8盾 和 1层坚守。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_lv2_logic_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 005
