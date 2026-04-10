# Story 006: 特殊交互规则（免疫/穿透/瘟疫）

> **Epic**: 状态效果系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/status-design.md`
**Requirement**: TR-status-design-001 (特殊交互边界条件)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: 状态效果系统架构
**ADR Decision Summary**: 处理免疫阻挡、穿透格挡、瘟疫传播等特殊机制。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须正确处理各类状态之间的边界情况。

---

## Acceptance Criteria

*From GDD `design/gdd/status-design.md`, scoped to this story:*

- [ ] **免疫 (IMMUNE)**：拥有该状态的单位在调用 `apply_status` 试图施加任何 `DEBUFF` 时，静默失败（不扣层数，不覆盖，不发应用信号）。施加 `BUFF` 正常。
- [ ] **穿透 vs 格挡**：战斗系统调用穿透攻击时，应能查询目标是否有格挡，穿透攻击应绕过格挡并且**不消耗格挡层数**（此功能需提供给战斗系统查询接口 `has_status_type()` 并在战斗逻辑里判定，但本故事需准备好 `is_immune()` 和格挡判断辅助）。
- [ ] **瘟疫传播 (PLAGUE)**：在回合结束 `tick_status` 时，如果单位有瘟疫层数，需要向"相邻单位"传播 1 层。由于 StatusManager 不知道节点位置，需通过发射信号 `status_plague_spread(target)` 让战斗系统去执行对相邻单位的施加。

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

1. 在 `apply_status()` 方法头部增加免疫检查：
   ```gdscript
   if _create_status(category, layers, "").type == StatusType.DEBUFF:
       if is_immune(target):
           return # 静默失败
   ```
2. 瘟疫传播：在 `tick_status(target)` 中，如果发现目标有 `PLAGUE` 状态，发送信号：
   ```gdscript
   signal status_plague_spread(source_target: Node)
   ```
   通知给外界监听器进行传播逻辑。
3. 提供 `is_immune(target) -> bool` 供外部便捷调用。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- C2 卡牌战斗系统中的具体物理占位(相邻)判定（本模块只发出传播信号，由战斗系统监听并向相邻单位施加瘟疫）。
- C2 中穿透攻击无视格挡的具体减伤逻辑（StatusManager只需准确返回目标有无格挡层数）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 免疫阻止 Debuff
  - Given: 目标有 1层 IMMUNE (Buff)
  - When: 试图施加 POISON (Debuff)
  - Then: get_status 返回 0，未触发应用信号
  - Edge cases: 试图施加 FURY (Buff) -> 成功

- **AC-2**: 瘟疫传播信号
  - Given: 目标有 2层 PLAGUE
  - When: 调用 tick_status(target)
  - Then: 目标瘟疫变为 1层，且系统发射了一次 `status_plague_spread` 信号并将该目标传递出去。

- **AC-3**: 辅助查询功能
  - Given: 目标拥有 BLOCK 和 IMMUNE
  - When: 调用 is_immune(target) 和 get_status(target, BLOCK)
  - Then: 正确返回 true 和 对应层数。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/status_system/status_special_interactions_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (数据结构), Story 003 (回合结算)
- Unlocks: 无
