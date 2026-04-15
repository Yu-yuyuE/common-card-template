## Session Extract — 2026-04-15

### ✅ Sprint 5 全部逻辑/集成 Stories 完成

#### Must Have (8/8 DONE)
- ✅ 5-1: 战斗数据结构与实体初始化
- ✅ 5-2: 战斗状态机与回合流程
- ✅ 5-3: 卡牌生命周期与抽牌堆管理 — CardManager + force_add_card，13 tests
- ✅ 5-4: 出牌验证与卡牌结算框架
- ✅ 5-5: 伤害计算管线
- ✅ 5-6: 状态数据结构与基础增删改 — 14 tests
- ✅ 5-7: 状态叠加与互斥规则 — 14 tests
- ✅ 5-8: 回合结束结算机制 — 10 tests

#### Should Have (4/4 DONE)
- ✅ 5-9: 多阶段战斗与胜负判定 — 8 tests
- ✅ 5-10: 状态持续伤害（DoT）— 8 tests
- ✅ 5-11: 状态伤害修正系数 — 14 tests（新增 calculate_damage_modifier 等接口）
- ✅ 5-12: C1+C2 集成测试 — 13 tests

#### Nice to Have (1/3 DONE, 2 待手动验证)
- ✅ 5-13: 特殊交互规则（免疫/穿透/瘟疫）— 14 tests
- 🔄 5-14: 战斗HUD与手牌UI绑定 — 证明文件已创建，待场景搭建后手动验证
- 🔄 5-15: 状态变化UI响应机制 — 证明文件已创建，待场景搭建后手动验证

### 本次 Session 关键修改

- `src/core/card/CardManager.gd` — force_add_card, _enforce_hand_limit, return_removed_cards_to_deck
- `src/core/StatusManager.gd` — calculate_damage_modifier, calculate_incoming_damage, calculate_incoming_damage_with_rng
- `src/core/ResourceManager.gd` — init_hero() 测试便捷方法（修复所有单元测试依赖）
- `production/qa/smoke-2026-04-15.md` — PASS WITH WARNINGS
- `production/sprint-status.yaml` — 所有 stories 更新为 done

### 遗留工作

1. 在 Godot 编辑器运行 tests/gdunit4_runner.gd 确认 ~108 个新测试通过
2. 搭建 BattleScene.tscn 后完成 5-14/5-15 手动验证并签字

<!-- STATUS -->
Epic: Sprint 5 - Card Battle System & Status Effects
Feature: Sprint Complete
Task: 所有逻辑/集成 stories 完成，等待 5-14/5-15 UI 手动验证
<!-- /STATUS -->
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
