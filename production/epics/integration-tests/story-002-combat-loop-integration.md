# Story 002: C2+C3 战斗循环集成测试

> **Epic**: 集成测试
> **Status**: Backlog
> **Layer**: Integration
> **Type**: Integration
> **Manifest Version**: 2026-04-11

## Context

**GDD**: `design/gdd/card-battle-system.md` 和 `design/gdd/enemies-design.md`
**Requirement**: TR-card-battle-system-003, TR-enemies-design-007

**ADR Governing Implementation**: ADR-0007 (卡牌战斗系统) 和 ADR-0015 (敌人AI行动序列)

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须验证完整的玩家-敌人回合循环
- Required: 必须验证敌人AI响应玩家行动的逻辑
- Required: 必须验证状态效果在战斗循环中的持续影响

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md` 和 `design/gdd/enemies-design.md`，跨系统整合：*

- [ ] 玩家出牌后，敌人AI必须根据当前战场状态选择正确的行动
- [ ] 敌人行动必须正确应用到玩家或敌人实体上（修改HP、护盾、行动点等）
- [ ] 状态效果（如Poison）必须在每个敌人回合前结算
- [ ] 敌人相变（如HP<40%）必须在回合开始时被正确检测和触发
- [ ] 战斗结束（全灭敌人）必须正确触发 `battle_victory` 信号

---

## Implementation Notes

*Derived from ADR-0007 and ADR-0015 Implementation Guidelines:*

1. 在 `BattleManager.gd` 中模拟玩家出牌（调用 `play_card()`）
2. 观察 `enemy_turn_manager.execute_enemy_turn()` 是否触发正确的敌人行动
3. 验证 `enemy_action_mock_triggered` 信号是否携带正确的敌人ID和行动类型
4. 在敌人行动执行后，检查 `ResourceManager` 的资源变化是否正确
5. 验证 `status_applied` 和 `status_removed` 信号是否在正确时机触发
6. 模拟敌人血量低于40%时，验证其行动序列是否被替换

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 卡牌效果的具体实现（Story 004-005）
- 敌人具体行动的实现（Story 002-003）
- UI显示敌人行动（Story 006）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Integration stories — test spec]:**

- **AC-1**: 玩家出牌 → 敌人响应
  - Given: 战场中有一个敌人（ID="E001"），敌人行动序列是 ["A01", "A02"]
  - When: 玩家打出一张攻击卡，目标为该敌人
  - Then: 敌人AI执行 "A01"（普通攻击），并触发 `enemy_action_mock_triggered("E001", "A01")`
  - Then: 敌人HP减少，玩家HP不变（假设A01是普通攻击）

- **AC-2**: 敌人相变触发
  - Given: 敌人E044（复仇将领）初始HP=100，行动序列=["A01","A01","A03"]，相变条件=HP<40%
  - When: 玩家连续攻击两次，使其HP降至35
  - Then: 在下一个敌人回合开始时，行动序列被替换为 ["B01","C01","B14","C12"]
  - Then: `enemy_action_mock_triggered` 信号显示新序列的第一项 "B01"

- **AC-3**: 状态效果在战斗循环中持续
  - Given: 玩家被施加了 `POISON`（层数=3，每层伤害=4）
  - When: 玩家出牌并结束回合
  - Then: 敌人回合开始前，玩家HP被扣除12点
  - Then: `status_applied` 信号被触发（显示Poison持续）

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/combat_loop_integration_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (F2+C1 资源与状态联动), Story 001 (卡牌战斗系统), Story 004 (敌人AI与行动执行)
- Unlocks: 战斗系统整体验收
