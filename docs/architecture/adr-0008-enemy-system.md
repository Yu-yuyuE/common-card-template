# ADR-0008: 敌人系统架构

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
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0002 (系统间通信模式), ADR-0006 (状态效果系统), ADR-0007 (卡牌战斗系统) |
| **Enables** | 战斗系统的敌人行动执行 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 依赖战斗系统，在其之后创建 |

## Context

### Problem Statement

敌人系统需要管理：
- 5种敌人职业：步兵 / 骑兵 / 弓兵 / 谋士 / 盾兵
- 3种敌人级别：普通 / 精英 / 强力
- 71种行动（A/B/C三类）
- 100名敌人（E001~E100）
- 行动序列循环，可预测

### Constraints
- **可预测性**: 敌人行动必须可预测，玩家可预判
- **性能**: AI计算必须高效

### Requirements
- 必须支持5种职业
- 必须支持行动序列循环
- 必须支持行动公示机制

## Decision

### 方案: 集中式 EnemyManager + 行动序列

采用 **敌人管理器 + 固定序列** 模式：

```gdscript
# enemy_manager.gd
class_name EnemyManager extends Node

# 敌人职业
enum EnemyClass { INFANTRY, CAVALRY, ARCHER, STRATEGIST, SHIELD }

# 敌人级别
enum EnemyTier { NORMAL, ELITE, POWERFUL }

# 行动类型
enum ActionType { ATTACK, BUFF, DEBUFF, HEAL, SPECIAL }

# 敌人数据结构
class EnemyData extends RefCounted:
    var id: String                    # E001~E100
    var name: String                  # 敌人名称
    var enemy_class: EnemyClass       # 职业
    var tier: EnemyTier               # 级别
    var max_hp: int                   # 最大HP
    var current_hp: int               # 当前HP
    var armor: int                    # 护甲
    var action_sequence: Array        # 行动序列 [A01, A04, B02, ...]
    var action_index: int = 0         # 当前序列位置
    var position: int                 # 战场位置 (0-2)
    var is_alive: bool = true
    var cooldown_actions: Dictionary  # 冷却行动 {action_id: remaining_rounds}

# 敌人数据存储
var _enemies: Dictionary = {}         # enemy_id -> EnemyData

# 敌人配置加载
func _ready():
    _load_enemy_data()

func _load_enemy_data() -> void:
    # 从CSV加载敌人配置
    var csv_data = _load_csv("res://design/detail/enemies.csv")
    for row in csv_data:
        var enemy = EnemyData.new()
        enemy.id = row.get("id", "")
        enemy.name = row.get("name", "")
        enemy.enemy_class = _parse_class(row.get("class", "infantry"))
        enemy.tier = _parse_tier(row.get("tier", "normal"))
        enemy.max_hp = row.get("hp", 30).to_int()
        enemy.current_hp = enemy.max_hp
        enemy.armor = row.get("armor", 0).to_int()
        enemy.action_sequence = row.get("action_sequence", "").split(",")
        
        _enemies[enemy.id] = enemy

# === 行动获取 ===

func get_next_action(enemy_id: String) -> Dictionary:
    """获取敌人下一回合的行动"""
    var enemy = _enemies.get(enemy_id)
    if enemy == null or not enemy.is_alive:
        return {}
    
    # 获取当前行动
    var action_id = enemy.action_sequence[enemy.action_index]
    
    # 检查冷却
    if enemy.cooldown_actions.has(action_id):
        var remaining = enemy.cooldown_actions[action_id]
        if remaining > 0:
            # 冷却中，使用备用行动
            action_id = _get_backup_action(enemy)
    
    # 移动到序列下一位
    enemy.action_index = (enemy.action_index + 1) % enemy.action_sequence.size()
    
    # 获取行动详情
    return _get_action_data(action_id)

func get_displayed_action(enemy_id: String) -> Dictionary:
    """获取敌人当前回合公示的行动（玩家回合开始前）"""
    var enemy = _enemies.get(enemy_id)
    if enemy == null:
        return {}
    
    var action_id = enemy.action_sequence[enemy.action_index]
    
    # 检查冷却
    if enemy.cooldown_actions.has(action_id):
        if enemy.cooldown_actions[action_id] > 0:
            action_id = _get_backup_action(enemy)
    
    return _get_action_display(action_id)

func _get_action_data(action_id: String) -> Dictionary:
    """获取行动详细信息"""
    var actions = _load_action_database()
    return actions.get(action_id, {})

func _get_action_display(action_id: String) -> Dictionary:
    """获取行动公示信息"""
    var action_data = _get_action_data(action_id)
    return {
        "id": action_id,
        "name": action_data.get("name", ""),
        "description": action_data.get("description", ""),
        "target": action_data.get("target", "player"),
        "is_charging": action_data.get("is_charging", false),
        "charge_target": action_data.get("charge_target", "")
    }

func _get_backup_action(enemy: EnemyData) -> String:
    """获取备用行动（冷却中时使用）"""
    # 简单策略：使用第一个非冷却行动
    for action_id in enemy.action_sequence:
        if not enemy.cooldown_actions.has(action_id):
            return action_id
    return enemy.action_sequence[0]

# === 行动执行 ===

func execute_action(enemy_id: String, battle_manager: BattleManager) -> void:
    """执行敌人行动"""
    var enemy = _enemies.get(enemy_id)
    if enemy == null or not enemy.is_alive:
        return
    
    var action = get_next_action(enemy_id)
    if action.is_empty():
        return
    
    var action_type = action.get("type", "")
    
    match action_type:
        "attack":
            _execute_attack(enemy, action, battle_manager)
        "buff":
            _execute_buff(enemy, action, battle_manager)
        "debuff":
            _execute_debuff(enemy, action, battle_manager)
        "heal":
            _execute_heal(enemy, action)
        "special":
            _execute_special(enemy, action, battle_manager)
    
    # 处理冷却
    if action.has("cooldown"):
        enemy.cooldown_actions[action["id"]] = action["cooldown"]
    
    # 更新冷却计数
    for action_id in enemy.cooldown_actions.keys():
        enemy.cooldown_actions[action_id] -= 1
        if enemy.cooldown_actions[action_id] <= 0:
            enemy.cooldown_actions.erase(action_id)

func _execute_attack(enemy: EnemyData, action: Dictionary, bm: BattleManager) -> void:
    var damage = action.get("damage", 5)
    var target = action.get("target", "player")
    var penetrate = action.get("penetrate", false)
    
    if target == "player":
        var actual = bm.player_entity.take_damage(damage, penetrate)
        bm.damage_dealt.emit(0, actual, false)

func _execute_buff(enemy: EnemyData, action: Dictionary, bm: BattleManager) -> void:
    var status = action.get("status", "")
    var layers = action.get("layers", 1)
    
    if status != "":
        StatusManager.apply_status(bm.enemy_entities[enemy.position], status, layers, enemy.id)

func _execute_debuff(enemy: EnemyData, action: Dictionary, bm: BattleManager) -> void:
    var status = action.get("status", "")
    var layers = action.get("layers", 1)
    
    if status != "":
        StatusManager.apply_status(bm.player_entity, status, layers, enemy.id)

func _execute_heal(enemy: EnemyData, action: Dictionary) -> void:
    var heal_amount = action.get("heal", 5)
    enemy.current_hp = min(enemy.max_hp, enemy.current_hp + heal_amount)

func _execute_special(enemy: EnemyData, action: Dictionary, bm: BattleManager) -> void:
    var special_type = action.get("special_type", "")
    
    match special_type:
        "summon":
            # 召唤逻辑
            pass
        "curse":
            _deliver_curse(action, bm)
        "charge":
            # 蓄力：下回合高伤
            pass

func _deliver_curse(action: Dictionary, bm: BattleManager) -> void:
    """投递诅咒卡"""
    var curse_id = action.get("curse_id", "")
    var position = action.get("position", "hand")  # hand/draw_top/draw_random/discard
    
    match position:
        "hand":
            bm.hand_cards.append(curse_id)
        "draw_top":
            bm.draw_pile.push_front(curse_id)
        "draw_random":
            var idx = randi() % (bm.draw_pile.size() + 1)
            bm.draw_pile.insert(idx, curse_id)
        "discard":
            bm.discard_pile.append(curse_id)

# === 敌人管理 ===

func get_enemy(enemy_id: String) -> EnemyData:
    return _enemies.get(enemy_id)

func get_enemies_by_tier(tier: EnemyTier) -> Array:
    var result: Array = []
    for enemy in _enemies.values():
        if enemy.tier == tier:
            result.append(enemy)
    return result

func get_enemies_by_class(enemy_class: EnemyClass) -> Array:
    var result: Array = []
    for enemy in _enemies.values():
        if enemy.enemy_class == enemy_class:
            result.append(enemy)
    return result

# === 辅助方法 ===

func _parse_class(class_str: String) -> EnemyClass:
    match class_str.to_lower():
        "infantry": return EnemyClass.INFANTRY
        "cavalry": return EnemyClass.CAVALRY
        "archer": return EnemyClass.ARCHER
        "strategist": return EnemyClass.STRATEGIST
        "shield": return EnemyClass.SHIELD
    return EnemyClass.INFANTRY

func _parse_tier(tier_str: String) -> EnemyTier:
    match tier_str.to_lower():
        "normal": return EnemyTier.NORMAL
        "elite": return EnemyTier.ELITE
        "powerful": return EnemyTier.POWERFUL
    return EnemyTier.NORMAL

func _load_csv(path: String) -> Array:
    # CSV 加载实现
    return []

func _load_action_database() -> Dictionary:
    # 从配置加载71种行动
    return {}
```

