# Story 006: 多阶段战斗与胜负判定

> **Epic**: 卡牌战斗系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-008 (多阶段战斗)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: 卡牌战斗系统架构
**ADR Decision Summary**: 在 `_check_phase()` 中判断是否全灭敌人，若满足阶段切换条件，保留玩家手牌/HP，重置AP/清零护盾，加载新敌人。全阶段通关即判定胜利。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 战斗阶段切换时：玩家手牌全部保留；护盾清零；行动点重置为基础值。
- Required: 玩家死亡直接判定失败。所有阶段完成判定胜利。

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md`, scoped to this story:*

- [ ] 在 `PHASE_CHECK` 状态下检查存活敌人。
- [ ] 如果当前阶段所有敌人死亡（HP<=0），且当前阶段 < 总阶段数，触发 `_start_next_stage()`。
- [ ] 阶段切换时：清空玩家护盾，重置玩家行动点（满）。手牌、卡组不重置。
- [ ] 发射带当前进度提示的 `battle_started`（或 `stage_changed`）信号，用于UI提示"阶段 2"。
- [ ] 如果是最后阶段全灭，判定胜利；如果是玩家 HP<=0，判定失败。调用 `_end_battle(victory)`。
- [ ] 胜利结算时：`removed_cards` 中所有卡牌回归 `draw_pile`。

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

1. 在 `_check_phase()` 增加判定：
   ```gdscript
   var all_dead = true
   for e in enemy_entities:
       if e.current_hp > 0: all_dead = false
   ```
2. `_start_next_stage()` 需要从暂存的 stage_config 里获取下一波敌人配置，实例化并覆盖 `enemy_entities` 数组。
3. `_end_battle()`：胜利的话执行 `draw_pile.append_array(removed_cards)`；最后发射 `battle_ended(victory, rewards)`。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体掉落奖励池的随机生成（通常由专门的 LootManager 处理，这里只发出携带胜利状态的信号）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 阶段切换资源继承
  - Given: 一场 2 阶段战斗。阶段 1 玩家手牌 3张，护盾 10，AP 1。敌人被消灭。
  - When: 触发阶段检查进入阶段 2。
  - Then: 玩家手牌 3张（保留），护盾 0（清零），AP 回满。新敌人生成。

- **AC-2**: 玩家死亡判定
  - Given: 敌人回合结束，玩家 HP = 0。
  - When: 触发阶段检查。
  - Then: 触发 `_end_battle(false)`，战斗失败。

- **AC-3**: 移除区回归
  - Given: 玩家打出过 2 张 "使用后移除" 的卡，`removed_cards` 有 2 个元素。
  - When: 最终阶段胜利，触发 `_end_battle(true)`
  - Then: `removed_cards` 清空，元素回到 `draw_pile`。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle_system/multi_phase_battle_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (状态机基础)
- Unlocks: 无
