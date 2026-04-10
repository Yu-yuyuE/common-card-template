# Story: 装备购买与槽位管理

> **Type**: Integration
> **Epic**: shop-system
> **ADR**: ADR-0012
> **Status**: Ready

## Context

装备区展示2件随机装备。购买后立即装备，若装备槽已满则触发替换流程。装备价格=等级×40金。

**依赖**：
- ADR-0012 (Shop System) - 装备槽位管理

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 装备区展示2件随机装备 | UI测试：进入商店验证 |
| AC2 | 购买装备立即装备 | 功能测试：购买后验证装备栏 |
| AC3 | 槽满时显示替换提示 | UI测试：6件装备时购买显示提示 |
| AC4 | 装备价格=等级×40金 | 功能测试：1级40,2级80,3级120 |

## Implementation Notes

### 装备购买逻辑

```gdscript
class EquipmentPurchaser:

    const PRICE_PER_TIER = 40

    func purchase_equipment(equipment_id: String, current_gold: int) -> Dictionary:
        var equipment = EquipmentSystem.get_equipment(equipment_id)
        var price = equipment.tier * PRICE_PER_TIER

        if current_gold < price:
            return {success: false, reason: "金币不足"}

        var current_count = EquipmentSystem.get_equipped_count()

        if current_count >= EquipmentSystem.get_carry_limit():
            # 槽位已满，需要替换
            return {
                success: false,
                reason: "装备槽已满",
                requires_replace: true,
                price: price
            }

        # 扣除金币并装备
        ResourceSystem.modify_gold(-price)
        EquipmentSystem.equip(equipment)

        return {success: true, gold_spent: price}

    func purchase_with_replace(equipment_id: String, replace_target_id: String, current_gold: int) -> Dictionary:
        var equipment = EquipmentSystem.get_equipment(equipment_id)
        var price = equipment.tier * PRICE_PER_TIER

        if current_gold < price:
            return {success: false, reason: "金币不足"}

        # 替换装备
        ResourceSystem.modify_gold(-price)
        EquipmentSystem.replace(replace_target_id, equipment)

        return {success: true, gold_spent: price}
```

## QA Test Cases

1. **test_equipment_display** - 装备区显示
2. **test_equipment_purchase** - 购买装备
3. **test_full_slot_replace** - 槽满替换
4. **test_equipment_price** - 装备价格
