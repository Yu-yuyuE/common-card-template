# Story 007: 战斗HUD与手牌UI绑定

> **Epic**: 卡牌战斗系统
> **Status**: Ready
> **Layer**: Core
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-012 (手牌显示), TR-card-battle-system-013 (战斗信息)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: 卡牌战斗系统架构
**ADR Decision Summary**: 通过监听 `BattleManager` 的信号（如 `phase_changed`, `card_played`, `damage_dealt`）动态更新显示。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须使用Signal驱动的响应式模式更新UI
- Forbidden: 禁止在 `_process` 中轮询战斗状态

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md`, scoped to this story:*

- [ ] 手牌区域监听 `hand_cards` 变化，实例化卡牌 UI 节点（显示卡牌基本信息：费用、名称）。
- [ ] 敌人头顶的意图图标和血条监听 `damage_dealt` 和 `battle_started` 信号更新。
- [ ] 屏幕中央提示当前 `current_phase`（如："玩家回合", "敌方回合", "阶段 2"）。
- [ ] 当费用不足时，手牌区域对应的卡牌表现出灰显不可点击的状态。

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

1. `BattleUI.gd` 注册监听：
   ```gdscript
   BattleManager.turn_started.connect(_on_turn_started)
   BattleManager.card_played.connect(_on_card_played)
   BattleManager.damage_dealt.connect(_on_damage_dealt)
   ```
2. 需要实现一个 `CardUI.tscn`，包含背景、费用Label、标题Label。
3. 玩家拖拽卡牌到目标的交互，可以使用 `gui_input` 或者 `Control` 节点的 `get_drag_data` 等标准机制（作为原型，点击卡牌再点击敌人也行）。当确认目标后，调用 `BattleManager.play_card(id, target_idx)`。
4. 灰显判定：每次 `ResourceManager.resource_changed` (AP变化时) 遍历手牌检查费用。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体动画效果（发牌动画、受击受击特效、卡牌溶解特效），这里仅需做到实例化/销毁、血条数字变动。
- 文本的多语言翻译绑定（交给 Localization System 负责，这里直接留个空或者用 key 即可）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 抽牌UI显示
  - Setup: 玩家回合开始。
  - Verify: 底部手牌区出现了 5 个 `CardUI` 节点。
  - Pass condition: 数量正确，能够正常显示耗费。

- **AC-2**: 费用不足反馈
  - Setup: 手牌中有 3费卡，玩家当前AP为 2。
  - Verify: 该卡牌UI变灰（Modulate调暗或禁用）。
  - Pass condition: 视觉上不可用，点击调用被拦截。

- **AC-3**: 敌人血条更新
  - Setup: 选中敌人释放攻击卡。
  - Verify: `damage_dealt` 信号发出后，目标敌人的 HP 进度条减少。
  - Pass condition: 数值与后台一致。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/battle-hud-binding-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 到 006 (整个后端的跑通)
- Unlocks: 无
