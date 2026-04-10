# Epic: 状态效果系统

> **Layer**: Core
> **GDD**: design/gdd/status-design.md
> **Architecture Module**: StatusSystem
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories status-effect-system`

## Overview

管理20种状态效果：7种Buff（护盾、攻击力强化、防御力强化、速度强化、恢复、闪避暴击、行动点恢复）和13种Debuff（灼烧、中毒、剧毒、瘟疫、重伤、流血、冰冻、沉默、虚弱、缴械、诅咒、迷惑、混乱）。同类状态叠加层数，不同类状态互斥覆盖。回合结束时结算持续伤害，区分穿透护盾和走护盾两种类型。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Status System | 集中式StatusManager+事件驱动 | LOW |

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

Run `/create-stories status-effect-system` to break this epic into implementable stories.