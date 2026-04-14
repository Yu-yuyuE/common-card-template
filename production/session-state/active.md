## Session Extract — 2026-04-13

### ✅ 已完成 Task

**Story 4-6: 诅咒注入机制完成**
- 新增: `src/core/curse-system/CurseInjectionSystem.gd`
- 实现核心接口: `inject_curse_card()`
- 支持所有5种注入来源和3种注入位置
- 默认注入规则符合GDD设计：
  - 敌人行动 → 弃牌堆
  - 地图事件 → 抽牌堆
  - 卡牌效果 → 手牌
  - 武将初始 → 抽牌堆
- 提供专用封装接口简化调用
- 完整事件系统: `curse_injected` 信号
- 新增测试: `tests/unit/curse_system/curse_injection_test.gd` (10个测试用例)

### Sprint 4 进度总结

**已完成 (5/13):**
- ✅ 4-1: 兵种卡系统 - 基础兵种卡核心逻辑
- ✅ 4-2: 兵种卡系统 - 高级兵种卡升级机制
- ✅ 4-3: 兵种卡系统 - 兵种地形天气联动
- ✅ 4-4: 兵种卡系统 - 统帅值约束与卡组管理
- ✅ 4-5: 诅咒系统 - 诅咒类型与数据结构
- ✅ 4-6: 诅咒系统 - 诅咒注入机制

**待开发 (7个):**
- 🔄 4-7: 集成测试 - D2+C2 兵种卡与战斗联动
- 🔄 4-8: 诅咒系统 - 诅咒净化机制
- 🔄 4-9: 集成测试 - D4+C2 诅咒与战斗联动
- 🔄 4-10: UI绑定 - 地形天气信息显示
- 🔄 4-11: 战斗UI - 状态效果可视化
- 🔄 4-12: 敌人系统 - 敌人行动公示
- 🔄 4-13: 资源管理系统 - 资源UI绑定

### 代码审查记录

**Story 4-4 (TroopBranchRegistry.gd)**
- ✅ 数据驱动设计，静态方法性能优秀
- ✅ 5大类兵种分支完整定义
- ⚠️ 建议：`is_max_level()` 增加 null 检查

**Story 4-5 (CurseCardData.gd + CurseManager.gd)**
- ✅ 继承设计合理，类型推断智能
- ✅ CSV解析健壮，错误处理完整
- ⚠️ 建议：文件路径提取为常量

**Story 4-6 (CurseInjectionSystem.gd)**
- ✅ 模块化设计，注入规则可配置
- ✅ 事件驱动，松耦合
- ✅ 错误处理完善，边界条件覆盖
- ✅ 手牌满时自动弃置机制正确

## ADR-0020: 卡组两层管理架构

**Status**: Accepted (2026-04-14)

### Completed Changes

- ✅ 更新 ADR-0020 状态从 "Proposed" → "Accepted"
- ✅ 更新 architecture.yaml 注册表
  - 更新 `deck_data` state ownership 接口描述
  - 添加 `battle_deck_initialization` 接口契约
  - 添加 `deck_save_serialization` 接口契约
- ✅ 创建 deck-management-system epic 的所有 stories (6个)
  - Story 001: 战役层卡组快照基础实现
  - Story 002: 战斗层卡组快照基础实现
  - Story 003: 卡组管理器集成
  - Story 004: 永久加入卡组机制
  - Story 005: 消耗品处理
  - Story 006: 敌人偷取卡牌机制
- ✅ 更新 Epic 文件，标记 stories 已创建

### Next Step

建议继续开发：
1. **Deck Management System**: 开始实现 Story 001-006 的代码
2. **Story 4-7**: 兵种卡与战斗集成测试 - 验证兵种卡在战斗中的正确运作
3. **Story 4-8**: 诅咒净化机制 - 完成诅咒系统的闭环功能
4. **Story 4-9**: 诅咒与战斗集成测试 - 验证诅咒卡在战斗中的注入和触发

当前Sprint 4核心功能（兵种卡 + 诅咒系统）已完成 ~46%，剩余工作主要为集成测试和净化功能。

<!-- STATUS -->
Epic: Sprint 5 - Card Battle System & Status Effects
Feature: Sprint Planning
Task: Sprint 5 plan ready, awaiting /qa-plan
<!-- /STATUS -->
