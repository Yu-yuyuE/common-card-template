# QA 测试计划：Sprint 7（最终周期）

**生成日期**：2026-04-22
**Sprint**：Sprint 7
**QA Lead**：qa-lead
**周期说明**：本文档为 Sprint 7 最终 QA 周期（补充 2026-04-20 版本），覆盖 7-6、7-7、7-8 新增 story 以及 7-1 AC4 补录项。

---

## 一、范围

**Sprint 目标**：补齐 Sprint 6 遗留阻塞项（C1 headless CI + C5 战役/酒馆持久化），推进存档持久化系统核心。

**本周期新增 Story**：7-6、7-7、7-8（2026-04-20 后完成）
**延续 Story**：7-1（AC4 补录）、7-2 ~ 7-5（回归检查）

---

## 二、Story 分类表

| Story | 类型 | 自动测试路径 | 手动 QA | 优先级 |
|-------|------|------------|---------|--------|
| 7-1 [C1] headless CI | Config/Data | — | ⚠️ AC4 实际运行结果补录 | must-have |
| 7-2 CampaignManager | Integration | tests/integration/map_system/campaign_management_test.gd | 否 | must-have |
| 7-3 InnPersistenceManager | Integration | tests/integration/inn_system/inn_persistence_test.gd | 否 | must-have |
| 7-4 Run Save 写入与恢复 | Integration | tests/integration/save-persistence-system/run_save_write_restore_test.gd | 建议烟雾 #5/#6 | must-have |
| 7-5 删除 Run Save | Logic | tests/unit/save-persistence-system/delete_run_save_test.gd | 否 | must-have |
| 7-6 BattleScene.tscn | UI/Visual | — | ⚠️ 证明文档待填写 | should-have |
| 7-7 原子写入与版本兼容 | Logic | tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd | 否 | should-have |
| 7-8 Meta Save 解锁记录 | Logic | tests/unit/save-persistence-system/meta-save-unlock-discovery_test.gd | 否 | nice-to-have |

---

## 三、自动化测试要求

| 测试文件 | 函数数 | 覆盖 Story | 状态 |
|---------|--------|-----------|------|
| tests/integration/save-persistence-system/run_save_write_restore_test.gd | 7 | 7-4 AC1~AC4 | ✅ 存在 |
| tests/unit/save-persistence-system/delete_run_save_test.gd | 6 | 7-5 AC1 | ✅ 存在 |
| tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd | 11 | 7-7 AC1~AC4 | ✅ 存在 |
| tests/unit/save-persistence-system/meta-save-unlock-discovery_test.gd | 9 | 7-8 AC1~AC2 | ✅ 存在 |
| tests/integration/map_system/campaign_management_test.gd | 9 | 7-2 全部 AC | ✅ 存在 |
| tests/integration/inn_system/inn_persistence_test.gd | 9 | 7-3 全部 AC | ✅ 存在 |

**运行命令**：`godot --headless --script tests/gdunit4_runner.gd`

---

## 四、手动 QA 范围

### 4.1 BattleScene.tscn UI 验证（7-6）

**文档路径**：`production/qa/evidence/battle-scene-7-6-evidence.md`
**AC 清单**：
1. 手牌区 CardUI 正确实例化（数量、费用标签、名称标签）
2. 费用不足时手牌灰显（modulate.a ≈ 0.4，不可点击）
3. PhaseLabel 随 phase_changed 信号更新
4. 敌人 ProgressBar 随 damage_dealt 信号更新（clamp 到 0）

**截图要求**：每项 AC 附截图至 `production/qa/evidence/screenshots/`

### 4.2 7-1 AC4 CI 实际运行补录

**文档路径**：`production/qa/evidence/sprint6-ci-run.md`（追加实际输出至 AC4 章节）
**操作**：在有 Godot 4.6.1 的环境执行 headless runner，将完整输出（pass/fail 统计、总耗时）写入文档。

---

## 五、超出本周期范围

- 全端到端游戏流程测试（战役完整通关）— 延至集成测试阶段
- 多语言 UI 验证 — Localization Story 尚未启动
- 性能基准测试（存档 I/O < 5ms）— 由 CI 性能测试覆盖，本周期不主动测量

---

## 六、准入条件

- [x] Sprint 7 全部 Must Have 故事 status: done
- [x] 自动化测试文件存在（6 个测试文件，51 个函数）
- [x] 烟雾测试判断：PASS WITH WARNINGS（无 FAIL）
- [ ] 7-1 AC4 实际运行输出（P1 优先行动）
- [ ] 7-6 手动验证文档填写（P1 优先行动）

---

## 七、退出条件

- 所有 Must Have story 测试结果为 PASS 或 PASS WITH NOTES
- S1/S2 Bug 数量为 0
- 7-6 手动验证文档完成（或标记为 DEFERRED 并记录为条件项）
- 7-1 AC4 有结果记录（或标记为 DEFERRED）
