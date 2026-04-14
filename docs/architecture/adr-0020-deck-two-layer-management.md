# ADR-0020: 卡组两层管理架构

## Status
Accepted

## Date
2026-04-13

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / Card Management |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0005 (存档序列化方案), ADR-0007 (卡牌战斗系统架构) |
| **Enables** | 战役层卡组管理、战斗层临时变更 |
| **Blocks** | 所有依赖卡组状态的系统 |
| **Ordering Note** | 本 ADR 在战斗系统和存档系统之后 |

## Context

### Problem Statement

游戏需要管理卡组在两个层次的状态：
1. **战役层（Campaign Level）**：卡组的持久状态，影响整场战役（包含3张小地图）
2. **战斗层（Battle Level）**：卡组在单场战斗中的临时状态

当前系统的问题：
- 没有明确区分两个层次的卡组状态
- "永久加入卡组"、"消耗品"等机制没有明确的实现路径
- 战斗中的临时变更（如敌人偷取卡牌、临时升级）没有清晰的状态管理

### Constraints

- **数据一致性**: 两层快照必须保持同步
- **性能**: 战斗初始化需要快速复制快照
- **持久化**: 战役层快照需要跨战斗保存
- **回滚**: 战斗层变更必须能够回滚

### Requirements

- 必须支持战役层卡组快照（`CampaignDeckSnapshot`）
- 必须支持战斗层卡组快照（`BattleDeckSnapshot`）
- 必须支持"永久加入卡组"机制（同时修改两层）
- 必须支持"消耗品"机制（战役层永久移除）
- 必须支持战斗结束后自动清理临时状态

## Decision

### 方案: 双快照系统 + 战役层权威

采用 **双快照系统**，战役层快照作为权威数据源，战斗层快照作为临时工作副本。

#### 核心原则

1. **战役层权威**: `CampaignDeckSnapshot` 是卡组的权威状态
2. **战斗层副本**: `BattleDeckSnapshot` 是战斗开始时从战役层复制的临时状态
3. **单向同步**: 战斗层变更不影响战役层（除非明确标记"永久"）
4. **自动清理**: 战斗结束时，`BattleDeckSnapshot` 自动销毁

#### 数据结构

```gdscript
# campaign_deck_snapshot.gd
class_name CampaignDeckSnapshot extends RefCounted

# 战役层卡组快照：整场战役的权威状态
var cards: Dictionary = {}  # card_id -> {level, special_attrs, is_permanent, source}
var version: int = 0        # 版本号，用于同步检查

signal snapshot_updated()

func _init():
    pass

# 添加卡牌到战役层
func add_card(card_id: String, level: int = 1, source: String = "unknown") -> void:
    cards[card_id] = {
        "level": level,
        "special_attrs": [],
        "is_permanent": true,
        "source": source,  # "shop", "event", "reward", "initial"
        "added_at": Time.get_ticks_msec()
    }
    version += 1
    snapshot_updated.emit()

# 移除卡牌
func remove_card(card_id: String) -> void:
    cards.erase(card_id)
    version += 1
    snapshot_updated.emit()

# 升级卡牌
func upgrade_card(card_id: String) -> bool:
    if not cards.has(card_id):
        return false
    if cards[card_id]["level"] >= 2:
        return false
    cards[card_id]["level"] = 2
    version += 1
    snapshot_updated.emit()
    return true

# 获取所有卡牌ID列表（用于初始化战斗层）
func get_all_card_ids() -> Array[String]:
    var result: Array[String] = []
    for card_id in cards:
        result.append(card_id)
    return result

# 序列化（用于存档）
func serialize() -> Dictionary:
    return {
        "cards": cards.duplicate(),
        "version": version
    }

# 反序列化（用于读档）
static func deserialize(data: Dictionary) -> CampaignDeckSnapshot:
    var snapshot = CampaignDeckSnapshot.new()
    snapshot.cards = data.get("cards", {})
    snapshot.version = data.get("version", 0)
    return snapshot
```

