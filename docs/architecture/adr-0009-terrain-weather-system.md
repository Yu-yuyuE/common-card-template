# ADR-0009: 地形天气系统架构

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Feature / Environment |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0002 (系统间通信模式), ADR-0006 (状态效果系统), ADR-0007 (卡牌战斗系统) |
| **Enables** | C2 卡牌战斗系统伤害计算, D2 兵种卡系统 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 是 Feature 层环境系统，在 Core 层之后 |

## Context

### Problem Statement

地形天气系统需要管理：
- 7种地形：平原、山地、森林、水域、沙漠、关隘、雪地
- 4种天气：晴、风、雨、雾
- 地形固定，战斗中不可改变
- 天气可变，可动态切换
- 28种组合产生不同战场效果

### Constraints
- **性能**: 地形天气查询必须高效
- **一致性**: 修正系数必须统一

### Requirements
- 必须支持7种地形
- 必须支持4种天气
- 必须支持天气动态切换
- 必须提供伤害修正系数接口

## Decision

### 方案: 集中式 TerrainWeatherManager

采用 **环境管理器 + 修正系数查询** 模式：

```gdscript
# terrain_weather_manager.gd
class_name TerrainWeatherManager extends Node

# 地形类型
enum Terrain { PLAIN, MOUNTAIN, FOREST, WATER, DESERT, PASS, SNOW }

# 天气类型
enum Weather { CLEAR, WIND, RAIN, FOG }

# 当前战场环境
var current_terrain: Terrain = Terrain.PLAIN
var current_weather: Weather = Weather.CLEAR

# 天气切换冷却
var weather_cooldowns: Dictionary = {}  # source_id -> remaining_rounds
var weather_change_history: Array = []  # 切换历史

signal terrain_changed(new_terrain: Terrain)
signal weather_changed(new_weather: Weather)

# === 初始化 ===

func setup_battle(terrain_str: String, weather_str: String) -> void:
    current_terrain = _parse_terrain(terrain_str)
    current_weather = _parse_weather(weather_str)
    
    # 战斗初始化时施加地形效果
    _apply_terrain_init_effects()
    
    # 战斗初始化时施加天气效果
    if current_weather == Weather.FOG:
        _apply_fog_effect()

func _apply_terrain_init_effects() -> void:
    """战斗开始时的一次性地形效果"""
    match current_terrain:
        Terrain.WATER:
            # 所有单位获得1层滑倒
            _apply_status_to_all(StatusManager.StatusCategory.SLIP, 1)
        Terrain.PASS:
            # 敌方获得10护甲 + 2层坚守
            _apply_shield_to_enemy(10)
            StatusManager.apply_status(null, StatusManager.StatusCategory.DEFEND, 2, "terrain_pass")
        Terrain.SNOW:
            # 玩家获得2层冻伤
            StatusManager.apply_status(
                BattleManager.player_entity, 
                StatusManager.StatusCategory.FROSTBITE, 
                2, 
                "terrain_snow"
            )
        Terrain.FOREST:
            # 森林每回合结束施加中毒 - 在 tick 中处理
            pass
        Terrain.DESERT:
            # 沙漠每回合结束施加灼烧 - 在 tick 中处理
            pass

func _apply_fog_effect() -> void:
    """雾天：所有单位获得2层盲目"""
    _apply_status_to_all(StatusManager.StatusCategory.BLIND, 2)

func _apply_status_to_all(status: StatusManager.StatusCategory, layers: int) -> void:
    """对所有单位施加状态"""
    # 玩家
    StatusManager.apply_status(BattleManager.player_entity, status, layers, "weather_effect")
    # 敌人
    for enemy in BattleManager.enemy_entities:
        if enemy.is_alive:
            StatusManager.apply_status(enemy, status, layers, "weather_effect")

# === 天气切换 ===

func change_weather(new_weather: String, source_id: String, cooldown: int = 2) -> bool:
    """切换天气"""
    var new_weather_type = _parse_weather(new_weather)
    
    # 检查是否为相同天气
    if new_weather_type == current_weather:
        return false
    
    # 检查冷却
    if weather_cooldowns.has(source_id):
        if weather_cooldowns[source_id] > 0:
            return false  # 冷却中
    
    # 切换天气
    var old_weather = current_weather
    current_weather = new_weather_type
    
    # 设置冷却
    weather_cooldowns[source_id] = cooldown
    
    # 记录历史
    weather_change_history.append({
        "from": old_weather,
        "to": new_weather_type,
        "source": source_id,
        "timestamp": Time.get_unix_time_from_system()
    })
    
    weather_changed.emit(current_weather)
    return true

func tick_weather_effects() -> void:
    """每回合结束的天气效果"""
    match current_weather:
        Weather.WIND:
            # 风：灼烧传播
            _spread_burn()
        Weather.RAIN:
            # 雨：灼烧额外消减1层
            _reduce_burn_extra()

func _spread_burn() -> void:
    """灼烧传播到相邻单位"""
    var burned_units = []
    
    # 找出所有灼烧单位
    for enemy in BattleManager.enemy_entities:
        if enemy.is_alive and StatusManager.get_status(enemy, StatusManager.StatusCategory.BURN) > 0:
            burned_units.append(enemy)
    
    # 对每个灼烧单位，尝试传播给相邻单位
    for burned in burned_units:
        var adjacent = _get_adjacent_units(burned)
        for adj in adjacent:
            var adj_burn_layers = StatusManager.get_status(adj, StatusManager.StatusCategory.BURN)
            if adj_burn_layers == 0:
                StatusManager.apply_status(adj, StatusManager.StatusCategory.BURN, 1, "wind_spread")

func _reduce_burn_extra() -> void:
    """雨：灼烧额外消减1层"""
    # 玩家
    var player_burn = StatusManager.get_status(BattleManager.player_entity, StatusManager.StatusCategory.BURN)
    if player_burn > 0:
        StatusManager.remove_status(BattleManager.player_entity, StatusManager.StatusCategory.BURN)
        if player_burn > 1:
            StatusManager.apply_status(BattleManager.player_entity, StatusManager.StatusCategory.BURN, player_burn - 1, "rain_reduce")
    
    # 敌人
    for enemy in BattleManager.enemy_entities:
        if enemy.is_alive:
            var enemy_burn = StatusManager.get_status(enemy, StatusManager.StatusCategory.BURN)
            if enemy_burn > 0:
                StatusManager.remove_status(enemy, StatusManager.StatusCategory.BURN)
                if enemy_burn > 1:
                    StatusManager.apply_status(enemy, StatusManager.StatusCategory.BURN, enemy_burn - 1, "rain_reduce")

func tick_terrain_effects() -> void:
    """每回合结束的地形效果"""
    match current_terrain:
        Terrain.FOREST:
            # 森林：每回合结束对所有单位施加1层中毒
            _apply_status_to_all(StatusManager.StatusCategory.POISON, 1)
        Terrain.DESERT:
            # 沙漠：每回合结束对所有单位施加1层灼烧
            _apply_status_to_all(StatusManager.StatusCategory.BURN, 1)

# === 修正系数接口 ===

func get_terrain_modifier(card_category: String) -> float:
    """获取地形对卡牌类别的伤害修正"""
    match current_terrain:
        Terrain.PLAIN:
            if card_category == "cavalry":
                return 1.5  # 骑兵伤害+50%
            return 1.0
        Terrain.MOUNTAIN:
            if card_category == "cavalry":
                return 0.5  # 骑兵伤害-50%
            return 1.0
        Terrain.FOREST:
            if card_category == "burn":
                return 1.5  # 灼烧伤害+50%
            return 1.0
        Terrain.SNOW:
            if card_category == "burn":
                return 0.5  # 灼烧伤害-50%
            return 1.0
        Terrain.DESERT:
            if card_category == "cavalry":
                return 1.0  # 费用-1在打出时处理
            return 1.0
    return 1.0

func get_weather_modifier(card_category: String) -> float:
    """获取天气对卡牌类别的伤害修正"""
    # 天气对伤害无直接修正
    return 1.0

func get_cavalry_cost_modifier() -> int:
    """获取骑兵卡费用修正"""
    if current_terrain == Terrain.DESERT:
        return -1  # 费用-1
    return 0

func is_terrain_favorable(card_category: String) -> bool:
    """检查地形是否对某卡牌类别有利"""
    return get_terrain_modifier(card_category) > 1.0

func is_terrain_unfavorable(card_category: String) -> bool:
    """检查地形是否对某卡牌类别不利"""
    return get_terrain_modifier(card_category) < 1.0

# === 辅助方法 ===

func _parse_terrain(terrain_str: String) -> Terrain:
    match terrain_str.to_lower():
        "plain": return Terrain.PLAIN
        "mountain": return Terrain.MOUNTAIN
        "forest": return Terrain.FOREST
        "water": return Terrain.WATER
        "desert": return Terrain.DESERT
        "pass": return Terrain.PASS
        "snow": return Terrain.SNOW
    return Terrain.PLAIN

func _parse_weather(weather_str: String) -> Weather:
    match weather_str.to_lower():
        "clear": return Weather.CLEAR
        "wind": return Weather.WIND
        "rain": return Weather.RAIN
        "fog": return Weather.FOG
    return Weather.CLEAR

func _apply_shield_to_enemy(amount: int) -> void:
    """给敌方施加护甲"""
    for enemy in BattleManager.enemy_entities:
        if enemy.is_alive:
            enemy.armor += amount

func _get_adjacent_units(unit) -> Array:
    """获取相邻单位"""
    var result = []
    var unit_pos = unit.position
    
    # 简单的相邻判断（实际应根据战场布局）
    for enemy in BattleManager.enemy_entities:
        if enemy.is_alive and enemy != unit:
            var pos_diff = abs(enemy.position - unit_pos)
            if pos_diff == 1:  # 相邻位置
                result.append(enemy)
    
    return result
```

