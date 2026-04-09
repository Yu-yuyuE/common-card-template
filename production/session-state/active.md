## Session Extract - /review-all-gdds 2026-04-08
- Verdict: CONCERNS
- GDDs reviewed: 17
- Flagged for revision: card-battle-system.md, map-design.md, curse-system.md, troop-cards-design.md, save-persistence-system.md, barracks-system.md, heroes-design.md, resource-management-system.md
- Blocking issues: None
- Recommended next: Run /design-review on flagged GDDs to address warnings
- Report: design/gdd/gdd-cross-review-2026-04-08.md

## Session Extract - ADR创建 2026-04-09
- All 16 ADRs Accepted: ADR-0001~ADR-0016
- ID conflicts resolved (renumbered to ADR-0014~ADR-0016)
- 16/16 ADRs: 100% coverage
- Recommended next: Run /gate-check pre-production
## Session Extract — /architecture-review 2026-04-09
- Verdict: PASS
- Requirements: 77 total — 77 covered, 0 partial, 0 gaps
- New TR-IDs registered: 77
- GDD revision flags: None
- Top ADR gaps: None
- Report: docs/architecture/architecture-review-2026-04-09.md
## Session Extract - /review-all-gdds 2026-04-09
- Verdict: FAIL
- GDDs reviewed: 17
- Flagged for revision: status-design.md, map-design.md, game-concept.md, resource-management-system.md, enemies-design.md, troop-cards-design.md, shop-system.md
- Blocking issues: 12 (including Fortify/Weakness formulas, Session Duration vs Node Count, Boss Cargo cost, Hero HP ranges, Undefined Status Effects)
- Recommended next: Resolve blocking consistency issues and mathematical contradictions before architecture
- Report: design/gdd/gdd-cross-review-2026-04-09.md

## Session Extract - status-design review 2026-04-09
- Updated status-design.md to include 7 missing states (暴露, 迷乱, 减速, 震慑, 动摇, 嘲讽, 迟钝)
- Re-aligned Fortify (坚守) to 50% damage reduction
- Re-aligned Weakness (虚弱) to 50% damage reduction
- Systems-index updated

- Updated shield/damage reduction order: apply damage reduction FIRST, then deduct from shield, then HP (consistent with standard roguelike conventions)

- Resolved map-design.md contradictions: Boss node costs 10 cargo, Inn restores 40 cargo, Barracks upgrades cost 30 cargo, Boss reward is fixed 50
- Resolved resource-management.md contradictions: HP does not auto-restore on Boss kill; DoT shield penetration aligns with status-design
- Updated systems-index.md

- Updated game-concept.md & map-design.md to define One Session as 1 campaign (3 maps, 3 acts), resolving math duration contradiction.
- Fixed stale HP (40-60), troop card count (41), and CSV counts in game-concept.md.

- Fixed remaining stale references in enemies-design.md and cards-design.md

- Authored design/ux/battle-hud.md UX specification for 1v3 combat interface, addressing the missing UI specs from the cross-review.

- Modified design/ux/battle-hud.md based on user feedback: Hero specific counters will use Icon+Number format distinct from normal status buffs, avoiding slot-based UI.

