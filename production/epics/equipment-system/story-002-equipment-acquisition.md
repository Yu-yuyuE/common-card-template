# Story: 装备获取渠道

> **Type**: Logic
> **Epic**: equipment-system
> **ADR**: ADR-0012, ADR-0011
> **Status**: Ready

## Context

装备通过两个渠道获取：商店节点购买和战斗胜利后的装备奖励事件。商店展示2件（祭酒令效果可额外+1），奖励事件3选1。

**依赖**：
- ADR-0012 (Shop System) - 商店购买接口
- ADR-0011 (Map Node System) - 战斗奖励事件触发

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 商店节点展示2件随机装备供购买 | UI测试：进入商店验证装备区显示 |
| AC2 | 战斗胜利后约10%概率触发装备奖励事件 | 统计测试：500场普通战斗奖励触发次数 |
| AC3 | 奖励事件展示3件装备供选择（3选1） | UI测试：触发奖励时验证3件显示 |
| AC4 | 可选择跳过奖励而不获取装备 | 功能测试：奖励事件选择跳过 |
| AC5 | 祭酒令携带时商店展示3件装备 | 配置测试：携带祭酒令进商店验证 |

## Implementation Notes

### 获取接口设计

```gdscript
class_name EquipmentSystem extends Node

# 商店获取
func get_shop_equipment_display(hero_id: String) -> Array[EquipmentData]:
    var count = 2
    if has_equipment(hero_id, "祭酒令"):
        count += 1
    return select_random_equipment(count)

func purchase_equipment(hero_id: String, equipment_id: String, cost: int) -> bool:
    # 验证金币足够
    # 检查携带上限
    # 执行装备或替换流程
    return true

# 战斗奖励获取
func trigger_battle_reward(hero_id: String, difficulty: String) -> Array[EquipmentData]:
    var chance = 0.10
    if difficulty == "elite":
        chance *= 1.5  # 15%

    if randf() > chance:
        return []  # 未触发

    return select_random_equipment(3)  # 3选1
```

### 奖励概率公式

```
RewardChance = BaseChance × DifficultyMult
普通战斗：10%
精英战斗：15%
Boss战：0%
```

## QA Test Cases

1. **test_shop_display_2_equipment** - 商店展示2件
2. **test_shop_display_3_with_relic** - 祭酒令时展示3件
3. **test_battle_reward_10_percent** - 10%基础概率
4. **test_battle_reward_3_options** - 3选1奖励
5. **test_skip_reward** - 可跳过奖励
