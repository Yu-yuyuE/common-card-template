# Sprint 6 — 2026-05-15 to 2026-05-22

## Sprint Goal
双线并进：（A）完成战斗可视化——实现战斗HUD与状态效果UI，让战斗从纯逻辑变为可视可玩；（B）打通地图/战役骨架——实现地图数据结构、节点导航、程序化地图生成，并完成军营/酒馆逻辑，让玩家可以在地图上移动并进入功能节点。

## Capacity
- Total days: 8
- Buffer (20%): 1.6 days reserved for unplanned work
- Available: 6.4 days ≈ 51 hours (按 8h/天计算)

## Tasks

### Must Have — 路径 B: 地图/战役骨架

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 6-1 | 地图数据结构与节点类型 | gameplay-programmer | 0.5 | Sprint 5 完成 | NodeType 7种枚举，MapNode 数据类（含 is_visited/is_completed），CampaignMap 结构，单元测试通过 |
| 6-2 | 节点导航与粮草消耗 | gameplay-programmer | 0.5 | 6-1 | can_move_to/move_to 接口，前置节点检查，粮草扣除/不足阻止，Boss奖励粮草，单元测试通过 |
| 6-3 | 地图生成算法 | gameplay-programmer | 1.0 | 6-1 | 12-16层、每层2-3分叉、DFS可达性验证、必要节点保证（商店/酒馆/军营各1）、精英每5层1个，单元测试通过 |
| 6-4 | 军营核心逻辑 | gameplay-programmer | 0.5 | Sprint 5（HeroManager）| 按兵种权重生成3张候选卡（无重复）、Lv2概率15%判定、统帅上限检查接口，单元测试通过 |
| 6-5 | 军营卡组集成 | gameplay-programmer | 0.5 | 6-4 | commit_add/upgrade/remove_card 接口，扣费50金，离开触发保存，放弃操作不修改卡组，集成测试通过 |
| 6-6 | 酒馆服务实现 | gameplay-programmer | 0.5 | Sprint 5（ResourceManager）| 歇息+15HP、购买粮草40金/50粮草、强化休整60金+20HP、每章限1次歇息，单元测试通过 |

### Should Have — 路径 A: 战斗可视化

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 6-7 | 战斗HUD与手牌UI绑定 | ui-programmer | 1.0 | Sprint 5 战斗系统 | 手牌区实例化CardUI（显示费用/名称）、费用不足灰显、敌人HP血条跟随damage_dealt信号更新、回合阶段提示，手动验证通过 |
| 6-8 | 状态变化UI响应机制 | ui-programmer | 0.5 | Sprint 5（StatusManager）| 施加/刷新/互斥/移除状态时图标实时更新，全信号驱动（无_process轮询），手动验证通过 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| 6-9 | 战役进度管理（桩接口版） | gameplay-programmer | 0.5 | 6-1, 6-3 | CampaignManager 战役推进逻辑（5战役×3地图），Boss击败信号，存档接口以桩函数实现（F1 Sprint 7引入）|
| 6-10 | 酒馆状态持久化（桩接口版） | gameplay-programmer | 0.5 | 6-6 | InnSaveData 序列化/反序列化，存档读写以桩函数实现（F1 Sprint 7引入）|

## Carryover from Sprint 5

| Task | Reason | New Estimate |
|------|--------|-------------|
| 5-14/5-15 UI手动验证 | 无可运行BattleScene，已推迟 | 1.5d（纳入6-7/6-8，含场景搭建）|

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| BattleScene.tscn 搭建依赖 UI 节点树，工作量超预期 | 中 | 中 | 6-7/6-8 纳入 Should Have，不阻塞地图骨架完成 |
| 地图生成算法复杂度超预期（DFS验证/必要节点保证） | 中 | 中 | 6-3 估算1d较充裕；若超出可先跳过精英分布，主路径可达优先 |
| 军营/酒馆集成依赖 F1 存档系统（未实现） | 高 | 低 | 6-5/6-10 使用桩接口，Sprint 7 正式接入 F1 |
| 战役管理（6-9）与地图生成强耦合 | 低 | 低 | 独立实现，通过 CampaignMap 接口解耦 |

## Dependencies on External Factors
- **Sprint 5 完成** ✅：BattleManager、StatusManager、ResourceManager、HeroManager 均已实现
- **ADR-0011**（Map Node System）：需确认 Accepted 状态
- **ADR-0010**（武将系统架构）：Accepted ✅（军营依赖）
- **ADR-0003**（Resource Notification）：Accepted ✅（节点导航依赖）
- **F1 存档系统**：Sprint 6 使用桩接口，Sprint 7 正式实现

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成（6-1 ～ 6-6）
- [ ] 所有任务通过验收标准
- [ ] QA 计划存在（`production/qa/qa-plan-sprint-6.md`）
- [ ] 所有 Logic/Integration stories 有通过的单元/集成测试
- [ ] 烟雾测试通过（`/smoke-check sprint`）
- [ ] QA 签字报告：APPROVED 或 APPROVED WITH CONDITIONS（`/team-qa sprint`）
- [ ] 无 S1 或 S2 级别 bug
- [ ] Sprint 6 结束后，地图可以程序化生成并导航，军营/酒馆逻辑可独立运行

---

> **Scope check：** Sprint 6 仅包含 map-node-system、barracks-system、inn-system 的前置逻辑 stories 和 5-14/5-15 的 UI stories，均来自已有 Epic，无额外 scope creep 风险。
>
> **注意：** F1 存档系统（save-persistence-system）是 6-5、6-9、6-10 的软依赖，Sprint 6 全部使用桩接口绕过，F1 的完整实现安排在 Sprint 7 或更晚。
