# ADR-0013: 酒馆系统架构

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Feature / Economy |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0003 (资源变更通知机制), ADR-0010 (武将系统架构) |
| **Enables** | 玩家HP恢复、粮草购买 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 依赖资源管理和武将系统 |

## Context

### Problem Statement
酒馆提供以下功能：
- **歇息**: +15 HP，消耗0金币
- **买粮草**: 40金币购买40粮草
- **强化休整**: +20 HP，消耗60金币

需要设计酒馆访问限制和功能逻辑。

### Constraints
- **限制**: 每章节只能歇息一次
- **经济**: 粮草价格需要与地图消耗匹配
- **HP上限**: 不能超过最大HP

### Requirements
- 歇息每章节限1次
- 粮草可以无限购买
- 强化休整消耗更多金币但回复更多HP
- HP不能超过上限

## Decision

### 方案: 章节限制 + 即时服务模式

```
酒馆系统架构:
┌─────────────────────────────────────────────────────────────┐
│  InnManager (酒馆逻辑)                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ rest_count: int (本章歇息次数)                       │   │
│  │ rest_limit: int = 1 (每章限制)                      │   │
│  │ rest(enhanced: bool) → 歇息逻辑                     │   │
│  │ buy_provisions(amount: int) → 买粮草                │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  InnUI (界面)                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 歇息按钮、买粮草数量选择、强化休整按钮              │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 核心实现

```gdscript
# inn_manager.gd
class_name InnManager extends Node

signal rested(health_gained: int, enhanced: bool)
signal provisions_bought(amount: int, gold_spent: int)

const REST_BASE_HEAL: int = 15          # 普通歇息回复
const ENHANCED_HEAL: int = 20           # 强化休整回复
const PROVISIONS_AMOUNT: int = 40       # 每次购买粮草数量
const PROVISIONS_PRICE: int = 40        # 粮草价格
const ENHANCED_PRICE: int = 60          # 强化休整价格

var rest_count: int = 0                 # 本章歇息次数
var rest_limit: int = 1                 # 每章限制

func _ready():
    # 章节开始时重置歇息次数
    EventBus.chapter_started.connect(_on_chapter_started)

func _on_chapter_started(chapter_id: String):
    rest_count = 0

func rest(enhanced: bool = false) -> bool:
    # 检查歇息次数限制
    if not enhanced and rest_count >= rest_limit:
        push_error("Rest limit reached for this chapter")
        return false

    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)

    if enhanced and gold < ENHANCED_PRICE:
        push_error("Not enough gold for enhanced rest: need %d, have %d" % [ENHANCED_PRICE, gold])
        return false

    var current_hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP)
    var max_hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP, true)

    # 计算可回复的HP
    var heal_amount: int
    if enhanced:
        heal_amount = ENHANCED_HEAL
    else:
        heal_amount = REST_BASE_HEAL

    var actual_heal = min(heal_amount, max_hp - current_hp)

    if actual_heal <= 0:
        push_warning("Already at full health")
        return false

    # 消耗金币（如果需要）
    if enhanced:
        ResourceManager.modify_resource(ResourceManager.ResourceType.GOLD, -ENHANCED_PRICE)

    # 回复HP
    ResourceManager.modify_resource(ResourceManager.ResourceType.HP, actual_heal)

    # 更新歇息次数（非强化）
    if not enhanced:
        rest_count += 1

    rested.emit(actual_heal, enhanced)
    return true

func buy_provisions(amount: int = PROVISIONS_AMOUNT) -> bool:
    if amount <= 0:
        return false

    var price = (amount / PROVISIONS_AMOUNT) * PROVISIONS_PRICE
    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)

    if gold < price:
        push_error("Not enough gold: need %d, have %d" % [price, gold])
        return false

    # 扣除金币
    ResourceManager.modify_resource(ResourceManager.ResourceType.GOLD, -price)

    # 添加粮草
    ResourceManager.modify_resource(ResourceManager.ResourceType.PROVISIONS, amount)

    provisions_bought.emit(amount, price)
    return true

func can_rest(enhanced: bool = false) -> bool:
    if not enhanced and rest_count >= rest_limit:
        return false

    var current_hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP)
    var max_hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP, true)

    if current_hp >= max_hp:
        return false

    if enhanced:
        var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)
        return gold >= ENHANCED_PRICE

    return true

