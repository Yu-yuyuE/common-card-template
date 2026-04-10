# Epic: 酒馆系统

> **Layer**: Feature
> **GDD**: design/gdd/inn-system.md
> **Architecture Module**: InnSystem
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories inn-system`

## Overview

酒馆节点提供三项服务：歇息恢复（免费+15HP自动触发，每章最多1次）、购买粮草（40金币/40粮草，可多次）、强化休整（60金币+20HP，每次访问限1次）。 curse卡净化由军营节点提供，酒馆不涉及。必须在歇息时检查HP上限，购买粮草按数量比例计算价格。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0013: Inn System | InnManager集中管理+章节重置机制 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-inn-system-001 | 歇息/粮草/休整 | ADR-0013 ✅ |
| TR-inn-system-002 | 歇息+15HP | ADR-0013 ✅ |
| TR-inn-system-003 | 买粮草40金/40粮 | ADR-0013 ✅ |
| TR-inn-system-004 | 强化休整60金+20HP | ADR-0013 ✅ |
| TR-inn-system-005 | 每章歇息1次 | ADR-0013 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/inn-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories inn-system` to break this epic into implementable stories.
