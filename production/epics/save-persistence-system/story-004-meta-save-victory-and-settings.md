# Story 004: Meta Save 通关与设置更新

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

- [ ] 武将通关后 completedCampaigns 正确追加战役章节 ID
- [ ] 设置修改（音量）立即写入 Meta Save，重启后保持

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- 在 `HeroSystem` 中，当武将完成一个战役（胜利）时，调用 `SaveManager.save_meta()` 更新 `heroRecords[heroId].completedCampaigns` 列表
- 在 `HeroSystem` 中，当武将战役失败时，调用 `SaveManager.save_meta()` 更新 `heroRecords[heroId].totalRuns` 计数
- 在 `HeroSystem` 中，当武将首次通关时，更新 `heroRecords[heroId].totalWins` 计数
- 在 `LocalizationManager` 中，当玩家修改语言设置时，调用 `SaveManager.save_meta()` 更新 `settings.language`
- 在 `AudioManager` 中，当玩家修改主音量、音乐音量或音效音量时，调用 `SaveManager.save_meta()` 更新 `settings.masterVolume`, `settings.musicVolume`, `settings.sfxVolume`
- 所有更新都使用原子写入（临时文件+重命名）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: Run Save 自动写入与恢复
- [Story 002]: 战役结束删除 Run Save
- [Story 003]: Meta Save 解锁与发现记录更新
- [Story 005]: 存档文件的原子写入与版本兼容

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 武将通关后 completedCampaigns 正确追加战役章节 ID
  - Given: 玩家正在进行曹操的战役，已通关"魏-第一章"
  - When: 玩家击败"魏-第二章"的BOSS
  - Then: 检查 `meta.json` 文件，确认 `heroRecords["cao_cao"].completedCampaigns` 包含 "wei_2"
  - Edge cases: 玩家在同一个战役章节多次失败后成功，只应记录一次

- **AC-2**: 设置修改（音量）立即写入 Meta Save，重启后保持
  - Given: 玩家将主音量从 0.8 调整为 0.5
  - When: 玩家关闭游戏，然后重新启动
  - Then: 重启后，主音量为 0.5
  - Edge cases: 玩家在修改音量后立即强制退出，重启后音量应为修改后的值

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save-persistence-system/meta-save-victory-settings_test.gd` — must exist and pass
- Integration: `tests/integration/save-persistence-system/meta-save-victory-settings_test.gd` OR playtest doc
- Visual/Feel: `production/qa/evidence/meta-save-victory-settings-evidence.md` + sign-off
- UI: `production/qa/evidence/meta-save-victory-settings-evidence.md` or interaction test
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005: 存档文件的原子写入与版本兼容
- Unlocks: None
