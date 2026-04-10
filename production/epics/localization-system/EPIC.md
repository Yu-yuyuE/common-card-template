# Epic: 本地化系统

> **Layer**: Foundation
> **GDD**: design/gdd/localization-system.md
> **Architecture Module**: LocalizationManager
> **Status**: Ready
> **Stories**: 7 stories created (see below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 本地化框架基础架构 | Logic | Ready | ADR-0017 |
| 002 | 翻译资源加载与管理 | Logic | Ready | ADR-0017 |
| 003 | 语言切换机制 | Logic | Ready | ADR-0017, ADR-0016 |
| 004 | 字体管理系统 | Logic | Ready | ADR-0017 |
| 005 | 文本绑定系统 | Logic | Ready | ADR-0016, ADR-0017 |
| 006 | 参数化文本替换 | Logic | Ready | ADR-0017 |
| 007 | 语言选择UI | UI | Ready | ADR-0016, ADR-0017 |

## Overview

支持中文、英文、日文三种语言的运行时切换。所有 UI 文本、卡牌描述、系统消息和叙事文本通过语言键引用，禁止硬编码字符串。采用 Godot 4.6 内置本地化框架，实现200ms内完成语言切换。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0016: UI Data Binding | Signal驱动的响应式模式 | LOW |
| ADR-0017: Localization System | Godot原生Translation资源 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| (本地化需求) | 三语言支持 | ADR-0017 ✅ |
| (本地化需求) | 运行时切换 | ADR-0017 ✅ |
| (本地化需求) | 参数化文本替换 | ADR-0017 ✅ |
| (本地化需求) | 三层回退机制 | ADR-0017 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/localization-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories localization-system` to break this epic into implementable stories.