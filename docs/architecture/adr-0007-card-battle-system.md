# ADR-0007: 卡牌战斗系统架构

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / Game Logic |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0002 (系统间通信模式), ADR-0003 (资源变更通知机制), ADR-0006 (状态效果系统) |
| **Enables** | D2 兵种卡系统, D3 武将系统, D4 诅咒系统, M5 卡牌升级系统 |
| **Blocks** | 所有需要战斗结算的系统 |
| **Ordering Note** | 本 ADR 是 Core 层核心战斗引擎，在状态系统之后 |

## Context

### Problem Statement

卡牌战斗系统是游戏核心引擎，需要支持：
- 1 vs 最多3个敌人的战场结构
- 回合流程：玩家回合 → 敌人回合 → 阶段检查
- 卡牌生命周期：抽牌堆 → 手牌 → 弃牌堆 → 移除区 → 消耗区
- 伤害计算：护盾优先，溢出扣HP
- 多阶段战斗（精英/Boss）

### Constraints
- **性能**: 每帧可能多次计算伤害，需高效
- **一致性**: 伤害计算顺序必须明确
- **可调试**: 战斗过程需可追踪

### Requirements
- 必须支持1v1~3战场结构
- 必须支持回合流程控制
- 必须支持卡牌生命周期管理
- 必须支持多阶段战斗

## Decision

### 方案: 集中式 BattleManager + 状态机

采用 **战斗管理器 + 阶段状态机** 模式：

