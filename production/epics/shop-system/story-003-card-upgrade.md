# Story: 卡牌升级价格与执行

> **Type**: Logic
> **Epic**: shop-system
> **ADR**: ADR-0005
> **Status**: Ready

## Context

升级区展示所有Lv1攻击卡/技能卡/武将专属卡。升级价格采用累进翻倍策略：首次60金，第2次120金，第3次240金。离开商店后重置。

**依赖**：
- ADR-0005 (Save Serialization) - 升级计数器持久化

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 升级区只展示Lv1攻击/技能/专属卡 | UI测试：诅咒卡/兵种卡不显示 |
| AC2 | 首次升级60金，第2次120金，第3次240金 | 功能测试：连续升级验证价格 |
| AC3 | 离开商店后升级计数器重置 | 功能测试：离开再进入，价格回60 |
| AC4 | 金币不足时升级按钮置灰 | UI测试：金币不足时不可升级 |

## Implementation Notes

### 升级价格逻辑

```gdscript
class CardUpgrader:

    const BASE_UPGRADE_PRICE = 60
    const HERO_EXCLUSIVE_MULT = 1.5
    const UPGRADE_MULTIPLIER = 2

    var upgrade_count: int = 1  # 本次访问升级次数

    func get_upgrade_price(card_id: String) -> int:
        var is_hero_exclusive = CardSystem.is_hero_exclusive(card_id)
        var type_mult = HERO_EXCLUSIVE_MULT if is_hero_exclusive else 1.0

        var price = BASE_UPGRADE_PRICE * type_mult * pow(UPGRADE_MULTIPLIER, upgrade_count - 1)
        return int(price)

    func upgrade_card(card_id: String, current_gold: int) -> Dictionary:
        var price = get_upgrade_price(card_id)

        if current_gold < price:
            return {success: false, reason: "金币不足"}

        if not can_upgrade(card_id):
            return {success: false, reason: "无法升级"}

        # 扣除金币
        ResourceSystem.modify_gold(-price)

        # 执行升级（M5系统）
        CardUpgradeSystem.upgrade_to_lv2(card_id)

        # 升级次数+1
        upgrade_count += 1

        return {success: true, gold_spent: price}

    func reset_on_leave():
        upgrade_count = 1

    func persist_upgrade_count():
        SaveSystem.save_data("shop_upgrade_count", upgrade_count)

    func load_upgrade_count():
        upgrade_count = SaveSystem.load_data("shop_upgrade_count", 1)
```

## QA Test Cases

1. **test_upgrade_display** - 升级区显示
2. **test_upgrade_price_progression** - 价格翻倍
3. **test_upgrade_count_reset** - 离开重置
4. **test_insufficient_gold_upgrade** - 金币不足阻止升级