```gdscript
# battle_deck_snapshot.gd
class_name BattleDeckSnapshot extends RefCounted

# 战斗层卡组快照：本场战斗的临时状态
var source_version: int = 0  # 来源战役快照版本（用于检测不一致）

# 战斗层专用区域
var draw_pile: Array[String] = []      # 抽牌堆
var hand_cards: Array[String] = []     # 手牌
var discard_pile: Array[String] = []   # 弃牌堆
var removed_cards: Array[String] = []  # 移除区（本场战斗移除，战斗结束回卡组）
var exhaust_cards: Array[String] = []  # 消耗区（永久消耗，本场战役后续不可用）

# 临时状态（战斗结束后清空）
var temporary_upgrades: Dictionary = {}  # card_id -> {temp_level, temp_effects}
var stolen_cards: Array[String] = []      # 被敌人偷取的卡牌

signal snapshot_updated()

# 从战役层快照初始化
func initialize_from_campaign(campaign_snapshot: CampaignDeckSnapshot) -> void:
    source_version = campaign_snapshot.version
    
    # 复制所有卡牌到抽牌堆
    draw_pile = campaign_snapshot.get_all_card_ids()
    draw_pile.shuffle()
    
    # 清空其他区域
    hand_cards.clear()
    discard_pile.clear()
    removed_cards.clear()
    exhaust_cards.clear()
    
    # 清空临时状态
    temporary_upgrades.clear()
    stolen_cards.clear()

# 抽牌
func draw_cards(count: int) -> Array[String]:
    var drawn: Array[String] = []
    for i in range(count):
        if draw_pile.is_empty():
            # 洗牌：弃牌堆 -> 抽牌堆
            _shuffle_discard_to_draw()
        if not draw_pile.is_empty():
            var card_id = draw_pile.pop_front()
            hand_cards.append(card_id)
            drawn.append(card_id)
    snapshot_updated.emit()
    return drawn

# 打出卡牌
func play_card(card_id: String, to_removed: bool = false, to_exhaust: bool = false) -> void:
    var idx = hand_cards.find(card_id)
    if idx >= 0:
        hand_cards.remove_at(idx)
        
        if to_exhaust:
            exhaust_cards.append(card_id)
        elif to_removed:
            removed_cards.append(card_id)
        else:
            discard_pile.append(card_id)
    
    snapshot_updated.emit()

# 敌人偷取卡牌
func steal_card(card_id: String) -> void:
    var idx = hand_cards.find(card_id)
    if idx >= 0:
        hand_cards.remove_at(idx)
        stolen_cards.append(card_id)
        # 注意：偷取的卡牌不放入removed_cards，战斗结束后不归还
    
    snapshot_updated.emit()

# 临时升级（仅本场战斗有效）
func temporary_upgrade(card_id: String, temp_level: int, temp_effects: Dictionary) -> void:
    temporary_upgrades[card_id] = {
        "temp_level": temp_level,
        "temp_effects": temp_effects
    }
    snapshot_updated.emit()

# 洗牌
func _shuffle_discard_to_draw() -> void:
    draw_pile.append_array(discard_pile)
    draw_pile.shuffle()
    discard_pile.clear()

# 战斗结束清理（生成需要回写到战役层的数据）
func finalize_battle() -> Dictionary:
    # 返回需要回写到战役层的变更
    return {
        "exhaust_cards": exhaust_cards.duplicate(),  # 消耗的卡牌（永久移除）
        "source_version": source_version
    }
```

#### 战役层管理器

```gdscript
# campaign_deck_manager.gd
class_name CampaignDeckManager extends Node

# 战役层卡组管理器：负责战役层快照的生命周期管理
var current_snapshot: CampaignDeckSnapshot = null
var current_battle_snapshot: BattleDeckSnapshot = null

signal campaign_snapshot_changed()
signal battle_snapshot_changed()

func _ready():
    current_snapshot = CampaignDeckSnapshot.new()

# 初始化战役（开始新游戏）
func initialize_campaign(hero_id: String) -> void:
    current_snapshot = CampaignDeckSnapshot.new()
    
    # 加载武将初始卡组
    var initial_deck = _load_initial_deck(hero_id)
    for card_id in initial_deck:
        current_snapshot.add_card(card_id, 1, "initial")
    
    campaign_snapshot_changed.emit()

# 开始战斗（创建战斗层快照）
func start_battle() -> void:
    current_battle_snapshot = BattleDeckSnapshot.new()
    current_battle_snapshot.initialize_from_campaign(current_snapshot)
    battle_snapshot_changed.emit()

# 结束战斗（回写变更到战役层）
func end_battle() -> void:
    if current_battle_snapshot == null:
        return
    
    var changes = current_battle_snapshot.finalize_battle()
    
    # 处理消耗的卡牌（永久移除）
    for card_id in changes["exhaust_cards"]:
        current_snapshot.remove_card(card_id)
    
    # 销毁战斗层快照
    current_battle_snapshot = null
    battle_snapshot_changed.emit()

# 永久加入卡组（同时修改两层）
func permanent_add_card(card_id: String, level: int = 1, source: String = "effect") -> void:
    # 修改战役层
    current_snapshot.add_card(card_id, level, source)
    
    # 如果正在战斗中，同时加入战斗层
    if current_battle_snapshot != null:
        current_battle_snapshot.draw_pile.append(card_id)
        current_battle_snapshot.snapshot_updated.emit()
    
    campaign_snapshot_changed.emit()

# 消耗卡牌（永久移除）
func exhaust_card(card_id: String) -> void:
    current_snapshot.remove_card(card_id)
    campaign_snapshot_changed.emit()

# 序列化（用于存档）
func serialize() -> Dictionary:
    return current_snapshot.serialize()

# 反序列化（用于读档）
func deserialize(data: Dictionary) -> void:
    current_snapshot = CampaignDeckSnapshot.deserialize(data)
    campaign_snapshot_changed.emit()
```