### 地形效果一览

| 地形 | 初始化效果 | 持续效果 | 伤害修正 |
|------|-----------|----------|----------|
| 平原 | - | - | 骑兵 +50% |
| 山地 | - | - | 骑兵 -50% |
| 森林 | - | 每回合中毒+1 | 灼烧 +50% |
| 水域 | 全体滑倒1层 | - | - |
| 沙漠 | - | 每回合灼烧+1 | 骑兵费用-1 |
| 关隘 | 敌方护甲+10, 坚守+2 | - | - |
| 雪地 | 玩家冻伤2层 | - | 灼烧 -50% |

### 天气效果一览

| 天气 | 初始化效果 | 持续效果 |
|------|-----------|----------|
| 晴 | - | - |
| 风 | - | 灼烧传播 |
| 雨 | - | 灼烧额外-1层 |
| 雾 | 全体盲目2层 | - |

## Alternatives Considered

### Alternative 1: 分布式环境管理
- **描述**: 每个场景自己管理地形天气
- **优点**: 简单
- **缺点**: 难以共享和查询
- **未采用原因**: 需要统一接口

### Alternative 2: TerrainWeatherManager (推荐方案)
- **描述**: 集中管理器 + 修正系数接口
- **优点**: 统一接口，易于查询
- **采用原因**: 符合需求

