# Story: 卡牌购买逻辑

> **Type**: Logic
> **Epic**: shop-system
> **ADR**: ADR-0003
> **Status**: Ready

## Context

玩家选择卡牌后确认金币，扣除金币后卡牌立即加入卡组（以展示等级加入，Lv1或Lv2）。购买不受卡组总数限制，不可退货。

**依赖**：
- ADR-0003 (Resource Notification) - 金币扣除

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 购买卡牌后金币正确扣除 | 功能测试：购买验证金币变化 |
| AC2 | 购买的卡牌以对应等级加入卡组 | 功能测试：购买Lv2卡，验证卡组中为Lv2 |
| AC3 | 金币不足时按钮置灰 | UI测试：金币30购买50金卡，置灰 |
| AC4 | 卡牌购买后不补货（空位保留） | 功能测试：购买后检查货架 |

## Implementation Notes

### 购买逻辑

```gdscript
class CardPurchaser:

    const BASE_PRICE = 50
    const LV2_MULTIPLIER = 1.8

    # 价格公式
    # PriceLv1 = 50 × RarityMult (普通1.0/高级1.5/稀有2.0)
    # PriceLv2 = PriceLv1 × 1.8

    func purchase_card(slot: CardSlot, current_gold: int) -> Dictionary:
        # 验证金币
        if current_gold < slot.price:
            return {success: false, reason: "金币不足"}

        # 扣除金币
        ResourceSystem.modify_gold(-slot.price)

        # 加入卡组
        var card_level = 2 if slot.is_lv2 else 1
        CardSystem.add_card_to_deck(slot.card_id, card_level)

        # 标记该位置为空（不补货）
        mark_slot_empty(slot)

        return {success: true, gold_spent: slot.price}
```

## QA Test Cases

1. **test_card_purchase** - 购买成功
2. **test_card_purchase_lv2** - Lv2卡购买
3. **test_insufficient_gold_block** - 金币不足阻止
4. **test_no_restock** - 购买后不补货
