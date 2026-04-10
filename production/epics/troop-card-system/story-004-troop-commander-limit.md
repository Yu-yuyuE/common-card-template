# Story 004: 统帅值约束与卡组管理

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (统帅占用，军营节点约束)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (相关集成)
**ADR Decision Summary**: 提供一套供地图事件/商店/军营调用的外部校验 API。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 兵种卡无论 Lv几，始终只占 1 个统帅槽。
- Required: 卡组中兵种卡总数 ≤ 武将统帅值。超限无法加入。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 `DeckManager.get_troop_card_count()`，遍历当前玩家持久化卡组中 `is_troop_card == true` 的总数量。
- [ ] 提供 `can_add_troop_card() -> bool` 接口，用当前总量比对武将(HeroManager)的统帅值(3~6)。
- [ ] 提供供 UI 层调用的 `get_available_lv3_branches(base_troop_type: String) -> Array`，读取卡牌数据库中属于该基础兵种且为Lv3的所有卡ID。
- [ ] 确保 Lv3 卡被选定替换后，从卡组中删除旧的 Lv2 卡，加入新的 Lv3 卡。

---

## Implementation Notes

*Derived from General Guidelines:*

1. 在 `DeckManager` (或称卡组管理器，负责战役局外/Meta持久化) 中实现：
   ```gdscript
   func can_add_troop_card(hero_id: String) -> bool:
       var max_limit = HeroManager.get_commander_leadership(hero_id)
       return get_troop_card_count() < max_limit
   ```
2. Lv3 分支检索：
   需要一个结构或配置字典，预存：
   `{"infantry": ["card_huben", "card_daodun", ...]}`

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 军营节点具体的UI绘制和弹窗（在军营系统的专属 Epic 中）。
- 具体的升级收益倍率运算（在铁匠铺/卡牌升级系统Epic中）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 统帅上限阻止添加
  - Given: 武将统帅 = 3，卡组已有 3 张兵种卡。
  - When: 调用 `can_add_troop_card()`
  - Then: 返回 false。

- **AC-2**: Lv3 替换逻辑
  - Given: 卡组有一张 "infantry_lv2"。
  - When: 确认升级分支 "infantry_huben" (虎贲卫)。
  - Then: 卡组中 "infantry_lv2" 消失，新增 "infantry_huben"。卡组兵种总数不变。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_system/troop_commander_limit_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: D3 武将系统 (统帅值)
- Unlocks: 无
