# QA Test Plan - Sprint 1

## Sprint Goal
实现核心战斗系统基础原型（F2 资源管理 + C1 状态效果 + C2 卡牌战斗 + C3 敌人系统），支持 1v3 战场的基本战斗循环。

## Scope

- **F2 资源管理系统**: HP、护盾、行动点、粮草机制
- **C1 状态效果系统**: Buff/Debuff数据结构与叠加、结算机制
- **C2 卡牌战斗系统**: 费用检查、手牌逻辑、出牌与1v3目标选择
- **C3 敌人系统**: 数据结构、AI行动队列与执行
- **集成测试**: 资源+状态联动，完整的战斗循环

## Required Tests by Story

### 1-1 资源管理系统 (F2) - 基础数据结构
- **Story Type**: Logic
- **Test Requirements**: Automated Unit Tests
- **Test Cases**:
  - [ ] 验证 HP 最大值限制与初始值
  - [ ] 验证护盾生命周期（回合结束清空等规则）
  - [ ] 验证行动点(AP)每回合恢复逻辑

### 1-2 资源管理系统 (F2) - 资源变动逻辑
- **Story Type**: Logic
- **Test Requirements**: Automated Unit Tests
- **Test Cases**:
  - [ ] 验证受击时优先扣除护盾，溢出部分扣除HP
  - [ ] 验证增加/减少行动点的边界值（不小于0）
  - [ ] 验证粮草消耗逻辑及其边界状态

### 1-3 状态效果系统 (C1) - 状态数据结构与Buff
- **Story Type**: Logic
- **Test Requirements**: Automated Unit Tests
- **Test Cases**:
  - [ ] 验证7种Buff的正确应用与参数读取
  - [ ] 验证Buff同名叠加规则（层数增加或时间重置）
  - [ ] 验证Buff持续时间减少和移除触发逻辑

### 1-4 状态效果系统 (C1) - Debuff与结算
- **Story Type**: Logic
- **Test Requirements**: Automated Unit Tests
- **Test Cases**:
  - [ ] 验证13种Debuff的正确应用与限制机制
  - [ ] 验证Debuff能否绕过/穿透护盾直接作用于HP（如毒）
  - [ ] 验证多状态并存时的优先级/结算顺序

### 1-5 卡牌战斗系统 (C2) - 出牌与费用逻辑
- **Story Type**: Logic
- **Test Requirements**: Automated Unit Tests
- **Test Cases**:
  - [ ] 验证卡牌费用足够时成功出牌，费用不足时被拒绝
  - [ ] 验证手牌打出后正确移动至弃牌堆或消耗堆
  - [ ] 验证出牌引发的AP扣除准确无误

### 1-6 卡牌战斗系统 (C2) - 1v3战场与目标选择
- **Story Type**: Logic/UI
- **Test Requirements**: Automated Unit Tests / Interaction Walkthrough
- **Test Cases**:
  - [ ] 验证单体攻击只命中选定目标
  - [ ] 验证群体攻击正确命中所有在场敌人
  - [ ] 验证无效目标的错误处理（如对空位释放单体卡）

### 1-7 敌人系统 (C3) - 敌人数据结构
- **Story Type**: Logic
- **Test Requirements**: Automated Unit Tests
- **Test Cases**:
  - [ ] 验证敌人初始化读取正确的属性表
  - [ ] 验证不同敌人类型(A/B/C)行动队列正确读取

### 1-8 敌人系统 (C3) - 敌人AI与行动执行
- **Story Type**: Logic
- **Test Requirements**: Automated Unit Tests
- **Test Cases**:
  - [ ] 验证AI根据预设行为树/行动队列正确选择本回合动作
  - [ ] 验证敌人执行攻击时正确造成玩家资源变动
  - [ ] 验证敌人执行强化/状态施加时正确修改其自身或玩家状态

### 1-9 集成测试：F2+C1 资源与状态联动
- **Story Type**: Integration
- **Test Requirements**: Automated Integration Tests
- **Test Cases**:
  - [ ] 测试持续伤害(PoT)正确跳过护盾直接扣血（若设计如此）
  - [ ] 测试护盾增益状态正确增强后续获取的护盾量

### 1-10 集成测试：C2+C3 战斗循环
- **Story Type**: Integration
- **Test Requirements**: Playtest / End-to-End Test
- **Test Cases**:
  - [ ] 回合流转测试：玩家出牌 -> 玩家结束回合 -> 敌人依序行动 -> 玩家新回合开始
  - [ ] 生死流转测试：敌人HP为0被正确清理，玩家HP为0触发失败流程

### 1-11 本地化系统 (F3) - 中文/英文/日文基础支持
- **Story Type**: UI/Visual
- **Test Requirements**: Manual Validation
- **Test Cases**:
  - [ ] 切换语言环境后，UI 文本（至少包含战斗界面）立即或刷新后正确对应语言

## Smoke Test Requirements

- **Smoke Check Scope**: 
  - 能成功进入一个1v3基础战斗场景
  - 玩家能够打出一张对敌人造成伤害的卡牌，并看到资源正确变动
  - 点击“结束回合”后敌人能够正常行动，并重新轮到玩家回合
- **Location**: `production/qa/smoke-sprint-1.md` (to be generated)

## Known Risks
- 测试框架GUT为首次配置，可能会拖慢Unit Test的编写进度。
- F2/C1/C2/C3高强度相互依赖，集成测试需在Sprint中后期才能完全开展。