# ADR-0003: 资源变更通知机制

## Status
Proposed

## Date
2026-04-08

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0002 (系统间通信模式) |
| **Enables** | UI层资源显示更新、成就系统、战斗结算 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 依赖 ADR-0002 的通信模式，应在其后编写 |

## Context

### Problem Statement
游戏有4种资源需要管理：
- **HP (40-60)**: 生命值，战斗核心资源
- **粮草 (0-150)**: 地图移动消耗
- **金币**: 商店购买
- **行动点**: 每回合行动次数

问题：当资源变化时，如何通知需要知道的系统？
- UI 需要更新显示
- 战斗系统需要检查是否战败
- 成就系统需要检查是否达成
- 事件系统可能触发特定条件

### Constraints
- **性能**: 资源变化频繁，不能有太大开销
- **一致性**: 所有资源变化必须通过统一接口
- **可追踪**: 便于调试和日志

### Requirements
- 任何资源变化必须触发通知
- 通知必须携带旧值、新值、变化量
- 监听者可以过滤关注的具体资源类型

## Decision

### 方案: 统一 ResourceManager + EventBus Signal

采用 **集中式资源管理 + Signal 广播** 模式：

```gdscript
# ResourceManager.gd (GameState 子节点)
extends Node

signal resource_changed(resource_type: String, old_value: int, new_value: int, delta: int)

enum ResourceType { HP, PROVISIONS, GOLD, ACTION_POINTS }

var resources: Dictionary = {
    ResourceType.HP: 50,
    ResourceType.PROVISIONS: 100,
    ResourceType.GOLD: 0,
    ResourceType.ACTION_POINTS: 3
}

var max_values: Dictionary = {
    ResourceType.HP: 60,
    ResourceType.PROVISIONS: 150,
    ResourceType.GOLD: 99999,
    ResourceType.ACTION_POINTS: 6
}

func modify_resource(type: ResourceType, delta: int, allow_overflow: bool = false) -> bool:
    var old = resources[type]
    var new_val = resources[type] + delta

    if not allow_overflow:
        new_val = clamp(new_val, 0, max_values[type])
    else:
        new_val = max(0, new_val)

    resources[type] = new_val

    # 发出通知
    resource_changed.emit(type, old, new_val, delta)
    return true

func get_resource(type: ResourceType) -> int:
    return resources[type]

func set_resource(type: ResourceType, value: int):
    var old = resources[type]
    resources[type] = clamp(value, 0, max_values[type])
    resource_changed.emit(type, old, resources[type], resources[type] - old)
```

### 使用方式

```gdscript
# UI 层订阅
func _ready():
    EventBus.resource_changed.connect(_on_resource_changed)

func _on_resource_changed(type, old_val, new_val, delta):
    match type:
        ResourceManager.ResourceType.HP:
            $HUD/HealthBar.value = new_val
            if new_val <= 0:
                trigger_game_over()
        ResourceManager.ResourceType.GOLD:
            $HUD/GoldLabel.text = str(new_val)

# 战斗系统订阅
func _ready():
    EventBus.resource_changed.connect(_on_resource_changed)

func _on_resource_changed(type, old_val, new_val, delta):
    if type == ResourceManager.ResourceType.HP and new_val <= 0:
        end_battle(victory = false)
```

### Signal 参数设计

| 参数 | 类型 | 说明 |
|------|------|------|
| `resource_type` | String/Enum | 资源类型 (HP/粮草/金币/行动点) |
| `old_value` | int | 变化前数值 |
| `new_value` | int | 变化后数值 |
| `delta` | int | 变化量 (可正可负) |

这种设计让监听者可以：
- 知道发生了什么变化
- 计算变化后的状态
- 知道变化了多少（用于显示动画等）

## Alternatives Considered

### Alternative 1: 轮询检查
- **描述**: 在 UI 的 `_process` 中每帧检查资源值
- **优点**:
  - 实现简单
  - 不需要了解 Signal
- **缺点**:
  - 性能浪费（每帧检查不变化的值）
  - 响应延迟（最大一帧）
  - 难以追踪变化来源
- **未采用原因**: 性能差，不符合事件驱动原则

### Alternative 2: 方法回调
- **描述**: 资源变化时调用各系统的回调方法
- **优点**:
  - 调用明确
  - 性能好
- **缺点**:
  - 强耦合（ResourceManager 需要知道所有回调者）
  - 难以动态添加/移除监听者
  - 违反 ADR-0002 的 Signal 通信原则
- **未采用原因**: 耦合度过高

### Alternative 3: Signal 驱动 (推荐方案)
- **描述**: 资源变化时 emit Signal，监听者订阅
- **优点**:
  - 完全解耦
  - 性能好（仅在变化时触发）
  - 符合 ADR-0002 的通信模式
  - 易于调试（Signal 可在编辑器查看）
- **采用原因**: 解耦最佳，与 ADR-0002 一致

## Consequences

### Positive
- **完全解耦**: ResourceManager 不需要知道谁在监听
- **性能好**: 仅在变化时触发，无轮询开销
- **可追踪**: Signal 可以在调试器查看连接
- **一致性好**: 所有资源变化走同一接口

### Negative
- **需要连接管理**: 确保不再需要时断开连接

### Risks
- **Signal 泄漏**: 监听者未断开连接导致内存泄漏
  - **缓解**: 在 `_exit_tree()` 中断开连接
- **过度通知**: 连续变化触发大量 Signal
  - **缓解**: 变化累积到下一帧处理（可选优化）

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| resource-management-system.md (F2) | HP(40-60), 粮草(0-150), 行动点, 金币 | 统一的 modify_resource() 接口 + Signal |
| card-battle-system.md (C2) | 战斗资源管理 | 通过 Signal 监听资源变化 |
| heroes-design.md (D3) | 武将HP管理 | 通过 Signal 更新UI |

## Performance Implications
- **CPU**: Signal emit 开销 < 0.001ms，可忽略
- **Memory**: 每个监听者一个 Signal 连接，约 32 字节

## Migration Plan
1. 创建 ResourceManager.gd 脚本
2. 实现 modify_resource() 和 Signal
3. 注册到 EventBus
4. UI 层添加监听连接
5. 各系统迁移到 Signal 监听

## Validation Criteria
- [ ] 资源变化时 EventBus.resource_changed Signal 被触发
- [ ] Signal 携带正确的 old/new/delta 值
- [ ] UI 正确响应资源变化
- [ ] 监听者在销毁时正确断开连接

## Related Decisions
- ADR-0001 (已创建): 场景管理策略
- ADR-0002 (已创建): 系统间通信模式
