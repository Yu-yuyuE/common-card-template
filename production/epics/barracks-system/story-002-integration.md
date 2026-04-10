# Story 002: 军营流转与全局系统集成

> **Epic**: 军营系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/barracks-system.md`
**Requirement**: `TR-barracks-system-001`

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 管理卡组变更，通过事件和全局单例与其他系统通信。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 采用双层通信架构：全局使用EventBus和Signal
- Forbidden: 禁止系统间直接强引用

---

## Acceptance Criteria

- [ ] 提供接口：添加选定候选卡，卡牌实际加入当前武将专属卡组
- [ ] 提供接口：升级卡牌（Lv1->Lv2, Lv2->Lv3），消耗全局金币 50 并替换原卡
- [ ] 提供接口：移出任意卡牌，该卡从卡组移除
- [ ] 只有当玩家“离开军营”时，才将上述更改固化并触发存档

---

## Implementation Notes

扩充 `barracks_manager.gd`：
添加 `commit_add_card()`, `commit_upgrade_card()`, `commit_remove_card()`。
使用 `ResourceManager.modify_resource("gold", -50)` 执行扣费。
操作时保留内部暂存状态，提供 `save_and_exit()` 方法，此方法被调用时，才会真正通知 `GameState`/`SaveManager` 保存当前状态。如果在调用此方法前重置/重新进入，则恢复原始状态。

---

## Out of Scope

- 军营UI面板。
- 存档底层原子写入实现（已由 ADR-0005 覆盖）。

---

## QA Test Cases

- **AC-1**: 升级扣费
  - Given: 玩家拥有 100 金币，执行卡牌升级
  - When: 调用 commit_upgrade_card()
  - Then: 玩家剩余金币为 50，且旧卡被替换为新卡
  - Edge cases: 玩家拥有 49 金币，操作应被拒绝
- **AC-2**: 放弃操作
  - Given: 在军营中添加了一张卡
  - When: 不调用离开保存，直接重新加载场景
  - Then: 卡组未发生变化

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/barracks_system/barracks_integration_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: None