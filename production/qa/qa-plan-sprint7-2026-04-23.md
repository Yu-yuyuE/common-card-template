# QA 测试计划 — Sprint 7

**日期**：2026-04-23
**范围**：Sprint 7（7-1 至 7-8，共 8 个故事）
**阶段**：Production
**QA Lead**：qa-lead 子智能体（/team-qa sprint）

---

## 范围

- **Sprint**：Sprint 7
- **故事数量**：8
- **日期**：2026-04-23
- **烟雾测试基准**：`production/qa/smoke-2026-04-20.md`（PASS WITH WARNINGS）

---

## 故事分类表

| 故事 ID | 标题 | 类型 | 自动化测试必须 | 手动 QA 必须 | 阻塞？ |
|---------|------|------|:---:|:---:|:---:|
| 7-1 | [C1] headless CI 实际运行 | Config/DevOps | ❌ | ✅ CI 环境验证 | ⚠️ WARN |
| 7-2 | [C5] 战役进度管理 | Integration | ✅ | ❌ | 无 |
| 7-3 | [C5] 酒馆状态持久化 | Integration | ✅ | ❌ | 无 |
| 7-4 | Run Save 写入与恢复 | Integration | ✅ | ❌ | 无 |
| 7-5 | 战役结束删除 Run Save | Logic | ✅ | ❌ | 无 |
| 7-6 | [C2] BattleScene.tscn 搭建与 UI 验证 | UI/Visual | ❌ | ✅（未完成） | 🔴 BLOCKED |
| 7-7 | 存档原子写入与版本兼容 | Logic | ✅ | ❌ | 无 |
| 7-8 | Meta Save 解锁记录 | Logic | ✅ | ❌ | 无 |

---

## 自动化测试要求

| 故事 ID | 测试文件路径 | 测试函数数量 | 类型 |
|---------|------------|:---:|------|
| 7-2 | `tests/integration/map_system/campaign_management_test.gd` | 9 | Integration |
| 7-3 | `tests/integration/inn_system/inn_persistence_test.gd` | 9 | Integration |
| 7-4 | `tests/integration/save-persistence-system/run_save_write_restore_test.gd` | 7 | Integration |
| 7-5 | `tests/unit/save-persistence-system/delete_run_save_test.gd` | 6 | Logic |
| 7-7 | `tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd` | 11 | Logic |
| 7-8 | `tests/unit/save-persistence-system/meta-save-unlock-discovery_test.gd` | 9 | Logic |

**总计**：6 个自动化测试文件，51 个测试函数

---

## 手动 QA 范围

| 故事 ID | 验证内容 | 预估工时 | 状态 |
|---------|---------|---------|------|
| 7-1 | CI 证明文件状态确认（补录真实运行结果） | 2–4h | ⚠️ 推迟至 CI 环境可用 |
| 7-6 | BattleScene.tscn 4 个 AC 手动步行 + 截图 + 签字 | 1–2h | 🔴 BLOCKED（证明文件全部 Pending） |

---

## 范围外（本次 QA 周期不覆盖）

- **7-9**：酒馆测试路径修正（文档更新任务，非功能性，Sprint 关闭时随手处理）
- **headless CI 实际执行结果**：需 Godot binary 在 PATH 的 CI 环境，当前不可用；计划 Sprint 8 第 1 周前完成
- **7-4 × 7-7 生产接线端到端验证**：save_stub → 真实 SaveManager 替换后的端到端联通测试，计划 Sprint 8 集成阶段
- **BattleScene.tscn 功能性交互测试**：场景搭建后方可执行，计划 Sprint 8

---

## 进入标准

- [x] 所有 Must Have 故事通过 `/story-done`（7-1 ～ 7-5）
- [x] Should Have 故事通过 `/story-done`（7-6、7-7）
- [x] Nice to Have 故事通过 `/story-done`（7-8）
- [x] 最新烟雾测试：PASS WITH WARNINGS（`smoke-2026-04-20.md`）
- [ ] 7-6 手动验证文档已填写（**🔴 BLOCKED — 已跳过，记录差距**）

---

## 退出标准

- [ ] 6 个 Logic/Integration 故事测试文件存在并已确认
- [ ] 7-1 证明文件内容已确认（结果补录待 CI 环境）
- [ ] 7-6 标记为 BLOCKED，差距记录在签字报告
- [ ] 手动 QA 结果汇总完成
- [ ] QA 签字报告写入 `production/qa/qa-signoff-sprint7-2026-04-23.md`
- [ ] 无 S1/S2 级 Bug

---

## 已知开放差距（写入签字报告）

| # | 差距描述 | 影响级别 | 计划解决时间 |
|---|---------|---------|------------|
| G1 | 7-6 BattleScene.tscn 手动验证文档全部 Pending，零证据 | 🔴 高（C2 条件未满足） | Sprint 8 开始前（Godot 编辑器验证） |
| G2 | headless CI（677 + 51 测试函数）从未实际运行，无真实通过记录 | ⚠️ 中（C1 条件未满足） | Sprint 8 第 1 周（CI 环境配置） |
| G3 | 7-4 × 7-7 save_stub 桩未替换为真实 SaveManager 端到端验证 | ⚠️ 中 | Sprint 8 集成阶段 |
| G4 | `tests/smoke/critical-paths.md` 烟雾路径未更新（核心机制仍为占位符） | ℹ️ 低 | Sprint 8 内部 |

---

> 本计划由 `/team-qa sprint` 自动生成（2026-04-23）。
