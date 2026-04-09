# ADR-0016: UI数据绑定方案

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Presentation / UI |
| **Knowledge Risk** | MEDIUM |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, Godot 4.x Control nodes |
| **Post-Cutoff APIs Used** | None — standard Control node API |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (系统间通信模式), ADR-0003 (资源变更通知机制) |
| **Enables** | 所有 UI 界面更新 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 依赖 Signal 通信模式 ADR-0002 |

## Context

### Problem Statement
游戏有大量需要动态更新的 UI 元素：
- **资源显示**: HP、粮草、金币、行动点
- **手牌区域**: 玩家手牌数量、内容、费用显示
- **战斗信息**: 敌人血量、状态图标、伤害数字
- **地图信息**: 节点状态、进度显示
- **商店/酒馆**: 商品列表、价格、可购买状态

需要一种机制，让 UI 自动响应游戏数据变化，避免手动刷新。

### Constraints
- **解耦**: UI 代码不应直接访问游戏逻辑
- **响应式**: 数据变化时 UI 自动更新
- **性能**: 频繁更新不能导致卡顿
- **Godot 原生**: 使用 Godot 的 Control 节点和 Signal

### Requirements
- UI 必须响应资源变化（HP、金币等）
- UI 必须响应卡牌变化（手牌、弃牌堆）
- UI 必须响应战斗状态变化（敌人血量、状态）
- UI 必须响应地图节点变化

## Decision

### 方案: Signal 驱动 + 自动绑定 (Signal-Driven Auto-Binding)

采用 **数据变化 → Signal 广播 → UI 订阅更新** 的响应式模式：

```
UI 数据绑定流程:
┌─────────────────────────────────────────────────────────────┐
│  数据层 (Data Layer)                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ResourceManager                                      │   │
│  │ - modify_resource() → resource_changed.emit()       │   │
│  │                                                      │   │
│  │ CardBattleSystem                                     │   │
│  │ - play_card() → card_played.emit()                  │   │
│  │ - end_turn() → turn_ended.emit()                    │   │
│  │                                                      │   │
│  │ EnemySystem                                          │   │
│  │ - take_damage() → enemy_damaged.emit()              │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ Signal
┌─────────────────────────────────────────────────────────────┐
│  绑定层 (Binding Layer)                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ UIBinder.gd (Autoload)                              │   │
│  │ - connect_signal(source, signal, target, method)   │   │
│  │ - 自动连接 Signal 到 UI 更新方法                    │   │
│  │ - 支持一对一、一对多绑定                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  UI 层 (Presentation Layer)                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ HUD (Control)                                        │   │
│  │ ├── HealthBar ←→ resource_changed(HP)              │   │
│  │ ├── GoldLabel ←→ resource_changed(GOLD)            │   │
│  │ ├── ProvisionsLabel ←→ resource_changed(PROV)      │   │
│  │                                                      │   │
│  │ HandPanel (Control)                                 │   │
│  │ ├── CardSlot[] ←→ hand_changed                     │   │
│  │                                                      │   │
│  │ EnemyPanel (Control)                                │   │
│  │ ├── EnemyHealthBar[] ←→ enemy_damaged              │   │
│  │ └── StatusIcon[] ←→ status_applied                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 核心 UIBinder 实现

```gdscript
# ui_binder.gd (Autoload)
extends Node

# 单例绑定映射
var _bindings: Dictionary = {}

# 绑定配置数据结构
class Binding extends RefCounted:
    var source: Object           # 信号源对象
    var signal_name: String      # 信号名称
    var target: Object           # 目标对象（UI）
    var method_name: String      # 目标方法
    var bound_data: Variant      # 额外数据（如资源类型）

func _ready():
    # 自动注册全局信号绑定
    _setup_global_bindings()

func _setup_global_bindings():
    # 资源变化 → HUD
    _bind(
        ResourceManager,
        "resource_changed",
        $HUD,
        "_on_resource_changed"
    )

    # 手牌变化 → HandPanel
    _bind(
        CardBattleSystem,
        "hand_changed",
        $HUD/HandPanel,
        "_on_hand_changed"
    )

    # 敌人血量变化 → EnemyPanel
    _bind(
        EnemySystem,
        "enemy_damaged",
        $HUD/EnemyPanel,
        "_on_enemy_damaged"
    )

    # 战斗开始/结束 → 场景切换
    _bind(
        CardBattleSystem,
        "battle_started",
        self,
        "_on_battle_started"
    )

# 绑定方法
func _bind(
    source: Object,
    signal_name: String,
    target: Object,
    method_name: String,
    bound_data: Variant = null
):
    var binding = Binding.new()
    binding.source = source
    binding.signal_name = signal_name
    binding.target = target
    binding.method_name = method_name
    binding.bound_data = bound_data

    # 检查信号是否存在
    if not source.has_signal(signal_name):
        push_warning("[UIBinder] Signal not found: %s on %s" % [signal_name, source])
        return

    # 连接信号
    var bound_method = func(...args):
        target.call(method_name, args, bound_data)

    source.connect(signal_name, bound_method)

    # 记录绑定（用于调试）
    var key = "%s.%s -> %s.%s" % [source, signal_name, target, method_name]
    _bindings[key] = binding

# 断开绑定
func _unbind(
    source: Object,
    signal_name: String,
    target: Object,
    method_name: String
):
    var key = "%s.%s -> %s.%s" % [source, signal_name, target, method_name]
    if _bindings.has(key):
        source.disconnect(signal_name, _bindings[key])
        _bindings.erase(key)
