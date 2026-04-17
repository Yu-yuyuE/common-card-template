# Story 6-7: 战斗HUD与手牌UI绑定 — 手动验证证据

**Story**: production/epics/card-battle-system/story-007-battle-hud-binding.md
**Date**: 2026-04-17
**Type**: UI Story — Manual Verification Required

## 验证状态

| AC | 验证条件 | 状态 |
|----|----------|------|
| AC-1 | 玩家回合开始后，手牌区出现对应 CardUI 节点 | 待场景搭建后验证 |
| AC-2 | AP 不足时对应 CardUI modulate.a=0.4，mouse_filter=IGNORE | 待场景搭建后验证 |
| AC-3 | damage_dealt 信号触发后敌人 ProgressBar 值减少 | 待场景搭建后验证 |

## 实现完成情况

- [x] BattleUI.gd — Signal 绑定实现完毕（battle_started/phase_changed/turn_started/damage_dealt）
- [x] CardUI.gd — 代码创建节点，费用显示，灰显逻辑完毕
- [x] 禁止 _process 轮询 — 已遵守 ADR-0007

## 待办

搭建 BattleScene.tscn 后执行手动 QA 并在此文档补充截图/实测结果，签字后关闭 ADVISORY 项。
