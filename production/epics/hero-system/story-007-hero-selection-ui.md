# Story 007: 武将选择UI绑定

> **Epic**: 武将系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/heroes-design.md`
**Requirement**: TR-heroes-design-002 (选择武将与查看属性)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 提供 `hero_selected` 信号给前端同步展示信息。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须能在 UI 层清晰显示选中武将的被动技能与基础数值。

---

## Acceptance Criteria

*From GDD `design/gdd/heroes-design.md`, scoped to this story:*

- [ ] 实现 `HeroSelectionPanel` UI场景，用于开始新游戏时的武将选择。
- [ ] 该面板加载时，读取所有可用的武将并按阵营分类显示。
- [ ] 选中某一武将时，面板右侧/下方显示其：基础 HP、费用(AP)、统帅值、主修/次修兵种图标、被动技能名称及多语言描述文本。
- [ ] 提供一个 "确认出征" 按钮，点击后调用 `HeroManager.select_hero(id)` 确认并切入下一个游戏流程。

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

1. 利用 `HeroManager.get_heroes_by_faction(Faction.WEI)` 等接口遍历填充左侧的 Grid/List。
2. 数据与文字的绑定应当使用 LocalizationManager `get_text(hero.name)` 以及 `get_text("hero_passive." + hero.passive_skill_id + ".desc")`。
3. 显示 统帅值 时，可以画成几把小旗子的数量；显示主修兵种用对应的兵种图标。这里用文本占位即可。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体武将高清立绘加载（美术资产，留空使用 TextureRect 代替）。
- 实际的"进入战斗地图"加载逻辑，这里只负责发确认信号给主管理器。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 列表分组呈现
  - Setup: 打开武将选择界面。
  - Verify: 能看到分在"魏"、"蜀"、"吴"、"群"标签下的对应武将名称。
  - Pass condition: 分组准确不越界。

- **AC-2**: 详细信息更新
  - Setup: 从曹操切换点击到张角。
  - Verify: 详情页数据从 HP 51，被动"挟令诸侯"瞬间变为 HP 47，被动"黄天当立"。
  - Pass condition: 刷新无延迟且所有参数均对应。

- **AC-3**: 确认选中
  - Setup: 点击"确认出征"。
  - Verify: `HeroManager.get_current_hero()` 获取到了最后高亮的武将数据。
  - Pass condition: 系统后台状态成功保存。

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/hero-selection-ui-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
