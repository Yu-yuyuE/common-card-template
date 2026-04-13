# Story 005: 魏蜀阵营代表性被动技能实现

Epic: 武将系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/heroes-design.md`
**Requirement**: TR-heroes-design-005 (1个被动技能)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 将核心业务逻辑填充入 Callable 结构中，并注册到 `_passive_skills` 字典。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持被动技能触发机制，具体到各武将的个性化逻辑。

---

## Acceptance Criteria

*From GDD `design/gdd/heroes-design.md`, scoped to this story:*

- [ ] 实现曹操"挟令诸侯"：`on_troop_card_played` 时，对随机敌人施加1层虚弱。附带50%增伤判定（由战斗系统在公式里调用，本故事先提供方法供查询或者直接由状态系统的WEAK实现，根据GDD虚弱是全目标共享状态，所以曹操是被动施加，后续增伤由状态自身或特定倍率支持）。
- [ ] 实现夏侯惇"刚烈"：`on_damaged` 时，累计伤害。下次使用卡牌时，可以选择受到3伤并抽1卡，外加附加累计伤害。
- [ ] 实现刘备"仁德"：兵种伤害+50%（通过全局修正），每次兵种击杀回8血（`on_troop_kill`）。
- [ ] 实现诸葛亮"卧龙"：`on_turn_start` 恢复1行动点；`on_skill_card_played` 抽1张卡。

---

## Implementation Notes

*Derived from Specific Rules:*

1. 为每个技能单独写一个函数，例如 `_effect_xie_ling_zhu_hou`, `_effect_ren_de`，然后通过 `Callable` 放入字典。
2. 诸葛亮的 `on_turn_start` 回费：
   ```gdscript
   ResourceManager.modify_resource(ResourceManager.ResourceType.ACTION_POINTS, 1, false)
   ```
3. 刘备的回血：
   ```gdscript
   ResourceManager.modify_resource(ResourceManager.ResourceType.HP, 8, false)
   ```
4. 抽取卡牌需通知战斗系统：可以发射一个 `request_draw_card(count)` 信号，由 `BattleManager` 监听。由于 `HeroManager` 不直接持有卡组，解耦最佳方式是信号。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 吴群阵营（太长，放下一个故事）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 曹操施加虚弱
  - Given: `cao_cao` 被选中，敌方场上有一个存活实体。
  - When: `trigger_passive("on_troop_card_played", {})`
  - Then: 敌方实体增加 1 层 WEAK 状态。

- **AC-2**: 诸葛亮回费
  - Given: 诸葛亮被选中。当前 AP = 3, MaxAP = 4。
  - When: `trigger_passive("on_turn_start", {})`
  - Then: `ResourceManager` 中的 AP 增加 1。

- **AC-3**: 诸葛亮抽卡
  - Given: 诸葛亮被选中。
  - When: `trigger_passive("on_skill_card_played", {})`
  - Then: 发射了要求抽 1 张卡的全局事件或信号。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/hero_system/passive_skills_wei_shu_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: 无
