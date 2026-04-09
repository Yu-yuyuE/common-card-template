# ADR-0010: 武将系统架构

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Feature / Character |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0004 (卡牌数据配置格式), ADR-0007 (卡牌战斗系统) |
| **Enables** | M1 地图节点系统, D2 兵种卡系统 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 是 Feature 层角色系统，在 Core 层之后 |

## Context

### Problem Statement

武将系统需要管理：
- 22名武将，分属魏、蜀、吴、群雄四阵营
- 每名武将：基础值（HP 40-60、费用 3-4、统帅 3-6）、被动技能、专属卡组（≤12张）、生涯地图（5张）
- 兵种倾向：主修2项 + 次修1项
- 阵营与地图主题

### Constraints
- **性能**: 武将数据查询必须高效
- **一致性**: 武将数据必须统一管理

### Requirements
- 必须支持22名武将
- 必须支持被动技能触发
- 必须支持专属卡组
- 必须支持生涯地图结构

## Decision

### 方案: 集中式 HeroManager

采用 **武将管理器 + 数据驱动** 模式：

```gdscript
# hero_manager.gd
class_name HeroManager extends Node

# 阵营
enum Faction { WEI, SHU, WU, YI }

# 兵种类型
enum TroopType { INFANTRY, CAVALRY, ARCHER, STRATEGIST, SHIELD }

# 武将数据
class HeroData extends RefCounted:
    var id: String                      # 唯一ID (cao_cao, xiahou_dun, etc.)
    var name: String                    # 中文名称
    var faction: Faction                # 阵营
    
    # 基础数值
    var max_hp: int                     # HP 40-60
    var cost: int                       # 费用 3-4
    var leadership: int                 # 统帅 3-6，可携带兵种卡上限
    
    # 兵种倾向
    var primary_troops: Array           # 主修2项
    var secondary_troop: TroopType      # 次修1项
    
    # 被动技能
    var passive_skill_id: String        # 被动技能ID
    var passive_skill_name: String      # 被动技能名称
    var passive_skill_desc: String      # 被动技能描述
    var passive_trigger: String         # 触发时机 (on_damaged, on_card_played, on_turn_end, etc.)
    
    # 专属卡组
    var exclusive_deck: Array           # 专属卡ID列表 (≤12)
    
    # 生涯地图
    var career_maps: Array              # 5张地图配置
    
    # 手牌上限
    var hand_limit: int = 5             # 默认5，袁绍6

# 被动技能效果
class PassiveSkillEffect:
    var skill_id: String
    var trigger_condition: String       # on_damaged / on_card_played / on_turn_start / on_turn_end
    var effect_function: Callable       # 效果执行函数

# 武将数据存储
var _heroes: Dictionary = {}            # hero_id -> HeroData
var _current_hero: HeroData = null      # 当前选中的武将

# 被动技能映射
var _passive_skills: Dictionary = {}    # skill_id -> PassiveSkillEffect

signal hero_selected(hero: HeroData)
signal passive_triggered(hero_id: String, skill_name: String, effect_result: Dictionary)

# === 初始化 ===

func _ready():
    _load_hero_data()
    _register_passive_skills()

func _load_hero_data() -> void:
    # 从CSV加载武将配置
    var csv_data = _load_csv("res://design/detail/heroes.csv")
    for row in csv_data:
        var hero = HeroData.new()
        hero.id = row.get("id", "")
        hero.name = row.get("name", "")
        hero.faction = _parse_faction(row.get("faction", "wei"))
        hero.max_hp = row.get("hp", 50).to_int()
        hero.cost = row.get("cost", 3).to_int()
        hero.leadership = row.get("leadership", 5).to_int()
        
        # 兵种倾向
        var primary = row.get("primary_troops", "").split("/")
        hero.primary_troops = [_parse_troop(primary[0]), _parse_troop(primary[1])] if primary.size() >= 2 else []
        hero.secondary_troop = _parse_troop(row.get("secondary_troop", "infantry"))
        
        # 被动技能
        hero.passive_skill_id = row.get("passive_id", "")
        hero.passive_skill_name = row.get("passive_name", "")
        hero.passive_skill_desc = row.get("passive_desc", "")
        hero.passive_trigger = row.get("passive_trigger", "")
        
        # 专属卡组
        hero.exclusive_deck = row.get("exclusive_deck", "").split(",")
        
        # 生涯地图
        hero.career_maps = _load_career_maps(hero.id)
        
        # 特殊手牌上限
        if hero.id == "yuan_shao":
            hero.hand_limit = 6  # 袁绍被动
        
        _heroes[hero.id] = hero

func _register_passive_skills() -> void:
    # 注册所有被动技能效果
    _passive_skills["xie_ling_zhu_hou"] = PassiveSkillEffect.new()
    _passive_skills["xie_ling_zhu_hou"].trigger_condition = "on_troop_card_played"
    _passive_skills["xie_ling_zhu_hou"].effect_function = _effect_xie_ling_zhu_hou
    
    _passive_skills["gang_lie"] = PassiveSkillEffect.new()
    _passive_skills["gang_lie"].trigger_condition = "on_damaged"
    _passive_skills["gang_lie"].effect_function = _effect_gang_lie
    
    # ... 其他被动技能

# === 武将选择 ===

func select_hero(hero_id: String) -> bool:
    """选择武将"""
    var hero = _heroes.get(hero_id)
    if hero == null:
        return false
    
    _current_hero = hero
    hero_selected.emit(hero)
    return true

func get_current_hero() -> HeroData:
    return _current_hero

func get_hero(hero_id: String) -> HeroData:
    return _heroes.get(hero_id)

func get_heroes_by_faction(faction: Faction) -> Array:
    var result: Array = []
    for hero in _heroes.values():
        if hero.faction == faction:
            result.append(hero)
    return result

# === 被动技能触发 ===

func trigger_passive(trigger_type: String, context: Dictionary) -> void:
    """触发被动技能"""
    if _current_hero == null:
        return
    
    var skill_id = _current_hero.passive_skill_id
    var skill_effect = _passive_skills.get(skill_id)
    
    if skill_effect == null:
        return
    
    if skill_effect.trigger_condition != trigger_type:
        return
    
    # 执行效果
    var result = skill_effect.effect_function.call(context)
    
    passive_triggered.emit(_current_hero.id, _current_hero.passive_skill_name, result)

func _effect_xie_ling_zhu_hou(context: Dictionary) -> Dictionary:
    """曹操：挟令诸侯 - 使用兵种卡时对随机敌人施加1层虚弱"""
    var enemy_list = BattleManager.enemy_entities
    if enemy_list.is_empty():
        return {"success": false}
    
    var target_enemy = enemy_list.pick_random()
    StatusManager.apply_status(target_enemy, StatusManager.StatusCategory.WEAK, 1, "hero_passive")
    
    # 检查是否对虚弱敌人有额外伤害
    var weak_layers = StatusManager.get_status(target_enemy, StatusManager.StatusCategory.WEAK)
    if weak_layers > 0:
        # 额外50%伤害会在卡牌结算时处理
        pass
    
    return {"success": true, "target": target_enemy.id, "status": "weak", "layers": 1}

func _effect_gang_lie(context: Dictionary) -> Dictionary:
    """夏侯惇：刚烈 - 受伤后下次攻击额外造成累计伤害"""
    var damage_taken = context.get("damage", 0)
    var accumulated = context.get("accumulated_damage", 0)
    accumulated += damage_taken
    
    return {
        "success": true, 
        "accumulated_damage": accumulated,
        "next_attack_bonus": accumulated
    }

# === 专属卡组 ===

func get_exclusive_deck(hero_id: String) -> Array:
    var hero = _heroes.get(hero_id)
    return hero.exclusive_deck if hero != null else []

func get_current_exclusive_deck() -> Array:
    if _current_hero == null:
        return []
    return _current_hero.exclusive_deck

# === 兵种倾向 ===

func get_troop_weights(hero_id: String) -> Dictionary:
    """获取兵种出现权重"""
    var hero = _heroes.get(hero_id)
    if hero == null:
        return {}
    
    var weights = {}
    for troop in TroopType:
        weights[troop] = 1.0  # 基础权重
    
    # 主修兵种权重提高
    for primary in hero.primary_troops:
        weights[primary] = 2.0
    
    # 次修兵种权重中等
    weights[hero.secondary_troop] = 1.5
    
    return weights

# === 生涯地图 ===

func _load_career_maps(hero_id: String) -> Array:
    """加载武将生涯地图"""
    # 从配置加载5张地图
    return []

func get_career_maps(hero_id: String) -> Array:
    var hero = _heroes.get(hero_id)
    return hero.career_maps if hero != null else []

# === 辅助方法 ===

func _parse_faction(faction_str: String) -> Faction:
    match faction_str.to_lower():
        "wei": return Faction.WEI
        "shu": return Faction.SHU
        "wu": return Faction.WU
        "yi": return Faction.YI
    return Faction.YI

func _parse_troop(troop_str: String) -> TroopType:
    match troop_str.to_lower():
        "infantry": return TroopType.INFANTRY
        "cavalry": return TroopType.CAVALRY
        "archer": return TroopType.ARCHER
        "strategist": return TroopType.STRATEGIST
        "shield": return TroopType.SHIELD
    return TroopType.INFANTRY

func _load_csv(path: String) -> Array:
    # CSV 加载实现
    return []
```

