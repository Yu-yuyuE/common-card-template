# Story 006: 资源恢复机制

Epic: 资源管理系统
Estimate: 1 day
Status: Ready
Layer: Foundation
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-001`, `TR-resource-management-system-002`
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

- [ ] Boss战胜后恢复50粮草，上限150
- [ ] 大地图切换时粮草重置为150
- [ ] Boss战胜后HP完全恢复
- [ ] HP恢复来源（酒馆/卡牌/事件）不超过武将HP上限
- [ ] 粮草恢复上限150（超出部分丢弃）

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. Boss战胜后恢复逻辑：
   ```gdscript
   func on_boss_defeated():
       # HP完全恢复
       resource_manager.set_resource(ResourceType.HP, hero_max_hp)
       
       # 粮草恢复50，上限150
       var new_provisions = min(150, resource_manager.get_resource(ResourceType.PROVISIONS) + 50)
       resource_manager.set_resource(ResourceType.PROVISIONS, new_provisions)
   ```

2. 大地图切换恢复逻辑：
   ```gdscript
   func on_new_map():
       # 粮草重置为150
       resource_manager.set_resource(ResourceType.PROVISIONS, 150)
       # HP保留（已由Boss战恢复或延续）
   ```

3. HP恢复上限检查（F7）：
   ```gdscript
   func restore_hp(amount: int):
       var new_hp = min(max_values[HP], resources[HP] + amount)
       resource_manager.set_resource(ResourceType.HP, new_hp)
   ```

4. 粮草恢复上限检查（F6）：
   ```gdscript
   func restore_provisions(amount: int):
       var new_provisions = min(max_values[PROVISIONS], resources[PROVISIONS] + amount)
       resource_manager.set_resource(ResourceType.PROVISIONS, new_provisions)
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 初始值设置
- Story 005: 粮草消耗
- Story 002: HP修改（恢复是修改的特例）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: Boss战后HP完全恢复
  - Given: 当前HP=30，MaxHP=50
  - When: Boss被击败
  - Then: HP=50（完全恢复）
  - Edge cases: 当前HP已满（50）

- **AC-2**: Boss战后粮草恢复
  - Given: 粮草=80
  - When: Boss被击败
  - Then: 粮草=130（80+50）
  - Edge cases: 粮草=140，恢复50后=150（上限）

- **AC-3**: 粮草恢复上限丢弃
  - Given: 粮草=145
  - When: Boss被击败（+50）
  - Then: 粮草=150（超出5丢弃）
  - Edge cases: 粮草=150，恢复任何值都不增加

- **AC-4**: 大地图切换粮草重置
  - Given: 粮草=100
  - When: 进入新地图
  - Then: 粮草=150
  - Edge cases: 粮草=0，切换后=150

- **AC-5**: HP恢复上限
  - Given: MaxHP=50，当前HP=45
  - When: 恢复10HP（酒馆/卡牌）
  - Then: HP=50（不超上限）
  - Edge cases: 恢复值=6，HP=50

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/resource_management/resource_recovery_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（ResourceManager初始化），Story 005（粮草消耗）
- Unlocks: 无（独立功能）
