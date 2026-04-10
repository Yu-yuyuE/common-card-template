# Story 007: 敌人意图与状态UI绑定

> **Epic**: 敌人系统
> **Status**: Ready
> **Layer**: Core
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-007 (行动公示), TR-enemies-design-012 (敌人血量)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 在玩家回合开始时获取并展示意图。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须实时反映敌人的意图、血量变化。

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 每个敌人头顶创建一个 `IntentUI` 节点。
- [ ] 玩家回合开始前，调用 `get_displayed_action()` 并将结果更新至 UI（显示图标或文本如"攻击 10点", "蓄力中"）。
- [ ] 敌人受到伤害或治疗时更新自身血条数值及进度条。
- [ ] 敌人死亡时，播放死亡动画或直接将整个敌方节点隐藏/移除。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. 在 `EnemyView.tscn` 里面集成 `ProgressBar` 供HP显示，和一个 `Label` / `TextureRect` 供意图显示。
2. 订阅战斗系统的 `turn_started(is_player)` 信号，如果是玩家，则刷新所有敌人的意图。
3. 订阅 `damage_dealt` 信号，匹配 `target_pos`，如果是自己，则用 tween 播放扣血动画。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体美术资源。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 意图显示准确
  - Setup: 玩家回合开始。
  - Verify: 敌人头顶显示即将执行的操作（如：防守、攻击 12）。
  - Pass condition: 与随后敌人回合实际作出的动作完全吻合。

- **AC-2**: 蓄力特殊提示
  - Setup: 敌人进入蓄力技能的前置回合。
  - Verify: UI上明确提示"蓄力"，而非普通攻击。

- **AC-3**: 动态血量更新
  - Setup: 使用卡牌攻击敌人。
  - Verify: 被击中瞬间，敌人血条和数值立刻下调。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/enemy-intent-ui-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (公示接口)
- Unlocks: 无
