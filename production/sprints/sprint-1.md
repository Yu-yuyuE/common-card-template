# Sprint 1 — 2026-04-10 to 2026-04-16

## Sprint Goal
实现核心战斗系统基础原型（F2 资源管理 + C1 状态效果 + C2 卡牌战斗 + C3 敌人系统），支持 1v3 战场的基本战斗循环。

## Capacity
- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 hours (按 8h/天计算)

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 1-1 | 资源管理系统 (F2) - 基础数据结构 | gameplay-programmer | 8 | - | HP/护盾/行动点/粮草数据结构定义完成，单元测试通过 |
| 1-2 | 资源管理系统 (F2) - 资源变动逻辑 | gameplay-programmer | 8 | 1-1 | 资源增减、护盾机制、行动点消耗逻辑完成，单元测试通过 |
| 1-3 | 状态效果系统 (C1) - 状态数据结构与Buff | gameplay-programmer | 8 | 1-2 | 7种Buff类型定义、叠加规则、持续时间逻辑完成 |
| 1-4 | 状态效果系统 (C1) - Debuff与结算 | gameplay-programmer | 8 | 1-3 | 13种Debuff类型、护盾穿透规则、结算顺序完成 |
| 1-5 | 卡牌战斗系统 (C2) - 出牌与费用逻辑 | gameplay-programmer | 8 | 1-4 | 费用检查、手牌管理、出牌结算流程完成 |
| 1-6 | 卡牌战斗系统 (C2) - 1v3战场与目标选择 | gameplay-programmer | 8 | 1-5 | 战场布局、目标选择、伤害分配逻辑完成 |
| 1-7 | 敌人系统 (C3) - 敌人数据结构 | ai-programmer | 6 | 1-2 | 敌人属性、行动队列、行动类型(A/B/C)定义完成 |
| 1-8 | 敌人系统 (C3) - 敌人AI与行动执行 | ai-programmer | 8 | 1-7 | 行动选择逻辑、回合执行、玩家可见的行动队列完成 |

### Should Have

| ID | Task | Agent/Owner | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 1-9 | 集成测试：F2+C1 资源与状态联动 | qa-tester | 4 | 1-4 | 资源变动触发状态效果的集成测试通过 |
| 1-10 | 集成测试：C2+C3 战斗循环 | qa-tester | 4 | 1-6, 1-8 | 玩家出牌→敌人响应→结算的完整循环测试通过 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 1-11 | 本地化系统 (F3) - 中文/英文/日文基础支持 | - | - | 1-1 | UI 文本支持多语言切换（可选，MVP 完成后） |

## Carryover from Previous Sprint
无 — 这是第一个 sprint

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| C2 卡牌战斗系统复杂度超预期 | 中 | 高 | 预留 2h 缓冲时间，必要时拆分任务 |
| 敌人 AI 行动队列机制需要额外设计 | 低 | 中 | C3 依赖 C2 进度，提前开始 C1 不受影响 |
| GUT 测试框架未配置 | 中 | 中 | 第1天优先配置测试框架 |

## Dependencies on External Factors
- **GUT 测试框架**: 需要使用 /test-setup 在第 1 天配置
- **引擎版本**: Godot 4.6.1 (已配置在 CLAUDE.md)

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过验收标准
- [ ] QA 计划存在 (`production/qa/qa-plan-sprint-1.md`)
- [ ] 所有 Logic/Integration 故事有通过的单元/集成测试
- [ ] 烟雾测试通过 (`/smoke-check sprint`)
- [ ] QA 签字报告: APPROVED 或 APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] 无 S1 或 S2 级别 bug
- [ ] 设计文档更新（如有偏差）
- [ ] 代码审查通过并合并

---

> **Note**: 这是一个新项目，没有里程碑定义。建议运行 `/milestone-review` 创建第一个里程碑。
