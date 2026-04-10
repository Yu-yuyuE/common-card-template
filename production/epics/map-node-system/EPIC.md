# Epic: 地图节点系统

> **Layer**: Meta
> **GDD**: design/gdd/map-design.md
> **Architecture Module**: MapNodeSystem
> **Status**: Ready
> **Stories**: 
> - [x] `production/epics/map-node-system/story-001-map-data-structure.md`
> - [x] `production/epics/map-node-system/story-002-node-navigation.md`
> - [x] `production/epics/map-node-system/story-003-map-generation.md`
> - [x] `production/epics/map-node-system/story-004-campaign-management.md`

## Overview

树形地图结构，包含6种节点类型：战斗、精英、BOSS、商店、酒馆、军营、事件。节点导航需要检查前置节点访问状态和粮草消耗（2-8粮草，根据距离）。记录访问历史用于存档。AllNodesCompleted信号在BOSS击败后触发。每位武将5场战役，每场3张小地图。战役结束后保留Meta Save，清除Run Save。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: Map Node System | 树形MapGraph+MapNavigator导航 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-map-design-001 | 节点导航、场景切换 | ADR-0011 ✅ |
| TR-map-design-002 | 树形地图结构 | ADR-0011 ✅ |
| TR-map-design-003 | 节点类型 | ADR-0011 ✅ |
| TR-map-design-004 | 前置依赖 | ADR-0011 ✅ |
| TR-map-design-005 | 粮草消耗 | ADR-0011 ✅ |
| TR-map-design-006 | 地图节点状态 | ADR-0011 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/map-design.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories map-node-system` to break this epic into implementable stories.
