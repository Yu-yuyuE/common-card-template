## Cross-GDD Review Report
Date: 2026-04-09
GDDs Reviewed: 17
Systems Covered: game-concept, status-design, resource-management-system, card-battle-system, enemies-design, terrain-weather-system, heroes-design, troop-cards-design, curse-system, map-design, card-upgrade-system, shop-system, equipment-design, cards-design, event-system, save-persistence-system, barracks-system, inn-system

---

### Consistency Issues

#### Blocking (must resolve before architecture begins)
🔴 **Boss Node Cargo Cost Contradiction**
[map-design.md, resource-management-system.md] map-design.md Rule 8 says Boss node costs 0 cargo, but its AC5 says it costs 10 cargo. resource-management-system.md doesn't explicitly mention it. Needs a definitive decision on whether moving to a Boss node costs cargo.

🔴 **Inn Cargo Restoration Contradiction**
[map-design.md, inn-system.md] map-design.md says inn restores 50 or 30-50 cargo. inn-system.md (the authoritative source) says 40 cargo (for 40 gold). Must align map-design.md to inn-system.md's 40 cargo.

🔴 **坚守 (Fortify) Damage Reduction Conflict**
[status-design.md, troop-cards-design.md] status-design.md defines it as -25% damage. troop-cards-design.md defines it as -50% damage. Must decide on one authoritative value and update both.

🔴 **Hero HP Range Stale Reference**
[game-concept.md, heroes-design.md] game-concept.md says hero HP is 30-50. heroes-design.md sets actual hero HPs between 40-61. game-concept.md needs to be updated to 40-60.

🔴 **Undefined Status Effects**
[status-design.md, troop-cards-design.md, enemies-design.md] 暴露, 迷乱, 减速, 震慑, 动摇, 嘲讽, 迟钝 are used in troop cards and enemies but are entirely missing from status-design.md. They must be defined in the canonical status list.

🔴 **Boss Kill HP Restoration Contradiction**
[resource-management-system.md] Intra-document contradiction: F2 text says "加满HP" (fully restore HP) on Boss kill, but the cross-map table says HP is "持久化 (不自动恢复)" (persistent, no auto-recovery). Must decide which rule applies.

🔴 **虚弱 (Weakness) Formula Conflict**
[status-design.md, enemies-design.md] status-design.md defines it as -25% damage (×0.75). enemies-design.md uses ×0.5 (-50%) as a reference. Must align to a single value.

🔴 **Barracks Upgrade Currency Conflict**
[map-design.md, barracks-system.md] map-design.md Rule 9 says upgrading troop cards costs gold. barracks-system.md (the authority) says it costs cargo. map-design.md must be corrected.

🔴 **Stale Entity Counts**
[game-concept.md, troop-cards-design.md, enemies-design.md, cards-design.md]
- Troop cards: game-concept.md says 29, CSV plan says 30, troop-cards-design.md says 41.
- Enemies: enemies-design.md AC1 says 55, but the doc contains 100.
All counts must be synchronized to the actual designs.

#### Warnings (should resolve, but won't block)
⚠️ **Boss Cargo Reward Range**
[map-design.md, resource-management-system.md] resource-management-system.md says Boss drops 50 cargo. map-design.md tuning knob says max 40. Should align the tuning knob to the fixed value.

⚠️ **DoT Shield Penetration Default**
[resource-management-system.md, status-design.md] resource-management-system.md AC10 says DoTs go through shields by default. status-design.md (the authority) explicitly defines most DoTs as bypassing shields. AC10 should be rephrased to avoid misleading programmers.

⚠️ **Shop System Boundary Stale**
[shop-system.md, inn-system.md, barracks-system.md] shop-system.md says it handles curse purification. This was moved to barracks-system.md. shop-system.md boundary exclusions need updating.

---

### Game Design Issues

#### Blocking
🔴 **"一局" (One Session) Duration vs Map Structure Mathematical Contradiction**
[game-concept.md, map-design.md] game-concept.md sets a target of 35-70 minutes per session. The map structure requires clearing 5 maps × 3 acts × 12-15 nodes, with 45% combat. This equals ~81 battles. 81 battles in 70 minutes is <52 seconds per battle, which is impossible for this combat system. Must redefine what "一局" means (1 map vs 5 maps) or drastically reduce node counts.

