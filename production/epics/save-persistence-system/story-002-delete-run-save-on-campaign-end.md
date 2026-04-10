# Story 002: 战役结束删除 Run Save

> **Epic**: 存档持久化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/save-persistence-system.md`
**Requirement**: `TR-save-persistence-system-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Save Serialization
**ADR Decision Summary**: 双JSON文件+原子写入，战役结束删除Run Save

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准 FileAccess API

**Control Manifest Rules (this layer)**:
- Required: 必须采用双JSON文件+原子写入模式
- Forbidden: 禁止使用Godot Resource序列化作为主要存档方式
- Guardrail: Run Save加载时间：< 5ms

---

## Acceptance Criteria

*From GDD `design/gdd/save-persistence-system.md`, scoped to this story:*

- [ ] 战役结束（胜利或死亡）后 Run Save 文件被删除

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- 在 `SaveManager` 中实现 `delete_run(hero_id: String) -> bool` 方法
- 该方法应调用 `DirAccess.remove()` 删除 `user://saves/run_{heroId}.json` 文件
- 在战役胜利（BOSS节点击败）和战役失败（HP归零）的事件处理器中调用 `delete_run()`
- 若删除失败（磁盘权限问题），记录到日志，不崩溃
- 下次启动时，检测到战役结束标志位（`campaignEnded: true`）的 Run Save，跳过"继续"选项

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: Run Save 自动写入与恢复
- [Story 003]: Meta Save 解锁与发现记录更新
- [Story 004]: Meta Save 通关与设置更新
- [Story 005]: 存档文件的原子写入与版本兼容

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 战役结束（胜利或死亡）后 Run Save 文件被删除
  - Given: 玩家正在进行曹操的战役，Run Save 文件存在
  - When: 玩家击败最终BOSS（胜利）或HP归零（死亡）
  - Then: 检查 `user://saves/` 目录，确认 `run_cao_cao.json` 文件不存在
  - Edge cases: 玩家在BOSS战最后一击时崩溃，重启后应回到BOSS战开始前状态，再次击败后删除存档

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save-persistence-system/delete-run-save_test.gd` — must exist and pass
- Integration: `tests/integration/save-persistence-system/delete-run-save_test.gd` OR playtest doc
- Visual/Feel: `production/qa/evidence/delete-run-save-evidence.md` + sign-off
- UI: `production/qa/evidence/delete-run-save-evidence.md` or interaction test
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001: Run Save 自动写入与恢复
- Unlocks: None
