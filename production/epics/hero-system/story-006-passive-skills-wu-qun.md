# Story 006: 吴群阵营及特殊机制被动实现

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
**ADR Decision Summary**: 补充实现剩余高复杂度的被动机制。

**Engine**: Godot 4.6.1 | **Risk**: MEDIUM
**Engine Notes**: 涉及自定义层数、特殊复活机制，需要仔细控制变量。

**Control Manifest Rules (this layer)**:
- Required: 被动机制不应当引起死循环。张角复活等需要妥善削减生命上限。

---

## Acceptance Criteria

*From GDD `design/gdd/heroes-design.md`, scoped to this story:*

- [ ] 实现司马懿"隐忍"：`on_curse_added_to_hand` 时，层数增加。每回合末基于层数执行回甲等效果，后清零。
- [ ] 实现典韦"恶来"："死战"状态及触发，暴击回血。
- [ ] 实现张角"黄天当立"：护甲无上限（需要在 ResourceManager 兼容）；`on_death` 时，记录复活次数，最大HP减半（最低1），并在下一回合（或战斗系统允许的帧）复活，上限 3 次。
- [ ] 实现贾诩"毒士"：当敌人获得负面状态时，贾诩施加的新负面状态会覆盖现有状态，但新状态的层数 = 现有状态层数 + 新施加层数；获得"诡谋"层数；2层诡谋下回合减费。

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

1. 张角复活 `on_death`：
   由于此时 HP 为 0 并且即将被战斗系统清理，这应当是最高优先级的事件。
   ```gdscript
   func _effect_huang_tian_dang_li(context):
       var resurrect_count = get_meta("resurrect_count", 0)
       if resurrect_count < 3:
           resurrect_count += 1
           set_meta("resurrect_count", resurrect_count)
           # MaxHP减半
           var cur_max = ResourceManager.get_resource(MAX_HP)
           var new_max = max(1, floor(cur_max * 0.5))
           ResourceManager.set_resource(MAX_HP, new_max)
           ResourceManager.set_resource(HP, new_max)
           # 阻止 game_over，通知战斗系统武将复活
           return {"resurrected": true}
       return {"resurrected": false}
   ```
2. 贾诩的被动实现：当贾诩施加新的负面状态时，需要检查目标是否已有负面状态。如果有，计算新层数（现有层数 + 新施加层数），然后调用 StatusManager 的 apply 方法覆盖旧状态。为避免死循环，层数合并效果执行时应带上特殊的来源标签跳过自身再检测。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体的死亡UI表现、沙兵召唤模型，这里仅实现数据的重置与复活信号反馈。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 张角复活3次减半
  - Given: 张角初始 MaxHP 40。
  - When: 触发三次死亡(`on_death` 钩子)。
  - Then: 第一次复活 MaxHP=20, 第二次=10, 第三次=5。第四次死亡时返回 `resurrected: false`。

- **AC-2**: 司马懿隐忍层数
  - Given: `on_curse_added` 被调用 5 次。
  - When: 检查内部隐忍层数变量。
  - Then: 层数最大为 4，不溢出。回合结束调用清零时恢复为 0。

- **AC-3**: 贾诩毒士覆合并层
  - Given: 贾诩选中，敌人当前有 3层 中毒。
  - When: 系统尝试给敌人施加 2层 中毒，触发贾诩被动计算修正。
  - Then: 最终施加层数变为 3+2 = 5 层（旧状态被覆盖，但层数合并）。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/hero_system/passive_skills_wu_qun_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: 无
