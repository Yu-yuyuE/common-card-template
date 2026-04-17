# Story 002: 军营流转与全局系统集成

> **Epic**: 军营系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/barracks-system.md`
**Requirement**: `TR-barracks-system-001`
**GDD Sections Referenced**: §F1（Lv1→Lv2 升级费用 50 金）、§F2（Lv2→Lv3 升级费用 50 金）、§E12（中途退出不保存，离开军营时写存档）、§4（添加/升级/移出全部操作规则）

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 管理卡组变更，通过事件和全局单例与其他系统通信。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 纯逻辑层，无 post-cutoff API 依赖。

**Control Manifest Rules (this layer)**:
- Required: 采用双层通信架构：全局使用 EventBus 和 Signal
- Forbidden: 禁止系统间直接强引用

---

## Acceptance Criteria

- [ ] 添加卡牌：`commit_add_card(card_id)` 将候选卡加入暂存卡组；若当前兵种卡数量 >= 统帅值（由调用方传入），返回失败
- [ ] 升级卡牌（Lv1→Lv2）：`commit_upgrade_card(card_id, current_gold)` 扣除 50 金，将原卡替换为 Lv2 版本，返回 `{success, gold_spent, new_card_id}`；金币不足（< 50）时返回失败
- [ ] 移出卡牌：`commit_remove_card(card_id)` 从暂存卡组移除指定卡，返回成功/失败
- [ ] 暂存保护：在 `save_and_exit()` 调用前，`get_pending_deck()` 与初始卡组快照不同；调用 `reset_pending()` 后，`get_pending_deck()` 恢复为初始快照（模拟中途离开不保存）

---

## Implementation Notes

扩充 `src/core/barracks-system/BarracksManager.gd`，新增集成层接口：
- `initialize_session(initial_deck: Array[String])` — 进入军营时传入当前卡组快照，存为内部暂存
- `commit_add_card(card_id: String, current_troop_count: int, leadership: int) -> Dictionary`
- `commit_upgrade_card(card_id: String, current_gold: int) -> Dictionary`（返回 {success, gold_spent, new_card_id, reason}）
- `commit_remove_card(card_id: String) -> Dictionary`
- `get_pending_deck() -> Array[String]`
- `save_and_exit() -> Array[String]`（返回最终卡组，调用方执行实际持久化）
- `reset_pending()` — 回滚到初始快照

关键约束（对齐 GDD §F1/§F2/§E12）：
- 升级费用常量 `UPGRADE_COST_LV1_TO_LV2 = 50`，`UPGRADE_COST_LV2_TO_LV3 = 50`
- 暂存状态保持在实例内存中，不主动调用 ResourceManager（金币扣除量由返回值通知调用方执行）
- `reset_pending()` 应完整恢复到 `initialize_session()` 时的快照

---

## Out of Scope

- 军营 UI 面板
- 存档底层原子写入实现（已由 ADR-0005 覆盖）
- Lv2→Lv3 分支选择逻辑（需要 troop_cards.csv 数据，属于 story-003）
- ResourceManager 金币实际扣减（调用方根据返回 gold_spent 执行）

---

## QA Test Cases

- **AC-1**: 升级扣费
  - Given: 初始卡组含 `troop_001_lv1`，金币 100
  - When: 调用 `commit_upgrade_card("troop_001_lv1", 100)`
  - Then: 返回 success=true, gold_spent=50, new_card_id="troop_001_lv2"；`get_pending_deck()` 中原卡不存在，新卡存在
  - Edge cases: 金币 = 49 时返回 success=false, reason="INSUFFICIENT_GOLD"
- **AC-2**: 统帅限制阻止添加
  - Given: current_troop_count=3, leadership=3
  - When: `commit_add_card("troop_002_lv1", 3, 3)`
  - Then: 返回 success=false, reason="LEADERSHIP_CAP"
- **AC-3**: 暂存保护
  - Given: 初始卡组 ["card_a", "card_b"]，添加 "troop_001_lv1"
  - When: 调用 `reset_pending()`
  - Then: `get_pending_deck()` == ["card_a", "card_b"]（恢复初始）

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/barracks_system/barracks_integration_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（Status: Complete ✅）
- Unlocks: None

---

## Estimate

**0.5 天**

## Completion Notes
**Completed**: 2026-04-17
**Criteria**: 4/4 passing
**Deviations**: None — UPGRADE_COST=50 与 GDD §F1/§F2 完全对齐，零单例依赖
**Test Evidence**: Integration — `tests/integration/barracks_system/barracks_integration_test.gd`（13 个测试函数，覆盖 AC1~AC4）
**Code Review**: Skipped — Lean mode