## Consequences

### Positive
- **统一接口**: 所有系统通过管理器查询
- **环境效果**: 提供差异化战场体验
- **动态天气**: 增加战斗变数

### Negative
- **复杂性**: 28种组合需要详细测试
- **状态管理**: 地形/天气状态需要跟踪

### Risks
- **效果冲突**: 多个效果叠加可能出问题
  - **缓解**: 明确的结算顺序
- **平衡问题**: 某些组合可能过强
  - **缓解**: 详细测试

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| terrain-weather-system.md | 7种地形 | Terrain 枚举覆盖 |
| terrain-weather-system.md | 4种天气 | Weather 枚举覆盖 |
| terrain-weather-system.md | 地形固定 | current_terrain 不可改变 |
| terrain-weather-system.md | 天气可变 | change_weather() 支持切换 |
| terrain-weather-system.md | 28种组合 | 修正系数覆盖所有组合 |
| terrain-weather-system.md | 天气切换冷却 | weather_cooldowns 管理 |

## Performance Implications
- **CPU**: 修正系数查询 O(1)
- **Memory**: 环境状态 < 100 字节

## Migration Plan
1. 创建 TerrainWeatherManager.gd
2. 实现地形效果初始化
3. 实现天气切换
4. 实现修正系数接口
5. 与战斗系统集成
6. 编写测试

## Validation Criteria
- [ ] 7种地形正确识别
- [ ] 4种天气正确识别
- [ ] 地形效果正确初始化
- [ ] 天气效果正确切换
- [ ] 修正系数正确返回
- [ ] 冷却机制正常工作

## Related Decisions
- ADR-0006 (已 Accepted): 状态效果系统
- ADR-0007 (已 Accepted): 卡牌战斗系统
