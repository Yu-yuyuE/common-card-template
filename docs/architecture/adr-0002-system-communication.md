# ADR-0002: 系统间通信模式

## Status
Accepted

## Date
2026-04-08

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None — Signal API 未发生变化 |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略) — 本ADR依赖场景管理框架来定义系统层级 |
| **Enables** | 所有需要跨系统通信的 ADRs |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 是 Core 层通信基础，其他系统 ADRs 应在本 ADR 后编写 |

## Context

### Problem Statement
游戏包含 17 个系统，需要大量跨系统通信：
- 卡牌打出 → 通知战斗系统 → 计算伤害 → 通知 UI 显示
- 敌人行动 → 通知战斗系统 → 应用效果 → 通知状态系统
- 资源变化 → 通知 UI 更新显示
- 战斗结束 → 通知地图系统 → 返回导航

需要决定系统间通信的统一模式。

### Constraints
- **解耦**: 系统间应保持松耦合，便于单元测试
- **类型安全**: GDScript 4 支持强类型，应利用
- **性能**: 通信开销应最小化

### Requirements
- 必须支持一对一通知（如 卡牌→战斗）
- 必须支持一对多广播（如 资源变化→所有监听者）
- 必须支持数据传递（如 伤害值、目标）

## Decision

### 方案: 分层 Signal 通信模式

采用 **双层通信架构**：

```
┌─────────────────────────────────────────────────────────────┐
│                    系统间通信分层                            │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: Node Signal (主要)                                │
│    ─ 同一场景内相邻节点间的直接通信                          │
│    ─ 使用 Godot 原生 Signal                                 │
│    ─ 例: BattleScene.CardPlayed.connect(UI.on_card_played) │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: Global EventBus (辅助)                            │
│    ─ 跨场景的全局事件广播                                    │
│    ─ 用于 GameState 下的全局状态变化                         │
│    ─ 例: ResourceManager.resource_changed.emit()           │
└─────────────────────────────────────────────────────────────┘
```

### 核心设计原则

1. **优先使用 Node Signal**: 同一场景层级内，使用 Godot 原生 Signal
2. **EventBus 仅用于全局事件**: 跨场景、需要广播给未知数量监听者的事件
3. **避免直接引用**: 系统间不应持有其他系统的节点引用，通过 Signal 通信
4. **强类型 Signal**: 使用 GDScript 4 的类型化 Signal

### Signal 命名规范

```gdscript
# 命名格式: [subject]_[action]_[past_tense]
# 例:
signal card_played(card_id: String, target: int)
signal turn_ended(is_player_turn: bool)
signal resource_changed(resource_type: String, old_value: int, new_value: int)
signal battle_started(enemy_count: int, terrain: String)
signal battle_ended(victory: bool, rewards: Dictionary)
```

### EventBus 实现

```gdscript
# EventBus.gd (Autoload)
extends Node

# 资源变化信号
signal resource_changed(resource_type: String, old_value: int, new_value: int)

# 场景切换信号
signal scene_changed(scene_name: String)

# 游戏状态信号
signal game_paused(is_paused: bool)
signal game_over(victory: bool)

# 存档信号
signal save_requested(save_type: int)
signal load_completed(save_type: int)
```

### 使用示例

**场景内通信 (Node Signal)**:
```gdscript
# BattleScene.gd
func _ready():
    $CardHand.card_played.connect(_on_card_played)
    $EnemyManager.enemy_action_completed.connect(_on_enemy_action)

func _on_card_played(card_id: String, target: int):
    # 处理卡牌打出
    pass
```

**全局通信 (EventBus)**:
```gdscript
# ResourceManager.gd
func _ready():
    EventBus.resource_changed.connect(_on_global_resource_changed)

func modify_resource(type: String, delta: int):
    var old = resources[type]
    resources[type] = clamp(resources[type] + delta, 0, max_values[type])
    EventBus.resource_changed.emit(type, old, resources[type])
```

## Alternatives Considered

### Alternative 1: 纯直接方法调用
- **描述**: 系统间持有引用，直接调用方法
- **优点**:
  - 调用简单直接
  - 性能最高（无 Signal 中间层）
- **缺点**:
  - 强耦合，难以测试
  - 循环依赖风险
  - 一个系统变化影响多个调用者
- **未采用原因**: 耦合度过高，违反解耦原则

### Alternative 2: 纯 EventBus
- **描述**: 所有通信都通过中央 EventBus
- **优点**:
  - 完全解耦
  - 广播方便
- **缺点**:
  - 难以追踪数据流
  - 调试困难（不知道谁在监听）
  - 全局状态难以管理
- **未采用原因**: 过度工程化，失去 Godot 场景树的组织优势

### Alternative 3: 分层 Signal + EventBus (推荐方案)
- **描述**: 场景内用 Node Signal，全局用 EventBus
- **优点**:
  - 兼顾解耦和可追踪性
  - 利用 Godot 原生特性
  - 性能与可维护性平衡
- **采用原因**: 符合 Godot 最佳实践

## Consequences

### Positive
- **松耦合**: 系统通过 Signal 通信，不直接依赖
- **可测试**: 可以单独测试每个系统 mock Signal
- **可追踪**: Signal 连接明确，调试器可查看
- **类型安全**: GDScript 4 强类型 Signal

### Negative
- **学习曲线**: 团队需要理解 Signal 模式
- **连接管理**: 需要注意连接/断开时机

### Risks
- **Signal 泄漏**: 子场景销毁时未断开 Signal
  - **缓解**: 在子场景的 `_exit_tree()` 中断开连接
- **循环 Signal**: A→B→A 导致死循环
  - **缓解**: 设计审查时注意避免

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| card-battle-system.md (C2) | 手牌/费用/出牌/结算循环 | CardPlayed/TurnEnded 等 Signal |
| status-design.md (C1) | 20种状态效果 | StatusApplied/StatusRemoved Signal |
| enemies-design.md (C3) | 敌人行动序列 | EnemyActionCompleted Signal |
| resource-management-system.md (F2) | 4种资源管理 | ResourceChanged via EventBus |

## Performance Implications
- **CPU**: Signal 调用开销 < 0.01ms，可忽略
- **Memory**: 每个 Signal 连接约 32 字节
- **Signal vs Method Call**: 性能差异 < 5%，可忽略

## Migration Plan
1. 创建 EventBus.gd (Autoload)
2. 定义全局 Signal 列表
3. 各系统迁移到 Signal 通信
4. 添加连接管理规范

## Validation Criteria
- [ ] 场景内通信使用 Node Signal
- [ ] 全局事件使用 EventBus
- [ ] Signal 名称符合规范
- [ ] 子场景正确断开 Signal 连接

## Related Decisions
- ADR-0001 (已创建): 场景管理策略 — 提供了场景层级结构
- ADR-0003 (待创建): 资源变更通知机制 — 具体应用本 ADR
