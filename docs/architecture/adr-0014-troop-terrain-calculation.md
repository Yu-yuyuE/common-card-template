# ADR-0014: 兵种卡地形联动计算顺序

## Status

Accepted

## Date

2026-04-09

## Engine Compatibility

| Field                     | Value                                    |
| ------------------------- | ---------------------------------------- |
| **Engine**                | Godot 4.6.1                              |
| **Domain**                | Core / Combat                            |
| **Knowledge Risk**        | LOW                                      |
| **References Consulted**  | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None                                     |
| **Verification Required** | None — standard arithmetic operations    |

## ADR Dependencies

| Field             | Value                                                                           |
| ----------------- | ------------------------------------------------------------------------------- |
| **Depends On**    | ADR-0001 (场景管理策略), ADR-0002 (系统间通信模式), ADR-0003 (资源变更通知机制) |
| **Enables**       | 兵种卡战斗系统、地形天气系统                                                    |
| **Blocks**        | 无直接阻塞                                                                      |
| **Ordering Note** | 本 ADR 依赖战斗系统基础通信框架，应在 ADR-0002 之后编写                         |

## Context

### Problem Statement

战斗伤害计算涉及多个步骤和修正系数：

1. **基础伤害**: 卡牌/兵种的原始伤害值
2. **地形修正**: 不同地形对不同兵种的伤害加成/减免
3. **天气修正**: 天气状态对伤害的额外影响
4. **状态效果修正**: Buff/Debuff 对伤害的加成/减免

需要明确这些修正的执行顺序，以确保计算结果的一致性和可预测性。

### Constraints

- **可调试**: 伤害计算过程应该可追踪，便于排查问题
- **性能**: 计算应在单帧内完成，不超过0.1ms
- **一致性**: 相同输入必须产生相同输出

### Requirements

- 地形修正必须在天气修正之前应用
- 状态效果修正必须在所有基础修正之后应用
- 最终伤害不能为负数
- 伤害计算过程需要记录日志

## Decision

### 方案: 分步乘法累计模式 (Sequential Multiplicative Pipeline)

采用 **基础值 × 地形系数 × 天气系数 × 状态系数** 的分步计算：

```
伤害计算流程:
┌─────────────────────────────────────────────────────────────┐
│ Step 1: 获取基础伤害值                                      │
│   BaseDamage = CardData.lv1_damage / Lv2_damage            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 2: 应用地形修正 (乘法)                                 │
│   TerrainModified = BaseDamage × TerrainModifier           │
│   地形系数表:                                               │
│   - 森林: 步兵×1.0, 弓兵×1.0, 骑兵×1.0                     │
│   - 山地: 步兵×1.0, 弓兵×1.0, 骑兵×0.5                     │
│   - 平原: 步兵×1.0, 弓兵×1.0, 骑兵×1.5                     │
│   - 水域: 步兵×1.0, 弓兵×1.0, 骑兵×1.0                     │
│   - 沙漠: 步兵×1.0, 弓兵×1.0, 骑兵×1.0                     │
│   - 雪地: 步兵×1.0, 弓兵×1.0, 骑兵×1.0                     │
│   - 关隘: 步兵×1.0, 弓兵×1.0, 骑兵×1.0                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 3: 应用天气修正 (乘法)                                 │
│   WeatherModified = TerrainModified × WeatherModifier      │
│   天气系数表:                                               │
│   - 晴: 所有兵种×1.0                                      │
│   - 雨: 所有兵种×1.0                               │
│   - 风: 所有兵种×1.0                │
│   - 雾: 所有兵种×1.0                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 4: 应用状态效果修正 (加法/乘法混合)                    │
│   StatusModified = WeatherModified × (1 + Sum(StatusBonuses))
│   增益状态: +10%/层 (attack_up)                            │
│   减益状态: -10%/层 (attack_down)                          │
│   最大加成: ±50% (5层)                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 5: 最终处理                                            │
│   FinalDamage = max(1, round(StatusModified))              │
│   最小伤害为1，避免0伤害                                    │
└─────────────────────────────────────────────────────────────┘
```

