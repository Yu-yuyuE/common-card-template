# ADR-0012: 商店系统架构

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
| **Depends On** | ADR-0001 (场景管理策略), ADR-0003 (资源变更通知机制), ADR-0004 (卡牌数据配置格式) |
| **Enables** | 卡牌购买、装备购买、卡牌升级 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 依赖卡牌数据格式 |

## Context

### Problem Statement
商店系统提供以下功能：
- **买攻击卡**: 消耗金币购买攻击卡
- **买技能卡**: 消耗金币购买技能卡
- **升级卡**: 消耗金币将Lv1卡升级为Lv2
- **买装备**: 消耗金币购买装备

需要设计商品刷新机制和购买逻辑。

### Constraints
- **经济平衡**: 金币消耗需要与收益匹配
- **刷新机制**: 商店商品需要定期刷新
- **购买限制**: 每人每种卡牌只能买一次

### Requirements
- 商品按批次刷新（每章节刷新一次）
- 金币不足时无法购买
- 已拥有的卡牌不能重复购买
- 装备有携带上限

## Decision

### 方案: 商品批次 + 即时购买模式

```
商店系统架构:
┌─────────────────────────────────────────────────────────────┐
│  ShopInventory (商品库存)                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ current_batch: Array<ShopItem>                     │   │
│  │ batch_number: int                                  │   │
│  │ refresh_cost: int (刷新消耗)                       │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  ShopManager (购买逻辑)                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ buy_card(item_id) → 购买卡牌                       │   │
│  │ upgrade_card(card_id) → 升级卡牌                   │   │
│  │ buy_equipment(item_id) → 购买装备                  │   │
│  │ refresh_batch() → 刷新商品                         │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  ShopUI (界面)                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 商品展示、购买按钮、余额显示                        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 核心数据结构

```gdscript
# shop_item.gd
class_name ShopItem extends RefCounted

enum ItemType { ATTACK_CARD, SKILL_CARD, EQUIPMENT }

var item_id: String
var item_type: ItemType
var price: int
var card_data: CardData = null      # 如果是卡牌
var equipment_data: EquipmentData = null  # 如果是装备
var is_sold: bool = false           # 是否已售出

# 商店配置
class_name ShopConfig extends RefCounted:
    var batch_size: int = 6         # 每批商品数量
    var refresh_price: int = 50     # 刷新消耗金币
    var attack_card_count: int = 2  # 攻击卡数量
    var skill_card_count: int = 2   # 技能卡数量
    var equipment_count: int = 2    # 装备数量
```

### 商店管理器

```gdscript
# shop_manager.gd
class_name ShopManager extends Node

signal item_sold(item: ShopItem)
signal batch_refreshed(new_batch: Array[ShopItem])

var config: ShopConfig
var current_batch: Array[ShopItem] = []
var batch_number: int = 0
var purchased_card_ids: Array[String] = []  # 已购买的卡牌ID
var equipped_count: int = 0
const MAX_EQUIPMENT: int = 5

func _ready():
    config = ShopConfig.new()
    _generate_batch()

func _generate_batch():
    current_batch.clear()
    batch_number += 1

    # 生成攻击卡
    var attack_pool = _get_available_cards("ATTACK")
    for i in range(config.attack_card_count):
        if attack_pool.size() > 0:
            var card = attack_pool.pick_random()
            if not _is_card_purchased(card.id):
                current_batch.append(_create_shop_item(card))

    # 生成技能卡
    var skill_pool = _get_available_cards("SKILL")
    for i in range(config.skill_card_count):
        if skill_pool.size() > 0:
            var card = skill_pool.pick_random()
            if not _is_card_purchased(card.id):
                current_batch.append(_create_shop_item(card))

    # 生成装备
    var equip_pool = _get_available_equipment()
    for i in range(config.equipment_count):
        if equip_pool.size() > 0:
            var equip = equip_pool.pick_random()
            current_batch.append(_create_shop_item(equip))

    batch_refreshed.emit(current_batch)

