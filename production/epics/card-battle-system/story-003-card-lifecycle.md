# Story 003: 卡牌生命周期与抽牌堆管理

> **Epic**: 卡牌战斗系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-006 (卡牌生命周期), TR-card-battle-system-009 (抽牌逻辑)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: 卡牌战斗系统架构
**ADR Decision Summary**: 卡牌生命周期按抽牌堆→手牌→弃牌堆→移除区→消耗区管理。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: Array操作，涉及 shuffle()

**Control Manifest Rules (this layer)**:
- Required: 卡牌必须按分区进行流转
- Required: 每回合开始时补足至当前手牌上限，若手牌满则不抽

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md`, scoped to this story:*

- [ ] 初始化5个 Array: `draw_pile`, `hand_cards`, `discard_pile`, `removed_cards`, `exhaust_cards`
- [ ] 实现 `_draw_cards(count: int)` 方法
- [ ] 手牌上限机制：默认上限为 5，若是武将"袁绍"(id: cao_sao 注意文档中四世三公写为cao_sao/yuan_shao需核实，假设 "yuan_shao") 则上限为 6。
- [ ] 若抽牌时 `draw_pile` 为空，将 `discard_pile` 洗入 `draw_pile`（调用 shuffle）。若两者皆空，则安全跳过，不报错。
- [ ] 手牌溢出机制：当通过被动/效果强制抽牌导致手牌超过上限时，超出部分直接进入弃牌堆。

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

1. 在 `setup_battle` 中，需要加入卡组初始化 `_initialize_deck()`，暂且使用 mock 卡牌ID 填充 `draw_pile`。
2. 抽牌数量计算：`DrawCount = max(0, HandLimit - CurrentHandSize)`。
3. `_draw_cards(count)` 会进入一个循环，每次 `pop_front` 一张卡加入 `hand_cards`。如果中途牌堆空了，触发洗牌 `draw_pile = discard_pile.duplicate(); discard_pile.clear(); draw_pile.shuffle()`。
4. 将 `_draw_cards(_get_hand_limit())` 注入到 `BattlePhase.PLAYER_DRAW` 阶段。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 抽入"诅咒卡"立刻触发的逻辑（由诅咒系统D4联动，本故事仅预留检查点注释）。
- 打出卡牌后的丢弃流程（在 Story 004 实现）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 补满手牌上限
  - Given: 武将非袁绍（上限5），手牌已有 2 张，抽牌堆有 10 张。
  - When: 回合开始调用抽牌
  - Then: 抽出 3 张牌，手牌达到 5 张。

- **AC-2**: 弃牌堆洗回
  - Given: 手牌 0 张，抽牌堆 2 张，弃牌堆 5 张。
  - When: 试图抽取 5 张牌。
  - Then: 先抽出抽牌堆的 2 张，弃牌堆清空并洗入抽牌堆，再抽出 3 张。最终手牌 5 张，抽牌堆 2 张，弃牌堆 0 张。

- **AC-3**: 牌库耗尽保护
  - Given: 抽牌堆 1 张，弃牌堆 0 张，手牌 0 张。
  - When: 试图抽取 5 张牌。
  - Then: 抽出 1 张后结束循环，手牌为 1 张，不抛出异常。

- **AC-4**: 袁绍上限特权
  - Given: 玩家实体 ID = "yuan_shao"
  - When: 获取手牌上限
  - Then: 返回 6。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle_system/card_lifecycle_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 004 (出牌结算)
