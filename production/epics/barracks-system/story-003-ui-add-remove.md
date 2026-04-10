# Story 003: 军营主场景及添加/移出面板

> **Epic**: 军营系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/barracks-system.md`
**Requirement**: `TR-barracks-system-001`

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 军营系统需提供界面交互，管理卡组增减。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须使用Signal驱动的响应式模式，必须通过语言键引用文本，必须使用原生 Translation。
- Forbidden: 禁止硬编码字符串，禁止在业务逻辑中操作 UI。

---

## Acceptance Criteria

- [ ] 搭建军营场景 UI（划分为添加、升级、移出三大区域）
- [ ] “添加”区域：展示 3 张生成的候选兵种卡，点击可添加。当统帅满时，按钮置灰且提示“兵种卡已达统帅上限”
- [ ] “移出”区域：滚动列表显示当前卡组内所有卡牌。点击卡牌可移出
- [ ] “移出”操作触发警告弹窗；若目标是“武将专属卡”，警告文本额外提示本局不可恢复
- [ ] 所有文本内容从 Godot 本地化翻译文件读取

---

## Implementation Notes

创建 `BarracksScene.tscn` 及其 UI 脚本。
订阅 `BarracksManager` 的状态。
当统帅满时，监听数据状态，将对应 Button 的 `disabled` 设置为 `true`。
弹出窗口使用单独的 `ConfirmationDialog`。

---

## Out of Scope

- “升级功能区”和 Lv2->Lv3 的复杂分支展示（由 Story 004 处理）。

---

## QA Test Cases

- **AC-1**: 统帅限制UI展示
  - Setup: 当前卡组兵种卡数达到统帅上限
  - Verify: 添加候选卡的按钮呈灰色，不可点击，提示文字正确
  - Pass condition: 玩家无法通过点击强行添加卡牌
- **AC-2**: 移除警告弹窗
  - Setup: 选择移除一张武将专属卡
  - Verify: 弹出“武将专属卡移出后本局不可恢复，确认？”的多语言化提示弹窗
  - Pass condition: 点击确认后卡牌消失

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/barracks-add-remove-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 004