# Story: 商店货架生成

> **Type**: Logic
> **Epic**: shop-system
> **ADR**: ADR-0012
> **Status**: Ready

## Context

商店节点进入时生成三个货架区：卡牌区×4、升级区、装备区×2。卡牌区每张独立判定Lv2（15%概率），州专属卡以20%概率出现。

**依赖**：
- ADR-0012 (Shop System) - ShopManager 集中管理

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 进入商店生成卡牌区×4、升级区、装备区×2 | 功能测试：访问商店验证三区显示 |
| AC2 | 4张卡牌不重复（ID唯一） | 数据验证：检查货架卡牌ID |
| AC3 | 每张卡独立15%概率为Lv2 | 统计测试：1000次生成，Lv2出现率10%-20% |
| AC4 | 州专属卡20%概率出现 | 统计测试：固定州500次，州专属卡15%-25% |

## Implementation Notes

### 货架生成逻辑

```gdscript
class ShopShelfGenerator:

    const CARD_SLOT_COUNT = 4
    const EQUIPMENT_SLOT_COUNT = 2

    const LV2_CHANCE = 0.15
    const REGIONAL_CHANCE = 0.20
    const PROGRESS_BONUS_PER_MAP = 0.05

    func generate_shelves(hero_id: String, current_map: int, state: String) -> ShopShelves:
        var shelves = ShopShelves.new()

        # 卡牌区
        shelves.cards = generate_card_slots(hero_id, current_map, state)

        # 升级区（从卡组读取）
        shelves.upgrades = generate_upgrade_slots()

        # 装备区
        shelves.equipment = generate_equipment_slots()

        return shelves

    func generate_card_slots(hero_id: String, current_map: int, state: String) -> Array[CardSlot]:
        var slots = []
        var used_ids = []

        for i in range(CARD_SLOT_COUNT):
            var card_pool = select_card_pool()  # 60%攻击/40%技能
            var is_lv2 = randf() < LV2_CHANCE

            var card_id = select_random_card(card_pool, used_ids)
            used_ids.append(card_id)

            # 州专属卡判定
            var regional_bonus = (current_map - 1) * PROGRESS_BONUS_PER_MAP
            var regional_chance = REGIONAL_CHANCE + regional_bonus
            if randf() < regional_chance:
                var regional_card = select_regional_card(state, used_ids)
                if regional_card != "":
                    card_id = regional_card

            var price = calculate_card_price(card_id, is_lv2)

            slots.append(CardSlot.new(card_id, is_lv2, price))

        return slots
```

## QA Test Cases

1. **test_shelf_generation** - 货架生成
2. **test_no_duplicate_cards** - 卡牌不重复
3. **test_lv2_chance** - Lv2概率
4. **test_regional_card_chance** - 州专属卡概率
