# Story: 酒馆服务实现

> **Type**: Logic
> **Epic**: inn-system
> **ADR**: ADR-0013
> **Status**: Ready

## Context

酒馆节点提供三项服务：歇息恢复（免费+15HP自动触发）、购买粮草（40金币/50粮草）、强化休整（60金币+20HP）。每次访问有限制规则。

**依赖**：
- ADR-0013 (Inn System) - InnManager 集中管理

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 进入酒馆自动触发歇息，恢复15HP（不超过最大HP） | 功能测试：进入酒馆验证HP变化 |
| AC2 | 购买粮草：40金币购买50粮草（不超过上限150） | 功能测试：购买后验证粮草和金币 |
| AC3 | 强化休整：60金币恢复20HP（不超过最大HP） | 功能测试：强化后验证HP和金币 |
| AC4 | 每章歇息最多1次，重访不重置 | 功能测试：重访同一酒馆验证 |
| AC5 | HP已满时歇息恢复0，提示"体力充沛" | UI测试：HP满时进入酒馆 |

## Implementation Notes

### 服务接口

```gdscript
class InnService:

    const BASE_HEAL: int = 15
    const BASE_FORTIFY_HEAL: int = 20
    const FORTIFY_PRICE: int = 60

    const CARGO_BUY_AMOUNT: int = 50
    const CARGO_PRICE: int = 40
    const MAX_CARGO: int = 150

    # 歇息恢复（自动触发）
    func trigger_rest(hero: HeroData):
        var heal_amount = min(BASE_HEAL, hero.max_hp - hero.current_hp)
        hero.current_hp += heal_amount
        return heal_amount

    # 购买粮草
    func purchase_cargo(hero: HeroData, current_gold: int, current_cargo: int) -> Dictionary:
        if current_gold < CARGO_PRICE:
            return {success: false, reason: "金币不足"}

        var actual_buy = min(CARGO_BUY_AMOUNT, MAX_CARGO - current_cargo)
        var cost = CARGO_PRICE

        return {
            success: true,
            cargo_gained: actual_buy,
            gold_spent: cost
        }

    # 强化休整
    func trigger_fortify(hero: HeroData, current_gold: int) -> Dictionary:
        if current_gold < FORTIFY_PRICE:
            return {success: false, reason: "金币不足"}

        if hero.current_hp >= hero.max_hp:
            return {success: false, reason: "体力已满"}

        var heal_amount = min(BASE_FORTIFY_HEAL, hero.max_hp - hero.current_hp)

        return {
            success: true,
            hp_gained: heal_amount,
            gold_spent: FORTIFY_PRICE
        }
```

### 访问状态管理

```gdscript
class InnNodeState:
    var is_rest_used: bool = false
    var is_fortify_used: bool = false
    var visit_count: int = 0
```

## QA Test Cases

1. **test_rest_auto_trigger** - 歇息自动触发
2. **test_rest_at_max_hp** - HP已满时恢复0
3. **test_purchase_cargo** - 购买粮草
4. **test_purchase_cargo_partial** - 粮草接近上限部分购买
5. **test_fortify** - 强化休整
6. **test_fortify_at_max_hp** - HP已满强化禁用
7. **test_revisit_no_reset** - 重访不重置
