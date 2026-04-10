# Epic: 存档持久化系统

> **Layer**: Foundation
> **GDD**: design/gdd/save-persistence-system.md
> **Architecture Module**: SaveManager
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories save-persistence-system`

## Overview

实现双层存档系统：Run Save（战役内临时存档）和 Meta Save（永久存档）。Run Save 在战役结束后清除，Meta Save 保留玩家进度、图鉴解锁和通关记录。采用原子写入（临时文件+重命名）防止崩溃导致存档损坏。支持版本兼容性检查和迁移。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Scene Management Strategy | 主场景+多图层实例化模式 | LOW |
| ADR-0005: Save Serialization | 双JSON文件+原子写入 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-persistence-system-001 | Run Save / Meta Save | ADR-0005 ✅ |
| TR-save-persistence-system-002 | Run Save + Meta Save 双层结构 | ADR-0005 ✅ |
| TR-save-persistence-system-003 | 原子写入 | ADR-0005 ✅ |
| TR-save-persistence-system-004 | 版本兼容 | ADR-0005 ✅ |
| TR-save-persistence-system-005 | 战役结束删除 Run Save | ADR-0005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/save-persistence-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Run Save 自动写入与恢复 | Integration | Ready | ADR-0005 |
| 002 | 战役结束删除 Run Save | Logic | Ready | ADR-0005 |
| 003 | Meta Save 解锁与发现记录更新 | Logic | Ready | ADR-0005 |
| 004 | Meta Save 通关与设置更新 | Logic | Ready | ADR-0005 |
| 005 | 存档文件的原子写入与版本兼容 | Logic | Ready | ADR-0005 |

## Next Step

Run `/story-readiness production/epics/save-persistence-system/story-001-run-save-write-and-restore.md` to validate the first story, then `/dev-story` to begin implementation.