### 与现有系统的集成

#### 与卡牌战斗系统的集成

```
BattleManager 初始化流程:
1. 调用 CampaignDeckManager.start_battle()
2. 获取 current_battle_snapshot
3. 使用 battle_deck_snapshot.draw_pile 初始化抽牌堆
4. 战斗结束后调用 CampaignDeckManager.end_battle()
```

#### 与存档系统的集成

```
存档保存流程:
1. 调用 CampaignDeckManager.serialize()
2. 将结果写入 Run Save 的 "deck" 字段

存档加载流程:
1. 从 Run Save 读取 "deck" 字段
2. 调用 CampaignDeckManager.deserialize(data)
```

#### 与商店/军营系统的集成

```
商店购买卡牌:
1. 调用 CampaignDeckManager.permanent_add_card(card_id, 1, "shop")

军营删除卡牌:
1. 调用 CampaignDeckManager.current_snapshot.remove_card(card_id)

商店升级卡牌:
1. 调用 CampaignDeckManager.current_snapshot.upgrade_card(card_id)
```

## Alternatives Considered

### Alternative 1: 单一快照 + 回滚日志

使用单一快照，战斗开始时记录变更日志，战斗结束时回滚。

**优缺点**:
- 优点：内存占用更小
- 缺点：回滚逻辑复杂，难以处理"永久"变更

**不选择理由**: 回滚日志难以处理复杂的交互（如永久加入+临时移除），容易出错。

### Alternative 2: 事件溯源

记录所有卡组变更事件，战斗结束时重放事件。

**优缺点**:
- 优点：完整的变更历史，便于调试
- 缺点：性能开销大，需要额外存储

**不选择理由**: 对于卡组管理这种高频操作，事件溯源的性能开销不可接受。

## Consequences

### 正面影响

1. **清晰的状态管理**: 两个层次的卡组状态明确分离
2. **易于实现"永久"机制**: 通过同时修改两层快照实现
3. **自动清理**: 战斗结束时自动清理临时状态，避免状态残留
4. **持久化简单**: 只需持久化战役层快照，战斗层快照无需存储

### 负面影响

1. **内存开销**: 需要维护两个快照，内存占用增加约 2x
2. **同步复杂度**: 需要确保两层快照的版本一致性

### 风险缓解

1. **内存开销**: 可接受（卡组数量通常 < 30张）
2. **同步复杂度**: 通过版本号检查和单元测试确保一致性

## GDD Requirements Addressed

| GDD Section | Requirement | ADR Solution |
|-------------|-------------|--------------|
| cards-design.md §0 | 战役层变更持续至本场战役结束 | `CampaignDeckSnapshot` 持久化 |
| cards-design.md §0 | 战斗层变更仅影响本场战斗 | `BattleDeckSnapshot` 自动销毁 |
| cards-design.md §0 | "永久加入卡组"同时修改两层 | `permanent_add_card()` 方法 |
| cards-design.md §0 | "消耗品"从战役层移除 | `exhaust_cards` 列表 |
| cards-design.md §0 | 敌人偷取卡牌不归还 | `stolen_cards` 列表 |

## Performance Implications

- **战斗初始化**: O(n) 复制卡牌ID列表（n = 卡组大小，通常 < 30）
- **内存占用**: 约为单快照的 2x（可接受）
- **战斗结束清理**: O(1) 销毁快照

## Testing Strategy

### 单元测试

- `CampaignDeckSnapshot` 的增删改查操作
- `BattleDeckSnapshot` 的初始化和清理
- 双快照同步的正确性
- "永久加入"机制的验证

### 集成测试

- 战斗开始/结束的完整流程
- 存档/读档后的状态恢复
- 跨战斗的卡组状态持久性

## Open Questions

None.

## References

- **GDD 主文档**: `design/gdd/cards-design.md`（第0-1节：术语定义与阶段管理）
- **相关 ADR**: ADR-0005 (存档序列化方案), ADR-0007 (卡牌战斗系统架构)
