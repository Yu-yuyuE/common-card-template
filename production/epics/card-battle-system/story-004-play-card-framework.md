# Story 004: 出牌验证与卡牌结算框架

Epic: 卡牌战斗系统
Estimate: 4 hours
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-001 (出牌结算), TR-card-battle-system-002 (出牌/结算循环)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: 卡牌战斗系统架构
**ADR Decision Summary**: 提供 `play_card(card_id, target)` 方法，验证费用，结算效果，并根据卡牌配置将其送入弃牌堆、移除区或消耗区。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 费用不足时拒绝打出
- Required: 卡牌打出后必须移动到对应区域
- Forbidden: 禁止分布式处理，打出逻辑全收拢在 BattleManager

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md`, scoped to this story:*

- [ ] 实现 `play_card(card_id: String, target_position: int) -> bool`。
- [ ] 验证卡牌是否在手牌中，验证玩家 AP 是否满足卡牌 cost。不足则返回 false。
- [ ] 扣除对应 AP。调用内部方法 `_resolve_card_effect`。
- [ ] 根据卡牌的 `remove_after_use` 或 `exhaust` 属性，将卡牌移出手牌并放入 `discard_pile`, `removed_cards` 或 `exhaust_cards`。
- [ ] 发射 `card_played` 信号。

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

1. 需要与（或Mock） `CardManager` 交互。`CardManager.get_card(card_id)` 返回具有 `cost`, `type`, `remove_after_use` 属性的字典或对象。
2. 扣除行动点：`player_entity.action_points -= card.cost` 且同步调用 `ResourceManager.modify_resource(ACTION_POINTS, -cost)`（更新全局资源以便UI联动，这部分取决于系统交互，ADR-0003指出资源统一管理，所以这里应当通知或直接改ResourceManager）。
3. `_resolve_card_effect` 使用 match type 路由到 `_resolve_attack`, `_resolve_skill`, `_resolve_troop`。
4. 本故事中 `_resolve_*` 方法保留为占位或仅发出信号，具体伤害公式放在 Story 005。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体伤害公式、地形、天气、状态修正计算（Story 005 实现）。
- 统帅值对兵种卡的限制（在军营购卡阶段验证，不在战斗出牌验证，战斗中可直接打出）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 费用不足拦截
  - Given: 手牌有一张 Cost 3 的卡，玩家仅剩 2 点 AP。
  - When: 调用 `play_card()`
  - Then: 返回 false，手牌未减少，AP 未扣除。

- **AC-2**: 正常出牌及弃牌流转
  - Given: 手牌有一张普通攻击卡，玩家 AP 足够。
  - When: 调用 `play_card()`
  - Then: 返回 true，AP被扣除，该卡从 `hand_cards` 移除并加入 `discard_pile`。发射 `card_played`。

- **AC-3**: 移除/消耗卡流转
  - Given: 手牌有一张 `remove_after_use=true` 的卡。
  - When: 调用 `play_card()`
  - Then: 卡牌被移动到 `removed_cards` 而不是弃牌堆。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle_system/play_card_framework_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (手牌管理)
- Unlocks: Story 005 (伤害公式)