### 被动技能触发时机

| 触发时机 | 说明 | 示例 |
|---------|------|------|
| on_damaged | 受到伤害时 | 夏侯惇刚烈 |
| on_card_played | 出牌时 | 曹操挟令诸侯 |
| on_troop_card_played | 打出兵种卡时 | 特定武将 |
| on_turn_start | 回合开始时 | 特定武将 |
| on_turn_end | 回合结束时 | 特定武将 |
| on_enemy_killed | 击杀敌人时 | 特定武将 |

### 武将数据模板

```gdscript
# 典型武将数据
{
    "id": "cao_cao",
    "name": "曹操",
    "faction": "WEI",
    "max_hp": 51,
    "cost": 3,
    "leadership": 6,
    "primary_troops": [INFANTRY, CAVALRY],
    "secondary_troop": STRATEGIST,
    "passive_skill_id": "xie_ling_zhu_hou",
    "passive_skill_name": "挟令诸侯",
    "passive_trigger": "on_troop_card_played",
    "exclusive_deck": ["ZY001", "ZY002", ...],  # 16张
    "career_maps": [5 maps],
    "hand_limit": 5
}
```

## Alternatives Considered

### Alternative 1: 分布式武将数据
- **描述**: 每个场景自己管理武将数据
- **优点**: 简单
- **缺点**: 难以共享
- **未采用原因**: 需要全局管理

