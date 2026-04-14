# Epic: 卡组管理系统

> **Layer**: Core
> **GDD**: design/gdd/cards-design.md (§0-§1: 术语定义与阶段管理)
> **Architecture Module**: DeckManagementSystem
> **Estimate**: 9 hours
> **Status**: Ready
> **Stories**: 6 stories created (see below)

## Overview

卡组两层管理架构，负责战役层和战斗层卡组状态的生命周期管理。战役层快照（CampaignDeckSnapshot）作为权威数据源持久化到存档，战斗层快照（BattleDeckSnapshot）作为临时状态仅存在于单场战斗中。支持"永久加入卡组"、"消耗品"、"敌人偷取卡牌"等机制，确保卡组状态在两个层次间正确同步。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 战役层卡组快照基础实现 | Logic | Ready | ADR-0020 |
| 002 | 战斗层卡组快照基础实现 | Logic | Ready | ADR-0020 |
| 003 | 卡组管理器集成 | Logic | Ready | ADR-0020 |
| 004 | 永久加入卡组机制 | Logic | Ready | ADR-0020 |
| 005 | 消耗品处理 | Logic | Ready | ADR-0020 |
| 006 | 敌人偷取卡牌机制 | Logic | Ready | ADR-0020 |

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0020: Deck Two Layer Management | 双快照系统：战役层权威 + 战斗层副本 | LOW |
| ADR-0005: Save Serialization | campaignDeck 持久化到 Run Save | LOW |
| ADR-0007: Card Battle System | 战斗层快照由 BattleManager 初始化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-deck-management-001 | 战役层卡组快照持久化 | ADR-0020 ✅ |
| TR-deck-management-002 | 战斗层卡组快照自动销毁 | ADR-0020 ✅ |
| TR-deck-management-003 | "永久加入卡组"机制 | ADR-0020 ✅ |
| TR-deck-management-004 | "消耗品"永久移除 | ADR-0020 ✅ |
| TR-deck-management-005 | 敌人偷取卡牌不归还 | ADR-0020 ✅ |
| TR-deck-management-006 | 战斗结束时消耗卡处理 | ADR-0020 ✅ |
| TR-deck-management-007 | 卡组快照版本一致性检查 | ADR-0020 ✅ |
| TR-deck-management-008 | 与存档系统集成 | ADR-0005 ✅ |
| TR-deck-management-009 | 与战斗系统集成 | ADR-0007 ✅ |
| TR-deck-management-010 | 与商店/军营/事件系统集成 | ADR-0020 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/cards-design.md` (§0-§1) are verified
- All Logic and Integration stories have passing test files in `tests/`
- CampaignDeckSnapshot correctly persists to/from Run Save
- BattleDeckSnapshot is correctly initialized from CampaignDeckSnapshot
- "永久加入卡组" updates both snapshots simultaneously
- "消耗品" cards are removed from CampaignDeckSnapshot after battle
- Stolen cards do not affect CampaignDeckSnapshot

## Next Step

Run `/create-stories deck-management-system` to break this epic into implementable stories.
