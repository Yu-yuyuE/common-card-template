# Epic: 事件系统

> **Layer**: Meta
> **GDD**: design/gdd/event-system.md
> **Architecture Module**: EventSystem
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories event-system`

## Overview

5大类50个事件（政治/军略/民心/人物/转折各10个）。大多数事件无选项，约30%有选项。后果类型包括：资源变化、战斗触发、卡组变化、天气修改。同地图已触发事件不重复触发。事件触发时检查前置条件，根据玩家选择执行对应后果。支持多语言事件文本。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: Map Node System | 事件触发绑定到地图节点 | LOW |
| ADR-0012: Shop System | 事件可能触发商店折扣 | LOW |
| ADR-0009: Terrain Weather System | 事件可能修改天气 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-event-001 | 50个事件，5大类 | ADR-0011 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/event-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories event-system` to break this epic into implementable stories.