```gdscript
# battle_manager.gd
class_name BattleManager extends Node

# 战斗阶段
enum BattlePhase { PLAYER_START, PLAYER_DRAW, PLAYER_PLAY, PLAYER_END, ENEMY_TURN, PHASE_CHECK }

# 卡牌区域
enum CardZone { DRAW_PILE, HAND, DISCARD, REMOVED, EXHAUSTED }

signal battle_started(phase_count: int, enemies: Array)
signal turn_started(is_player_turn: bool)
signal card_played(card_id: String, target: int)
signal damage_dealt(target: int, damage: int, is_critical: bool)
signal battle_ended(victory: bool, rewards: Dictionary)
signal phase_changed(new_phase: int)

# 战斗状态
var current_phase: BattlePhase = BattlePhase.PLAYER_START
var current_stage: int = 0           # 当前阶段（0-based）
var total_stages: int = 1            # 总阶段数
var is_player_turn: bool = true

# 战场数据
var player_entity: BattleEntity       # 玩家主将
var enemy_entities: Array[BattleEntity]  # 敌人（最多3个）
var terrain: String = "plain"         # 当前地形
var weather: String = "clear"         # 当前天气

# 卡牌管理
var draw_pile: Array[String] = []     # 抽牌堆卡ID
var hand_cards: Array[String] = []    # 手牌卡ID
var discard_pile: Array[String] = []  # 弃牌堆卡ID
var removed_cards: Array[String] = [] # 移除区卡ID
var exhaust_cards: Array[String] = [] # 消耗区卡ID

# 战斗实体类
class BattleEntity extends RefCounted:
    var id: String
    var max_hp: int
    var current_hp: int
    var shield: int
    var max_shield: int
    var action_points: int
    var max_action_points: int
    var is_player: bool
    var status_effects: Dictionary = {}  # status_category -> layers
    
    func take_damage(damage: int, penetrate_shield: bool = false) -> int:
        var actual_damage = damage
        if not penetrate_shield and shield > 0:
            var shield_damage = min(shield, damage)
            shield -= shield_damage
            actual_damage -= shield_damage
        
        if actual_damage > 0:
            current_hp -= actual_damage
            current_hp = max(0, current_hp)
        
        return actual_damage

# === 战斗初始化 ===

func setup_battle(stage_config: Dictionary) -> void:
    current_stage = 0
    total_stages = stage_config.get("stage_count", 1)
    terrain = stage_config.get("terrain", "plain")
    weather = stage_config.get("weather", "clear")
    
    # 创建玩家实体
    player_entity = BattleEntity.new()
    player_entity.id = "player"
    player_entity.max_hp = ResourceManager.get_resource(ResourceManager.ResourceType.MAX_HP)
    player_entity.current_hp = ResourceManager.get_resource(ResourceManager.ResourceType.HP)
    player_entity.shield = 0
    player_entity.max_shield = player_entity.max_hp
    player_entity.action_points = ResourceManager.get_resource(ResourceManager.ResourceType.MAX_ACTION_POINTS)
    player_entity.max_action_points = player_entity.action_points
    player_entity.is_player = true
    
    # 创建敌人实体
    enemy_entities.clear()
    var enemy_list = stage_config.get("enemies", [])
    for i in range(min(enemy_list.size(), 3)):
        var e = BattleEntity.new()
        e.id = enemy_list[i].get("id", "enemy_" + str(i))
        e.max_hp = enemy_list[i].get("hp", 50)
        e.current_hp = e.max_hp
        e.shield = 0
        e.max_shield = e.max_hp
        e.action_points = 1
        e.max_action_points = 1
        e.is_player = false
        enemy_entities.append(e)
    
    # 初始化卡组
    _initialize_deck()
    
    # 抽初始手牌
    _draw_cards(_get_hand_limit())
    
    battle_started.emit(total_stages, enemy_entities)
    _start_player_turn()

# === 回合流程 ===

func _start_player_turn() -> void:
    is_player_turn = true
    current_phase = BattlePhase.PLAYER_START
    turn_started.emit(true)
    
    # 回合开始触发
    _process_status_start_turn(player_entity)
    
    # 抽牌阶段
    current_phase = BattlePhase.PLAYER_DRAW
    _draw_cards(_get_hand_limit())
    
    # 出牌阶段
    current_phase = BattlePhase.PLAYER_PLAY
    phase_changed.emit(current_phase)

func end_player_turn() -> void:
    if not is_player_turn:
        return
    
    # 回合结束触发
    current_phase = BattlePhase.PLAYER_END
    _process_status_end_turn(player_entity)
    
    # 进入敌人回合
    _start_enemy_turn()

func _start_enemy_turn() -> void:
    is_player_turn = false
    current_phase = BattlePhase.ENEMY_TURN
    turn_started.emit(false)
    
    # 按顺序执行敌人行动
    for enemy in enemy_entities:
        if enemy.current_hp > 0:
            _execute_enemy_action(enemy)
    
    # 敌人行动结束，检查阶段
    _check_phase()

func _execute_enemy_action(enemy: BattleEntity) -> void:
    # 从敌人系统获取行动
    var action = EnemySystem.get_next_action(enemy.id)
    if action == null:
        return
    
    # 执行行动
    match action.type:
        "attack":
            var damage = action.get("damage", 5)
            var target_pos = action.get("target", 0)
            if target_pos == 0:  # 攻击玩家
                var actual = player_entity.take_damage(damage, action.get("penetrate", false))
                damage_dealt.emit(0, actual, false)
        "status":
            StatusManager.apply_status(player_entity, action.get("status"), action.get("layers", 1), enemy.id)
        "buff":
            StatusManager.apply_status(enemy, action.get("status"), action.get("layers", 1), enemy.id)

func _check_phase() -> void:
    current_phase = BattlePhase.PHASE_CHECK
    
    # 检查当前阶段是否完成
    var all_dead = true
    for enemy in enemy_entities:
        if enemy.current_hp > 0:
            all_dead = false
            break
    
    if all_dead:
        if current_stage < total_stages - 1:
            # 进入下一阶段
            current_stage += 1
            _start_next_stage()
        else:
            # 战斗胜利
            _end_battle(true)
    else:
        # 回到玩家回合
        if player_entity.current_hp <= 0:
            _end_battle(false)
        else:
            _start_player_turn()

func _start_next_stage() -> void:
    # 阶段切换：资源保留，护盾清零
    player_entity.shield = 0
    player_entity.action_points = player_entity.max_action_points
    
    # 加载新阶段敌人
    var stage_config = _get_stage_config(current_stage)
    _setup_stage_enemies(stage_config)
    
    battle_started.emit(total_stages - current_stage, enemy_entities)
    _start_player_turn()

func _end_battle(victory: bool) -> void:
    var rewards = {}
    if victory:
        rewards = _calculate_rewards()
        # 战斗结算
        player_entity.shield = 0
        player_entity.action_points = 0
        # 移除区卡回归卡组
        for card_id in removed_cards:
            draw_pile.append(card_id)
        removed_cards.clear()
    
    battle_ended.emit(victory, rewards)

# === 卡牌打出 ===

func play_card(card_id: String, target_position: int) -> bool:
    """打出卡牌"""
    # 检查费用
    var card_data = CardManager.get_card(card_id)
    if card_data == null:
        return false
    
    if player_entity.action_points < card_data.cost:
        return false  # 费用不足
    
    # 扣除费用
    player_entity.action_points -= card_data.cost
    
    # 结算卡牌效果
    _resolve_card_effect(card_id, target_position)
    
    # 移动卡牌到对应区域
    hand_cards.erase(card_id)
    if card_data.remove_after_use:
        removed_cards.append(card_id)
    else:
        discard_pile.append(card_id)
    
    card_played.emit(card_id, target_position)
    return true

func _resolve_card_effect(card_id: String, target_pos: int) -> void:
    var card_data = CardManager.get_card(card_id)
    if card_data == null:
        return
    
    match card_data.type:
        CardManager.CardType.ATTACK:
            _resolve_attack(card_data, target_pos)
        CardManager.CardType.SKILL:
            _resolve_skill(card_data, target_pos)
        CardManager.CardType.TROOP:
            _resolve_troop(card_data, target_pos)
        CardManager.CardType.CURSE:
            _resolve_curse(card_data, target_pos)

func _resolve_attack(card_data: CardData, target_pos: int) -> void:
    if target_pos < 0 or target_pos >= enemy_entities.size():
        return
    
    var enemy = enemy_entities[target_pos]
    if enemy.current_hp <= 0:
        return
    
    # 计算伤害
    var base_damage = card_data.lv1_damage
    if card_data.status_effect != "":
        base_damage = StatusManager.calculate_damage_modifier(player_entity, base_damage)
    
    # 地形/天气修正
    var terrain_mod = TerrainWeatherSystem.get_terrain_modifier(terrain, card_data.category)
    var weather_mod = TerrainWeatherSystem.get_weather_modifier(weather, card_data.category)
    var final_damage = int(base_damage * terrain_mod * weather_mod)
    
    # 应用状态效果
    if card_data.status_effect != "":
        StatusManager.apply_status(enemy, card_data.status_effect, card_data.status_stacks, "player_attack")
    
    # 造成伤害
    var actual = enemy.take_damage(final_damage, card_data.penetrate_shield)
    damage_dealt.emit(target_pos, actual, false)

# === 抽牌与牌堆管理 ===

func _draw_cards(count: int) -> void:
    for i in range(count):
        if hand_cards.size() >= _get_hand_limit():
            break  # 手牌已满
        
        if draw_pile.is_empty():
            if discard_pile.is_empty():
                break  # 无牌可抽
            # 洗牌
            draw_pile = discard_pile.duplicate()
            discard_pile.clear()
            draw_pile.shuffle()
        
        var card_id = draw_pile.pop_front()
        hand_cards.append(card_id)
        
        # 检查是否是诅咒卡（抽到触发型）
        _check_curse_trigger(card_id)

func _get_hand_limit() -> int:
    # 袁绍被动：6张手牌
    if player_entity.id == "cao_sao":
        return 6
    return 5

# === 状态结算 ===

func _process_status_start_turn(entity: BattleEntity) -> void:
    # 回合开始时状态效果
    pass

func _process_status_end_turn(entity: BattleEntity) -> void:
    # 回合结束时状态结算
    StatusManager.tick_status(entity)
```

