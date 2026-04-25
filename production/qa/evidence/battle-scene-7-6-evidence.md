# 手动验证证明：BattleScene.tscn 搭建与 UI 绑定

**Story**: Sprint 7 — 7-6 [C2] BattleScene.tscn 搭建
**Scene**: `src/ui/battle/BattleScene.tscn`
**Date**: 待填写（验证完成后填入）
**Tester**: 待填写
**Status**: ⬜ Pending — 等待在 Godot 编辑器中实际验证

---

## 验证前提

在 Godot 4.6.1 编辑器中打开项目，将 `BattleScene.tscn` 加入测试场景或直接运行。
需要一个能触发 `BattleManager` 信号的测试入口（可复用现有测试框架或手动调用）。

---

## AC-1：手牌区 CardUI 正确实例化

**Story 007 / AC-1 对应验证**

| 步骤 | 操作 | 预期结果 | 实测结果 |
|------|------|----------|----------|
| 1 | 运行场景，调用 `BattleUI.refresh_hand(["card_cost_1", "card_cost_2", "card_cost_3"], 3)` | HandContainer 下出现 3 个 CardUI 节点 | ⬜ |
| 2 | 检查每个 CardUI 的费用标签 | 分别显示 1、2、3 | ⬜ |
| 3 | 检查每个 CardUI 的名称标签 | 显示对应 card_id | ⬜ |

**截图路径**（验证通过后附上）：`production/qa/evidence/screenshots/battle-scene-hand-ac1.png`

---

## AC-2：费用不足时手牌灰显

**Story 007 / AC-2 对应验证**

| 步骤 | 操作 | 预期结果 | 实测结果 |
|------|------|----------|----------|
| 1 | 调用 `BattleUI.refresh_hand(["card_cost_3"], 1)` | 该牌 modulate.a ≈ 0.4，视觉灰显 | ⬜ |
| 2 | 点击该卡牌 | 无响应（mouse_filter = IGNORE） | ⬜ |
| 3 | 调用 `BattleUI.refresh_hand(["card_cost_1"], 3)` | 该牌恢复正常亮度，可点击 | ⬜ |

**截图路径**：`production/qa/evidence/screenshots/battle-scene-grey-ac2.png`

---

## AC-3：PhaseLabel 随战斗阶段更新

**Story 007 / AC-3 对应验证**

| 步骤 | 操作 | 预期结果 | 实测结果 |
|------|------|----------|----------|
| 1 | 触发 `BattleManager.phase_changed(BattlePhase.PLAYER_PLAY)` | PhaseLabel 显示"玩家回合" | ⬜ |
| 2 | 触发 `phase_changed(BattlePhase.ENEMY_TURN)` | 显示"敌方回合" | ⬜ |
| 3 | 触发 `phase_changed(BattlePhase.PLAYER_DRAW)` | 显示"摸牌阶段" | ⬜ |

**截图路径**：`production/qa/evidence/screenshots/battle-scene-phase-ac3.png`

---

## AC-4：敌人血条随 damage_dealt 更新

**Story 007 / AC-4 对应验证**

| 步骤 | 操作 | 预期结果 | 实测结果 |
|------|------|----------|----------|
| 1 | 调用 `BattleUI.register_enemy_hp_bar("enemy_0", $EnemyArea/Enemy0Area/Enemy0HpBar)` | 血条注册成功，初始值 100 | ⬜ |
| 2 | 触发 `BattleManager.damage_dealt("enemy_0", 30)` | Enemy0HpBar.value 变为 70 | ⬜ |
| 3 | 再次触发 `damage_dealt("enemy_0", 80)` | 血条 clamp 到 0，不出现负值 | ⬜ |

**截图路径**：`production/qa/evidence/screenshots/battle-scene-hpbar-ac4.png`

---

## 场景结构验证

| 检查项 | 预期 | 实测结果 |
|--------|------|----------|
| BattleScene 根节点挂载 BattleUI.gd | ✅ | ⬜ |
| hand_container_path 指向 HandContainer | ✅ | ⬜ |
| phase_label_path 指向 PhaseLabel | ✅ | ⬜ |
| 3 个敌人 ProgressBar 节点存在 | ✅ | ⬜ |
| 场景可在编辑器无报错打开 | ✅ | ⬜ |

---

## 最终签字

| 项目 | 值 |
|------|-----|
| 验证日期 | |
| 验证者 | |
| 总体结论 | ⬜ PASS / ⬜ FAIL / ⬜ PARTIAL |
| 遗留问题 | |

---

> **Note**: 本文档对应 Sprint 7 条件 C2（BattleScene.tscn 手动 UI 验证）。
> 所有 AC 验证通过后，将本文档更新为 PASS 并在 `/story-done` 时引用此路径。