### 行动公示机制

```
[玩家回合开始]
    ↓
[敌人回合前]
    ↓
[遍历所有存活敌人]
    ├─ 获取 get_displayed_action(enemy_id)
    ├─ 显示行动名称 + 描述 + 目标
    └─ 蓄力行动显示特殊标记
    ↓
[玩家可据此规划出牌]
```

### 行动循环规则

| 敌人级别 | 行动种类 | 循环长度 | 可用行动等级 |
|----------|----------|----------|--------------|
| 普通 | ≤2种 | 3步 | 仅A类 |
| 精英 | 2~3种 | 3~4步 | A类 + B类 |
| 强力 | 3种 | 4~5步 | A类 + B类 + C类 |

## Alternatives Considered

### Alternative 1: 随机行动选择
- **描述**: 敌人每回合随机选择行动
- **优点**: 变化多
- **缺点**: 不可预测，违反设计原则
- **未采用原因**: 要求可预测

### Alternative 2: 纯AI决策
- **描述**: 敌人使用行为树决策
- **优点**: 灵活
- **缺点**: 复杂，难以预测
- **未采用原因**: 过度工程

### Alternative 3: 固定序列 (推荐方案)
- **描述**: 敌人按固定序列循环行动
- **优点**: 可预测，简单
- **采用原因**: 符合设计要求

