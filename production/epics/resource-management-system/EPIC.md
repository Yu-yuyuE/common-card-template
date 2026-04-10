# Epic: 资源管理系统

> **Layer**: Foundation
> **GDD**: design/gdd/resource-management-system.md
> **Architecture Module**: ResourceManager
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories resource-management-system`

## Overview

集中管理四种游戏资源：HP（40-60玩家上限）、粮草（0-150上限）、行动点（可累积，上限=武将基础值）、金币（无上限）。所有资源变化通过 Signal 广播通知监听者，实现响应式 UI 更新。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: System Communication | 双层通信架构（Node Signal + EventBus） | LOW |
| ADR-0003: Resource Notification | 集中式资源管理+Signal广播 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-resource-management-system-001 | 4种资源管理 | ADR-0003 ✅ |
| TR-resource-management-system-002 | HP(40-60), 粮草(0-150), 行动点, 金币 | ADR-0003 ✅ |
| TR-resource-management-system-003 | 资源显示 | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/resource-management-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories resource-management-system` to break this epic into implementable stories.