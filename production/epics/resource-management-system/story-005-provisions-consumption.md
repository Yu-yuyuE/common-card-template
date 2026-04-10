# Story 005: 粮草消耗与归零惩罚

> **Epic**: 资源管理系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: 资源变更通知机制
**ADR Decision Summary**: 集中式ResourceManager管理所有资源，通过Signal广播变化。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 所有资源变化必须通过ResourceManager统一接口
- Required: 资源变化时必须触发resource_changed信号
- Forbidden: 禁止使用轮询检查方式监控资源变化

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md`, scoped to this story:*

- [ ] 粮草移动消耗在地图绘制时确定并固定，与战斗结果无关
- [ ] 粮草归零时，HP 替代粮草支付移动代价；HP 耗尽则游戏结束
- [ ] 粮草移动消耗为2–8（早期节点2–6，后期节点4–8）
- [ ] 粮草归零时恰好为0不触发HP惩罚

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. 粮草移动消耗逻辑（F4公式）：
   ```gdscript
   func move_to_node(node: MapNode):
       var food_cost = node.move_cost  # 2-8，由地图绘制时随机生成
       if resource_manager.get_resource(ResourceType.PROVISIONS) < food_cost:
           # 粮草不足，触发HP惩罚
           var hp_cost = food_cost - resource_manager.get_resource(ResourceType.PROVISIONS)
           var new_hp = resource_manager.get_resource(ResourceType.HP) - hp_cost
           if new_hp <= 0:
               EventBus.game_over.emit(false)
               return false
           else:
               resource_manager.modify_resource(ResourceType.HP, -hp_cost)
       resource_manager.modify_resource(ResourceType.PROVISIONS, -food_cost)
       return true
   ```

2. 粮草消耗触发Signal：
   - 调用 `modify_resource(PROVISIONS, -cost)` 会自动触发resource_changed信号

3. 地图节点消耗值：
   - 早期节点（前50%）：move_cost ∈ [2,6]
   - 后期节点（后50%）：move_cost ∈ [4,8]
   - 由MapGraph在生成时随机赋值，持久化到节点数据中

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 粮草初始化（上限150）
- Story 006: Boss战后粮草奖励
- Story 007: UI粮草显示

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 粮草消耗触发
  - Given: 粮草=100，节点消耗=5
  - When: 调用move_to_node()
  - Then: 粮草=95，触发resource_changed(PROVISIONS, 100, 95, -5)
  - Edge cases: 消耗值=0（不可能，但应处理）

- **AC-2**: 粮草归零触发HP惩罚
  - Given: 粮草=5，节点消耗=8
  - When: 调用move_to_node()
  - Then: 粮草=0，HP减少3，触发resource_changed(HP, old_hp, new_hp, -3)
  - Edge cases: 粮草=1，消耗=2

- **AC-3**: HP耗尽触发游戏结束
  - Given: HP=2，粮草=1，节点消耗=8
  - When: 调用move_to_node()
  - Then: HP=0，触发EventBus.game_over(false)
  - Edge cases: HP=1，消耗=9

- **AC-4**: 粮草恰好归零
  - Given: 粮草=5，节点消耗=5
  - When: 调用move_to_node()
  - Then: 粮草=0，HP不变，不触发game_over
  - Edge cases: 粮草=0，消耗=0（不可能）

- **AC-5**: 早期/后期节点消耗
  - Given: 节点在地图前50%位置
  - When: 地图生成时
  - Then: node.move_cost ∈ [2,6]
  - Edge cases: 节点在后50%位置，消耗∈[4,8]

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/resource_management/provisions_consumption_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（ResourceManager初始化）
- Unlocks: Story 006（资源恢复机制）
