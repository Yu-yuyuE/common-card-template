# Epic: 地形天气系统

> **Layer**: Feature
> **GDD**: design/gdd/terrain-weather-system.md
> **Architecture Module**: TerrainWeatherSystem
> **Status**: Ready
> **Stories**: 6 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 地形天气数据结构与初始化接口 | Logic | Ready | ADR-0009 |
| 002 | 地形天气一次性初始化效果 | Logic | Ready | ADR-0009 |
| 003 | 伤害修正系数与费用调整接口 | Logic | Ready | ADR-0009 |
| 004 | 每回合结束的持续环境效果 | Logic | Ready | ADR-0009 |
| 005 | 动态天气切换机制 | Logic | Ready | ADR-0009 |
| 006 | 地形天气UI标识与提示 | UI | Ready | ADR-0009 |

## Overview

集中式地形和天气管理，支持7种地形（平原、山地、森林、水域、沙漠、关隘、雪地）和4种天气（晴、风、雨、雾）。地形固定，天气可动态切换（冷却2回合）。为每种地形/天气组合提供修正系数，影响伤害计算。在战斗初始化时设置环境，并在每回合结束时结算持续效果。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0009: Terrain Weather System | 集中式管理+修正系数接口 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-terrain-weather-system-001 | 7种地形 | ADR-0009 ✅ |
| TR-terrain-weather-system-002 | 4种天气 | ADR-0009 ✅ |
| TR-terrain-weather-system-003 | 地形固定 | ADR-0009 ✅ |
| TR-terrain-weather-system-004 | 天气可变 | ADR-0009 ✅ |
| TR-terrain-weather-system-005 | 28种组合 | ADR-0009 ✅ |
| TR-terrain-weather-system-006 | 天气切换冷却 | ADR-0009 ✅ |
| TR-terrain-weather-system-007 | 7地形×4天气对战斗的影响 | ADR-0009 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/terrain-weather-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories terrain-weather-system` to break this epic into implementable stories.
