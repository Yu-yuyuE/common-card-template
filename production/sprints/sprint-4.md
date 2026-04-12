# Sprint 4 — 2026-05-01 to 2026-05-07

## Sprint Goal
实现兵种卡系统和诅咒系统核心功能，完善卡牌类型多样性，为完整Roguelike卡组构建体验提供关键机制支持。

## Capacity
- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 hours (按 8h/天计算)

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 4-1 | 兵种卡系统 (D2) - 基础兵种卡（Lv1）核心逻辑 | gameplay-programmer | 1 | Sprint 3完成 | 实现5种基础兵种卡，兵种伤害公式正确计算，通过单元测试 |
| 4-2 | 兵种卡系统 (D2) - 高级兵种卡（Lv2）升级机制 | gameplay-programmer | 1 | 4-1 | 实现Lv1→Lv2升级逻辑，提升系数1.20-1.35，通过单元测试 |
| 4-3 | 兵种卡系统 (D2) - 兵种地形天气联动 | gameplay-programmer | 1 | 4-1, Sprint 3 | 地形天气修正正确应用到兵种卡伤害，通过集成测试 |
| 4-4 | 兵种卡系统 (D2) - 统帅值约束与卡组管理 | gameplay-programmer | 1 | 4-1 | 实现统帅上限（3-6张），卡组管理逻辑完成，通过单元测试 |
| 4-5 | 诅咒系统 (D4) - 诅咒类型与数据结构 | gameplay-programmer | 1 | Sprint 2完成 | 定义3种诅咒类型，基础25张诅咒卡数据，通过单元测试 |
| 4-6 | 诅咒系统 (D4) - 诅咒注入机制 | gameplay-programmer | 1 | 4-5 | 实现诅咒卡添加到手牌/抽牌堆/弃牌堆，通过单元测试 |
| 4-7 | 集成测试：D2+C2 兵种卡与战斗联动 | qa-tester | 0.5 | 4-3 | 兵种卡在战斗中正确工作，地形天气修正生效，通过集成测试 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 4-8 | 诅咒系统 (D4) - 诅咒净化机制 | gameplay-programmer | 1 | 4-6 | 实现诅咒卡移出卡组逻辑，通过单元测试 |
| 4-9 | 集成测试：D4+C2 诅咒与战斗联动 | qa-tester | 0.5 | 4-6 | 诅咒卡在战斗中正确注入和触发，通过集成测试 |
| 4-10 | UI绑定：地形天气信息显示 | ui-programmer | 0.5 | Sprint 3完成 | 战斗HUD显示当前地形、天气及其效果提示 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 4-11 | 战斗UI：状态效果可视化 | ui-programmer | 1 | Sprint 3完成 | 在战斗HUD中显示当前状态效果（图标+层数） |
| 4-12 | 敌人系统 (C3) - 敌人行动公示 | ai-programmer | 1 | Sprint 2完成 | 在敌人回合前公示即将执行的行动序列（1-3回合） |
| 4-13 | 资源管理系统 (F2) - 资源UI绑定 | ui-programmer | 0.5 | Sprint 2完成 | 将HP、粮草、金币、行动点显示在HUD上 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 3-10 UI绑定：地形天气信息显示 | 优先级调整至Sprint 4 | 0.5 days |
| 3-11 战斗UI：状态效果可视化 | 优先级调整至Sprint 4 | 1 day |
| 3-12 敌人系统 (C3) - 敌人行动公示 | 优先级调整至Sprint 4 | 1 day |
| 3-13 资源管理系统 (F2) - 资源UI绑定 | 优先级调整至Sprint 4 | 0.5 days |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| D2兵种卡地形联动复杂度超预期 | 中 | 中 | 优先实现核心地形（平原、山地、森林），其他地形简化处理 |
| D4诅咒触发时机难以统一 | 低 | 低 | 使用事件系统统一管理触发点 |
| 兵种卡升级分支逻辑复杂 | 中 | 低 | 先实现Lv1和Lv2，Lv3分支在后续Sprint完善 |

## Dependencies on External Factors
- **CSV数据文件**: assets/csv_data/troop_cards.csv, curse_cards.csv (需创建)
- **引擎版本**: Godot 4.6.1 (已配置在 CLAUDE.md)
- **测试框架**: GdUnit4 (已在Sprint 1配置完成)

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过验收标准
- [ ] QA 计划存在 (`production/qa/qa-plan-sprint-4.md`)
- [ ] 所有 Logic/Integration 故事有通过的单元/集成测试
- [ ] 烟雾测试通过 (`/smoke-check sprint`)
- [ ] QA 签字报告: APPROVED 或 APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] 无 S1 或 S2 级别 bug
- [ ] 设计文档更新（如有偏差）
- [ ] 代码审查通过并合并

---

> **Note**: Sprint 4聚焦于卡组多样性——兵种卡和诅咒卡。这两个系统完成后，玩家将拥有完整的卡组构建体验，包括攻击卡、技能卡、兵种卡和诅咒卡，为完整的Roguelike循环奠定基础。