### Alternative 2: HeroManager (推荐方案)
- **描述**: 集中管理器 + 数据驱动
- **优点**: 统一接口，易于扩展
- **采用原因**: 符合需求

## Consequences

### Positive
- **统一管理**: 所有武将数据集中
- **数据驱动**: 易于扩展新武将
- **被动技能**: 可配置的触发机制

### Negative
- **复杂性**: 22个武将需要详细配置
- **平衡难度**: 被动技能需要仔细平衡

### Risks
- **被动技能冲突**: 多个被动可能冲突
  - **缓解**: 明确的触发顺序
- **平衡问题**: 某些武将可能过强
  - **缓解**: 详细测试

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| heroes-design.md | 22名武将 | _heroes 字典存储 |
| heroes-design.md | 4阵营 | Faction 枚举覆盖 |
| heroes-design.md | 基础值 (HP 40-60, 费用 3-4, 统帅 3-6) | HeroData 字段 |
| heroes-design.md | 1个被动技能 | passive_skill_id + 触发机制 |
| heroes-design.md | 专属卡组 (≤12张) | exclusive_deck 数组 |
| heroes-design.md | 生涯地图 (5张) | career_maps 数组 |
| heroes-design.md | 兵种倾向 | primary_troops + secondary_troop |

## Performance Implications
- **CPU**: 武将数据查询 O(1)
- **Memory**: 每武将约 200 字节，22名约 4KB

## Migration Plan
1. 创建 HeroManager.gd
2. 实现武将数据加载
3. 实现被动技能系统
4. 实现专属卡组管理
5. 实现兵种权重
6. 集成到战斗系统
7. 编写测试

## Validation Criteria
- [ ] 22名武将正确加载
- [ ] 4阵营正确分类
- [ ] 基础值正确初始化
- [ ] 被动技能正确触发
- [ ] 专属卡组正确获取
- [ ] 兵种权重正确计算

## Related Decisions
- ADR-0004 (已 Accepted): 卡牌数据配置格式
- ADR-0007 (已 Accepted): 卡牌战斗系统
