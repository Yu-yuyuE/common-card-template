# Epic: 敌人系统

> **Layer**: Core
> **GDD**: design/gdd/enemies-design.md
> **Architecture Module**: EnemySystem
> **Status**: Ready
> **Stories**: 7 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 敌人数据模型与CSV加载 | Logic | Ready | ADR-0008 |
| 002 | 敌人行动库(71种)数据加载 | Logic | Ready | ADR-0008 |
| 003 | 敌人固定行动序列轮转机制 | Logic | Ready | ADR-0008 |
| 004 | 敌人意图公示机制 | Logic | Ready | ADR-0008 |
| 005 | 敌人AI行动队列执行器 | Logic | Ready | ADR-0015 |
| 006 | 敌人具体行动结算路由 | Logic | Ready | ADR-0008, ADR-0015 |
| 007 | 诅咒投递与特殊机制 | Integration | Ready | ADR-0008 |

## Overview

集中式敌人管理系统，包含100名敌人（E001~E100）和71种行动（A/B/C三类）。支持5种职业和3种级别分类。行动采用固定序列循环，确保可预测性。支持行动公示机制，让玩家可预判。行动队列执行支持条件触发、冷却机制和备用行动选择。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Enemy System | 集中式EnemyManager+固定行动序列 | LOW |
| ADR-0015: Enemy AI Executor | 决策树→行动队列→顺序执行三层架构 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-enemies-design-001 | 敌人行动序列 | ADR-0008 ✅ |
| TR-enemies-design-002 | 5种敌人职业 | ADR-0008 ✅ |
| TR-enemies-design-003 | 3种敌人级别 | ADR-0008 ✅ |
| TR-enemies-design-004 | 71种行动 | ADR-0008 ✅ |
| TR-enemies-design-005 | 100名敌人 | ADR-0008 ✅ |
| TR-enemies-design-006 | 行动序列循环 | ADR-0008 ✅ |
| TR-enemies-design-007 | 行动公示 | ADR-0008 ✅ |
| TR-enemies-design-008 | 诅咒投递 | ADR-0008 ✅ |
| TR-enemies-design-009 | 100名敌人, 71种行动 | ADR-0008 ✅ |
| TR-enemies-design-010 | 行动队列 | ADR-0015 ✅ |
| TR-enemies-design-011 | 敌人行动间隔 | ADR-0015 ✅ |
| TR-enemies-design-012 | 敌人血量显示 | ADR-0008 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/enemies-design.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories enemy-system` to break this epic into implementable stories.
