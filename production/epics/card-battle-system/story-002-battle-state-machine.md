# Story 002: 战斗状态机与回合流程控制

Epic: 卡牌战斗系统
Estimate: 4 hours
Status: Done
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-005 (回合流程), TR-card-battle-system-011 (敌人回合)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: 卡牌战斗系统架构
**ADR Decision Summary**: 使用枚举 `BattlePhase` 和状态机变量，严格控制从玩家回合到敌人回合再到阶段检查的线性流动。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须实现完整的回合流程：玩家回合→敌人回合→阶段检查
- Forbidden: 禁止纯事件驱动难以追踪执行顺序

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md`, scoped to this story:*

- [x] 定义 `BattlePhase` 枚举: `PLAYER_START`, `PLAYER_DRAW`, `PLAYER_PLAY`, `PLAYER_END`, `ENEMY_TURN`, `PHASE_CHECK`
- [x] 实现 `_start_player_turn()`: 设置玩家阶段，触发回合开始事件
- [x] 实现 `end_player_turn()`: 玩家主动调用结束出牌，切换到 `PLAYER_END`，然后进入 `ENEMY_TURN`
- [x] 实现 `_start_enemy_turn()`: 遍历存活的敌人执行行动，结束后进入 `PHASE_CHECK`
- [x] 实现阶段检查逻辑：所有存活敌人HP检查，如果敌人未死，调用 `_start_player_turn()` 开启下一轮。
- [x] 发射 `turn_started(is_player)` 和 `phase_changed(phase)` 信号

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

1. 在 `BattleManager` 中添加 `current_phase` 和 `is_player_turn`。
2. 暂时 mock `_execute_enemy_action()`：如果敌人存活，仅发射一个测试用信号或打印日志，具体战斗逻辑交由后续系统(C3)补全。
3. 状态流转顺序必须硬编码在一个个函数末尾的调用中，不要依赖离散的事件触发机制，以保证顺序绝对可控。
4. 调用 `StatusManager.tick_status(player_entity)` 放置在 `PLAYER_END` 阶段。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 敌人AI的真正决策与行为（由 C3 敌人系统实现）。
- 玩家的抽牌行为（Story 003 实现）。
- 阶段全灭后的多阶段切换（Story 006 实现）。本故事中阶段检查如果全灭，暂只发射测试完成信号。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 状态机流转顺畅
  - Given: `BattleManager` 处于 `PLAYER_PLAY` 阶段
  - When: 外部调用 `end_player_turn()`
  - Then: `current_phase` 依次变为 `PLAYER_END`, 然后 `ENEMY_TURN`, 最后在敌人全不死的条件下回到 `PLAYER_START` (最后停留在 PLAYER_PLAY)。

- **AC-2**: 敌人跳过已死目标
  - Given: `ENEMY_TURN` 开始，敌人2(索引1)已死亡(HP<=0)
  - When: 遍历执行敌人回合
  - Then: 只有敌人1和敌人3触发了 mock 的 action，敌人2被跳过。

- **AC-3**: 信号通知
  - Given: 状态切换
  - When: `_start_player_turn` 被调用
  - Then: 发射 `phase_changed` 信号，值为 `PLAYER_START`。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle_system/battle_state_machine_test.gd` — must exist and pass

**Status**: [x] Implemented in BattleManager - tests in battle_state_machine_test.gd

---

## Dependencies

- Depends on: Story 001 (实体数据)
- Unlocks: Story 003 (可在适当阶段加入抽牌)
