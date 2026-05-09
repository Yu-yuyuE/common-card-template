# Sprint 8 — 2026-04-28 到 2026-05-04

## Sprint Goal

完成端到端战役流程的初步整合（战斗 ↔ 地图 ↔ 存档），补齐 Sprint 7 遗留 QA 差距（G1-G4），建立 Polish 阶段质量基线。

## Capacity

- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 小时（按 8h/天计算）

---

## Must Have（关键路径）

| ID | 故事 | 文件 | 归属 | 估算 | 依赖 |
|----|------|------|------|------|------|
| 8-1 | **G2: CI 构建日志正式化** — 在具备 Godot binary 的环境实际执行 headless 测试，保存构建日志至 sprint8-ci-run.md | `production/qa/evidence/sprint8-ci-run.md` | devops-engineer | 0.5d | — |
| 8-2 | **G3: SaveManager 端到端集成** — 将 RunSaveManager 和 AtomicSaveWriter 的 save_stub 替换为真实 SaveManager 调用，补写联通集成测试 | `production/epics/save-persistence-system/story-001-run-save-write-and-restore.md`（追加集成）| gameplay-programmer | 1.0d | — |
| 8-3 | **G4: Smoke 关键路径更新** — 更新 tests/smoke/critical-paths.md，纳入存档、酒馆、地图、战役进度系统；同时修正 7-9 酒馆测试路径字段 | `tests/smoke/critical-paths.md` | qa-tester | 0.3d | 8-1 |
| 8-4 | **Meta Save 胜利与设置** — 实现通关记录和全局设置持久化，完成双层存档系统闭环 | `production/epics/save-persistence-system/story-004-meta-save-victory-and-settings.md` | gameplay-programmer | 0.5d | 8-2 |

**Must Have 小计：2.3d**

---

## Should Have

| ID | 故事 | 文件 | 归属 | 估算 | 依赖 |
|----|------|------|------|------|------|
| 8-5 | **资源管理 UI 绑定** — 将 HP/护甲/行动点/粮草连接到战斗 HUD | `production/epics/resource-management-system/story-007-resource-ui-binding.md` | ui-programmer | 1.0d | — |
| 8-6 | **资源系统集成测试** — F2 × C2 端到端集成，验证战斗中资源正确变化 | `production/epics/resource-management-system/story-008-resource-system-integration.md` | gameplay-programmer | 0.5d | 8-5 |
| 8-7 | **heal-shield 修正器** — 回血/护盾修正系数实现，补全状态效果系统 | `production/epics/status-effects-system/story-008-heal-shield-modifier.md` | gameplay-programmer | 0.5d | — |

**Should Have 小计：2.0d**

---

## Nice to Have

| ID | 故事 | 文件 | 归属 | 估算 | 依赖 |
|----|------|------|------|------|------|
| 8-8 | **G1: 证明文件补录** — 在 Godot 编辑器内完成 battle-scene-7-6-evidence.md 手动验证并签字 | `production/qa/evidence/battle-scene-7-6-evidence.md` | qa-tester | 0.2d | — |
| 8-9 | **性能基线** — 运行 /perf-profile 建立 Polish 阶段帧时间和内存基线 | `tests/performance/` | performance-analyst | 0.3d | 8-6 |

**Nice to Have 小计：0.5d**

---

## Carryover from Sprint 7

| 任务 | 原因 | 处理方式 |
|------|------|----------|
| 7-9 [C3] 酒馆测试路径修正 | 优先级低，不影响功能 | 合并进 8-3（0.1d） |

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| save_stub 替换引入回归 | 中 | 高 | 8-2 写全量集成测试再替换，保留原 unit test 接口不变 |
| Godot PATH 仍未配置（G2 阻塞） | 中 | 中 | 用 CI 环境备选；若本地无法运行，记录用户口头确认并待 CI 环境补录 |
| resource UI 绑定依赖 BattleScene 节点结构 | 低 | 中 | BattleScene.tscn 已有完整骨架（Sprint 7 完成），风险低 |
| Polish 阶段范围膨胀 | 低 | 中 | Sprint 8 聚焦存档闭环 + 质量基线，功能扩展推迟到 Sprint 9 |

---

## External Dependencies

- **Godot binary in PATH**: 8-1 (CI 构建日志) 需要本地或 CI 环境配置 Godot 4.6.1
- **BattleScene.tscn**: 8-5 资源 UI 绑定依赖 Sprint 7 已完成的 HeroZone/APZone 节点

---

## Definition of Done

- [ ] 所有 Must Have 故事通过 `/story-done`
- [ ] G2：有可追溯的 CI/本地构建日志（sprint8-ci-run.md）
- [ ] G3：RunSaveManager 端到端测试通过（非 save_stub 版本）
- [ ] G4：tests/smoke/critical-paths.md 已更新并涵盖所有新系统
- [ ] 所有 Logic/Integration 故事有对应的通过测试文件
- [ ] 烟雾测试通过（`/smoke-check sprint`）
- [ ] QA 签字报告：APPROVED 或 APPROVED WITH CONDITIONS（`/team-qa sprint`）
- [ ] 无 S1/S2 级 Bug
- [ ] `production/sprint-status.yaml` 所有完成故事更新为 done

---

> **Note**: Sprint 8 是 Polish 阶段的第一个 Sprint。核心使命是将存档系统从"有桩测试"升级到"真实联通"，同时打通资源管理与 HUD 的视觉反馈，为后续 Sprint 的完整可玩性测试奠定基础。G1-G4 遗留差距是本 Sprint 的优先清偿项。
