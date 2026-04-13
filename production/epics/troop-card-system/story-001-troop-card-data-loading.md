# Story 001: 兵种卡数据加载与等级管理

> **Epic**: 兵种卡系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (兵种卡 Lv1/Lv2/Lv3 效果)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: 兵种卡地形联动计算顺序
**ADR Decision Summary**: 提供 `TroopCardData` 数据结构，解析CSV兵种属性，支持获取不同等级（Lv1/Lv2/Lv3）的配置和效果说明。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持Lv1→Lv2→Lv3的三层升级路径
- Required: 升级后保留原卡身份与标签，仅提升效果，不改变核心定位

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 定义 `TroopCardData` 类，包含基础卡牌属性及升级特有属性 (upgrade_count, is_branch_card)。
- [ ] 从 `assets/data/troop_cards.csv` 读取 41 种兵种卡的基础数据。
- [ ] 实现 `CardTier()` 方法判定卡的当前层级：
  - `upgradeCount == 0` → Lv1
  - `upgradeCount == 1` → Lv2
  - `isBranchCard == true` → Lv3
- [ ] Lv3 分支卡必须正确继承对应 Lv1 的基础兵种标签（如"虎贲卫"是"步兵"）。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在 `CardManager` 或专用的 `TroopCardManager` 中实现解析逻辑。
2. 兵种卡的 `CardData` 扩展：
   ```gdscript
   var upgrade_count: int = 0
   var is_branch_card: bool = false
   var base_type: String # infantry, cavalry, archer, strategist, shield
   ```
3. CSV 应该包含所有 41 种卡。5 种基础卡的 `is_branch_card` 为 false，拥有两级效果描述；另外 36 种扩展卡 `is_branch_card` 为 true，拥有独立的Lv1/Lv2(实际上就是作为Lv3)描述和独立的cost。
4. 提供 `get_troop_tier(card_data)` 供外界查询。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体在战斗中的出牌效果（Story 002/003 处理）。
- 军营节点中展示升级选项的逻辑（Story 006 处理）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 层级判定 - Lv1
  - Given: 一张新创建的基础步兵卡 (`upgradeCount = 0`, `isBranchCard = false`)
  - When: 调用 `get_troop_tier()`
  - Then: 返回 1 (Lv1)。

- **AC-2**: 层级判定 - Lv2
  - Given: 一张升级过一次的基础步兵卡 (`upgradeCount = 1`, `isBranchCard = false`)
  - When: 调用 `get_troop_tier()`
  - Then: 返回 2 (Lv2)。

- **AC-3**: 层级判定 - Lv3 (分支卡)
  - Given: 一张"虎贲卫"卡 (`isBranchCard = true`)
  - When: 调用 `get_troop_tier()`
  - Then: 返回 3 (Lv3)。

- **AC-4**: 卡牌总数加载
  - Given: 完整的 `troop_cards.csv`
  - When: 系统启动加载
  - Then: 字典中包含 41 种兵种卡定义。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_cards/troop_card_data_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: ADR-0004 卡牌数据配置格式
- Unlocks: Story 002, Story 006
