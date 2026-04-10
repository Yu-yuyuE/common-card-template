# Story 005: 存档文件的原子写入与版本兼容

> **Epic**: 存档持久化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/save-persistence-system.md`
**Requirement**: `TR-save-persistence-system-003, TR-save-persistence-system-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Save Serialization
**ADR Decision Summary**: 双JSON文件+原子写入，支持版本兼容性检查和迁移

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准 FileAccess API

**Control Manifest Rules (this layer)**:
- Required: 必须采用双JSON文件+原子写入模式
- Forbidden: 禁止使用Godot Resource序列化作为主要存档方式
- Guardrail: Run Save加载时间：< 5ms

---

## Acceptance Criteria

*From GDD `design/gdd/save-persistence-system.md`, scoped to this story:*

- [ ] 原子写入：写入时先写临时文件，成功后原子替换
- [ ] 版本兼容：minor 版本升级后旧存档可正常读取，缺失字段填默认值
- [ ] major 版本不兼容时提示玩家，旧 Run Save 被清除
- [ ] 存档文件损坏时显示友好提示，不崩溃

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- 在 `SaveManager.save_run()` 和 `SaveManager.save_meta()` 中，实现原子写入：
  - 将JSON数据写入临时文件（.tmp）
  - 使用 `DirAccess.rename()` 将临时文件重命名为最终文件名
  - 如果重命名失败，返回错误，保留原文件
- 在 `SaveManager._load_json()` 中，实现版本兼容性检查：
  - 读取存档的 `version` 字段
  - 比较其 major 版本号与当前 `CURRENT_VERSION`
  - 如果 major 版本不兼容，返回空字典，提示玩家
  - 如果 major 版本兼容，将缺失字段填充为默认值
- 在 `SaveManager._load_json()` 中，实现损坏处理：
  - 如果JSON解析失败，返回空字典，提示玩家
  - 对于 Run Save 损坏，提示"存档损坏，该武将战役进度无法恢复"
  - 对于 Meta Save 损坏，提示"元数据损坏，图鉴与解锁记录已重置"，创建默认Meta
- 所有文件操作必须检查 `FileAccess` 返回值，处理权限和磁盘空间不足错误

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: Run Save 自动写入与恢复
- [Story 002]: 战役结束删除 Run Save
- [Story 003]: Meta Save 解锁与发现记录更新
- [Story 004]: Meta Save 通关与设置更新

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 原子写入：写入时先写临时文件，成功后原子替换
  - Given: 一个正常的 Run Save
  - When: 调用 `save_run()`，并在 `rename()` 前模拟写入中断（删除临时文件）
  - Then: 原始文件未被修改，再次调用 `save_run()` 应能成功
  - Edge cases: 模拟磁盘空间不足，应返回错误，原文件不变

- **AC-2**: minor 版本升级后旧存档可正常读取，缺失字段填默认值
  - Given: 一个 v1.0.0 的存档（缺少 `pendingWeather` 字段）
  - When: 用 v1.1.0 游戏加载该存档
  - Then: 游戏正常启动，`pendingWeather` 字段值为 ""（默认值）
  - Edge cases: 存档包含 v1.0.0 的所有字段，无新增，应完全兼容

- **AC-3**: major 版本不兼容时提示玩家，旧 Run Save 被清除
  - Given: 一个 v1.0.0 的存档
  - When: 用 v2.0.0 游戏加载该存档
  - Then: 显示"存档版本不兼容，无法继续上次战役"，并删除该存档文件
  - Edge cases: 同时存在多个不兼容的存档，都应被删除

- **AC-4**: 存档文件损坏时显示友好提示，不崩溃
  - Given: 一个损坏的 Run Save 文件（内容为"invalid json")
  - When: 游戏启动并尝试加载该存档
  - Then: 显示"存档损坏，该武将战役进度无法恢复"，不崩溃，返回主菜单
  - Edge cases: 损坏的 Meta Save 文件，应显示"元数据损坏，图鉴与解锁记录已重置"

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save-persistence-system/save-atomic-write-version-compat_test.gd` — must exist and pass
- Integration: `tests/integration/save-persistence-system/save-atomic-write-version-compat_test.gd` OR playtest doc
- Visual/Feel: `production/qa/evidence/save-atomic-write-version-compat-evidence.md` + sign-off
- UI: `production/qa/evidence/save-atomic-write-version-compat-evidence.md` or interaction test
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 001, Story 003, Story 004
