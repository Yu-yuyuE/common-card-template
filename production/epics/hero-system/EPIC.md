# Epic: 武将系统

> **Layer**: Feature
> **GDD**: design/gdd/heroes-design.md
> **Architecture Module**: HeroSystem
> **Status**: Ready
> **Stories**: 7 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 武将数据结构与CSV解析加载 | Logic | Ready | ADR-0010 |
| 002 | 兵种倾向与出现权重算法 | Logic | Ready | ADR-0010 |
| 003 | 被动技能框架与时机钩子注册 | Logic | Ready | ADR-0010 |
| 004 | 专属卡组与生涯地图接口 | Logic | Ready | ADR-0010 |
| 005 | 魏蜀阵营代表性被动技能实现 | Logic | Ready | ADR-0010 |
| 006 | 吴群阵营及特殊机制被动实现 | Logic | Ready | ADR-0010 |
| 007 | 武将选择UI绑定 | UI | Ready | ADR-0010 |

## Overview

23名武将（魏蜀吴群雄各5~7名），每名武将拥有1个被动技能和专属卡组（≤12张）。武将有5种兵种倾向权重和5张生涯地图。HP范围40~60，费用3~4，统帅3~6，行动点2~4。支持袁绍特殊规则（手牌上限6张）。数据从CSV配置文件加载。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Hero System | 集中式HeroManager+CSV配置 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-heroes-design-001 | 武将HP管理 | ADR-0010 ✅ |
| TR-heroes-design-002 | 22名武将 | ADR-0010 ✅ |
| TR-heroes-design-003 | 4阵营 | ADR-0010 ✅ |
| TR-heroes-design-004 | 基础值 (HP 40-60, 费用 3-4, 统帅 3-6) | ADR-0010 ✅ |
| TR-heroes-design-005 | 1个被动技能 | ADR-0010 ✅ |
| TR-heroes-design-006 | 专属卡组 (≤12张) | ADR-0010 ✅ |
| TR-heroes-design-007 | 生涯地图 (5张) | ADR-0010 ✅ |
| TR-heroes-design-008 | 兵种倾向 | ADR-0010 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/heroes-design.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories hero-system` to break this epic into implementable stories.