### 核心实现代码

```gdscript
# damage_calculator.gd
class_name DamageCalculator extends Node

# 地形伤害系数表
const TERRAIN_MODIFIERS = {
    "forest": {"infantry": 1.5, "archer": 1.2, "cavalry": 0.8, "default": 1.0},
    "mountain": {"infantry": 1.3, "archer": 1.5, "cavalry": 0.6, "default": 1.0},
    "plain": {"infantry": 1.0, "archer": 1.0, "cavalry": 1.5, "default": 1.0},
    "water": {"infantry": 0.8, "archer": 0.7, "cavalry": 0.5, "default": 1.0},
    "desert": {"infantry": 0.9, "archer": 0.9, "cavalry": 1.3, "default": 1.0},
    "snow": {"infantry": 0.7, "archer": 0.7, "cavalry": 1.2, "default": 1.0},
    "town": {"infantry": 1.2, "archer": 1.0, "cavalry": 0.9, "default": 1.0}
}

# 天气伤害系数表
const WEATHER_MODIFIERS = {
    "sunny": {"default": 1.0},
    "light_rain": {"archer": 0.8, "default": 1.0},
    "heavy_rain": {"archer": 0.6, "default": 1.0},
    "light_snow": {"infantry": 0.9, "archer": 0.9, "cavalry": 1.1, "default": 1.0},
    "heavy_snow": {"infantry": 0.7, "archer": 0.7, "cavalry": 1.3, "default": 1.0},
    "sandstorm": {"archer": 0.7, "default": 0.9},
    "fog": {"default": 0.8}  # 远程攻击命中率降低
}

# 状态效果加成上限
const MAX_STATUS_BONUS = 0.5  # ±50%
const STATUS_BONUS_PER_STACK = 0.1  # 每层±10%

func calculate_damage(
    base_damage: int,
    troop_category: String,      # infantry/archer/cavalry
    terrain: String,
    weather: String,
    status_effects: Array[String]  # e.g., ["attack_up", "attack_down"]
) -> int:
    var damage = float(base_damage)

    # Step 1: 地形修正
    damage *= _get_terrain_modifier(terrain, troop_category)

    # Step 2: 天气修正
    damage *= _get_weather_modifier(weather, troop_category)

    # Step 3: 状态效果修正
    damage *= _get_status_modifier(status_effects)

    # Step 4: 最终处理
    damage = max(1, round(damage))
    return int(damage)

func _get_terrain_modifier(terrain: String, category: String) -> float:
    var terrain_data = TERRAIN_MODIFIERS.get(terrain, TERRAIN_MODIFIERS["plain"])
    return terrain_data.get(category, terrain_data["default"])

func _get_weather_modifier(weather: String, category: String) -> float:
    var weather_data = WEATHER_MODIFIERS.get(weather, WEATHER_MODIFIERS["sunny"])
    return weather_data.get(category, weather_data["default"])

func _get_status_modifier(statuses: Array[String]) -> float:
    var total_bonus = 0.0
    for status in statuses:
        match status:
            "attack_up": total_bonus += STATUS_BONUS_PER_STACK
            "attack_down": total_bonus -= STATUS_BONUS_PER_STACK
            "powerful": total_bonus += STATUS_BONUS_PER_STACK * 2  # 强效攻击

    # 限制在±50%范围内
    total_bonus = clamp(total_bonus, -MAX_STATUS_BONUS, MAX_STATUS_BONUS)
    return 1.0 + total_bonus
```

### 伤害计算日志示例

