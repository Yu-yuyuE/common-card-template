# Story 004: 行动点累积与消耗

Epic: 资源管理系统
Estimate: 1 day
Status: Ready
Layer: Foundation
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: 资源变更通知机制
**ADR Decision Summary**: 所有资源变化通过modify_resource()统一接口，触发resource_changed信号。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 所有资源变化必须通过ResourceManager统一接口
- Required: 资源变化时必须触发resource_changed信号
- Forbidden: 禁止使用轮询检查方式监控资源变化

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md`, scoped to this story:*

- [ ] 行动点在本回合剩余量保留至下回合；累积值不超过武将上限
- [ ] X费卡以打出时实际行动点为X，打出后行动点归零
- [ ] 每回合开始时不自动补充行动点（上回合剩余保留）
- [ ] 卡牌效果增加的行动点上限仅本战有效；装备效果可累积到下场战斗

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. 行动点累积逻辑（F2公式）：
   ```gdscript
   var max_ap = hero_base_ap + equipment_bonus  # 装备效果跨战斗累积
   var ap_next_round = min(max_ap, previous_remaining_ap)
   resources[ACTION_POINTS] = ap_next_round
   ```

2. X费卡逻辑（F3公式）：
   ```gdscript
   func play_x_cost_card():
       var x = resources[ACTION_POINTS]  # 打出时当前全部行动点
       # 使用X执行卡牌效果
       resources[ACTION_POINTS] = 0
       resource_changed.emit(ACTION_POINTS, old_value, 0, -old_value)
   ```

3. 回合开始处理：
   - BattleScene在turn_started信号中调用：
   ```gdscript
   resource_manager.preserve_action_points()
   ```

4. 卡牌/装备效果区分：
   - 卡牌效果：临时上限 `temp_max_ap_bonus`，战斗结束清零
   - 装备效果：`equipment_bonus`，持久化到存档

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 行动点初始化
- Story 006: 资源恢复机制（包含卡牌增加行动点上限）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 行动点跨回合保留
  - Given: 武将基础AP=4，第1回合剩余AP=2
  - When: 第2回合开始
  - Then: 行动点=2（不自动补充）
  - Edge cases: 前回合已用完（剩余AP=0）

- **AC-2**: 行动点累积不超过上限
  - Given: 武将基础AP=3，装备增加+1AP上限，第1回合剩余AP=4
  - When: 第2回合开始
  - Then: 行动点=4（不超过MaxAP=4）
  - Edge cases: 前回合剩余=MaxAP

- **AC-3**: X费卡逻辑
  - Given: 当前行动点=3
  - When: 打出X费卡
  - Then: 卡牌效果X=3，行动点变为0
  - Edge cases: 当前行动点=0（X=0）

- **AC-4**: 每回合不自动补充
  - Given: 第1回合花费5点行动点（初始全消耗）
  - When: 第2回合开始
  - Then: 行动点=0（不自动回满）
  - Edge cases: 确认未调用回满逻辑

- **AC-5**: 装备效果跨战斗累积
  - Given: 武将基础AP=3，装备+1AP
  - When: 当前战斗结束，进入下一场战斗
  - Then: MaxAP=4（装备效果保留）
  - Edge cases: 多个AP装备叠加

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/resource_management/action_points_accumulation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（ResourceManager初始化）
- Unlocks: Story 006（资源恢复机制）
