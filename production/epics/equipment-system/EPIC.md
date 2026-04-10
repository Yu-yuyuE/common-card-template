# Epic: 装备系统

> **Layer**: Meta
> **GDD**: design/gdd/equipment-design.md
> **Architecture Module**: EquipmentSystem
> **Status**: Ready
> **Stories**: 
> - [x] `production/epics/equipment-system/story-001-equipment-data-structure.md`
> - [x] `production/epics/equipment-system/story-002-equipment-acquisition.md`
> - [x] `production/epics/equipment-system/story-003-equipment-equipping.md`
> - [x] `production/epics/equipment-system/story-004-equipment-effects.md`
> - [x] `production/epics/equipment-system/story-005-battle-integration.md`

## Overview

5个部位（武器、防具、饰品、宝物、坐骑）共60件装备。携带上限5件（袁绍6件）。部位可重复装备，同名装备不叠加。百分比加成相加计算。两渠道获取：商店购买+战斗奖励事件（10%基础概率）。通过装备槽位管理装备状态，提供get_equipment_bonus接口供战斗系统调用。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Card Battle System | 装备集成到战斗结算 | LOW |
| ADR-0012: Shop System | 装备购买通过商店接口 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-equipment-001 | 5部位60件装备，携带上限5件 | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/equipment-design.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories equipment-system` to break this epic into implementable stories.
