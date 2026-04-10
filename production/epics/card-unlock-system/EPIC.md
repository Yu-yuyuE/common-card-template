# Epic: 卡牌解锁系统

> **Layer**: Meta
> **GDD**: design/gdd/cards-design.md
> **Architecture Module**: CardUnlockSystem
> **Status**: Ready
> **Stories**: 5 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 图鉴解锁管理器核心逻辑 | Logic | Ready | ADR-0004 |
| 002 | 解锁状态与Meta Save集成 | Integration | Ready | ADR-0005 |
| 003 | 战役结算与新卡解锁规则 | Logic | Ready | ADR-0004 |
| 004 | 掉落池与商店过滤集成 | Integration | Ready | ADR-0004 |
| 005 | 游戏外图鉴展示界面(Compendium) | UI | Ready | ADR-0004 |

## Overview

实现卡牌图鉴系统，追踪玩家收集的107张攻击卡、80张技能卡、41张兵种卡和诅咒卡。解锁条件包括战役进度、成就达成和商店购买。支持图鉴分级（基础/高级/稀有），通过存档持久化系统（F1）保存解锁状态。为商店系统提供可购买卡牌的过滤机制。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: Save Serialization | Run Save + Meta Save 双层结构 | LOW |
| ADR-0004: Card Data Format | CSV配置+CardData类封装 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-cards-design-001 | 107攻击卡+80技能卡+30兵种卡 | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/cards-design.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories card-unlock-system` to break this epic into implementable stories.
