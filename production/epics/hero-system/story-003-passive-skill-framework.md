# Story 003: 被动技能框架与时机钩子注册

> **Epic**: 武将系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/heroes-design.md`
**Requirement**: TR-heroes-design-005 (1个被动技能)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 提供 `_passive_skills` 字典及 `trigger_passive(trigger_type, context)` 方法。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持被动技能触发机制。
- Forbidden: 禁止将被动技能逻辑硬编码在武将类中，必须使用可配置的trigger_condition和effect_function。

---

## Acceptance Criteria

*From GDD `design/gdd/heroes-design.md`, scoped to this story:*

- [ ] 定义 `PassiveSkillEffect` 内部结构，包含 `trigger_condition` 字符串和 `effect_function` Callable。
- [ ] 实现 `trigger_passive(trigger_type: String, context: Dictionary) -> void`。
- [ ] 该方法应匹配 `_current_hero.passive_trigger` 以及当前传入的 `trigger_type`，如果吻合，调用对应的 Callable。
- [ ] 执行成功后，发射 `passive_triggered(hero_id, skill_name, result)` 信号，供 UI 弹出提示。
- [ ] 至少写一个模拟的被动技能实现，验证整个注册、派发和回调流程。

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

1. 在 `HeroManager` 的 `_register_passive_skills()` 中，创建 `PassiveSkillEffect` 实例并将其存在 `_passive_skills` 中。
2. 触发：
   ```gdscript
   func trigger_passive(trigger_type: String, context: Dictionary) -> void:
       if not _current_hero: return
       var effect = _passive_skills.get(_current_hero.passive_skill_id)
       if effect and effect.trigger_condition == trigger_type:
           var res = effect.effect_function.call(context)
           passive_triggered.emit(_current_hero.id, _current_hero.passive_skill_name, res)
   ```
3. 这个故事仅搭建平台和关隘，具体复杂的魏蜀吴被动逻辑在 005 和 006 完善。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体的诸葛亮、司马懿被动效果等业务代码（后续故事填补）。
- 战斗框架中的实际调用抛出（如 `BattleManager` 里主动抛出 `on_damaged`）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 正常触发与信号发出
  - Given: 注册了一个名为 "mock_skill" 的被动，条件为 "on_turn_start"，当前武将绑定此技能。
  - When: 调用 `trigger_passive("on_turn_start", {})`
  - Then: 绑定的 Mock 函数被执行，并发出了 `passive_triggered` 信号，携带武将 ID 和返回结果字典。

- **AC-2**: 不匹配时机跳过
  - Given: 当前武将被动条件是 "on_damaged"
  - When: 调用 `trigger_passive("on_turn_start", {})`
  - Then: 静默返回，不抛错，不发信号。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/hero_system/passive_skill_framework_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 005, Story 006
