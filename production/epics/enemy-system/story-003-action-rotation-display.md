# Story 003: 固定行动序列循环与公示

> **Epic**: 敌人系统
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-001, TR-enemies-design-006, TR-enemies-design-007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 提供 `get_next_action()` 和 `get_displayed_action()` 接口，管理内部计数器 `action_index`，轮转序列并处理冷却。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 敌人行动按规律轮换，保证可预判性。
- Required: 必须能在玩家回合开始前提供本回合要执行的行动信息以供公示。

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `get_displayed_action(enemy_id)`，不推进内部计数器，仅预览。若动作正在冷却，预览备用动作。
- [ ] 实现 `get_next_action(enemy_id)`，获取要执行的动作并将 `action_index` 移至下一步（循环）。
- [ ] 处理冷却逻辑：如果在 `cooldown_actions` 中存在且剩余冷却 > 0，则跳过该动作并选择序列中下一个非冷却的（或者按 GDD 约定的备份动作）执行，同时显示此备份动作。
- [ ] 应对状态：如果敌人处于"眩晕"(STUN)状态，本回合跳过行动，但是 `action_index` 计数器**必须正常推进**。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. 在 `EnemyData` 实例内部保存 `action_index`（初值为0）和 `cooldown_actions: Dictionary`。
2. 眩晕跳过判定可在 `CardBattleSystem` 的敌人回合流转中实现，或在这里返回特殊 `SKIP` 行动，但要确保计数器递增：
   ```gdscript
   enemy.action_index = (enemy.action_index + 1) % enemy.action_sequence.size()
   ```
3. 备用行动：GDD 约定，如果是条件不满足（或冷却中），直接"替换为序列中下一个非冷却行动"。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 动作真实的执行（结算掉血、生成卡牌等由 Story 006 处理）。
- 真正的条件触发相变插队（由 Story 004 决策树处理）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 循环递增
  - Given: 敌人序列为 `["A01", "A02"]`
  - When: 连续调用3次 `get_next_action`
  - Then: 依次返回 "A01", "A02", 然后再次返回 "A01"。

- **AC-2**: 预览与执行一致
  - Given: 敌人当前即将执行 "A02"
  - When: 先调用 `get_displayed_action`，再调用 `get_next_action`
  - Then: 预览返回的结果与真实抓取要执行的动作完全一致。且预览调用不影响计数器。

- **AC-3**: 冷却规避
  - Given: 序列 `["C05", "A01"]`，其中 C05 被标记在冷却字典中。
  - When: 轮到 C05 时请求 `get_next_action`
  - Then: 返回 "A01"，计数器正常推进。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/action_rotation_display_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (数据), Story 002 (行动库)
- Unlocks: Story 005 (执行器)
