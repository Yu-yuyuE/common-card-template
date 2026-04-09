# ADR-0004: 卡牌数据配置格式

## Status
Accepted

## Date
2026-04-08

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Data / Scripting |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | 卡牌战斗系统、商店系统、军营系统 |
| **Blocks** | 无 |
| **Ordering Note** | 本 ADR 可独立于其他 Foundation ADRs 编写 |

## Context

### Problem Statement
游戏需要配置和管理以下卡牌数据：
- **攻击卡**: AC0001–AC0107 (107张)
- **技能卡**: SC0001–SC0080 (80张)
- **兵种卡**: TC0001–TC0030 (30张)
- **诅咒卡**: CC0001–CC0025 (25张)
- **武将专属卡**: 各武将独立卡组

需要决定：
1. 配置文件的存储格式
2. 运行时数据结构
3. 加载和访问方式

### Constraints
- **设计-实现同步**: GDD 审批后必须同步更新 CSV
- **可读性**: 设计师需要能直接查看/编辑 CSV
- **性能**: 加载时间不能影响游戏体验

### Requirements
- 必须支持按 ID 快速查找卡牌
- 必须支持按类型（攻击/技能/兵种/诅咒）过滤
- 必须支持 Lv1/Lv2 效果切换

## Decision

### 方案: CSV 配置 + CardData class

```
design/detail/
├── all_cards/
│   ├── attack_cards.csv    # 攻击卡
│   ├── skill_cards.csv     # 技能卡
│   ├── troop_cards.csv     # 兵种卡
│   └── curse_cards.csv     # 诅咒卡
├── heroes_exclusive_decks.csv  # 武将专属卡
└── enemies.csv
```

### CSV 字段设计

**attack_cards.csv 示例**:
```csv
id,name,type,cost,damage,range,status_effect,status_stacks,remove_after_use,rarity,lv2_damage,lv2_status_stacks
AC0001,普通斩,近战,1,6,1,none,0,false,common,8,0
AC0002,穿刺射击,远程,2,4,3,bleed,2,false,common,6,3
```

**troop_cards.csv 示例**:
```csv
id,name,category,hp,damage,terrain_mod,weather_mod,attack_range,lv2_hp,lv2_damage,lv3_hp,lv3_damage
TC0001,步兵,步兵,5,3,forest:1.5,rain:0.8,1,7,4,10,6
TC0002,骑兵,骑兵,4,4,plain:1.5,sand:cost_down,1,6,5,8,7
```

### 运行时 Card 类设计

```gdscript
# card_data.gd
class_name CardData extends Resource

enum CardType { ATTACK, SKILL, TROOP, CURSE, HERO_EXCLUSIVE }

@export var id: String
@export var name: String
@export var type: CardType
@export var cost: int                          # 费用
@export var lv1_damage: int                    # Lv1 伤害
@export var lv2_damage: int                    # Lv2 伤害 (0 if not upgradable)
@export var status_effect: String              # 状态效果类型
@export var status_stacks: int                 # 状态层数
@export var remove_after_use: bool             # 使用后移除
@export var rarity: String                     # common/rare/epic/legendary

# 运行时实例
class_name CardInstance extends RefCounted
    var data: CardData
    var current_level: int = 1                  # 1 or 2

    func get_damage() -> int:
        return data.lv2_damage if current_level == 2 else data.lv1_damage
```

### CardManager 实现

