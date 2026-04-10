# Story: 装备携带与替换机制

> **Type**: Logic
> **Epic**: equipment-system
> **ADR**: ADR-0005, ADR-0010
> **Status**: Ready

## Context

装备携带上限默认5件，袁绍特殊6件。满载后获得新装备触发替换流程。替换后被移除的装备永久失去。同名装备可携带但效果不叠加。

**依赖**：
- ADR-0005 (Save Serialization) - 装备状态持久化
- ADR-0010 (Hero System) - 袁绍被动修改上限

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 默认携带上限5件，满5件后获得新装备触发替换 | 功能测试：5件后购买第6件，验证替换界面 |
| AC2 | 袁绍携带上限6件 | 功能测试：袁绍5件后第6件直接装备 |
| AC3 | 替换时被移除装备永久失去 | 功能测试：移除装备后该局不可找回 |
| AC4 | 同名装备可携带但仅第一件生效 | 数值测试：2件玄甲，护甲+10（非+20） |
| AC5 | 袁绍满6件后触发替换流程 | 功能测试：袁绍6件后第7件触发替换 |

## Implementation Notes

### 携带管理接口

```gdscript
class EquipmentManager:
    var equipped_items: Array[EquipmentData] = []
    var carry_limit: int = 5

    func can_equip(equipment: EquipmentData) -> bool:
        return equipped_items.size() < carry_limit

    func equip(equipment: EquipmentData) -> bool:
        if equipped_items.size() >= carry_limit:
            return false  # 需要触发替换流程
        equipped_items.append(equipment)
        return true

    func replace(old_equipment: EquipmentData, new_equipment: EquipmentData) -> bool:
        var index = equipped_items.find(old_equipment)
        if index == -1:
            return false
        equipped_items[index] = new_equipment
        return true

    func is_effect_active(equipment: EquipmentData) -> bool:
        # 检查同名装备：仅第一件生效
        var first_index = -1
        for i in range(equipped_items.size()):
            if equipped_items[i].equipment_id == equipment.equipment_id:
                if first_index == -1:
                    first_index = i
                else:
                    return false  # 后续同名装备不生效
        return true
```

### 袁绍特殊处理

```gdscript
func set_carry_limit(hero_id: String):
    if hero_id == "hero_yuanshao":
        carry_limit = 6  # 袁绍被动
    else:
        carry_limit = 5
```

## QA Test Cases

1. **test_default_5_slot_limit** - 默认5件上限
2. **test_yuanshao_6_slot_limit** - 袁绍6件上限
3. **test_replace_equipment** - 替换流程
4. **test_same_name_no_stack** - 同名不叠加
5. **test_removed_equipment_lost** - 移除后永久失去