### 战斗流程状态机

```
[战斗开始]
    ↓
[玩家回合开始] → 状态触发 → 抽牌 → 出牌阶段
    ↓
[玩家结束回合]
    ↓
[敌人回合] → 按顺序执行行动 → 阶段检查
    ↓
    ├─ 阶段未完成 → [玩家回合开始]
    ├─ 进入下一阶段 → [阶段切换] → [玩家回合开始]
    └─ 战斗结束 → [胜利/失败结算]
```

### 伤害计算公式

```
有效伤害 = BaseDamage × 地形修正 × 天气修正 × 状态修正

护盾计算:
  若 Shield > 0:
    Shield -= min(Shield, 有效伤害)
    HP溢出 = max(0, 有效伤害 - Shield)
    HP -= HP溢出
  若 Shield = 0:
    HP -= 有效伤害

无视护甲: 直接扣HP，跳过护盾
```

## Alternatives Considered

### Alternative 1: 分布式战斗实体
- **描述**: 每个单位独立处理自己的回合
- **优点**: 简单
- **缺点**: 难以协调全局状态（如阶段切换）
- **未采用原因**: 需要全局协调

### Alternative 2: 纯事件驱动
- **描述**: 所有战斗逻辑通过事件触发
- **优点**: 解耦
- **缺点**: 难以追踪执行顺序
- **未采用原因**: 战斗顺序必须明确

