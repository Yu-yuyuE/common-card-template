# Story 003: Meta Save 解锁与发现记录更新

> **Epic**: 存档持久化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/save-persistence-system.md`
**Requirement**: `TR-save-persistence-system-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Save Serialization
**ADR Decision Summary**: 双JSON文件+原子写入，Meta Save 永久保留

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准 FileAccess API

**Control Manifest Rules (this layer)**:
- Required: 必须采用双JSON文件+原子写入模式
- Forbidden: 禁止使用Godot Resource序列化作为主要存档方式
- Guardrail: Meta Save加载时间：< 3ms

---

## Acceptance Criteria

*From GDD `design/gdd/save-persistence-system.md`, scoped to this story:*

- [ ] Meta Save 在首次解锁新卡牌时立即更新
- [ ] 图鉴发现记录（discoveredEvents/discoveredEquipment）在战役失败后保留

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- 在 `CardUnlockSystem` 中，当玩家首次解锁一张新卡牌时，调用 `SaveManager.save_meta()` 更新 `unlockedCards` 列表
- 在 `EventSystem` 中，当玩家首次遇到一个新事件时，调用 `SaveManager.save_meta()` 更新 `discoveredEvents` 列表
- 在 `EquipmentSystem` 中，当玩家首次获得一件新装备时，调用 `SaveManager.save_meta()` 更新 `unlockedEquipment` 列表
- 所有更新都使用原子写入（临时文件+重命名）
- 确保这些事件在战役失败后依然被记录

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: Run Save 自动写入与恢复
- [Story 002]: 战役结束删除 Run Save
- [Story 004]: Meta Save 通关与设置更新
- [Story 005]: 存档文件的原子写入与版本兼容

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: Meta Save 在首次解锁新卡牌时立即更新
  - Given: 玩家尚未解锁卡牌 AC0001
  - When: 玩家通过奇遇事件获得 AC0001
  - Then: 检查 `meta.json` 文件，确认 `unlockedCards.attack` 列表中包含 "AC0001"
  - Edge cases: 同一卡牌在不同战役中多次获得，只应记录一次

- **AC-2**: 图鉴发现记录在战役失败后保留
  - Given: 玩家在战役中首次遇到事件 EV010
  - When: 玩家在该战役中失败
  - Then: 检查 `meta.json` 文件，确认 `discoveredEvents` 列表中包含 "EV010"
  - Edge cases: 玩家在战役中多次遇到同一事件，只应记录一次

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save-persistence-system/meta-save-unlock-discovery_test.gd` — must exist and pass
- Integration: `tests/integration/save-persistence-system/meta-save-unlock-discovery_test.gd` OR playtest doc
- Visual/Feel: `production/qa/evidence/meta-save-unlock-discovery-evidence.md` + sign-off
- UI: `production/qa/evidence/meta-save-unlock-discovery-evidence.md` or interaction test
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005: 存档文件的原子写入与版本兼容
- Unlocks: None
