# Sprint 2 — 2026-04-17 to 2026-04-23

## Sprint Goal
完成卡牌战斗系统与敌人系统的核心联动，实现完整1v3战斗循环，为首个可玩原型奠定基础。

## Capacity
- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 hours (按 8h/天计算)

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 2-1 | 卡牌战斗系统 (C2) - 战斗状态机优化 | gameplay-programmer | 1 | 1-7 | 实现完整的战斗阶段（玩家回合/敌人回合/结算），状态机转换逻辑通过单元测试 |
| 2-2 | 敌人系统 (C3) - 敌人AI与行动执行 | ai-programmer | 1 | 1-8 | 实现敌人行动选择逻辑，支持A/B/C三类行动，能正确响应玩家行动和状态效果 |
| 2-3 | 敌人系统 (C3) - 敌人相变机制 | ai-programmer | 1 | 2-2 | 实现HP<40%等相变条件检测，行动序列动态切换，触发事件信号 |
| 2-4 | 集成测试：C2+C3 战斗循环 | qa-tester | 0.5 | 2-1, 2-2 | 完整的玩家出牌→敌人响应→结算循环通过集成测试，覆盖所有边缘情况 |
| 2-5 | 卡牌战斗系统 (C2) - 手牌管理与费用结算 | gameplay-programmer | 1 | 1-6 | 实现手牌抽取、费用消耗、出牌限制逻辑，满足GDD要求 |
| 2-6 | 资源管理系统 (F2) - 资源恢复机制 | gameplay-programmer | 0.5 | 1-2 | 实现回合结束时HP/行动点恢复机制（符合GDD规则） |
| 2-7 | 状态效果系统 (C1) - 状态持续伤害结算 | gameplay-programmer | 1 | 1-4 | 实现DOT效果在每个回合结算，正确处理护盾穿透和资源变化联动 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 2-8 | 地形天气系统 (D1) - 基础配置加载 | gameplay-programmer | 1 | 2-1 | 从配置文件加载地形/天气类型，基础效果初始化 |
| 2-9 | 地形天气系统 (D1) - 天气动态切换 | gameplay-programmer | 1 | 2-8 | 实现战斗中天气动态切换（冷却2回合），影响战斗效果 |
| 2-10 | 集成测试：F2+C1+C2 战斗与资源联动 | qa-tester | 0.5 | 2-6, 2-7 | 验证资源恢复、持续伤害、护盾穿透等跨系统联动效果 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 2-11 | 战斗UI：状态效果可视化 | ui-programmer | 1 | 2-7 | 在战斗HUD中显示当前状态效果（图标+层数） |
| 2-12 | 敌人系统 (C3) - 敌人行动公示 | ai-programmer | 1 | 2-2 | 在敌人回合前公示即将执行的行动序列（1-3回合） |
| 2-13 | 资源管理系统 (F2) - 资源UI绑定 | ui-programmer | 0.5 | 2-6 | 将HP、粮草、金币、行动点显示在HUD上 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 1-10 集成测试：F2+C1 资源与状态联动 | 将在Sprint 2中完成 | 0.5 days |
| 1-11 集成测试：C2+C3 战斗循环 | 将在Sprint 2中完成 | 0.5 days |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| C2战斗状态机复杂度超预期 | 中 | 高 | 预留缓冲时间，优先完成核心状态机，UI功能后置 |
| C3敌人相变机制难以调试 | 低 | 中 | 使用日志和测试用例，确保每个相变条件都有明确验证 |
| 敌人AI行动响应延迟 | 中 | 中 | 采用事件驱动模式，避免轮询，确保实时响应 |

## Dependencies on External Factors
- **GUT测试框架**: 已在Sprint 1完成配置
- **引擎版本**: Godot 4.6.1 (已配置在 CLAUDE.md)
- **CSV数据文件**: assets/csv_data/enemies.csv (已存在)

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过验收标准
- [ ] QA 计划存在 (`production/qa/qa-plan-sprint-2.md`)
- [ ] 所有 Logic/Integration 故事有通过的单元/集成测试
- [ ] 烟雾测试通过 (`/smoke-check sprint`)
- [ ] QA 签字报告: APPROVED 或 APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] 无 S1 或 S2 级别 bug
- [ ] 设计文档更新（如有偏差）
- [ ] 代码审查通过并合并

---

> **QA Plan**: `production/qa/qa-plan-sprint-2.md` — defines test requirements for all stories