func can_buy_provisions(amount: int = PROVISIONS_AMOUNT) -> bool:
    var price = (amount / PROVISIONS_AMOUNT) * PROVISIONS_PRICE
    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)
    return gold >= price
```

### 酒馆UI集成

```gdscript
# inn_ui.gd
class_name InnUI extends Control

@onready var rest_button = $RestButton
@onready var enhanced_rest_button = $EnhancedRestButton
@onready var buy_provisions_button = $BuyProvisionsButton
@onready var gold_label = $GoldLabel
@onready var hp_label = $HPLabel
@onready var provisions_label = $ProvisionsLabel
@onready var rest_count_label = $RestCountLabel

func _ready():
    # 连接资源变化信号
    EventBus.resource_changed.connect(_on_resource_changed)

    # 连接按钮信号
    rest_button.pressed.connect(_on_rest_pressed)
    enhanced_rest_button.pressed.connect(_on_enhanced_rest_pressed)
    buy_provisions_button.pressed.connect(_on_buy_provisions_pressed)

    _update_ui()

func _on_resource_changed(type, old_value, new_value, delta):
    _update_ui()

func _update_ui():
    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)
    var hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP)
    var max_hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP, true)
    var provisions = ResourceManager.get_resource(ResourceManager.ResourceType.PROVISIONS)

    gold_label.text = "金币: %d" % gold
    hp_label.text = "HP: %d/%d" % [hp, max_hp]
    provisions_label.text = "粮草: %d" % provisions
    rest_count_label.text = "歇息次数: %d/1" % InnManager.rest_count

    # 更新按钮状态
    rest_button.disabled = not InnManager.can_rest(false)
    enhanced_rest_button.disabled = not InnManager.can_rest(true)
    buy_provisions_button.disabled = not InnManager.can_buy_provisions()

func _on_rest_pressed():
    if InnManager.rest(false):
        _show_feedback("歇息成功 +15HP")

func _on_enhanced_rest_pressed():
    if InnManager.rest(true):
        _show_feedback("强化休整成功 +20HP")

func _on_buy_provisions_pressed():
    if InnManager.buy_provisions():
        _show_feedback("购买粮草 +40")

func _show_feedback(text: String):
    $FeedbackLabel.text = text
    $FeedbackLabel.visible = true
    await get_tree().create_timer(2.0).timeout
    $FeedbackLabel.visible = false
```

## Alternatives Considered

### Alternative 1: 无限制歇息
- **描述**: 可以无限歇息
- **优点**: 玩家自由度大
- **缺点**: 游戏难度降低
- **未采用原因**: 缺乏挑战

### Alternative 2: 永久限制歇息
- **描述**: 整个战役只能歇息N次
- **优点**: 长期策略
- **缺点**: 早期决策影响过大
- **未采用原因**: 惩罚过重

### Alternative 3: 章节限制 (推荐方案)
- **描述**: 每章节歇息一次
- **优点**: 平衡自由度和难度
- **采用原因**: 符合行业标准

## Consequences

### Positive
- **难度控制**: 限制歇息次数增加地图策略性
- **经济循环**: 粮草购买消耗金币
- **简单实现**: 逻辑清晰

### Negative
- **配置固定**: 数值需要平衡测试

### Risks
- **难度失衡**: 粮草价格或歇息回复不合理
  - **缓解**: 严格测试经济循环

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| inn-system.md (D7) | 歇息+15HP | rest(false) 逻辑 |
| inn-system.md (D7) | 买粮草40金/40粮 | buy_provisions() 逻辑 |
| inn-system.md (D7) | 强化休整60金+20HP | rest(true) 逻辑 |
| inn-system.md (D7) | 每章歇息1次 | rest_count 限制 |

## Validation Criteria
- [ ] 歇息正确回复HP
- [ ] 歇息次数限制生效
- [ ] 粮草购买正确扣金币加粮草
- [ ] HP不超过上限
- [ ] 金币不足时无法操作

## Related Decisions
- ADR-0001: 场景管理策略 — 酒馆场景
- ADR-0003: 资源变更通知机制 — 资源变化通知
- ADR-0010: 武将系统架构 — HP上限来自武将