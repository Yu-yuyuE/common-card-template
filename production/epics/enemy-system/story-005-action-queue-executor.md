# Story 005: 敌人AI行动队列执行器

> **Epic**: 敌人系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-13

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-010 (行动队列), TR-enemies-design-011 (敌人行动间隔)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: 敌人AI行动序列执行器
**ADR Decision Summary**: 提供 `EnemyActionQueue` 节点，接受要执行的行动列表，然后按照设定的时间间隔 (0.5~1.0秒) 逐步执行。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 涉及协程/计时器 `await get_tree().create_timer(interval).timeout`。

**Control Manifest Rules (this layer)**:
- Required: 敌人行动之间必须有视觉间隔，不能瞬间全部算完。
- Required: 敌人执行前必须验证自己是否存活，目标是否存活。

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `EnemyActionQueue`，包含 `add_action(enemy_id, action_data)` 接口。
- [ ] 实现 `execute_all(interval: float)`，使用异步等待，在每个行动之间暂停一段时间。
- [ ] 执行前二次校验：如果执行者已经死亡，直接跳过当前行动继续下一个。
- [ ] 执行行动时调用实际的效果派发器（Story 006 的 `execute_action()`）。
- [ ] 队列执行完毕后，发射 `all_actions_completed` 信号，告知 BattleManager 推进到阶段检查。

---

## Implementation Notes

*Derived from ADR-0015 Implementation Guidelines:*

1. 在 `EnemyTurnManager` 内部装配此队列。
2. `ENEMY_TURN` 开始时，遍历所有存活敌人，从序列获取他们要做的 action 加入队列。
3. 开启 `execute_all(0.8)` 协程。
4. 每一步执行前：
   ```gdscript
   var enemy = EnemyManager.get_enemy(action.source_enemy_id)
   if not enemy.is_alive or enemy.current_hp <= 0:
       continue # 等待时间可略过或保持
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体行动造成什么数值效果（由 Story 006 实现）。
- UI 显示。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 间隔执行不堵塞
  - Given: 队列中有 3 个行动
  - When: 调用 `execute_all(0.5)`
  - Then: 整个方法应该花费大约 1.5 秒完成，并依次触发 3 次单个动作完成信号，最后触发全部完成信号。

- **AC-2**: 死亡跳过
  - Given: 队列里有敌人 A 和 B 的动作。但在 A 执行时产生的联动效果导致 B 死亡。
  - When: 轮到 B 的动作执行时。
  - Then: B 的动作直接跳过，不产生任何战斗效果。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/action_queue_executor_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: Story 006