func buy_card(item_id: String) -> bool:
    var item = _find_item(item_id)
    if item == null or item.item_type != ShopItem.ItemType.ATTACK_CARD and item.item_type != ShopItem.ItemType.SKILL_CARD:
        return false

    if item.is_sold:
        push_error("Item already sold")
        return false

    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)
    if gold < item.price:
        push_error("Not enough gold: need %d, have %d" % [item.price, gold])
        return false

    # 扣除金币
    ResourceManager.modify_resource(ResourceManager.ResourceType.GOLD, -item.price)

    # 标记已售出
    item.is_sold = true
    purchased_card_ids.append(item.card_data.id)

    # 添加到玩家卡组
    CardCollection.add_card(item.card_data.id)

    item_sold.emit(item)
    return true

func upgrade_card(card_id: String) -> bool:
    var card_data = CardManager.get_card(card_id)
    if card_data == null:
        return false

    var upgrade_price = _calculate_upgrade_price(card_data)
    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)

    if gold < upgrade_price:
        return false

    # 扣除金币
    ResourceManager.modify_resource(ResourceManager.ResourceType.GOLD, -upgrade_price)

    # 升级卡牌
    CardCollection.upgrade_card(card_id)

    return true

func buy_equipment(item_id: String) -> bool:
    if equipped_count >= MAX_EQUIPMENT:
        push_error("Equipment limit reached")
        return false

    var item = _find_item(item_id)
    if item == null or item.item_type != ShopItem.ItemType.EQUIPMENT:
        return false

    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)
    if gold < item.price:
        return false

    # 扣除金币
    ResourceManager.modify_resource(ResourceManager.ResourceType.GOLD, -item.price)

    # 添加装备
    EquipmentSystem.equip(item.equipment_data)
    equipped_count += 1

    item.is_sold = true
    item_sold.emit(item)
    return true

func refresh_batch() -> bool:
    var gold = ResourceManager.get_resource(ResourceManager.ResourceType.GOLD)
    if gold < config.refresh_price:
        return false

    ResourceManager.modify_resource(ResourceManager.ResourceType.GOLD, -config.refresh_price)
    _generate_batch()
    return true

func _calculate_upgrade_price(card_data: CardData) -> int:
    # 升级价格公式: base_price * (1.20 ~ 1.35)^level
    var base_price = 30
    var multiplier = 1.25  # 中间值
    return int(base_price * pow(multiplier, card_data.lv1_damage))
```

## Alternatives Considered

### Alternative 1: 固定商品
- **描述**: 商店商品永不刷新
- **优点**: 简单
- **缺点**: 后期无聊
- **未采用原因**: 缺乏策略性

### Alternative 2: 随机刷新
- **描述**: 每次进入商店随机商品
- **优点**: 高度随机
- **缺点**: 玩家无法规划
- **未采用原因**: 规划感缺失

### Alternative 3: 批次刷新 (推荐方案)
- **描述**: 章节开始刷新商品，中途可付费刷新
- **优点**: 平衡随机性与规划
- **采用原因**: 符合行业标准

## Consequences

### Positive
- **规划感**: 玩家可规划购买策略
- **刷新选项**: 金币充裕时可刷新
- **限制合理**: 避免刷钱

### Negative
- **配置复杂**: 需要配置商品池和价格

### Risks
- **经济崩溃**: 价格设置不合理
  - **缓解**: 严格测试金币获取/消耗平衡

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| shop-system.md (M2) | 买攻击卡/技能卡 | buy_card() 方法 |
| shop-system.md (M2) | 升级卡 | upgrade_card() 方法 |
| shop-system.md (M2) | 买装备 | buy_equipment() 方法 |
| shop-system.md (M2) | 批次刷新 | refresh_batch() 方法 |

## Validation Criteria
- [ ] 金币不足无法购买
- [ ] 已购买卡牌不能重复购买
- [ ] 装备携带上限为5
- [ ] 刷新消耗50金币
- [ ] 升级价格正确计算

## Related Decisions
- ADR-0001: 场景管理策略 — 商店场景
- ADR-0003: 资源变更通知机制 — 金币变化
- ADR-0004: 卡牌数据配置格式 — 卡牌数据加载