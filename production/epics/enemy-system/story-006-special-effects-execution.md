# Story 006: 诅咒投递与特殊效果执行

> **Epic**: 敌人系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-008 (诅咒投递), 及各类A/B/C具体行动效果的路由派发。
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008, ADR-0015
**ADR Decision Summary**: 提供最终执行层 `_execute_attack`, `_execute_buff`, `_execute_curse`。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 行动必须支持各种不同的投递位置(手牌、抽牌堆顶、随机等)。
- Forbidden: 诅咒卡数量不受约束导致系统死循环。

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `execute_action()` 的分类路由 (`match type: attack/buff/debuff/curse/special`)。
- [ ] 攻击类：调用 `BattleManager.player_entity.take_damage(dmg, penetrate)`（考虑嘲讽、混乱目标改变等边角逻辑：如果处于混乱，目标转向友军）。
- [ ] Buff/Debuff类：调用 `StatusManager.apply_status()`。
- [ ] 诅咒投递类：解析配置，向 `BattleManager` 的对应卡组区域（`hand_cards`, `draw_pile`，根据投递方式 `hand`, `draw_top`, `draw_random`, `discard`）中加入对应 `curse_id`。
- [ ] 召唤类：从预设池实例化新敌人加入 `enemy_entities` 数组（满3人自动跳过）。
- [ ] 偷取金币/手牌类：扣除玩家对应资源；如果是偷手牌，记录下被偷的卡ID，以便该敌人死后归还。

---

## Implementation Notes

*Derived from ADR-0015 Implementation Guidelines:*

1. 需要持有 `BattleManager` 的引用来进行资源变更。
2. 随机向卡组插入：
   ```gdscript
   var idx = randi() % (draw_pile.size() + 1)
   draw_pile.insert(idx, curse_id)
   ```
3. 混乱目标判定：如果在 `_execute_attack` 时发现自己处于 CONFUSION 状态，则更改 target 为同伴，并减少自己1层 CONFUSION。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体诅咒卡牌抽到时的行为（诅咒系统处理）。
- 卡组区域的基础定义（已在战斗系统 Story 003 实现）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 混乱攻击友军
  - Given: 敌人1处于混乱状态。
  - When: 执行攻击指令(目标原为玩家)。
  - Then: 选择其他敌人(如敌人2)作为目标，调用它的 `take_damage`，不伤害玩家。

- **AC-2**: 诅咒卡投递
  - Given: 执行投递阴险诅咒到抽牌堆随机位置的指令。
  - When: `execute_action()` 运行后。
  - Then: 玩家的 `draw_pile` 大小增加 1，包含指定的诅咒卡ID。

- **AC-3**: 召唤满场跳过
  - Given: 战场已有 3 名敌人。
  - When: 敌人执行召唤指令。
  - Then: 直接跳过，不报错，不增加第4名敌人。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/special_effects_execution_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005 (执行器入口), BattleManager, StatusManager
- Unlocks: 无
