# Sprint 7 — 2026-05-22 to 2026-05-29

## Sprint Goal

补齐 Sprint 6 遗留阻塞项（C1 headless CI + C5 战役/酒馆持久化），推进存档持久化系统核心，为战役流程的完整持久化奠定基础。

## Capacity

- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 hours（按 8h/天计算）

---

## Must Have（关键路径）

| ID | 故事 | 文件 | 归属 | 估算 | 阻塞 |
|----|------|------|------|------|------|
| 7-1 | **[C1] headless CI 实际运行** — 配置 GdUnit4 headless 环境，运行全部 ~100 个测试函数并记录结果 | `production/qa/evidence/sprint6-ci-run.md` | devops-engineer | 1.0d | — |
| 7-2 | **[C5] 战役进度管理** — CampaignManager 实现，含 5战役×3地图结构、Boss 完成信号、Run Save 集成（桩接口版） | `production/epics/map-node-system/story-004-campaign-management.md` | gameplay-programmer | 0.5d | — |
| 7-3 | **[C5] 酒馆状态持久化** — InnPersistenceManager + InnSaveData 序列化，保存/恢复每个节点访问状态 | `production/epics/inn-system/story-002-inn-persistence.md` | gameplay-programmer | 0.5d | — |
| 7-4 | **Run Save 写入与恢复** — SaveManager 实现双层 JSON 存档，Run Save 自动写入与加载恢复 | `production/epics/save-persistence-system/story-001-run-save-write-and-restore.md` | gameplay-programmer | 1.0d | 7-2, 7-3 |
| 7-5 | **战役结束删除 Run Save** — 战役结束时原子清除 Run Save，保存 Meta Save 更新 | `production/epics/save-persistence-system/story-002-delete-run-save-on-campaign-end.md` | gameplay-programmer | 0.5d | 7-4 |

**Must Have 小计：3.5d**

---

## Should Have

| ID | 故事 | 文件 | 归属 | 估算 | 阻塞 |
|----|------|------|------|------|------|
| 7-6 | **[C2] BattleScene.tscn 搭建** — 创建战斗场景骨架，手动验证 6-7/6-8 UI 绑定（补签 5-14/5-15 UI 证明） | `src/ui/battle/BattleScene.tscn` | ui-programmer | 1.5d | — |
| 7-7 | **存档原子写入与版本兼容** — 临时文件+重命名写入，版本号检查与空数据默认迁移 | `production/epics/save-persistence-system/story-005-save-atomic-write-and-version-compat.md` | gameplay-programmer | 0.5d | 7-4 |

**Should Have 小计：2.0d**

---

## Nice to Have

| ID | 故事 | 文件 | 归属 | 估算 | 阻塞 |
|----|------|------|------|------|------|
| 7-8 | **Meta Save 解锁记录** — 图鉴解锁与发现记录写入 Meta Save，支持重载恢复 | `production/epics/save-persistence-system/story-003-meta-save-unlock-and-discovery.md` | gameplay-programmer | 0.5d | 7-4 |
| 7-9 | **[C3] 酒馆测试路径修正** — 更新 story-001-inn-services.md 测试证明路径字段（当前显示"not yet created"） | `production/epics/inn-system/story-001-inn-services.md` | gameplay-programmer | 0.1d | — |

**Nice to Have 小计：0.6d**

---

## Sprint 6 遗留条件状态

| 条件 | 类型 | 解决 Story | 目标周 |
|------|------|-----------|--------|
| C1: headless CI 实际运行 | 🚫 阻塞 | 7-1 | 第 1 周 |
| C5: 6-9 战役进度管理完成 | 🚫 阻塞 | 7-2 | 第 1 周 |
| C5: 6-10 酒馆状态持久化完成 | 🚫 阻塞 | 7-3 | 第 1 周 |
| C2: BattleScene.tscn 手动 UI 验证 | ⚠️ 非阻塞 | 7-6 | 第 2 周 |
| C4: MapNode layer 字段显式化 | ⚠️ 非阻塞 | 技术债务 backlog | — |

---

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| headless GdUnit4 环境配置复杂 | 中 | 高 | 优先在 Sprint 第 1 天完成；参考 `tests/gdunit4_runner.gd` 已有脚手架 |
| SaveManager 接口依赖尚未定义 | 中 | 中 | 7-2/7-3 使用桩接口先行，7-4 再接真实 SaveManager |
| BattleScene.tscn 手动验证耗时 | 低 | 低 | 列为 Should Have；不影响 Must Have 关闭 |

---

## 外部依赖

- **GdUnit4 headless runner**: `tests/gdunit4_runner.gd`（已有脚手架，需配置 CI 命令）
- **ADR-0005**: Save Serialization（7-4/7-5 的架构依据）
- **存档 GDD**: `design/gdd/save-persistence-system.md`

---

## Sprint 完成定义（DoD）

- [ ] 所有 Must Have 故事通过 `/story-done`
- [ ] C1：headless 测试实际运行结果记录在 `production/qa/evidence/sprint6-ci-run.md`
- [ ] C5：7-2 + 7-3 均有通过的单元测试（Logic/Integration 类型，BLOCKING）
- [ ] 7-4 + 7-5 有通过的集成测试
- [ ] 烟雾测试通过 `production/qa/smoke-2026-05-29.md`
- [ ] QA 签字报告：APPROVED 或 APPROVED WITH CONDITIONS（`/team-qa sprint`）
- [ ] 无 S1/S2 级别 Bug
- [ ] `production/sprint-status.yaml` 所有完成故事更新为 `done`

---

> **Note**: Sprint 7 的核心使命是清除两个 Sprint 6 遗留阻塞条件（C1 + C5），并将存档系统推进到"可保存/可恢复的战役流程"状态。C1 完成后，项目将首次拥有真实通过的 headless CI 记录，标志着 Production 阶段质量门槛正式建立。
