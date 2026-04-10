# Story: 装备效果计算与叠加

> **Type**: Logic
> **Epic**: equipment-system
> **ADR**: ADR-0007
> **Status**: Ready

## Context

装备效果分为常驻被动和条件触发两类。百分比加成相加计算，固定值直接叠加。触发类效果独立判定。"低血时"每回合开始检查。

**依赖**：
- ADR-0007 (Card Battle System) - 战斗事件触发

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 百分比加成相加计算（+20%+15%=+35%） | 数值测试：两件装备最终+35% |
| AC2 | 固定值直接叠加 | 数值测试：两件+5装备最终+10 |
| AC3 | 条件触发效果独立判定 | 功能测试：两件"攻击命中时"各自独立判定 |
| AC4 | "低血时"每回合开始检查HP≤30% | 功能测试：35%受伤到25%下回合生效 |
| AC5 | "首次受击"每场战斗只触发一次 | 功能测试：3次受击只触发第1次 |

## Implementation Notes

### 效果计算公式

```gdscript
func calculate_total_modifier(stat: String) -> Dictionary:
    var percent_bonus: float = 0.0
    var flat_bonus: int = 0

    for equip in equipped_items:
        if not is_effect_active(equip):
            continue

        # 常驻被动
        if equip.passive_stat_modifiers.has(stat):
            var value = equip.passive_stat_modifiers[stat]
            if value is float and value < 1.0:  # 百分比
                percent_bonus += value
            elif value is int:
                flat_bonus += value

    return {
        "percent": percent_bonus,
        "flat": flat_bonus,
        "final": lambda base: int(base * (1 + percent_bonus) + flat_bonus)
    }

func apply_trigger_effects(condition: TriggerCondition, context: Dictionary):
    for equip in equipped_items:
        if not is_effect_active(equip):
            continue
        if equip.trigger_condition != condition:
            continue

        # 触发概率判定
        if randf() > equip.trigger_chance:
            continue

        execute_trigger_effect(equip.trigger_effect, context)
```

### 触发条件检查

```gdscript
func check_low_hp_trigger(current_hp: int, max_hp: int) -> bool:
    return float(current_hp) / float(max_hp) <= 0.30

var first_damage_this_battle: bool = true

func check_first_damage_trigger() -> bool:
    if first_damage_this_battle:
        first_damage_this_battle = false
        return true
    return false
```

## QA Test Cases

1. **test_percent_bonus_addition** - 百分比相加
2. **test_flat_bonus_addition** - 固定值叠加
3. **test_trigger_independent** - 触发独立判定
4. **test_low_hp_round_start_check** - 低血回合开始检查
5. **test_first_damage_once_per_battle** - 首次受击每战一次
