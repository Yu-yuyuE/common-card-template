# ADR-0015: 敌人AI行动序列执行器

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / AI |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — standard Array/Dictionary operations |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0002 (系统间通信模式), ADR-0003 (资源变更通知机制), ADR-0006 (兵种卡地形联动计算顺序) |
| **Enables** | 敌人战斗行为、卡牌战斗系统 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 依赖伤害计算 ADR-0006，应在其后编写 |

## Context

### Problem Statement
游戏包含100名敌人(E001-E100)，每名敌人有独特的行动模式。敌人行动涉及：
1. **行动队列**: 每回合敌人按队列顺序执行行动
2. **条件触发**: 根据血量、位置、状态效果触发不同行动
3. **随机性**: 部分行动有随机目标或随机效果
4. **间隔执行**: 敌人行动之间需要视觉间隔（0.5-1秒）

需要设计一个可扩展的敌人AI执行架构。

### Constraints
- **响应性**: 玩家能看到敌人行动的准备和执行过程
- **可预测性**: 相同条件下同一敌人应做出相同决策
- **可调试**: 能查看敌人的行动决策过程
- **性能**: 单次决策 < 1ms

### Requirements
- 敌人行动必须支持条件触发（如HP<50%触发特定行动）
- 敌人行动必须支持随机选择（如随机目标）
- 敌人行动之间必须有视觉间隔
- 敌人行动可以被打断或延迟

## Decision

### 方案: 行动序列执行器 + 决策树模式 (Action Queue Executor + Decision Tree)

采用 **决策树 → 行动队列 → 顺序执行** 的三层架构：

```
敌人AI架构:
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: 决策层 (Decision Tree)                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ EnemyAIbrain.gd                                     │   │
│  │ - evaluate_conditions() → 选择最佳行动              │   │
│  │ - 条件: HP阈值、卡牌数量、位置、状态效果            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: 行动队列层 (Action Queue)                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ActionQueue.gd                                      │   │
│  │ - add_action() → 加入队列                           │   │
│  │ - execute_next() → 取出执行                         │   │
│  │ - execute_all() → 全部执行                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: 执行器层 (Action Executor)                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ActionExecutor.gd                                   │   │
│  │ - execute_with_interval() → 带间隔执行              │   │
│  │ - play_animation() → 播放动画                       │   │
│  │ - apply_effect() → 应用效果                         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 敌人行动类型定义

```gdscript
# enemy_action.gd
class_name EnemyAction extends RefCounted

enum ActionType {
    ATTACK,          # 攻击玩家
    DEFEND,          # 防御姿态
    BUFF_SELF,       # 强化自身
    DEBUFF_PLAYER,   # 减益玩家
    DRAW_CARD,       # 抽卡
    SPECIAL          # 特殊行动
}

enum TargetType {
    PLAYER,          # 玩家本人
    RANDOM_CARD,     # 随机手牌
    ALL_ENEMIES,     # 所有敌人
    SELF             # 自身
}

# 行动数据结构
class Action extends RefCounted:
    var type: ActionType
    var target_type: TargetType
    var base_damage: int = 0
    var condition: Callable  # 条件函数
    var priority: int = 0    # 优先级（高优先执行）
    var animation: String    # 动画名称

# 示例敌人行动配置
const ENEMY_001_ACTIONS = [
    # 行动1: 普通攻击（总是执行）
    Action.new(
        ActionType.ATTACK,
        TargetType.PLAYER,
        5,  # 伤害
        func(): return true,  # 无条件
        10,
        "attack_slash"
    ),
    # 行动2: 当HP<50%时，使用强力攻击
    Action.new(
        ActionType.ATTACK,
        TargetType.PLAYER,
        10,
        func(enemy): return enemy.current_hp < enemy.max_hp * 0.5,
        20,  # 高优先级
        "attack_powerful"
    ),
    # 行动3: 当手牌>3张时，抽卡
    Action.new(
        ActionType.DRAW_CARD,
        TargetType.SELF,
        0,
        func(enemy): return enemy.hand_size > 3,
        5,
        "draw_card"
    )
]
```

### 决策树实现

```gdscript
# enemy_ai_brain.gd
class_name EnemyAIBrain extends Node

func evaluate_actions(enemy: Enemy) -> Array[EnemyAction]:
    var available_actions: Array[EnemyAction] = []
    var all_actions = _get_enemy_actions(enemy.enemy_id)

    # 筛选满足条件的行动
    for action in all_actions:
        if action.condition.call(enemy):
            available_actions.append(action)

    # 按优先级排序
    available_actions.sort_custom(func(a, b): return a.priority > b.priority)

    return available_actions

func _get_enemy_actions(enemy_id: String) -> Array[EnemyAction]:
    # 从配置中加载敌人行动
    match enemy_id:
        "E001": return ENEMY_001_ACTIONS
        "E002": return ENEMY_002_ACTIONS
        # ... 共100个敌人
    return []

func select_primary_action(enemy: Enemy) -> EnemyAction:
    var available = evaluate_actions(enemy)
    if available.size() == 0:
        return _get_default_action(enemy)
    # 选择最高优先级的行动
    return available[0]
