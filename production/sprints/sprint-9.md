# Sprint 9 — 2026-05-05 到 2026-05-11

## Sprint Goal

解决 Polish → Release gate check 的 5 个阻塞项，建立发布准备度基线，为重新 gate-check 创造条件。

## Capacity

- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 小时（按 8h/天计算）

---

## Must Have（解除 Gate Blocker）

| ID | 故事 | 文件 | 归属 | 估算 | 依赖 |
|----|------|------|------|------|------|
| 9-1 | **Localization 外部化** — 运行 `/localize`，抽取 src/ 中所有硬编码玩家文本到翻译文件（zh/en/ja），确保无硬编码字符串残留在代码中 | `src/core/LocalizationManager.gd` + 翻译文件 | godot-gdscript-specialist | 1.5d | — |
| 9-2 | **性能基线** — 运行 `/perf-profile`，测量战斗帧时间/内存/存档加载，写入 `tests/performance/baseline-sprint9.md`，验证在预算内（60fps/16.6ms/512MB） | `tests/performance/baseline-sprint9.md` | performance-analyst | 0.5d | — |
| 9-3 | **Accessibility 定义** — 创建 `design/accessibility-requirements.md`，定义无障碍层级（至少 Basic） | `design/accessibility-requirements.md` | ux-designer | 0.3d | — |
| 9-4 | **CI Headless 验证** — 配置 GdUnit4 headless runner，实际运行测试套件，结果补录到 `production/qa/evidence/sprint9-ci-run.md` | `production/qa/evidence/sprint9-ci-run.md` | devops-engineer | 1.0d | — |
| 9-5 | **Release Checklist** — 运行 `/release-checklist`，生成发布检查清单，关键项确认 | `production/release-checklist.md` | release-manager | 0.3d | 9-2 |

**Must Have 小计：3.6d**

---

## Should Have

| ID | 故事 | 文件 | 归属 | 估算 | 依赖 |
|----|------|------|------|------|------|
| 9-6 | **Difficulty Curve 文档** — 创建 `design/difficulty-curve.md`，定义前 3 场战役难度递进目标和测量方法 | `design/difficulty-curve.md` | game-designer | 0.5d | — |
| 9-7 | **8-5 AC-3 离散图标补齐** — 实现 AP 离散图标显示（每点一格），补全 ResourceHUD 的 AP 区域 | `src/ui/ResourceHUD.gd` | ui-programmer | 0.5d | — |
| 9-8 | **8-8 G1 证明文件补录** — battle-scene-7-6-evidence.md 18 项手动验证并签字 | `production/qa/evidence/battle-scene-7-6-evidence.md` | qa-tester | 0.3d | — |

**Should Have 小计：1.3d**

---

## Nice to Have

| ID | 故事 | 文件 | 归属 | 估算 | 依赖 |
|----|------|------|------|------|------|
| 9-9 | **Changelog 起草** — 运行 `/changelog` 生成变更日志 | `production/changelog.md` | producer | 0.2d | — |
| 9-10 | **Playtest #4** — 第 4 次结构化 playtest，验证难度曲线和核心循环 | `production/playtests/playtest-04.md` | qa-tester | 0.5d | 9-6 |

**Nice to Have 小计：0.7d**

---

## Carryover from Sprint 8

| 任务 | 原因 | 处理方式 |
|------|------|----------|
| 8-8 G1 证明文件补录 | Nice to Have 未开始 | 合并入 9-8 |
| 8-9 性能基线 | Nice to Have 未开始 | 合并入 9-2（升级为 Must Have） |

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Localization 外部化工作量大 | 中 | 高 | 先用 `/localize` 扫描；优先 UI 层；内部逻辑文本可标记为"下一迭代" |
| CI 环境无法配置 Godot binary | 中 | 高 | 本地 runner 备选；或使用 Docker Godot 镜像 |
| 性能基线不达标 | 低 | 高 | 先测量再优化；超标项记录并规划优化 |
| Accessibility 层级决策耗时 | 低 | 低 | 选择 Basic 层级即可满足 gate 要求 |

---

## External Dependencies

- **Godot binary in PATH 或 CI 环境**: 9-4 需要本地或 CI 环境配置 Godot 4.6.1
- **翻译内容审校**: 9-1 抽取后需审校 zh/en/ja 翻译质量（可延后至 Release 前）

---

## Definition of Done

- [ ] 所有 Must Have 故事通过 `/story-done`
- [ ] Localization：无硬编码玩家文本在 src/ 中
- [ ] 性能：基线数据存在且在预算内
- [ ] Accessibility：`design/accessibility-requirements.md` 存在且层级已定义
- [ ] CI：headless runner 实际运行且 734+ 测试全绿
- [ ] Release checklist 存在且关键项已确认
- [ ] 所有 Logic/Integration 故事有对应的通过测试文件
- [ ] 烟雾测试通过（`/smoke-check sprint`）
- [ ] QA 签字报告：APPROVED 或 APPROVED WITH CONDITIONS（`/team-qa sprint`）
- [ ] 无 S1/S2 级 Bug
- [ ] `production/sprint-status.yaml` 所有完成故事更新为 done

---

> **Note**: Sprint 9 的核心使命是关闭 gate-check 的 5 个 Blocker，使项目具备重新运行 `/gate-check` 并通过的条件。完成 Must Have 后即可重新验证 Polish → Release 跃迁。
