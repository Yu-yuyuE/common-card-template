# Epic: 卡牌战斗系统

> **Layer**: Core
> **GDD**: design/gdd/card-battle-system.md
> **Architecture Module**: CardBattleSystem
> **Status**: Ready
> **Stories**: 7 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 战斗数据结构与实体初始化 | Logic | Ready | ADR-0007 |
| 002 | 战斗状态机与回合流程控制 | Logic | Ready | ADR-0007 |
| 003 | 卡牌生命周期与抽牌堆管理 | Logic | Ready | ADR-0007 |
| 004 | 出牌验证与卡牌结算框架 | Logic | Ready | ADR-0007 |
| 005 | 伤害计算管线 | Logic | Ready | ADR-0014, ADR-0007 |
| 006 | 多阶段战斗与胜负判定 | Logic | Ready | ADR-0007 |
| 007 | 战斗HUD与手牌UI绑定 | UI | Ready | ADR-0007 |

## Overview

核心战斗系统，实现1对最多3个敌人的战场结构。完整的回合流程：玩家回合→敌人回合→阶段检查。手牌/费用/出牌/结算循环。卡牌生命周期管理：抽牌堆→手牌→弃牌堆→移除区→消耗区。伤害计算采用护盾优先、溢出扣HP的公式。支持多阶段战斗（精英/Boss）。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Card Data Format | CSV配置+CardData类封装 | LOW |
| ADR-0007: Card Battle System | 集中式BattleManager+阶段状态机 | LOW |
| ADR-0014: Troop Terrain Calculation | 伤害计算顺序（基础×地形×天气×状态） | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-card-battle-system-001 | 1v3战场、出牌结算 | ADR-0007 ✅ |
| TR-card-battle-system-002 | 手牌/费用/出牌/结算循环 | ADR-0007 ✅ |
| TR-card-battle-system-003 | 战斗资源管理 | ADR-0007 ✅ |
| TR-card-battle-system-004 | 1v3战场结构 | ADR-0007 ✅ |
| TR-card-battle-system-005 | 回合流程 | ADR-0007 ✅ |
| TR-card-battle-system-006 | 卡牌生命周期 | ADR-0007 ✅ |
| TR-card-battle-system-007 | 伤害计算 | ADR-0014 ✅ |
| TR-card-battle-system-008 | 多阶段战斗 | ADR-0007 ✅ |
| TR-card-battle-system-009 | 抽牌逻辑 | ADR-0007 ✅ |
| TR-card-battle-system-010 | 伤害公式 | ADR-0014 ✅ |
| TR-card-battle-system-011 | 敌人回合流程 | ADR-0007 ✅ |
| TR-card-battle-system-012 | 手牌显示 | ADR-0007 ✅ |
| TR-card-battle-system-013 | 战斗信息 | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/card-battle-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories card-battle-system` to break this epic into implementable stories.
