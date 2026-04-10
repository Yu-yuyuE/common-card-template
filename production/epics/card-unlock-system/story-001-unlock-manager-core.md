# Story 001: 图鉴解锁管理器核心逻辑

> **Epic**: 卡牌解锁系统
> **Status**: Ready
> **Layer**: Meta
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/cards-design.md`
**Requirement**: `TR-cards-design-001`

**ADR Governing Implementation**: ADR-0004: Card Data Format
**ADR Decision Summary**: 采用 CSV 配置 + CardData class，需提供按 ID 查找和类型过滤。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持按 ID 快速查找卡牌
- Required: 必须支持按图鉴归属过滤

---

## Acceptance Criteria

- [ ] 提供基于内存的单例 `CardUnlockManager` (或融入 `CardManager`) 管理所有卡牌的解锁状态
- [ ] 建立三层图鉴分类判定逻辑（初始通用、待开启通用、十三州专属）
- [ ] 提供判断卡牌是否已解锁的 API `is_card_unlocked(card_id: String) -> bool`
- [ ] “初始通用图鉴”中的卡牌默认始终处于已解锁状态

---

## Implementation Notes

由于 ADR-0004 中定义了 `CardManager` 负责加载所有卡，可以在 `CardManager` 中扩充或者独立写一个 `CardUnlockManager` 类关联 `CardManager`。
必须能够识别哪张卡属于哪个图鉴批次，这需要读取 `CardData` 中的额外字段（或通过前缀/列表硬编码建立对应关系，首选通过CSV新字段 `unlock_group` 支持）。

---

## Out of Scope

- 存档持久化（写入/读取硬盘），见 Story 002。
- 具体通关解锁新卡的规则，见 Story 003。

---

## QA Test Cases

- **AC-1**: 初始图鉴判定
  - Given: `CardUnlockManager` 初始化完毕
  - When: 传入一张被标记为“初始通用”的攻击卡ID
  - Then: `is_card_unlocked` 返回 `true`
  - Edge cases: 传入无效的卡牌ID，应返回 `false`

- **AC-2**: 待开启图鉴判定
  - Given: `CardUnlockManager` 初始化完毕，尚未执行任何解锁操作
  - When: 传入一张被标记为“待开启”或“专属”的卡牌ID
  - Then: `is_card_unlocked` 返回 `false`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/card_unlock/unlock_manager_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: ADR-0004 `CardManager` 基础功能就绪
- Unlocks: Story 002, Story 003, Story 004