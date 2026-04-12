# Sprint 3 — 2026-04-24 to 2026-04-30

## Sprint Goal
实现地形天气系统和武将系统核心功能，完善战斗环境交互，为完整MVP战斗体验提供环境变量支持。

## Capacity
- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 hours (按 8h/天计算)

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 3-1 | 地形天气系统 (D1) - 基础配置加载 | gameplay-programmer | 1 | Sprint 2完成 | 从配置文件加载7种地形和4种天气，初始化TerrainWeatherManager，通过单元测试 |
| 3-2 | 地形天气系统 (D1) - 地形天气初始化效果 | gameplay-programmer | 1 | 3-1 | 战斗开始时应用地形天气效果，水域滑倒、沙漠减速等效果正确触发 |
| 3-3 | 地形天气系统 (D1) - 地形天气修正值 | gameplay-programmer | 1 | 3-2 | 地形天气对伤害/防御/行动点的修正值正确应用，通过集成测试 |
| 3-4 | 地形天气系统 (D1) - 动态天气切换 | gameplay-programmer | 1 | 3-1 | 实现天气动态切换（冷却2回合），卡牌/事件可触发天气变化，冷却机制生效 |
| 3-5 | 武将系统 (D3) - 武将数据加载 | gameplay-programmer | 1 | Sprint 2完成 | 从CSV加载23名武将数据（HP/行动点/被动技能），正确解析属性 |
| 3-6 | 武将系统 (D3) - 被动技能框架 | gameplay-programmer | 1 | 3-5 | 实现被动技能基础框架，支持回合开始/结束/出牌/受击等钩子事件 |
| 3-7 | 集成测试：D1+C2 地形天气与战斗联动 | qa-tester | 0.5 | 3-3 | 地形天气效果正确影响战斗伤害、防御、行动点，通过完整集成测试 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 3-8 | 武将系统 (D3) - 魏蜀武将被动技能实现 | gameplay-programmer | 1 | 3-6 | 实现魏国（曹操、夏侯惇等）和蜀国（刘备、关羽等）武将的被动技能 |
| 3-9 | 集成测试：D3+C2 武将与战斗联动 | qa-tester | 0.5 | 3-8 | 武将被动技能在战斗中正确触发，属性加成正确应用 |
| 3-10 | UI绑定：地形天气信息显示 | ui-programmer | 0.5 | 3-3 | 战斗HUD显示当前地形、天气及其效果提示 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 3-11 | 战斗UI：状态效果可视化 | ui-programmer | 1 | Sprint 2完成 | 在战斗HUD中显示当前状态效果（图标+层数） |
| 3-12 | 敌人系统 (C3) - 敌人行动公示 | ai-programmer | 1 | Sprint 2完成 | 在敌人回合前公示即将执行的行动序列（1-3回合） |
| 3-13 | 资源管理系统 (F2) - 资源UI绑定 | ui-programmer | 0.5 | Sprint 2完成 | 将HP、粮草、金币、行动点显示在HUD上 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 2-8 地形天气系统 (D1) - 基础配置加载 | 优先级调整至Sprint 3 | 1 day |
| 2-9 地形天气系统 (D1) - 天气动态切换 | 优先级调整至Sprint 3 | 1 day |
| 2-10 集成测试：F2+C1+C2 战斗与资源联动 | 优先级调整至Sprint 3 | 0.5 days |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| D1地形天气效果复杂度超预期 | 中 | 中 | 优先实现核心地形（平原、山地、森林、水域），其他地形简化处理 |
| D3武将被动技能触发时机难以统一 | 中 | 中 | 设计通用事件系统，所有被动技能监听统一事件总线 |
| 天气切换冷却机制与战斗状态同步问题 | 低 | 低 | 在BattleManager中集中管理天气切换，确保状态一致性 |

## Dependencies on External Factors
- **CSV数据文件**: assets/csv_data/heroes_passive_skills.csv, heroes_exclusive_decks.csv (已存在)
- **引擎版本**: Godot 4.6.1 (已配置在 CLAUDE.md)
- **测试框架**: GdUnit4 (已在Sprint 1配置完成)

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过验收标准
- [ ] QA 计划存在 (`production/qa/qa-plan-sprint-3.md`)
- [ ] 所有 Logic/Integration 故事有通过的单元/集成测试
- [ ] 烟雾测试通过 (`/smoke-check sprint`)
- [ ] QA 签字报告: APPROVED 或 APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] 无 S1 或 S2 级别 bug
- [ ] 设计文档更新（如有偏差）
- [ ] 代码审查通过并合并

---

> **Note**: Sprint 3聚焦于MVP关键路径——地形天气系统与武将系统。这两个系统完成后，将实现完整的环境交互战斗体验，为首个可玩原型提供完整的战斗循环。