```gdscript
# 调试日志输出
func calculate_damage_with_log(...) -> int:
    var damage = float(base_damage)
    print("=== Damage Calculation ===")
    print("Base Damage: %d" % base_damage)

    # 地形
    var terrain_mod = _get_terrain_modifier(terrain, troop_category)
    damage *= terrain_mod
    print("After Terrain (x%.2f): %d" % [terrain_mod, damage])

    # 天气
    var weather_mod = _get_weather_modifier(weather, troop_category)
    damage *= weather_mod
    print("After Weather (x%.2f): %d" % [weather_mod, damage])

    # 状态
    var status_mod = _get_status_modifier(status_effects)
    damage *= status_mod
    print("After Status (x%.2f): %d" % [status_mod, damage])

    # 最终
    damage = max(1, round(damage))
    print("Final Damage: %d" % damage)
    return int(damage)
```

## Alternatives Considered

### Alternative 1: 一次性计算公式

- **描述**: 使用单个公式: `damage = base * terrain * weather * (1 + status_sum)`
- **优点**: 代码简洁
- **缺点**: 难以调试，无法追踪每个修正阶段的贡献
- **未采用原因**: 可调试性差

### Alternative 2: 加法累计模式

- **描述**: `damage = base + terrain_bonus + weather_bonus + status_bonus`
- **优点**: 简单直观
- **缺点**: 乘法和加法混用不符合游戏设计惯例（通常使用乘法系数）
- **未采用原因**: 不符合行业标准

### Alternative 3: 分步乘法 (推荐方案)

- **描述**: 分阶段应用乘法系数，每阶段可独立调试
- **优点**: 可追踪、易调试、符合行业惯例
- **采用原因**: 平衡了可维护性和准确性

## Consequences

### Positive

- **可追踪**: 每步计算可单独日志输出
- **易调试**: 可快速定位哪一步导致异常结果
- **可扩展**: 新增修正系数只需插入新步骤
- **一致性**: 固定顺序确保每次计算结果相同

### Negative

- **代码量**: 相对单公式略多
- **性能**: 多次乘法微乎其微，可忽略

### Risks

- **系数配置错误**: 地形/天气系数表配置错误导致伤害异常
  - **缓解**: 启动时校验系数表完整性
- **状态效果遗漏**: 新增状态效果忘记更新计算逻辑
  - **缓解**: 使用常量定义所有状态类型

## GDD Requirements Addressed

| GDD System                     | Requirement             | How This ADR Addresses It  |
| ------------------------------ | ----------------------- | -------------------------- |
| troop-cards-design.md (D2)     | 兵种卡地形×天气联动     | Terrain × Weather 乘法系数 |
| terrain-weather-system.md (D1) | 7地形×4天气对战斗的影响 | 地形/天气系数表定义        |
| card-battle-system.md (C2)     | 伤害公式                | 分步计算流程定义           |
| status-design.md (C1)          | 状态效果对伤害的修正    | StatusModifier 乘法系数    |

## Performance Implications

- **CPU**: 单次计算 < 0.01ms（简单浮点运算）
- **Memory**: 仅存储系数表，约 1KB
- **复杂度**: O(1) 时间复杂度

## Migration Plan

1. 创建 DamageCalculator.gd 类
2. 实现地形/天气系数表
3. 实现状态效果加成逻辑
4. 集成到 CardBattleSystem
5. 添加调试日志功能
6. 编写单元测试验证各步骤

## Validation Criteria

- [ ] 相同输入产生相同输出
- [ ] 地形修正正确应用（测试所有7种地形）
- [ ] 天气修正正确应用（测试所有4种天气）
- [ ] 状态效果加成在±50%范围内
- [ ] 最小伤害为1
- [ ] 伤害计算日志正确输出

## Related Decisions

- ADR-0001: 场景管理策略 — 战斗场景结构
- ADR-0002: 系统间通信模式 — Signal 通信
- ADR-0003: 资源变更通知机制 — 伤害导致资源变化时通知
- ADR-0004: 卡牌数据配置格式 — 卡牌基础数据加载
