# Story 006: 兵种卡Lv3分支选项查询与升级判定

Epic: 兵种卡系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/troop-cards-design.md`
**Requirement**: TR-troop-cards-design-001 (Lv3 分支路径)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014
**ADR Decision Summary**: 提供基于卡牌大类的分支查询功能，并处理分支卡替换时的属性映射（费用继承与专精溢价限制）。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 军营节点必须能正确展示全部的 Lv3 分支选项。
- Required: 分支卡费用默认继承基础兵种的Lv1费用，最多+1费。

---

## Acceptance Criteria

*From GDD `design/gdd/troop-cards-design.md`, scoped to this story:*

- [ ] 实现 `TroopCardManager.get_branch_options(base_type: String) -> Array[CardData]`。
  - 当传入 "infantry" 时返回 5 个分支（虎贲卫、刀盾手、戟兵、山地步兵、游侠）等。
  - 弓兵特殊："archer" 返回 6 个分支。
  - 盾兵："shield" 返回 5 个分支（包含铁甲步兵）。
- [ ] 升级逻辑：提供接口 `upgrade_to_branch(original_card_id, branch_card_id)`。由于卡牌ID替换了，需要处理费用继承。确保无论数据怎么配，新卡的费用不超过 `base_card_cost + 1`，特例游侠保持0费。如果采用纯配置，这里加一个合法性校验器即可。
- [ ] 确保分支选定后无法再次升级（`upgradeCount` 约束或不出现在升级池）。

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

1. 在数据加载时，将 `is_branch_card = true` 的卡按照 `base_type` 分组存入字典 `branch_pools[base_type]`。
2. `get_branch_options("infantry")` 直接返回 `branch_pools["infantry"]` 数组。
3. 校验器：在启动时校验所有的分支卡 `cost <= base_cost + 1`，如果配置错误抛出报错（这是对数据的防御性编程）。
4. 军营升级：调用方只需将卡组里的 `old_id` 替换为选中的 `branch_id`。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 军营选择分支的可视化 UI 弹窗。
- 替换后的保存持久化（由保存系统进行）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 分支池准确提取
  - Given: 数据已加载。
  - When: 调用 `get_branch_options("archer")`
  - Then: 恰好返回 6 张卡的配置数据。

- **AC-2**: 弓兵/盾兵特例验证
  - Given: 盾兵分支
  - When: 调用获取
  - Then: 返回列表中包含 "铁甲步兵"。

- **AC-3**: 升级不可逆与到达上限
  - Given: 一张已经是 Lv3 的卡。
  - When: 获取它的层级（Story001已实现）并尝试继续升级
  - Then: 确保后续系统会判定它不可再升级（通过暴露 `can_be_upgraded(card)` 接口返回 false）。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/troop_cards/troop_branch_upgrade_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
