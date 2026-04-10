# Epic: 商店系统

> **Layer**: Meta
> **GDD**: design/gdd/shop-system.md
> **Architecture Module**: ShopSystem
> **Status**: Ready
> **Stories**: 
> - [x] `production/epics/shop-system/story-001-shop-shelf-generation.md`
> - [x] `production/epics/shop-system/story-002-card-purchase.md`
> - [x] `production/epics/shop-system/story-003-card-upgrade.md`
> - [x] `production/epics/shop-system/story-004-equipment-purchase.md`
> - [x] `production/epics/shop-system/story-005-shop-ui.md`

## Overview

商店节点提供三项功能：买卡（攻击卡+技能卡，含Lv2直购15%概率）、升级卡（累进翻倍价格，离开重置）、买装备。每批6件商品，刷新消耗50金币。金币跨地图累积。州专属卡有概率出现。装备携带上限5件（袁绍6件）。购买记录防止重复购买相同卡牌。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0012: Shop System | ShopManager集中管理+批刷新机制 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-shop-system-001 | 买卡/升级/装备 | ADR-0012 ✅ |
| TR-shop-system-002 | 买攻击卡/技能卡 | ADR-0012 ✅ |
| TR-shop-system-003 | 升级卡 | ADR-0012 ✅ |
| TR-shop-system-004 | 买装备 | ADR-0012 ✅ |
| TR-shop-system-005 | 批次刷新 | ADR-0012 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/shop-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories shop-system` to break this epic into implementable stories.
