# Story: 装备战斗集成

> **Type**: Integration
> **Epic**: equipment-system
> **ADR**: ADR-0007
> **Status**: Ready

## Context

装备效果在战斗中的各个时机触发：回合开始、回合结束、攻击命中、首次受击等。需要与 CardBattleSystem 紧密集成。

**依赖**：
- ADR-0007 (Card Battle System) - 战斗事件监听

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 回合开始时触发 ROUND_START 装备效果 | 战斗测试：虎符每回合+1行动点 |
| AC2 | 回合结束时触发 ROUND_END 装备效果 | 战斗测试：玉玺未受伤抽1张 |
| AC3 | 攻击命中时触发 ON_ATTACK_HIT 装备效果 | 战斗测试：朱雀符30%概率附加灼烧 |
| AC4 | 首次受击时触发 ON_FIRST_DAMAGE 装备效果 | 战斗测试：铁胄免疫首次控制 |
| AC5 | 装备效果修改的资源正确应用到战斗 | 数值测试：玄甲初始+10护甲生效 |

## Implementation Notes

### 与 C2 集成点

```gdscript
class EquipmentBattleIntegration:

    func _ready():
        # 订阅战斗事件
        BattleSystem.connect("round_start", _on_round_start)
        BattleSystem.connect("round_end", _on_round_end)
        BattleSystem.connect("attack_hit", _on_attack_hit)
        BattleSystem.connect("damage_taken", _on_damage_taken)
        BattleSystem.connect("card_played", _on_card_played)

    func _on_round_start():
        # 触发 ROUND_START 类型装备
        apply_trigger_effects(TriggerCondition.ROUND_START, {})

        # 检查低血效果
        check_low_hp_effects()

    func _on_round_end():
        # 触发 ROUND_END 类型装备
        apply_trigger_effects(TriggerCondition.ROUND_END, {})

    func _on_attack_hit(attack_context: Dictionary):
        # 触发 ON_ATTACK_HIT 类型装备
        apply_trigger_effects(TriggerCondition.ON_ATTACK_HIT, attack_context)

    func _on_damage_taken(damage: int):
        # 首次受击检查
        if check_first_damage_trigger():
            apply_trigger_effects(TriggerCondition.ON_FIRST_DAMAGE, {damage: damage})

    func _on_card_played(card_data: CardData):
        var card_type = card_data.get_type()
        apply_trigger_effects(TriggerCondition.ON_CARD_PLAYED, {card_type: card_type})
```

### 资源修改接口

```gdscript
func apply_equipment_modifiers():
    var modifier = EquipmentSystem.calculate_total_modifier("armor")

    # 初始护甲加成（如玄甲+10）
    ResourceSystem.add_base_modifier("armor", modifier["flat"])

    # 其他资源类似...
```

## QA Test Cases

1. **test_round_start_trigger** - 回合开始触发
2. **test_round_end_trigger** - 回合结束触发
3. **test_attack_hit_trigger** - 攻击命中触发
4. **test_first_damage_trigger** - 首次受击触发
5. **test_card_played_trigger** - 打牌触发
