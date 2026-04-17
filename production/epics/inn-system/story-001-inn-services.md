# Story 001: 酒馆服务实现

> **Epic**: inn-system
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/inn-system.md`
**Requirement**: `TR-inn-system-001`

**ADR Governing Implementation**: ADR-0013: 酒馆系统架构
**ADR Decision Summary**: 采用章节限制 + 即时服务模式；InnManager 集中管理歇息次数与服务逻辑；UI 通过信号更新。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 无 post-cutoff API 使用，RefCounted 纯逻辑层不依赖 Node 生命周期。

**Control Manifest Rules (this layer)**:
- Required: 纯逻辑层使用参数注入而非直接调用 ResourceManager 单例（保持可测试性）
- Forbidden: 禁止在逻辑方法内直接访问 ResourceManager（UI 层可以，逻辑层不行）

---

## Acceptance Criteria

- [ ] 歇息服务：调用 `rest()` 后，英雄 HP 增加 min(15, max_hp - current_hp)，返回实际恢复量
- [ ] HP 已满时歇息：current_hp == max_hp 时，`rest()` 返回 0，不修改状态
- [ ] 粮草购买：40金币购买 40 粮草；金币不足时返回失败；粮草不超过上限（上限由调用方传入）
- [ ] 强化休整：消耗 60金币，HP 增加 min(20, max_hp - current_hp)；HP 已满时返回失败；金币不足时返回失败
- [ ] 章节限制：每章歇息（非强化）最多 1 次；`rest_count >= rest_limit` 时 `can_rest(false)` 返回 false；重置通过 `reset_chapter()` 触发

---

## Implementation Notes

新建 `src/core/inn-system/InnManager.gd`，采用参数注入（接收 current_hp, max_hp, current_gold 等参数），不直接读写 ResourceManager，保持纯逻辑可测。

关键常量（与 ADR-0013 对齐）：
- `REST_BASE_HEAL = 15`
- `ENHANCED_HEAL = 20`
- `PROVISIONS_AMOUNT = 40`（每次购买数量）
- `PROVISIONS_PRICE = 40`（金币）
- `ENHANCED_PRICE = 60`
- `REST_LIMIT = 1`（每章限制）

暴露接口：
- `rest(current_hp, max_hp) -> int`（返回实际恢复量，0表示无效）
- `fortify(current_hp, max_hp, current_gold) -> Dictionary`（返回 {success, hp_gained, gold_spent}）
- `buy_provisions(current_gold, current_provisions, max_provisions) -> Dictionary`
- `can_rest() -> bool`
- `can_fortify(current_hp, max_hp, current_gold) -> bool`
- `reset_chapter()` — 章节开始时重置 rest_count

---

## Out of Scope

- UI 展示（按钮、标签、反馈动画）— 见 story-002 或 UI epic
- ResourceManager 实际资源扣减（由调用方执行，本 story 只返回变更量）
- 音效与视觉反馈
- 酒馆状态持久化 — 见 story-002-inn-persistence（6-10）

---

## QA Test Cases

1. **test_rest_auto_trigger** - 歇息自动触发（HP 不满时）
2. **test_rest_at_max_hp** - HP 已满时恢复量为 0
3. **test_rest_partial_heal** - HP 差值小于 15 时只恢复差值
4. **test_rest_chapter_limit** - 歇息超过 1 次时 can_rest 返回 false
5. **test_rest_reset_on_new_chapter** - reset_chapter() 后 can_rest 恢复 true
6. **test_purchase_provisions** - 40 金购买 40 粮
7. **test_purchase_provisions_insufficient_gold** - 金不足返回失败
8. **test_purchase_provisions_at_cap** - 粮草达上限时返回失败
9. **test_fortify_success** - 60 金强化休整成功
10. **test_fortify_at_max_hp** - HP 已满时强化失败
11. **test_fortify_insufficient_gold** - 金不足时强化失败

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/inn_system/inn_services_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: ResourceManager 初始化完毕（ADR-0003）
- Unlocks: story-002-inn-persistence（6-10）

---

## Estimate

**0.5 天**

## Completion Notes
**Completed**: 2026-04-17
**Criteria**: 5/5 passing
**Deviations**: None — 所有常量与 ADR-0013 完全对齐，零单例依赖
**Test Evidence**: Logic — `tests/unit/inn_system/inn_services_test.gd`（13 个测试函数，覆盖 AC1~AC5）
**Code Review**: Skipped — Lean mode