```gdscript
# card_manager.gd
class_name CardManager extends Node

var attack_cards: Dictionary = {}    # id -> CardData
var skill_cards: Dictionary = {}
var troop_cards: Dictionary = {}
var curse_cards: Dictionary = {}

func _ready():
    load_all_cards()

func load_all_cards():
    attack_cards = _load_csv("res://design/detail/all_cards/attack_cards.csv")
    skill_cards = _load_csv("res://design/detail/all_cards/skill_cards.csv")
    troop_cards = _load_csv("res://design/detail/all_cards/troop_cards.csv")
    curse_cards = _load_csv("res://design/detail/all_cards/curse_cards.csv")

func _load_csv(path: String) -> Dictionary:
    var result = {}
    var file = FileAccess.open(path, FileAccess.READ)
    var headers = file.get_csv_line()

    while not file.eof_reached():
        var row = file.get_csv_line()
        if row.size() > 0 and row[0] != "":
            var card = CardData.new()
            # 映射 CSV 列到 CardData 属性
            card.id = row[0]
            card.name = row[1]
            # ... 其他字段映射
            result[card.id] = card

    return result

func get_card(card_id: String) -> CardData:
    var prefix = card_id.substr(0, 2)
    match prefix:
        "AC": return attack_cards.get(card_id)
        "SC": return skill_cards.get(card_id)
        "TC": return troop_cards.get(card_id)
        "CC": return curse_cards.get(card_id)
    return null

func get_cards_by_type(type: CardType) -> Array:
    match type:
        CardType.ATTACK: return attack_cards.values()
        CardType.SKILL: return skill_cards.values()
        CardType.TROOP: return troop_cards.values()
        CardType.CURSE: return curse_cards.values()
    return []
```

## Alternatives Considered

### Alternative 1: 纯 JSON 配置
- **描述**: 使用 JSON 文件存储卡牌数据
- **优点**:
  - 解析简单
  - 人类可读
- **缺点**:
  - JSON 冗余度高（每个卡牌重复字段名）
  - GDD 设计时用的是 CSV 格式
- **未采用原因**: 与现有 GDD 的 CSV 设计不一致

### Alternative 2: Godot Resource 文件
- **描述**: 每个卡牌一个 .tres Resource 文件
- **优点**:
  - 类型安全
  - 编辑器支持
- **缺点**:
  - 100+ 个文件难以管理
  - 无法用 Excel 批量编辑
- **未采用原因**: 不适合大量数据

### Alternative 3: CSV + CardData class (推荐方案)
- **描述**: CSV 存储 + GDScript class 运行时解析
- **优点**:
  - 与 GDD 设计一致
  - 可用 Excel 批量编辑
  - 运行时快速访问
  - 支持热重载
- **采用原因**: 平衡可维护性和性能

## Consequences

### Positive
- **与 GDD 一致**: 设计师看 CSV，开发者看代码
- **快速查找**: 字典存储，O(1) 访问
- **类型安全**: CardData class 提供强类型
- **易于扩展**: 新增字段只需修改 CSV 和映射代码

### Negative
- **CSV 解析开销**: 启动时一次性加载
- **字段映射维护**: 新增字段需同步修改解析代码

### Risks
- **CSV 格式错误**: 解析失败导致游戏崩溃
  - **缓解**: 启动时验证 CSV 格式，记录错误并使用默认值
- **GDD 与 CSV 不同步**: 设计变更未同步到 CSV
  - **缓解**: CI 检查 GDD 修改时间与 CSV 修改时间

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| cards-design.md | 107攻击卡+80技能卡+30兵种卡 | CSV 存储，CardManager 加载 |
| troop-cards-design.md | 兵种卡 Lv1/Lv2/Lv3 效果 | CardData.lv1_damage, lv2_damage 字段 |
| curse-system.md | 3种诅咒类型 | CardType.CURSE + curse_cards.csv |
| game-concept.md | CSV 数据一致性规则 | 统一的 CSV 格式和加载逻辑 |

## Performance Implications
- **Load Time**: 约 100KB CSV，解析时间 < 50ms
- **Memory**: 每张 CardData 约 200 字节，200张约 40KB
- **Access**: 字典查找 O(1)

## Migration Plan
1. 创建 CSV 文件模板
2. 实现 CardData class
3. 实现 CardManager
4. 填充测试数据
5. 集成到战斗系统

## Validation Criteria
- [ ] CSV 文件能被正确解析为 CardData
- [ ] 按 ID 查找返回正确卡牌
- [ ] 按类型过滤返回正确集合
- [ ] Lv1/Lv2 效果正确切换

## Related Decisions
- ADR-0003 (已创建): 资源变更通知机制 — 独立
