# Story 003: 护盾生命周期管理

> **Epic**: 资源管理系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: 资源变更通知机制
**ADR Decision Summary**: 集中式ResourceManager管理护盾，通过Signal广播护盾变化。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 所有资源变化必须通过ResourceManager统一接口
- Required: 资源变化时必须触发resource_changed信号
- Forbidden: 禁止使用轮询检查方式监控资源变化

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md`, scoped to this story:*

- [ ] 护盾跨回合保留（战斗内回合切换时护盾值不变）
- [ ] 战斗结束后护盾值清零
- [ ] 护盾上限按武将类型决定：默认=MaxHP，曹仁=MaxHP+30，张角无上限
- [ ] 护盾值超出上限时丢弃超出部分

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. 护盾作为独立资源类型存储在ResourceManager中：
   ```gdscript
   resources[ResourceType.ARMOR] = 0
   max_values[ResourceType.ARMOR] = hero_max_armor  # 根据武将类型设置
   ```
2. 战斗内回合切换逻辑：
   - 回合开始时不重置护盾（与行动点不同）
   - 护盾值保留至上回合结束
3. 战斗结束清零：
   - BattleScene在battle_ended信号中调用：
   ```gdscript
   resource_manager.set_resource(ResourceType.ARMOR, 0)
   ```
4. 武将类型判断（从HeroManager读取武将ID）：
   - 曹仁（hero_id="cao_ren"）：max_armor = max_hp + 30
   - 张角（hero_id="zhang_jiao"）：max_armor = 999999（无上限）
   - 默认：max_armor = max_hp

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 护盾修改与伤害吸收
- Story 006: Boss战后恢复（仅恢复HP和粮草，不影响护盾）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 护盾跨回合保留
  - Given: 战斗中第1回合结束，护盾=15
  - When: 进入第2回合
  - Then: 护盾仍为15（不重置）
  - Edge cases: 护盾恰好为0

- **AC-2**: 战斗结束护盾清零
  - Given: 战斗中护盾=20
  - When: 战斗结束（胜利或失败）
  - Then: 护盾=0
  - Edge cases: 战斗结束前护盾已为0

- **AC-3**: 默认武将护盾上限
  - Given: 武将MaxHP=50（非曹仁、非张角）
  - When: ResourceManager初始化
  - Then: max_values[ARMOR] == 50
  - Edge cases: MaxHP边界值40和60

- **AC-4**: 曹仁护盾上限
  - Given: 武将=曹仁，MaxHP=50
  - When: ResourceManager初始化
  - Then: max_values[ARMOR] == 80
  - Edge cases: 曹仁MaxHP边界值

- **AC-5**: 张角护盾无上限
  - Given: 武将=张角
  - When: ResourceManager初始化
  - Then: max_values[ARMOR] == 999999（或特殊标记无上限）
  - Edge cases: 护盾值>999999时是否正确处理

- **AC-6**: 护盾超出上限丢弃
  - Given: 默认武将MaxHP=50，当前护盾=0
  - When: 获得60护盾（modify_resource(ARMOR, +60)）
  - Then: 护盾=50（超出10丢弃）
  - Edge cases: 护盾恰好等于上限

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/resource_management/armor_lifecycle_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（ResourceManager初始化），Story 002（护盾修改接口）
- Unlocks: 无（护盾生命周期是独立功能）
