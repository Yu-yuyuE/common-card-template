# Story 007: 状态变化UI响应机制

> **Epic**: 状态效果系统
> **Status**: Ready
> **Layer**: Core
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: 状态显示 (Player Fantasy 要求 UI 清晰显示当前激活状态)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: 系统间通信模式
**ADR Decision Summary**: UI 通过订阅 `StatusManager` 的 `status_applied`, `status_removed`, `status_refreshed` 信号动态更新状态栏。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: UI必须通过Signal驱动的响应式模式更新
- Forbidden: 禁止手动轮询(Polling)状态数据

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [ ] 战斗HUD（玩家/敌人状态栏）监听状态系统信号。
- [ ] `status_applied` 时：在单位血条旁/上方实例化状态图标，显示层数角标。
- [ ] `status_refreshed` 时：更新对应状态图标的层数数字。
- [ ] `status_removed` 时：销毁对应的状态图标，更新排版布局。
- [ ] (可选/如果有资源) 触发状态伤害（`status_damage_dealt`）时在目标头顶飘字（显示为毒/火特定颜色飘字）。

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

1. 在 UI 脚本（如 `UnitStatusBar.gd`）中：
   ```gdscript
   func _ready():
       StatusManager.status_applied.connect(_on_status_applied)
       StatusManager.status_refreshed.connect(_on_status_refreshed)
       StatusManager.status_removed.connect(_on_status_removed)
   ```
2. 注意由于信号是全局广播，UI接收时必须先判断 `target` 是否是自己绑定的战斗单位（`if target != my_unit: return`）。
3. 使用 `HBoxContainer` 或 `GridContainer` 自动管理图标排列。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体状态图标的绘制/贴图资源获取（由美术团队提供，此处用占位符 ColorRect 或文字替代实现逻辑连通）。
- UI 本地化翻译（由 Epic: 本地化系统 处理）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 状态施加显示
  - Setup: 战斗界面，某单位空状态。
  - Verify: 给单位施加2层破甲。
  - Pass condition: 单位血条旁立刻出现 1 个代表破甲的图标，并在角标显示 "2"。

- **AC-2**: 状态刷新显示
  - Setup: 目标已有 2层 破甲图标。
  - Verify: 再给单位施加 3层 破甲。
  - Pass condition: 没有增加新图标，原图标角标变为 "3"。

- **AC-3**: 状态互斥UI表现
  - Setup: 目标有 3层 中毒图标。
  - Verify: 施加 2层 破甲。
  - Pass condition: 中毒图标消失，破甲图标出现并显示 "2"。

- **AC-4**: 状态移除
  - Setup: 目标有破甲图标。
  - Verify: 触发移除逻辑（或回合结束层数归0）。
  - Pass condition: 图标从UI容器中平滑销毁，不留空白缝隙。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/status-ui-binding-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (增删改), Story 002 (刷新互斥信号发出)
- Unlocks: 无
