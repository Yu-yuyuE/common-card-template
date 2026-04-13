# Story 007: 诅咒投递与特殊机制

> **Epic**: 敌人系统
> **Status**: Ready
> **Layer**: Integration
> **Type**: Logic
> **Manifest Version**: 2026-04-13

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-008
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 实现 `_execute_special` 中针对诅咒投递（`hand`, `draw_top`, `draw_random`, `discard`）以及战场召唤机制的支持。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持4种诅咒投递位置（手牌、牌顶、随机、弃牌）
- Required: 召唤满场（3名敌将）时自动跳过

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `_deliver_curse`：按照配置参数将指定的 `curse_id` 放入 `BattleManager` 的对应数组 (`hand_cards`, `draw_pile`, `discard_pile`)。
- [ ] 针对 `draw_random`，在 0 到 size 之间产生一个随机索引插入。
- [ ] 针对手牌满的情况（由于诅咒强制塞牌，根据 C2 规则可能直接进入弃牌堆，需调用 C2 提供的方法或直接遵循约定处理）。
- [ ] 实现 `_summon_enemy`：检查当前战场人数，如果 $< 3$，实例化一个新敌人加入 `BattleManager.enemy_entities` 数组；如果 $\ge 3$，直接跳过。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. 需要调用 `BattleManager` （或通过信号）完成卡牌和敌人的注入。
2. 建议让 `BattleManager` 提供类似 `add_card_to_zone(card_id, zone, option)` 的接口给敌人系统使用。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 诅咒卡本身的触发逻辑（由诅咒系统Epic负责）。
- 阵列重新排版与动画（由 HUD 负责）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 牌顶投递
  - Given: 执行投递诅咒到牌顶 (`draw_top`)
  - When: 执行动作。
  - Then: 对应诅咒 ID 成为 `draw_pile` 的索引 0 元素。

- **AC-2**: 召唤满场跳过
  - Given: 战场已有 3 名敌人。执行召唤。
  - When: 触发。
  - Then: `BattleManager.enemy_entities` 依然为 3，行动跳过，不报错。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Logic: `tests/unit/enemy_system/curse_summon_mechanics_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 006 (路由分发), C2 卡牌战斗系统 (提供接口操作手牌和敌将列表)
- Unlocks: 无
