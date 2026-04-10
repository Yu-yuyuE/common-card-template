# Story: 酒馆UI交互

> **Type**: UI
> **Epic**: inn-system
> **ADR**: ADR-0016
> **Status**: Ready

## Context

酒馆节点需要展示服务菜单，处理用户交互。UI需要正确显示各服务的可用状态和限制条件。

**依赖**：
- ADR-0016 (UI Data Binding) - UI数据绑定

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 酒馆UI正确显示歇息/粮草/强化三项服务 | UI测试：进入酒馆验证菜单显示 |
| AC2 | 不可用服务项正确置灰并显示原因 | UI测试：HP满时强化置灰 |
| AC3 | 重访时显示"已休整"标签 | UI测试：重访酒馆验证标签 |
| AC4 | 粮草接近上限时显示实际购入量 | UI测试：粮草140时购买显示实际量 |

## Implementation Notes

### UI状态定义

```gdscript
class InnUIState:
    var can_purchase_cargo: bool
    var can_fortify: bool
    var is_rest_used: bool
    var is_fortify_used: bool

    var current_gold: int
    var current_cargo: int
    var max_cargo: int = 150

    var cargo_price: int = 40
    var fortify_price: int = 60

    func update_state(hero: HeroData, inn_state: InnNodeState, gold: int, cargo: int):
        current_gold = gold
        current_cargo = cargo
        is_rest_used = inn_state.is_rest_used
        is_fortify_used = inn_state.is_fortify_used

        can_purchase_cargo = gold >= cargo_price and cargo < max_cargo
        can_fortify = gold >= fortify_price and hero.current_hp < hero.max_hp and not is_fortify_used
```

### UI显示逻辑

```gdscript
# 粮草购买按钮
if can_purchase_cargo:
    enable_button("购买粮草")
    set_button_text("购买粮草 (40金/50粮)")
else if current_cargo >= max_cargo:
    disable_button("粮草充足（上限）")
else if current_gold < cargo_price:
    disable_button(f"金币不足 (需要{cargo_price}金)")

# 强化休整按钮
if can_fortify:
    enable_button("强化休整")
    set_button_text("强化休整 (60金/+20HP)")
else if is_fortify_used:
    disable_button("本次访问已使用")
else if hero.current_hp >= hero.max_hp:
    disable_button("当前体力已满")
else if current_gold < fortify_price:
    disable_button(f"金币不足 (需要{fortify_price}金)")
```

## QA Test Cases

1. **test_inn_menu_display** - 菜单显示
2. **test_button_states** - 按钮状态
3. **test_visited_tag** - 已休整标签
4. **test_partial_cargo_display** - 部分购入量显示
