# Cross-GDD Review Report
Date: 2026-04-08
GDDs Reviewed: 17
Systems Covered: status-design, resource-management-system, card-battle-system, enemies-design, terrain-weather-system, heroes-design, troop-cards-design, curse-system, map-design, card-upgrade-system, shop-system, equipment-design, cards-design, event-system, save-persistence-system, barracks-system, inn-system

---

## Consistency Issues

### Warnings (should resolve, but won't block)
⚠️ Dependency Bidirectionality - save-persistence-system.md lists card-upgrade-system.md as a dependent system, but card-upgrade-system.md does not list save-persistence-system.md as a dependency. (GDDs involved: save-persistence-system.md, card-upgrade-system.md)

⚠️ Dependency Bidirectionality - barracks-system.md lists card-upgrade-system.md as a weak dependency, but card-upgrade-system.md does not acknowledge barracks-system.md in its dependencies section. (GDDs involved: barracks-system.md, card-upgrade-system.md)

⚠️ Data and Tuning Knob Ownership Conflict - Both troop-cards-design.md and card-battle-system.md claim ownership of护盾 (shield) mechanics. (GDDs involved: troop-cards-design.md, card-battle-system.md)

⚠️ Formula Compatibility - resource-management-system.md defines护盾上限 = 角色当前最大 HP as the default, but heroes-design.md shows曹仁铁壁将军 having护盾上限额外 +30, which conflicts with the default formula. (GDDs involved: resource-management-system.md, heroes-design.md)

⚠️ Dependency Bidirectionality - curse-system.md mentions司马懿被动 directly感知诅咒卡进入手牌事件, but heroes-design.md doesn't clearly indicate that it provides the OnCurseCardDrawn event hook that curse-system.md references. (GDDs involved: curse-system.md, heroes-design.md)

---

## Game Design Issues

### Warnings
⚠️ Player Attention Budget - Players must simultaneously manage 10+ active systems (card battle, terrain,兵种卡, hero, curse, map navigation, shop, equipment, barracks, inn), exceeding the recommended 3-4 systems and potentially causing cognitive overload. (GDDs involved: all 17 systems)

⚠️ Progression Loop Competition - Multiple competing progression systems (gold-based, cargo-based, deck-building, equipment, experience/unlock) may dilute player focus and create unclear primary progression drivers. (GDDs involved: resource-management-system.md, shop-system.md, equipment-design.md, barracks-system.md, save-persistence-system.md)

⚠️ Dominant Strategy Detection - Risk-free optimization paths exist, particularly司马懿's curse utilization (turning negatives into positives) and兵种卡upgrades (Lv2→Lv3) that appear universally beneficial, potentially leading to dominant strategies. (GDDs involved: heroes-design.md, curse-system.md, troop-cards-design.md, barracks-system.md)

⚠️ Economic Loop Imbalance - Potential disconnect between gold earned from combat (~30-75 per fight) and costs for meaningful upgrades (兵种卡Lv2 upgrade: 30 cargo,兵种卡Lv3 upgrade: 50 cargo, equipment: 40-120 gold), which may create resource scarcity that feels punishing rather than strategic. (GDDs involved: resource-management-system.md, shop-system.md, card-battle-system.md, barracks-system.md)

---

## Cross-System Scenario Issues

Scenarios walked: 3
1. Player enters new map with full cargo (150) navigating to boss battle
2. Sima Yi hero using curse cards strategically while managing barracks upgrades
3. Player approaches boss battle with limited resources optimizing preparation

### Warnings
⚠️ Boss move cost contradiction - map-design.md says "移动到Boss节点不消耗粮草" but game-concept.md implies boss move does consume cargo. (GDDs involved: map-design.md, game-concept.md)

⚠️ Multi-phase resource retention inconsistency - card-battle-system.md has conflicting information about whether shield/action points carry between phases or reset. (GDDs involved: card-battle-system.md)

⚠️ Curse type differentiation - The design documents show three curse types that need to be correctly differentiated in implementation for Sima Yi's passive to handle all cases appropriately. (GDDs involved: curse-system.md, heroes-design.md)

### Info
ℹ️ Emergency supply mechanism - For stuck players with low cargo, the emergency supply mechanism needs clear UI feedback. (GDDs involved: map-design.md, resource-management-system.md)

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| card-battle-system.md | Multi-phase resource retention inconsistency | Consistency | Warning |
| map-design.md | Boss move cost contradiction with game-concept.md | Consistency | Warning |
| curse-system.md | Missing dependency reference to heroes-design.md | Consistency | Warning |
| troop-cards-design.md | Shield mechanics ownership conflict with card-battle-system.md | Consistency | Warning |
| save-persistence-system.md | Missing reciprocal dependency declaration with card-upgrade-system.md | Consistency | Warning |
| barracks-system.md | Missing reciprocal dependency declaration with card-upgrade-system.md | Consistency | Warning |
| heroes-design.md | Unclear OnCurseCardDrawn event hook provision for司马懿 | Consistency | Warning |
| resource-management-system.md | Formula compatibility issue with heroes-design.md | Consistency | Warning |

---

## Verdict: CONCERNS

PASS: No blocking issues. Warnings present but don't prevent architecture.
CONCERNS: Warnings present that should be resolved but are not blocking.
FAIL: One or more blocking issues must be resolved before architecture begins.

### If FAIL - required actions before re-running:
N/A - No blocking issues found

---

## Session Extract - /review-all-gdds 2026-04-08
- Verdict: CONCERNS
- GDDs reviewed: 17
- Flagged for revision: card-battle-system.md, map-design.md, curse-system.md, troop-cards-design.md, save-persistence-system.md, barracks-system.md, heroes-design.md, resource-management-system.md
- Blocking issues: None
- Recommended next: Run /design-review on flagged GDDs to address warnings
- Report: design/gdd/gdd-cross-review-2026-04-08.md