# Epic: 资源管理系统

> **Layer**: Foundation
> **GDD**: design/gdd/resource-management-system.md
> **Architecture Module**: ResourceManager
> **Status**: Ready
> **Stories**: 7 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 资源数据结构初始化 | Logic | Ready | ADR-0003 |
| 002 | HP/护盾修改与Signal通知 | Logic | Ready | ADR-0003 |
| 003 | 护盾生命周期管理 | Logic | Ready | ADR-0003 |
| 004 | 行动点累积与消耗 | Logic | Ready | ADR-0003 |
| 005 | 粮草消耗与归零惩罚 | Logic | Ready | ADR-0003 |
| 006 | 资源恢复机制 | Logic | Ready | ADR-0003 |
| 007 | 资源变化UI响应 | UI | Ready | ADR-0002 |

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