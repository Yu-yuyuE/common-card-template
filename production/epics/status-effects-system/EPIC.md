# Epic: 状态效果系统

> **Layer**: Core
> **GDD**: design/gdd/status-design.md
> **Architecture Module**: StatusSystem
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories status-effects-system`

## Overview

集中式状态管理系统，支持7种Buff和13种Debuff共20种状态效果。同类状态叠加层数，不同类状态互斥覆盖。状态伤害区分穿透护盾和走护盾两种类型。通过状态变化信号广播，回合结束时自动结算持续伤害和消耗。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Status System | 集中式管理+事件驱动模式 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-status-design-001 | 20种状态效果 | ADR-0006 ✅ |
| TR-status-design-002 | 7种Buff + 13种Debuff | ADR-0006 ✅ |
| TR-status-design-003 | 同类叠加/不同类互斥 | ADR-0006 ✅ |
| TR-status-design-004 | 状态伤害计算 | ADR-0006 ✅ |
| TR-status-design-005 | 回合结束消耗 | ADR-0006 ✅ |
| TR-status-design-006 | 穿透护盾/走护盾 | ADR-0006 ✅ |
| TR-status-design-007 | 状态效果对伤害的修正 | ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/status-design.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories status-effects-system` to break this epic into implementable stories.
