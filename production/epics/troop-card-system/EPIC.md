# Epic: 兵种卡系统

> **Layer**: Feature
> **GDD**: design/gdd/troop-cards-design.md
> **Architecture Module**: TroopCardSystem
> **Status**: Ready
> **Stories**: 6 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 兵种卡数据加载与等级管理 | Logic | Ready | ADR-0014 |
| 002 | 兵种卡基础(Lv1)战斗效果结算 | Logic | Ready | ADR-0014 |
| 003 | 兵种卡升级(Lv2)与附加机制 | Logic | Ready | ADR-0014 |
| 004 | 兵种卡地形天气联动 | Logic | Ready | ADR-0014 |
| 005 | 军营节点统帅与选卡验证 | Logic | Ready | ADR-0014 |
| 006 | 兵种卡Lv3分支选项查询与升级判定 | Logic | Ready | ADR-0014 |

## Overview

41种兵种卡（基础5+扩展36），支持Lv1→Lv2→Lv3升级。兵种卡效果受到地形和天气联合影响。统帅上限为武将统帅值（3~6张）。Lv2提升效果系数为1.20~1.35。Lv3提供分支选择（选定后不可撤销）。在军营节点提供添加/升级/移出功能。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0014: Troop Terrain Calculation | 兵种伤害计算顺序（基础×地形×天气×状态） | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-troop-cards-design-001 | 兵种卡 Lv1/Lv2/Lv3 效果 | ADR-0014 ✅ |
| TR-troop-cards-design-002 | 兵种卡地形×天气联动 | ADR-0014 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/troop-cards-design.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories troop-card-system` to break this epic into implementable stories.