### Alternative 3: BattleManager + 状态机 (推荐方案)
- **描述**: 集中管理器 + 阶段状态机
- **优点**: 全局控制明确，易于调试
- **采用原因**: 符合需求

## Consequences

### Positive
- **全局控制**: 所有战斗逻辑在 BattleManager
- **阶段明确**: 状态机保证执行顺序
- **易于调试**: 所有事件通过 Signal 发出
- **集成方便**: 其他系统通过接口交互

### Negative
- **单点风险**: BattleManager 是核心
- **复杂性**: 状态机需要仔细设计

### Risks
- **状态同步**: 多实体状态需要同步
  - **缓解**: 使用 Signal 驱动
- **性能**: 大量伤害计算
  - **缓解**: 按需计算

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| card-battle-system.md | 1v3战场结构 | enemy_entities 数组支持最多3个 |
| card-battle-system.md | 回合流程 | 状态机控制 PLAYER_START → ... → PHASE_CHECK |
| card-battle-system.md | 卡牌生命周期 | draw_pile/hand/discard/removed/exhaust 分区管理 |
| card-battle-system.md | 伤害计算 | _resolve_attack() 实现 F1 公式 |
| card-battle-system.md | 多阶段战斗 | current_stage/total_stages + 阶段切换逻辑 |
| card-battle-system.md | 抽牌逻辑 | _draw_cards() 实现 F3 公式 |

## Performance Implications
- **CPU**: 每次伤害计算 < 0.1ms
- **Memory**: 战斗状态约 1KB

## Migration Plan
1. 创建 BattleManager.gd
2. 实现战斗实体数据结构
3. 实现回合状态机
4. 实现卡牌打出和伤害结算
5. 与 StatusManager 集成
6. 与 EnemySystem 集成
7. 编写单元测试

## Validation Criteria
- [ ] 1 vs 1~3 敌人战场正确初始化
- [ ] 回合流程按顺序执行
- [ ] 卡牌正确流转（抽牌→手牌→打出→弃牌）
- [ ] 伤害计算正确（护盾优先）
- [ ] 多阶段战斗正确切换
- [ ] 敌人行动正确执行

## Related Decisions
- ADR-0001 (已 Accepted): 场景管理策略
- ADR-0002 (已 Accepted): 系统间通信模式
- ADR-0003 (已 Accepted): 资源变更通知机制
- ADR-0006 (已 Accepted): 状态效果系统
- ADR-000? (待创建): 敌人系统 — 依赖本 ADR