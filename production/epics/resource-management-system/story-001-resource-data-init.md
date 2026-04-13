# Story 001: 资源数据结构初始化

Epic: 资源管理系统
Estimate: 1 day
Status: Done
Layer: Foundation
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-001`, `TR-resource-management-system-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: 资源变更通知机制
**ADR Decision Summary**: 采用集中式ResourceManager + Signal广播模式，所有资源变化通过统一接口触发resource_changed信号。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须采用集中式资源管理+Signal广播模式
- Required: 必须使用强类型Signal: `signal resource_changed(resource_type: String, old_value: int, new_value: int, delta: int)`
- Forbidden: 禁止使用轮询检查方式监控资源变化

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md`, scoped to this story:*

- [x] 初始化HP范围40-60（武将个体差异），当前值=武将MaxHP
- [x] 初始化粮草上限150，当前值=150
- [x] 初始化金币为0，上限99999
- [x] 初始化行动点=武将基础行动点(3-4)，上限=武将基础行动点
- [x] ResourceManager作为GameState子节点，在_ready()中初始化所有资源

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

1. 创建 `ResourceManager.gd` 作为 GameState 的子节点
2. 定义ResourceType枚举：HP, PROVISIONS, GOLD, ACTION_POINTS
3. 使用Dictionary存储当前值和上限值：
   ```gdscript
   var resources: Dictionary = {}
   var max_values: Dictionary = {}
   ```
4. 在_ready()中从HeroManager读取武将MaxHP和基础行动点进行初始化
5. 所有资源初始值必须在合法范围内（clamp to [0, max]）

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 资源修改逻辑（modify_resource接口）
- Story 003: 护盾生命周期管理
- Story 007: UI响应资源变化

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: HP初始化
  - Given: 武将MaxHP=50（从HeroManager读取）
  - When: ResourceManager初始化
  - Then: resources[HP] == 50, max_values[HP] == 50
  - Edge cases: MaxHP边界值40和60

- **AC-2**: 粮草初始化
  - Given: 武将选择完成
  - When: ResourceManager初始化
  - Then: resources[PROVISIONS] == 150, max_values[PROVISIONS] == 150
  - Edge cases: 确保上限固定为150

- **AC-3**: 金币初始化
  - Given: 武将选择完成
  - When: ResourceManager初始化
  - Then: resources[GOLD] == 0, max_values[GOLD] == 99999
  - Edge cases: 无

- **AC-4**: 行动点初始化
  - Given: 武将基础行动点=4
  - When: ResourceManager初始化
  - Then: resources[ACTION_POINTS] == 4, max_values[ACTION_POINTS] == 4
  - Edge cases: 基础行动点边界值3和4

- **AC-5**: GameState子节点
  - Given: GameState场景已加载
  - When: 场景进入_ready()
  - Then: GameState包含名为"ResourceManager"的子节点
  - Edge cases: 确保节点命名正确

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/resource_management/resource_data_init_test.gd` — must exist and pass

**Status**: [x] All tests pass — `tests/unit/resource_management/resource_data_init_test.gd`

---

## Dependencies

- Depends on: HeroManager提供武将基础属性（MaxHP、基础行动点）
- Unlocks: Story 002（资源修改逻辑依赖此初始化）
