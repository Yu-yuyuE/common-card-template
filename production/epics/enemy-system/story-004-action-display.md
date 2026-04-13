# Story 004: 敌人意图公示机制

Epic: 敌人系统
Estimate: 1 day
Status: Ready
Layer: Core
Type: Logic
Manifest Version: 2026-04-13

## Context

**GDD**: `design/gdd/enemies-design.md`
**Requirement**: TR-enemies-design-007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: 敌人系统架构
**ADR Decision Summary**: 提供 `get_displayed_action(enemy_id)` 方法，让玩家回合开始前能够获取下回合敌人的行动意图。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持行动公示机制，让玩家可预判

---

## Acceptance Criteria

*From GDD `design/gdd/enemies-design.md`, scoped to this story:*

- [ ] 实现 `get_displayed_action(enemy_id)`，不改变 `action_index` 状态（纯获取）。
- [ ] 考虑冷却状态：如果预判行动在冷却中，应公示其备用行动。
- [ ] 返回格式需包含：行动名称、简述、固定目标。
- [ ] 特殊支持蓄力行动公示：明确返回 "正在蓄力，下回合将释放 [行动名]"。

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

1. 和 `get_next_action` 类似，但绝对不要执行 `action_index = (action_index + 1) % size`。
2. 根据 `is_charging` 标记，组织并返回蓄力专用的展示文案。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体UI展示和界面绘制（UI相关由战斗系统的HUD故事处理）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 纯获取无副作用
  - Given: `action_index` = 0
  - When: 调用 `get_displayed_action()` 5次
  - Then: `action_index` 依然为 0，5次返回内容完全一致。

- **AC-2**: 蓄力公示
  - Given: `action_index` 指向一个带有 `is_charging=true` 且 `charge_target="C01"` 的行动。
  - When: 调用 `get_displayed_action()`
  - Then: 提取出 C01 的名称，组装成蓄力提示文案。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/enemy_system/action_display_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (序列轮转核心逻辑的基础)
- Unlocks: 无
