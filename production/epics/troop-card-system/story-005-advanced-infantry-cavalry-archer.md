# Story 005: 扩展分支（Lv3）步骑弓效果实现

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014
**ADR Decision Summary**: 为Lv3特种兵分支编写专用的效果处理块。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须能在 `_resolve_troop` 中精准派发特定的分支兵种效果。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 **虎贲卫 (1费)**: 造成10伤；若目标有滑倒，额外5伤并移除1层滑倒。
- [ ] 实现 **刀盾手 (1费)**: 造成7伤，获6盾；若我方已有护盾，额外造成3伤。
- [ ] 实现 **戟兵 (1费)**: 前排全攻9伤；无前排时单体8伤。
- [ ] 实现 **游侠 (0费)**: 直击全体4伤；森林地形且有灼烧目标额外增伤。
- [ ] 实现 **轻骑兵 (0费)**: 平原环境连续2回合末触发4伤。
- [ ] 实现 **火骑兵 (2费)**: 前排全体6伤+击退+2层灼烧。
- [ ] 实现 **象兵 (2费)**: 造成5伤+减速；水域延长减速。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `BattleManager._resolve_troop` 匹配特定的 `card_id`（例如 "troop_huben_lv3"），跳过通用的 Lv1/Lv2 处理。
2. 对于 **虎贲卫**，在施加伤害前检查 `StatusManager.get_status(target, SLIP) > 0`。
3. 对于 **戟兵** 和 **火骑兵** 的前排群体判定：遍历 `enemy_entities` 筛选 `is_frontrow == true` 的目标执行。
4. 延迟伤害（轻骑兵）：在目标身上施加一个特殊的 `DELAYED_DAMAGE` 状态，由状态系统在回合末结算；或在 `BattleManager` 里维持一个延迟伤害队列。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Lv3 谋士和盾兵分支（由于兵种数量较多，拆分至 Story 006）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 虎贲卫额外伤害与状态剥夺
  - Given: 敌人 A 身上有 1层 `SLIP`（滑倒）状态。
  - When: 对 A 打出虎贲卫
  - Then: 敌人 A 受到 15 点伤害，且身上的滑倒状态变为 0。

- **AC-2**: 火骑兵群体附加与位置操作
  - Given: 前排有 2 名敌人。
  - When: 打出火骑兵。
  - Then: 2 名敌人都受到 6 点伤害，各获得 2 层灼烧，且被推至后排。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/advanced_infantry_cavalry_archer_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
