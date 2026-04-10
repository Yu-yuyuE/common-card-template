# Story 007: 兵种卡UI联动显示

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: 分支选择预览 (Player Fantasy 选择感)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: N/A
**ADR Decision Summary**: 军营节点的 UI 层展示，包括卡牌发光提示和 Lv3 分支 3选1 窗口。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 分支选择必须告知"选择后不可更改"。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 在战斗中，若地形和兵种有加成（如平原骑兵），手牌中的兵种卡UI应有视觉提示（如发光或绿色箭头）。
- [ ] 制作 `TroopBranchSelectUI` 弹出界面，接收一个卡牌基础类型，展示该类型对应的所有 Lv3 分支。
- [ ] 分支卡片需显示其卡面数值、费用和独有说明。
- [ ] 玩家点击其中一个分支后，弹出二次确认弹窗"此选择本局内不可更改"，确认后派发升级完成信号。
- [ ] 若玩家点击"暂不升级"，窗口关闭，返回原始节点界面。

---

## Implementation Notes

*Derived from UI Pattern Guidelines:*

1. 手牌的联动提示：通过 `TerrainWeatherManager.is_terrain_favorable(card.category)` 控制一个图标节点的可见性或 `Modulate`。
2. `TroopBranchSelectUI` 实例化传入 `base_type`，从配置加载该类别所有 `tier=3` 的卡牌并遍历生成 `CardUI`。
3. 二次确认可使用标准 `ConfirmationDialog`。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 将卡牌实际替换入牌库的逻辑（该 UI 仅发送信号，由 DeckManager/营地系统 执行实际替换）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 优势地形视觉提示
  - Setup: 战斗处于平原地形，手牌中有一张骑兵卡和一张弓兵卡。
  - Verify: 骑兵卡边缘泛绿光或有增益标记，弓兵卡无特殊显示。
  - Pass condition: 提示醒目但不干扰点击。

- **AC-2**: 分支选择弹窗
  - Setup: 在军营节点触发升级步兵。
  - Verify: 弹出界面，显示 5 种步兵 Lv3 分支卡。
  - Pass condition: 卡面信息完整，支持滚动或网格排列显示全。

- **AC-3**: 二次确认机制
  - Setup: 选中"虎贲卫"分支。
  - Verify: 弹出确认窗口。点击取消则退回列表；点击确认则窗口消失。
  - Pass condition: 流程符合防误触预期。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/troop-ui-branch-select-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004
- Unlocks: 无