```

### UI 更新方法示例

```gdscript
# hud.gd
class_name HUD extends Control

@onready var health_bar = $HealthBar
@onready var gold_label = $GoldLabel
@onready var provisions_label = $ProvisionsLabel
@onready var action_points_label = $ActionPointsLabel
@onready var hand_panel = $HandPanel
@onready var enemy_panel = $EnemyPanel

# === 资源更新 ===

func _on_resource_changed(args: Array, bound_data):
    var resource_type = args[0]  # 资源类型
    var new_value = args[2]      # 新值

    match resource_type:
        ResourceManager.ResourceType.HP:
            _update_health(new_value)
        ResourceManager.ResourceType.GOLD:
            _update_gold(new_value)
        ResourceManager.ResourceType.PROVISIONS:
            _update_provisions(new_value)
        ResourceManager.ResourceType.ACTION_POINTS:
            _update_action_points(new_value)

func _update_health(value: int):
    var max_hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP, true)
    health_bar.max_value = max_hp
    health_bar.value = value

    # 血量变化动画
    if value < max_hp * 0.3:
        health_bar.modulate = Color.RED
    else:
        health_bar.modulate = Color.WHITE

func _update_gold(value: int):
    gold_label.text = "金: %d" % value

func _update_provisions(value: int):
    provisions_label.text = "粮: %d" % value

func _update_action_points(value: int):
    action_points_label.text = "行动: %d" % value

# === 手牌更新 ===

func _on_hand_changed(args: Array):
    var hand = args[0] as Array
    hand_panel.update_cards(hand)

# === 敌人更新 ===

func _on_enemy_damaged(args: Array):
    var enemy_id = args[0]
    var new_hp = args[1]
    enemy_panel.update_enemy_health(enemy_id, new_hp)
```

### 特定场景绑定配置

```gdscript
# battle_hud_binder.gd
class_name BattleHUDBinder extends Node

func setup_battle_ui():
    var battle_system = get_tree().get_first_node_in_group("battle_system")

    # 战斗专用绑定
    UIBinder._bind(
        battle_system,
        "card_played",
        $BattleHUD/CardPlayedFeedback,
        "_on_card_played"
    )

    UIBinder._bind(
        battle_system,
        "turn_ended",
        $BattleHUD,
        "_on_turn_ended"
    )

    UIBinder._bind(
        EnemySystem,
        "enemy_action_executed",
        $BattleHUD/EnemyActionFeedback,
        "_on_enemy_action"
    )

func cleanup_battle_ui():
    # 战斗结束时断开绑定
    pass
```

## Alternatives Considered

### Alternative 1: 手动刷新 (Polling)
- **描述**: 在 `_process` 中每帧检查数据变化
- **优点**: 实现简单
- **缺点**: 性能差，响应延迟
- **未采用原因**: 违反性能要求

### Alternative 2: 观察者模式 (Observer)
- **描述**: UI 主动注册为数据观察者
- **优点**: 完全解耦
- **缺点**: 需要额外的观察者接口
- **未采用原因**: 过度工程化

### Alternative 3: Signal 驱动绑定 (推荐方案)
- **描述**: 数据变化 emit Signal，UI 订阅
- **优点**: 性能好、解耦、响应及时
- **采用原因**: 符合 Godot 最佳实践

## Consequences

### Positive
- **响应式**: 数据变化立即更新 UI
- **解耦**: UI 不需要了解数据源
- **性能**: 仅在变化时更新，无轮询
- **可追踪**: Signal 连接可在调试器查看
- **可维护**: 新增 UI 只需添加绑定

### Negative
- **连接管理**: 需要注意断开时机
- **学习曲线**: 团队需要理解 Signal 模式

### Risks
- **Signal 泄漏**: 场景切换时未断开导致内存泄漏
  - **缓解**: 在 `_exit_tree()` 中批量断开
- **循环更新**: UI 更新触发数据变化，循环调用
  - **缓解**: 设计审查时注意单向数据流

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| resource-management-system.md (F2) | 资源显示 | resource_changed → UI 更新 |
| card-battle-system.md (C2) | 手牌显示 | hand_changed → HandPanel 更新 |
| card-battle-system.md (C2) | 战斗信息 | battle_started/ended → 场景切换 |
| enemies-design.md (C3) | 敌人血量显示 | enemy_damaged → EnemyPanel 更新 |
| map-design.md (M1) | 地图节点状态 | node_changed → MapUI 更新 |

## Performance Implications
- **CPU**: Signal emit < 0.01ms，UI 更新复杂度决定
- **Memory**: 每 Binding 约 64 字节
- **帧率影响**: 仅在数据变化时更新，无每帧开销

## Migration Plan
1. 创建 UIBinder.gd (Autoload)
2. 实现通用绑定方法
3. 为每个 UI 场景创建更新方法
4. 配置场景启动时的绑定
5. 实现场景切换时的断开逻辑
6. 添加调试工具查看绑定状态

## Validation Criteria
- [ ] 资源变化时 HUD 正确更新
- [ ] 手牌变化时 HandPanel 正确更新
- [ ] 敌人血量变化时 EnemyPanel 正确更新
- [ ] 场景切换时正确断开旧绑定
- [ ] 绑定状态可在调试器查看

## Related Decisions
- ADR-0002: 系统间通信模式 — Signal 通信基础
- ADR-0003: 资源变更通知机制 — 资源 Signal 定义