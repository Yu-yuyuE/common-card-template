# Story 6-8: 状态变化UI响应机制 — 手动验证证据

**Story**: production/epics/status-effects-system/story-007-status-ui-binding.md
**Date**: 2026-04-17
**Type**: UI Story — Manual Verification Required

## 信号适配说明

Story 原稿引用了 `status_refreshed` 信号，但 StatusManager 实际对外信号为：

| 信号 | 签名 | 触发时机 |
|------|------|----------|
| `status_applied` | `(type, new_layers, source)` | 施加新状态 **或** 刷新已有状态的层数 |
| `status_removed` | `(type, reason)` | 状态到期或被移除 |
| `dot_dealt` | `(type, damage, pierced_armor)` | 持续伤害结算 |

AC-2（刷新更新角标）通过 `status_applied` 实现：层数变化时 `new_layers` 即为最新值，
`_on_status_applied` 检测到图标已存在时直接调用 `set_layers(new_layers)`，功能与
`status_refreshed` 等价。

## 验证状态

| AC | 验证条件 | 状态 |
|----|----------|------|
| AC-1 | 施加状态后 UnitStatusBar 出现对应 StatusIconUI，角标显示正确层数 | 待场景搭建后验证 |
| AC-2 | 再次施加同类状态，已有图标角标更新为新层数（不新增图标） | 待场景搭建后验证 |
| AC-3 | 施加互斥状态后旧图标销毁、新图标出现（由 StatusManager 先发 removed 再发 applied） | 待场景搭建后验证 |
| AC-4 | `status_removed` 后对应图标从容器销毁，HBoxContainer 布局自动收缩 | 待场景搭建后验证 |

## 实现完成情况

- [x] `UnitStatusBar.gd` — `status_applied` / `status_removed` / `dot_dealt` 信号绑定完毕
- [x] `StatusIconUI.gd` — 占位 ColorRect + 层数 Label，节点由代码创建，不依赖 .tscn
- [x] 禁止 Polling — 已遵守 ADR-0002，纯 Signal 驱动，无 `_process` 轮询

## 偏差记录

| 偏差 | 原因 | 影响级别 |
|------|------|----------|
| `status_refreshed` 不存在，改用 `status_applied` | StatusManager 已有信号中无此信号 | ADVISORY（功能等价） |

## 待办

搭建 BattleScene.tscn 后执行手动 QA，将上表"待验证"项替换为实测截图或日志，
签字确认后关闭 ADVISORY 偏差项。