```

### 行动队列执行器

```gdscript
# enemy_action_queue.gd
class_name EnemyActionQueue extends Node

signal action_started(action: EnemyAction)
signal action_completed(action: EnemyAction)
signal all_actions_completed()

var queue: Array[EnemyAction] = []
var current_executor: Node = null

func add_action(action: EnemyAction):
    queue.append(action)

func execute_all(interval: float = 0.8):
    var index = 0

    func _execute_next():
        if index >= queue.size():
            all_actions_completed.emit()
            return

        var action = queue[index]
        index += 1
        action_started.emit(action)

        # 执行行动
        await _execute_single_action(action)

        # 等待间隔后执行下一个
        await get_tree().create_timer(interval).timeout
        _execute_next()

    _execute_next()

func _execute_single_action(action: EnemyAction):
    # 1. 播放动画
    if action.animation != "":
        await _play_animation(action.animation)

    # 2. 应用效果
    match action.type:
        ActionType.ATTACK:
            _apply_attack(action)
        ActionType.DEFEND:
            _apply_defend(action)
        ActionType.BUFF_SELF:
            _apply_buff_self(action)
        # ... 其他类型

    action_completed.emit(action)

func _apply_attack(action: EnemyAction):
    var damage = action.base_damage
    # 应用地形/天气修正（调用 ADR-0006 的 DamageCalculator）
    damage = DamageCalculator.calculate_damage(
        damage,
        "enemy",
        BattleField.current_terrain,
        BattleField.current_weather,
        []
    )
    # 造成伤害
    PlayerSystem.take_damage(damage)
```

### 敌人回合执行流程

```gdscript
# enemy_turn_manager.gd
class_name EnemyTurnManager extends Node

@onready var ai_brain = EnemyAIBrain.new()
@onready var action_queue = EnemyActionQueue.new()

func execute_enemy_turn(enemies: Array[Enemy]):
    for enemy in enemies:
        # 1. AI 决策
        var action = ai_brain.select_primary_action(enemy)

        # 2. 加入行动队列
        action_queue.add_action(action)

    # 3. 依次执行所有行动
    await action_queue.execute_all(interval: 0.8)

    # 4. 回合结束
    SignalBus.enemy_turn_ended.emit()
```

## Alternatives Considered

### Alternative 1: 纯随机行动
- **描述**: 敌人随机选择行动
- **优点**: 实现简单
- **缺点**: 缺乏策略性，战斗无聊
- **未采用原因**: 不符合游戏设计要求

### Alternative 2: 硬编码状态机
- **描述**: 使用状态机硬编码敌人行为
- **优点**: 控制精确
- **缺点**: 100个敌人需要100个状态机，难以维护
- **未采用原因**: 扩展性差

### Alternative 3: 决策树 + 队列执行器 (推荐方案)
- **描述**: 条件驱动决策，队列顺序执行
- **优点**: 数据驱动、易扩展、可调试
- **采用原因**: 符合行业标准，平衡复杂度与灵活性

## Consequences

### Positive
- **数据驱动**: 新增敌人只需添加行动配置，无需修改代码
- **可调试**: 可查看决策过程和执行日志
- **可扩展**: 新行动类型只需添加 case
- **玩家友好**: 行动间隔让玩家能跟上战斗节奏

### Negative
- **配置复杂**: 需要为100个敌人配置行动数据
- **调试困难**: 条件触发问题难以复现

### Risks
- **配置错误**: 敌人行动配置错误导致AI异常
  - **缓解**: 启动时校验所有行动配置完整性
- **死循环**: 条件函数可能导致无限行动
  - **缓解**: 每个敌人最多执行3个行动

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| enemies-design.md (C3) | 100名敌人, 71种行动 | 决策树支持条件触发和优先级 |
| enemies-design.md (C3) | 行动队列 | ActionQueue 按序执行 |
| enemies-design.md (C3) | 敌人行动间隔 | execute_all() 带 interval 参数 |
| card-battle-system.md (C2) | 敌人回合流程 | EnemyTurnManager 统一管理 |

## Performance Implications
- **CPU**: 单次决策 < 0.1ms（简单条件判断）
- **Memory**: 每敌人约 1KB 行动配置
- **网络**: 无网络开销，纯本地计算

## Migration Plan
1. 创建 EnemyAction 数据类
2. 创建 EnemyAIBrain 决策类
3. 创建 EnemyActionQueue 执行器
4. 实现100个敌人的行动配置
5. 集成到 CardBattleSystem
6. 添加调试日志

## Validation Criteria
- [ ] 条件触发正确（测试各阈值条件）
- [ ] 优先级排序正确（高优先级先执行）
- [ ] 行动间隔正确（0.5-1秒可配置）
- [ ] 所有71种行动类型可执行
- [ ] 敌人行动日志正确输出

## Related Decisions
- ADR-0001: 场景管理策略 — 战斗场景结构
- ADR-0002: 系统间通信模式 — Signal 通信
- ADR-0003: 资源变更通知机制 — 敌人伤害通知
- ADR-0006: 兵种卡地形联动计算顺序 — 敌人伤害计算