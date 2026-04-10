# Epic: 军营系统

> **Layer**: Feature
> **GDD**: design/gdd/barracks-system.md
> **Architecture Module**: BarracksSystem
> **Status**: Ready
> **Stories**: 4 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 军营核心状态与权重算法 | Logic | Ready | ADR-0010 |
| 002 | 军营流转与全局系统集成 | Integration | Ready | ADR-0010 |
| 003 | 军营主场景及添加/移出面板 | UI | Ready | ADR-0010 |
| 004 | 升级功能区与分支选择交互 | UI | Ready | ADR-0010, ADR-0014 |

## Overview

军营节点提供的三大核心功能：添加兵种卡（从3张候选中选择，根据武将军种倾向权重推荐）、升级兵种卡（Lv1→Lv2消耗50金币，Lv2→Lv3分支选择消耗50金币）、移出任意卡牌。Lv3分支选定后不可撤销。通过兵种卡系统的质量体系验证升级规则。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Hero System | 武将倾向权重读取接口 | LOW |
| ADR-0014: Troop Terrain Calculation | 兵种升级遵循通用规则 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-barracks-system-001 | 兵种添加/升级/移出 | ADR-0010 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/barracks-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories barracks-system` to break this epic into implementable stories.
