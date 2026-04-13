# Story 005: 军营节点统帅与选卡验证

Epic: 兵种卡系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (卡组上限/统帅占用)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014
**ADR Decision Summary**: 提供验证逻辑，在玩家视图往卡组中加入兵种卡时，限制其总数不超过武将的统帅值 (3~6)。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 兵种卡总数必须受到统帅值上限的严格约束。
- Required: 一张兵种卡无论层级如何，始终只占1个统帅槽。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 `TroopCardManager.count_troop_cards_in_deck(deck: Array) -> int` 辅助方法，统计当前卡组内所有拥有兵种大类 (`is_troop == true`) 的卡牌总数。
- [ ] 实现 `can_add_troop_card(deck, hero_leadership) -> bool` 返回是否还可以加入新的兵种卡。
- [ ] 确保不论卡的 `upgrade_count` 还是 `is_branch_card` 为真，都被统计为 1。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `CardManager` 模块中提供工具函数：
   ```gdscript
   func get_current_troop_count(deck_card_ids: Array) -> int:
       var count = 0
       for card_id in deck_card_ids:
           var card = get_card(card_id)
           if card != null and card.type == CardType.TROOP:
               count += 1
       return count
   ```
2. 军营节点UI调用 `get_current_troop_count(HeroManager.get_current_deck()) >= HeroManager.get_current_hero().leadership` 来决定是否灰显获取按钮。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 军营节点的整体UI与交互（由 Map System 或专门的 Camp Node 负责）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 统帅占用正确统计
  - Given: 卡组中有 2 张普通攻击卡，1 张步兵 Lv1，1 张虎贲卫（步兵Lv3分支）。
  - When: 调用 `get_current_troop_count()`
  - Then: 返回 2。

- **AC-2**: 上限拦截判定
  - Given: `hero_leadership` = 3，当前兵种卡 = 3。
  - When: 调用 `can_add_troop_card()`
  - Then: 返回 false。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_cards/troop_deck_limit_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (卡牌数据)
- Unlocks: 无
