# Story 004: 升级功能区与分支选择交互

> **Epic**: 军营系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/barracks-system.md`
**Requirement**: `TR-barracks-system-001`

**ADR Governing Implementation**: ADR-0010 (Hero System), ADR-0014 (Troop Terrain Calculation)
**ADR Decision Summary**: 提供界面升级兵种卡；Lv2 到 Lv3 为多分支选择，不可撤销。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须使用Signal驱动的响应式模式，UI 数据解耦。
- Forbidden: 禁止在代码中使用硬编码字符串。

---

## Acceptance Criteria

- [ ] “升级”区域：以列表形式展示玩家卡组中所有的 Lv1 和 Lv2 兵种卡
- [ ] Lv1->Lv2 交互：展示 50 金币消耗与 Lv2 效果预览，金币不足时按钮置灰
- [ ] Lv2->Lv3 分支交互：点击升级后，弹出分支选择弹窗，显示 5-6 张对应的 Lv3 精锐兵种卡
- [ ] Lv2->Lv3 弹窗包含“暂不升级”选项，确认升级后不可撤销，且界面实时更新
- [ ] 动态订阅当前金币量，金币变动时自动刷新当前可点击的升级按钮状态

---

## Implementation Notes

在 `BarracksScene.tscn` 内扩充“升级功能区”。
设计专门的分支选择面板（例如 `TroopBranchSelectionDialog.tscn`）。
从卡牌数据库（CSV）读取 Lv2 对应的合法 Lv3 卡牌列表进行实例化预览。

---

## Out of Scope

- 兵种卡数据的 CSV 录入（默认已有模拟数据或由其他Epic负责）。

---

## QA Test Cases

- **AC-1**: 金币不足限制
  - Setup: 设置当前金币为 10，拥有 Lv1 兵种卡
  - Verify: 升级按钮被置灰，提示文字显示“金币不足”
  - Pass condition: 无法点击执行升级
- **AC-2**: 分支选择交互
  - Setup: 点击 Lv2 兵种卡升级按钮
  - Verify: 弹出对应分支的 5 个 Lv3 选项。选中一个并确认后，原 Lv2 卡立即从界面列表中变为新 Lv3 卡，且不再显示升级按钮
  - Pass condition: 升级流程顺畅，扣费正确，无撤销路径

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/barracks-upgrade-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 003
- Unlocks: None