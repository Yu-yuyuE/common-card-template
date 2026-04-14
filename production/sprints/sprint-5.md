# Sprint 5 — 2026-05-08 to 2026-05-14

## Sprint Goal
打通完整单局战斗闭环：实现卡牌战斗系统核心流程（状态机、出牌结算、多阶段胜负判定）与状态效果系统（叠加/结算/DoT），让玩家可以从战斗开始到胜/负完整地玩一场战斗。

## Capacity
- Total days: 7
- Buffer (20%): 1.4 days reserved for unplanned work
- Available: 5.6 days ≈ 45 hours (按 8h/天计算)

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 5-1 | 卡牌战斗系统 (C2) - 战斗数据结构与实体初始化 | gameplay-programmer | 0.5 | Sprint 1-4 完成 | BattleEntity/BattleManager 初始化，1v3 战场结构，单元测试通过 |
| 5-2 | 卡牌战斗系统 (C2) - 战斗状态机与回合流程 | gameplay-programmer | 1 | 5-1 | 玩家回合→敌人回合→阶段检查完整循环，状态机转换正确，单元测试通过 |
| 5-3 | 卡牌战斗系统 (C2) - 卡牌生命周期与抽牌堆管理 | gameplay-programmer | 0.5 | 5-1 | 抽牌堆→手牌→弃牌堆→移除区→消耗区流转正确，洗牌逻辑，单元测试通过 |
| 5-4 | 卡牌战斗系统 (C2) - 出牌验证与卡牌结算框架 | gameplay-programmer | 1 | 5-2, 5-3 | 费用验证、目标合法性检查、出牌信号、效果结算框架，单元测试通过 |
| 5-5 | 卡牌战斗系统 (C2) - 伤害计算管线 | gameplay-programmer | 0.5 | 5-4 | 基础×地形×天气×状态公式，护盾优先溢出扣HP，通过单元测试 |
| 5-6 | 状态效果系统 (C1) - 状态数据结构与基础增删改 | gameplay-programmer | 0.5 | Sprint 1-4 完成 | 20种状态定义，StatusManager增删接口，信号广播，单元测试通过 |
| 5-7 | 状态效果系统 (C1) - 状态叠加与互斥规则 | gameplay-programmer | 0.5 | 5-6 | 同类叠加层数，不同类互斥覆盖，层数上限，单元测试通过 |
| 5-8 | 状态效果系统 (C1) - 回合结束结算机制 | gameplay-programmer | 0.5 | 5-7 | 回合结束消耗层数/移除状态，结算顺序正确，单元测试通过 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 5-9 | 卡牌战斗系统 (C2) - 多阶段战斗与胜负判定 | gameplay-programmer | 0.5 | 5-4, 5-5 | 精英/Boss 多阶段切换，全灭胜利/玩家HP归零失败判定，测试通过 |
| 5-10 | 状态效果系统 (C1) - 状态持续伤害（DoT） | gameplay-programmer | 0.5 | 5-8 | 灼烧/中毒每回合结算，穿透护盾vs走护盾区分，单元测试通过 |
| 5-11 | 状态效果系统 (C1) - 状态伤害修正系数 | gameplay-programmer | 0.5 | 5-8 | 状态对伤害加成/减免系数正确应用于伤害管线，集成测试通过 |
| 5-12 | 集成测试：C1+C2 状态效果与战斗联动 | qa-tester | 0.5 | 5-9, 5-11 | 战斗中施加/结算/移除状态全流程，DoT扣血，修正系数生效，集成测试通过 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 5-13 | 状态效果系统 (C1) - 特殊交互规则（免疫/穿透/瘟疫） | gameplay-programmer | 0.5 | 5-10 | 免疫状态屏蔽新增、穿透忽略护盾、瘟疫状态扩散规则，单元测试通过 |
| 5-14 | 卡牌战斗系统 (C2) - 战斗HUD与手牌UI绑定 | ui-programmer | 1 | 5-4 | 手牌显示、费用显示、出牌区域、敌人HP/护盾显示，手动验证通过 |
| 5-15 | 状态效果系统 (C1) - 状态变化UI响应机制 | ui-programmer | 0.5 | 5-6 | StatusEffectHUD 与 StatusManager 信号对接，状态增删时UI刷新，手动验证 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| UI 4-10～4-13 手动验证 | Sprint 4 无可运行 build，推迟手动验证 | 0.5 days（并入 5-14/5-15 场景搭建时一并验收） |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 战斗状态机复杂度超预期 | 中 | 高 | 5-2 先实现最小状态机（3个阶段），多阶段 5-9 推迟为 Should Have |
| 状态效果与伤害管线集成冲突 | 低 | 中 | 5-5 和 5-11 分开实现，集成测试 5-12 作为验收门 |
| 卡牌战斗系统与现有 CardManager 重复实现 | 中 | 中 | 5-1 开始前审查现有 BattleManager.gd，复用而非重写 |

## Dependencies on External Factors
- **已完成 Sprint 1-4**：ResourceManager、TerrainWeatherManager、HeroManager、CurseInjectionSystem、TroopCard 均已实现
- **ADR-0007**（卡牌战斗系统架构）：Accepted ✅
- **ADR-0006**（状态效果系统）：Accepted ✅

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过验收标准
- [ ] QA 计划存在 (`production/qa/qa-plan-sprint-5.md`)
- [ ] 所有 Logic/Integration stories 有通过的单元/集成测试
- [ ] 烟雾测试通过 (`/smoke-check sprint`)
- [ ] QA 签字报告: APPROVED 或 APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] 无 S1 或 S2 级别 bug
- [ ] 设计文档更新（如有偏差）
- [ ] 代码审查通过并合并
- [ ] Sprint 5 结束后，可以从战斗开始到胜/败完整运行一局战斗

---

> **Scope check:** 本 Sprint 完全来自已有 Epic（card-battle-system + status-effects-system），无额外 scope creep 风险。
>
> **注意**: Sprint 4 的 UI stories (4-10～4-13) 手动验证推迟至本 Sprint 5-14/5-15 场景搭建时一并完成。
