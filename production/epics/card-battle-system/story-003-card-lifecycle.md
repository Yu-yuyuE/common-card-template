# Story 003: 卡牌生命周期与抽牌堆管理

Epic: 卡牌战斗系统
Estimate: 4 hours
Status: Complete
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-006 (卡牌生命周期), TR-card-battle-system-009 (抽牌逻辑)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD 精确引用**：
- §3.4 回合流程 — "抽牌（补至手牌上限：默认5张，袁绍6张）"
- §3.5 卡牌生命周期 — 五分区定义与卡牌流转规则（普通打出→弃牌堆、移除→战斗后回卡组、消耗→永久移除、溢出→弃牌堆）
- F3 手牌抽取数量 — `DrawCount = max(0, HandLimit - CurrentHandSize)`；HandLimit 默认=5，袁绍=6

**ADR Governing Implementation**: ADR-0007: 卡牌战斗系统架构（Status: Accepted）
**ADR Decision Summary**: 卡牌生命周期按抽牌堆→手牌→弃牌堆→移除区→消耗区管理；五分区由 BattleManager 统一持有。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: Array 操作，涉及 shuffle()；Godot 4.x Array.shuffle() 为原地乱序，返回 void，不需要接收返回值（与 4.0 前行为一致，无后训练截止风险）

**Control Manifest Rules (this layer)**:
- Required: 卡牌必须按分区进行流转
- Required: 每回合开始时补足至当前手牌上限，若手牌满则不抽

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md` §3.4/§3.5/F3，本故事范围内，无需打开 GDD 即可判断完成：*

- [ ] **AC-1 五分区初始化**：战斗初始化后，对象持有5个 Array：`draw_pile`、`hand_cards`、`discard_pile`、`removed_cards`、`exhaust_cards`，每个均为非 null 的 Array 实例（初始可为空）。
- [ ] **AC-2 补牌到上限**：`_draw_cards(count: int)` 从 `draw_pile` 取牌加入 `hand_cards`，实际抽取数量 = `min(count, draw_pile.size())`（单次牌堆充足时）。公式：`DrawCount = max(0, HandLimit - CurrentHandSize)`。
- [ ] **AC-3 袁绍手牌上限**：当战斗实体 hero_id == `"yuan_shao"` 时，`_get_hand_limit()` 返回 6；其他所有武将返回 5。
- [ ] **AC-4 抽牌堆为空时洗牌回补**：`draw_pile` 耗尽、`discard_pile` 非空时，`discard_pile` 全部移入 `draw_pile` 并执行 shuffle，`discard_pile` 清空，继续完成剩余抽牌请求。
- [ ] **AC-5 双堆皆空时安全跳过**：`draw_pile` 与 `discard_pile` 均为空时，`_draw_cards(count)` 安全返回，不抛出异常，`hand_cards` 保持原状。
- [ ] **AC-6 手牌溢出弃置**：通过被动或效果强制抽入导致 `hand_cards.size() > HandLimit` 时，超出部分（从末尾起）立即移入 `discard_pile`，最终 `hand_cards.size() == HandLimit`。

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
- 打出卡牌后的丢弃流程（在 Story 5-4 实现）。
- 移除区/消耗区卡牌的战斗结束回收清算（在 Story 5-9 多阶段胜负判定中处理）。
- 任何 UI 渲染、手牌视觉显示（在 Story 5-14 实现）。

## Performance Notes

手牌操作（Array pop_front / append / shuffle）每回合最多调用一次，卡牌数量上限约 30 张。复杂度 O(n)，n ≤ 30，对 16.6ms 帧预算无可测量影响。无性能约束需额外设计。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1 补满手牌上限**
  - Given: 武将非袁绍（上限5），手牌已有 2 张，抽牌堆有 10 张。
  - When: 回合开始调用 `_draw_cards(max(0, 5 - 2))` = `_draw_cards(3)`
  - Then: 手牌达到 5 张，抽牌堆剩 7 张，各分区计数之和不变。

- **AC-2 弃牌堆洗回**
  - Given: 手牌 0 张，抽牌堆 2 张，弃牌堆 5 张。
  - When: 试图抽取 5 张牌（`_draw_cards(5)`）。
  - Then: 先抽出抽牌堆 2 张；触发洗牌：弃牌堆 5 张移入抽牌堆并 shuffle，弃牌堆清零；再抽 3 张。最终手牌 5 张，抽牌堆 2 张，弃牌堆 0 张。

- **AC-3 牌库耗尽保护**
  - Given: 抽牌堆 1 张，弃牌堆 0 张，手牌 0 张。
  - When: `_draw_cards(5)` 调用。
  - Then: 抽出 1 张后安全结束，手牌 = 1 张，不抛出任何异常或错误。

- **AC-4 袁绍上限特权**
  - Given: 战斗实体 hero_id = "yuan_shao"
  - When: 调用 `_get_hand_limit()`
  - Then: 返回 6（整数）。

- **AC-5 手牌溢出弃置**
  - Given: 手牌上限 5，当前手牌 5 张（已满）。
  - When: 强制追加 2 张牌（模拟被动效果）触发溢出检查。
  - Then: `hand_cards.size() == 5`，`discard_pile` 新增 2 张，总牌数守恒。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle_system/card_lifecycle_test.gd` — must exist and pass

**Status**: [x] Created — 12 unit tests covering AC-1 through AC-6 + return_removed_cards_to_deck

---

## Dependencies

- Depends on: 5-1（战斗数据结构与实体初始化）、5-2（战斗状态机与回合流程）
- Unlocks: 5-4（出牌验证与卡牌结算框架）