## Consequences

### Positive
- **可预测**: 玩家可预判敌人行动
- **简单高效**: 序列查询 O(1)
- **易于平衡**: 序列固定，易于调整
- **支持特殊**: 冷却机制支持特殊行动

### Negative
- **变化有限**: 长期可能觉得单调
- **难以复杂**: 不支持复杂AI

### Risks
- **序列泄露**: 玩家完全知道敌人下一步
  - **缓解**: 保留部分随机性（冷却机制）
- **平衡问题**: 某些序列可能过强
  - **缓解**: 详细测试

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| enemies-design.md | 5种敌人职业 | EnemyClass 枚举覆盖 |
| enemies-design.md | 3种敌人级别 | EnemyTier 枚举覆盖 |
| enemies-design.md | 71种行动 | _load_action_database() 加载 |
| enemies-design.md | 100名敌人 | _enemies 字典存储 |
| enemies-design.md | 行动序列循环 | action_sequence + action_index |
| enemies-design.md | 行动公示 | get_displayed_action() |
| enemies-design.md | 诅咒投递 | _deliver_curse() |

## Performance Implications
- **CPU**: 行动查询 < 0.01ms
- **Memory**: 每敌人约 100 字节

## Migration Plan
1. 创建 EnemyManager.gd
2. 实现敌人数据加载
3. 实现行动序列逻辑
4. 实现行动公示
5. 与 BattleManager 集成
6. 编写测试

## Validation Criteria
- [ ] 5种职业正确识别
- [ ] 3种级别正确区分
- [ ] 行动序列按顺序循环
- [ ] 行动公示正确显示
- [ ] 冷却机制正常工作

## Related Decisions
- ADR-0006 (已 Accepted): 状态效果系统
- ADR-0007 (已 Accepted): 卡牌战斗系统
