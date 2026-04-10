# Epic: 卡牌升级系统

> **Layer**: Meta
> **GDD**: design/gdd/card-upgrade-system.md
> **Architecture Module**: CardUpgradeSystem
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories card-upgrade-system`

## Overview

实现卡牌从Lv1到Lv2的一次性升级机制。升级收益系数1.20–1.35，遵循单维度提升原则。商店节点为主要升级入口，军营节点可升级兵种卡。诅咒卡不可升级。升级价格采用累进翻倍策略（首次50金币，离开商店重置）。通过CardBattleSystem验证升级后的卡牌效果。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Card Battle System | 升级后卡牌效果验证 | LOW |
| ADR-0005: Save Serialization | 升级状态持久化 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-card-upgrade-001 | Lv1→Lv2升级，系数1.20-1.35 | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/card-upgrade-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories card-upgrade-system` to break this epic into implementable stories.
