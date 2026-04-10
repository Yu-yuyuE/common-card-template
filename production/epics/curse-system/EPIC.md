# Epic: 诅咒系统

> **Layer**: Feature
> **GDD**: design/gdd/curse-system.md
> **Architecture Module**: CurseSystem
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories curse-system`

## Overview

3种诅咒类型：抽到触发、常驻牌库、常驻手牌。诅咒牌通过多种方式添加到玩家卡组（战斗胜利、事件等）。净化操作将诅咒卡移出卡组。提供OnCurseCardDrawn事件钩子供武将被动技能监听（如司马懿诅咒流）。基础25张+高阶30张诅咒卡。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Card Battle System | 诅咒卡集成到战斗系统 | LOW |
| ADR-0006: Status System | 诅咒作为状态效果管理 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-curse-system-001 | 3种诅咒类型 | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/curse-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories curse-system` to break this epic into implementable stories.
