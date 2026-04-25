# QA Plan: Sprint 7
**Date**: 2026-04-20
**Sprint**: Sprint 7（2026-05-22 ~ 2026-05-29）
**Stage**: Production
**Stories in scope**: 6（7-1, 7-2, 7-3, 7-4, 7-5, 7-7）
**Stories deferred**: 1（7-6 BattleScene.tscn — 推迟至战斗场景开发阶段）

---

## Scope

Sprint 7 核心目标：补齐 Sprint 6 遗留阻塞（C1 headless CI + C5 战役/酒馆持久化），并推进存档持久化系统核心（Run Save 写入/恢复/删除 + 原子写入 + 版本兼容）。

---

## Story Classification

| Story | ID | Type | 自动测试文件 | AC 数 | 手动 QA 需求 |
|-------|----|------|------------|------|------------|
| [C1] headless CI 实际运行 | 7-1 | Config/DevOps | 证明文件：`production/qa/evidence/sprint6-ci-run.md` | N/A | 需在 Godot 环境执行 headless runner 并补录结果 |
| [C5] 战役进度管理 | 7-2 | Integration | `tests/integration/map_system/campaign_management_test.gd`（9函数） | 4 | 无 |
| [C5] 酒馆状态持久化 | 7-3 | Integration | `tests/integration/inn_system/inn_persistence_test.gd`（9函数） | 3 | 无 |
| Run Save 写入与恢复 | 7-4 | Integration | `tests/integration/save-persistence-system/run_save_write_restore_test.gd`（7函数） | 4 | 无 |
| 战役结束删除 Run Save | 7-5 | Logic | `tests/unit/save-persistence-system/delete_run_save_test.gd`（6函数） | 1 | 无 |
| 存档原子写入与版本兼容 | 7-7 | Logic | `tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd`（11函数） | 4 | 无 |

**总计**：42 个自动化测试函数，16 个 AC，0 MISSING

---

## Automated Test Requirements

| 系统 | 测试文件 | 函数数 | 框架 | 运行命令 |
|------|---------|------|------|---------|
| map-system | `tests/integration/map_system/campaign_management_test.gd` | 9 | GdUnit4 | `godot --headless --script tests/gdunit4_runner.gd` |
| inn-system | `tests/integration/inn_system/inn_persistence_test.gd` | 9 | GdUnit4 | 同上 |
| save-persistence-system | `tests/integration/save-persistence-system/run_save_write_restore_test.gd` | 7 | GdUnit4 | 同上 |
| save-persistence-system | `tests/unit/save-persistence-system/delete_run_save_test.gd` | 6 | GdUnit4 | 同上 |
| save-persistence-system | `tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd` | 11 | GdUnit4 | 同上 |

---

## Manual QA Scope

### QA-S1：headless CI 执行（必须）

**执行环境**：需要 Godot 4.6.1 binary 在 PATH

```bash
godot --headless --script tests/gdunit4_runner.gd 2>&1
```

**验收标准**：
- 总测试函数数 ≥ 677（Sprint 6 基线）+ 42（Sprint 7 新增）= 719
- S1/S2 失败数 = 0
- 结果补录至 `production/qa/evidence/sprint6-ci-run.md`（或新建 sprint7 版本）

**条件通过协议**：若 CI 环境暂不可用，7-1 按条件通过处理，在下次有 Godot 环境时补录。

---

## Out of Scope

- **7-6 BattleScene.tscn**：推迟至战斗场景开发阶段，届时随战斗系统完整搭建一并验证
- **端到端存档集成**：7-4 + 7-7 当前使用桩注入，真实文件 I/O 路径端到端集成留 Sprint 8 补充
- **UI 手动验证（Sprint 6 C2）**：BattleScene.tscn 未搭建，UI 手动验证随 7-6 推迟
- **性能测试**：无完整游戏循环，性能测试推迟至游戏循环完整后进行

---

## Entry Criteria

- [x] 所有 Must Have stories 已通过 `/story-done`
- [x] Smoke check PASS WITH WARNINGS（`production/qa/smoke-2026-04-20.md`）
- [x] 无 MISSING 测试文件
- [x] 无 S1/S2 级别已知 Bug

---

## Exit Criteria

- [ ] 所有 6 个 in-scope stories 结果为 PASS 或 PASS WITH CONDITIONS
- [ ] QA-S1 headless CI 执行完成（或条件通过记录在案）
- [ ] 无新增 S1/S2 Bug
- [ ] QA sign-off 报告生成并写入 `production/qa/qa-signoff-sprint7-*.md`

---

## Advisory Items（不阻塞）

1. **B-1 条件阻塞**：headless CI 需在 Godot 4.6.1 环境执行。当前按条件通过处理，下次 CI 环境可用时补录实际结果。
2. **桩注入未升级**：7-4 / 7-7 的存档测试通过桩隔离，AtomicSaveWriter 真实 I/O 路径无端到端测试。建议 Sprint 8 补充。
