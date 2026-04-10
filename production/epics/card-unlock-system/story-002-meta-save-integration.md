# Story 002: 解锁状态与Meta Save集成

> **Epic**: 卡牌解锁系统
> **Status**: Ready
> **Layer**: Meta
> **Type**: Integration
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/cards-design.md`
**Requirement**: `TR-cards-design-001`

**ADR Governing Implementation**: ADR-0005: Save Serialization
**ADR Decision Summary**: 双 JSON 文件 + 原子写入；Meta Save 负责记录 `unlockedCards` 永久数据。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 实现 Meta Save (永久)，文件为 `user://saves/meta.json`
- Required: 必须支持版本兼容性检查

---

## Acceptance Criteria

- [ ] `CardUnlockManager` 启动时，自动调用 `SaveManager.load_meta()` 将 `unlockedCards` 数据同步至内存
- [ ] 当卡牌状态变更为“已解锁”时，通知或直接调用 `SaveManager.save_meta()` 写入硬盘
- [ ] 确保存档字段 `unlockedCards: { attack: [], skill: [], troop: [], curse: [] }` 能够被正确解析和还原

---

## Implementation Notes

整合 `CardUnlockManager` 和 `SaveManager`。
增加 `unlock_card(card_id: String)` 方法，方法内更新字典后，调用持久化写入。

---

## Out of Scope

- “何时”调用解锁（通关结算），见 Story 003。

---

## QA Test Cases

- **AC-1**: Meta Save 读取测试
  - Given: 一个写有 `AC0099` 已解锁的 `meta.json` 文件
  - When: `CardUnlockManager` 初始化
  - Then: `is_card_unlocked("AC0099")` 必须为 `true`
- **AC-2**: Meta Save 写入集成
  - Given: `AC0099` 初始为未解锁
  - When: 调用 `unlock_card("AC0099")`
  - Then: `SaveManager` 被触发，文件内出现 `AC0099`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/card_unlock/meta_save_integration_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, ADR-0005 `SaveManager` 基础功能
- Unlocks: None