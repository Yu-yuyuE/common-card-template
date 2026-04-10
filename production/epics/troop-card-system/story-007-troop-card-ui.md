# Story 007: 兵种卡UI联动显示

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: 界面展示 (分支预览、地形加成提示)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: UI数据绑定
**ADR Decision Summary**: 卡牌 UI 动态查询并显示自身在当前地形天气下的修正结果。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须响应地形天气，在兵种卡上给出视觉提示（如伤害数字变绿）。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 在战斗场景的手牌卡牌上，如果有地形正向联动（`is_terrain_favorable`），则该卡的伤害数值或边缘显示绿色/高亮。如果有负面惩罚（`is_terrain_unfavorable`），显示红色/警告。
- [ ] 实装军营节点的 Lv2 → Lv3 分支升级UI（面板）。给定一张 Lv2 卡，弹出所有相关的 Lv3 选项供点击选择。
- [ ] 分支卡选择面板上，必须包含二次确认弹窗："此选择本局内不可更改"。

---

## Implementation Notes

*Derived from ADR-0016 Implementation Guidelines:*

1. `CardUI` 类 `_process` 或是响应环境切换事件：
   ```gdscript
   var terrain_mgr = TerrainWeatherManager
   if terrain_mgr.is_terrain_favorable(card_data.troop_type):
       damage_label.modulate = Color.GREEN
   elif terrain_mgr.is_terrain_unfavorable(card_data.troop_type):
       damage_label.modulate = Color.RED
   else:
       damage_label.modulate = Color.WHITE
   ```
2. `CampUpgradePanel.tscn` 创建用于展示卡牌的网格：
   ```gdscript
   func show_options(base_type: String):
       var options = DeckManager.get_available_lv3_branches(base_type)
       # 循环实例化 CardUI 显示，绑定点击事件 -> 弹窗确认 -> 替换卡组 -> 关闭
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体分支升级卡牌的美术原画。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 地形惩罚红色预警
  - Setup: 进入山地(MOUNTAIN)节点。
  - Verify: 手牌中骑兵卡的伤害数字显示为红色。
  - Pass condition: 明显提醒玩家此卡被削弱。

- **AC-2**: 沙漠费用减色
  - Setup: 进入沙漠(DESERT)节点。
  - Verify: 手牌中骑兵卡的费用数字变成 0，并高亮。
  - Pass condition: 玩家能感知到费用红利。

- **AC-3**: 分支选择不可逆警告
  - Setup: 在军营选择分支卡。
  - Verify: 点击某分支后，弹出确认对话框。
  - Pass condition: 取消后可以重选；确认后关闭UI并完成卡组替换。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/troop-card-ui-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003, Story 004
- Unlocks: 无