🔴 **Combat UI Information Architecture Missing**
[All GDDs] The 1v3 combat system requires tracking 3 enemy intents, custom hero counters (司马懿/贾诩), terrain/weather buffs, and curse cards simultaneously. No GDD defines the UX/UI specifications for this high-density information layout, risking severe cognitive overload and breaking the "mastermind" player fantasy. A UX spec is required before implementation.

#### Warnings
⚠️ **Progression Loop & Economy Priority Unclear**
[shop-system.md, barracks-system.md, resource-management-system.md] Players have 5 parallel progression tracks competing for gold and cargo. The implicit priority (e.g., cargo for movement vs cargo for barracks upgrades) is never explicitly stated, risking player frustration. Recommend adding a "recommended early-game priority" note for tutorials.

⚠️ **Sima Yi's Curse Strategy Potential Dominant Strategy**
[heroes-design.md, curse-system.md] Sima Yi can reach 4 stacks of "隐忍" by hoarding curses, reducing all card costs by 1. In a low-cost deck, this enables infinite/0-cost combos. Needs close attention during balance testing.

⚠️ **Diao Chan's Low HP vs 1v3 Combat**
[heroes-design.md] Diao Chan has 40 HP (lowest in game) and a reactive defense (confuse attacker when hit). In a 1v3 scenario, taking hits from 3 enemies to trigger confusion will likely kill her in 2-3 turns against strong enemies. Her survivability needs validation in prototyping.

⚠️ **Guan Yu's Deck Bloat**
[heroes-design.md] Guan Yu adds up to 5 "过关斩将" cards to his deck for passive damage buffs (+15 total). These cards have no playable effect, effectively creating 5 dead draws. The impact on deck cycling needs explicit design acknowledgment.

---

### Cross-System Scenario Issues

Scenarios walked: 3
1. Boss Kill Sequence
2. Inn Visit
3. Barracks Troop Upgrade

#### Blockers
🔴 **Boss Kill Sequence** — [resource-management-system.md, map-design.md]
Step where failure occurs: End of Boss battle.
Nature of failure: Undefined behavior due to contradictions. Does the player fully heal? (F2 says yes, cross-map table says no). Does the player get 50 cargo? (Yes, but map-design tuning says max 40). Did it cost 10 cargo to enter? (map-design AC5 says yes, Rule 8 says no). The entire sequence is structurally ambiguous.

🔴 **Inn Visit** — [inn-system.md, map-design.md, shop-system.md]
Step where failure occurs: Buying cargo and purifying curses.
Nature of failure: map-design says inn gives 50 or 30-50 cargo. inn-system says 40. shop-system claims it does purification, but inn boundary says barracks does it. The player experience at rest nodes is fragmented across conflicting rules.

#### Warnings
⚠️ **Barracks Troop Upgrade** — [barracks-system.md, map-design.md]
What the unintended outcome is: map-design says upgrades cost gold, barracks says cargo. If implemented incorrectly, the dual-economy tension is destroyed.

---

### GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| status-design.md | 7+ missing status effects, 坚守/虚弱 formula conflicts | Consistency | Blocking |
| map-design.md | Boss node cost, Inn cargo values, Barracks currency conflicts | Consistency | Blocking |
| game-concept.md | Stale HP range, stale entity counts, Session duration vs math conflict | Consistency & Design | Blocking |
| resource-management-system.md | Boss HP restore internal contradiction | Consistency | Blocking |
| enemies-design.md | AC1 stale enemy count | Consistency | Blocking |
| troop-cards-design.md | Align 坚守 reduction with status-design | Consistency | Blocking |
| shop-system.md | Stale boundary exclusion (purification) | Consistency | Warning |

---

### Verdict: FAIL

FAIL: Multiple blocking consistency issues and one major game design mathematical contradiction (Session Duration vs Node Count) must be resolved before architecture begins.

### If FAIL — required actions before re-running:
1. **status-design.md**: Add definitions for 暴露, 迷乱, 减速, 震慑, 动摇, 嘲讽, 迟钝. Resolve 坚守 (-25% vs -50%) and 虚弱 (-25% vs -50%) authoritative values.
2. **game-concept.md**: Redefine "一局" (One Session) to mathematically align with the 35-70 minute goal (likely changing it to mean 1 map instead of 5). Update stale HP ranges and entity counts.
3. **map-design.md**: Fix Boss node cargo cost, Inn cargo restoration values, and Barracks upgrade currency to match their respective authoritative GDDs.
4. **resource-management-system.md**: Resolve the internal contradiction regarding HP restoration after Boss kills.
5. **UI/UX**: Create `design/ux/battle-hud.md` to solve the 1v3 combat information architecture.