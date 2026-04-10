# Story: 商店UI交互

> **Type**: UI
> **Epic**: shop-system
> **ADR**: ADR-0016
> **Status**: Ready

## Context

商店UI需要展示三个货架区，提供购买/升级交互，显示金币余额，处理不可用状态的按钮置灰。

**依赖**：
- ADR-0016 (UI Data Binding) - UI数据绑定

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 商店UI正确显示卡牌区/升级区/装备区 | UI测试：进入商店验证三区显示 |
| AC2 | 当前金币正确显示在UI | UI测试：验证金币显示 |
| AC3 | 不可用按钮正确置灰并显示原因 | UI测试：金币不足时按钮置灰 |
| AC4 | 购买/升级后UI即时更新 | 功能测试：购买后验证刷新 |

## Implementation Notes

### UI状态管理

```gdscript
class ShopUIState:

    var current_gold: int
    var card_shelves: Array[CardSlot]
    var upgrade_cards: Array[CardData]
    var equipment_shelves: Array[EquipmentData]

    func update_from_system(shop: ShopSystem):
        current_gold = ResourceSystem.get_gold()
        card_shelves = shop.get_card_shelves()
        upgrade_cards = shop.get_upgradable_cards()
        equipment_shelves = shop.get_equipment_shelves()

    func can_purchase_card(slot: CardSlot) -> bool:
        return current_gold >= slot.price and not slot.is_purchased

    func can_upgrade_card(card: CardData) -> bool:
        var price = ShopSystem.get_upgrade_price(card.card_id)
        return current_gold >= price

    func can_purchase_equipment(equipment: EquipmentData) -> bool:
        var price = equipment.tier * 40
        return current_gold >= price

    func get_button_text(slot: CardSlot) -> String:
        if slot.is_purchased:
            return "已购买"
        var price_text = "%d 金" % slot.price
        return "购买 (%s)" % price_text

    func get_upgrade_button_text(card: CardData) -> String:
        var price = ShopSystem.get_upgrade_price(card.card_id)
        var price_text = "%d 金" % price
        return "升级 (%s)" % price_text
```

## QA Test Cases

1. **test_shop_ui_display** - UI显示
2. **test_gold_display** - 金币显示
3. **test_button_states** - 按钮状态
4. **test_ui_refresh** - UI刷新
