# Story 005: 游戏外图鉴展示界面(Compendium)

> **Epic**: 卡牌解锁系统
> **Status**: Ready
> **Layer**: Meta
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/cards-design.md`
**Requirement**: `TR-cards-design-001`

**ADR Governing Implementation**: ADR-0016: UI Data Binding
**ADR Decision Summary**: 数据变化驱动UI，且文本多语言化。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 所有UI元素需要遵循ADR-0016的数据绑定模式，通过语言键引用文本。
- Forbidden: 禁止在代码中使用硬编码字符串。

---

## Acceptance Criteria

- [ ] 创建一个独立的UI场景 `CompendiumScene.tscn`（图鉴界面），在主菜单可进入
- [ ] 以网格（GridContainer）展示所有卡牌，包含分类（攻击/技能/兵种/诅咒）过滤标签
- [ ] 已解锁的卡牌显示真实缩略图、名称与费用，点击可查看详情面板
- [ ] 未解锁的卡牌显示为“问号”或阴影（剪影），隐藏具体效果文本，仅显示解锁条件（如：“通关第2次后解锁”）
- [ ] 支持分页或滚动查看

---

## Implementation Notes

开发 `CompendiumScene` 和相关的 `CompendiumCardItem` 预制体。
根据 `CardUnlockManager.is_card_unlocked(id)` 切换 UI 显示模式。
解锁条件需要作为元数据或语言键存在，例如 `UNLOCK_COND_B1`。

---

## Out of Scope

- 局内战斗。
- 动画特效（极简即可，由Polish阶段完善）。

---

## QA Test Cases

- **AC-1**: 未解锁状态视觉验证
  - Setup: 进入图鉴界面，找到一张未解锁的卡牌
  - Verify: 缩略图为问号或阴影，卡面文本不显示真实伤害数值，而显示解锁提示
  - Pass condition: 玩家无法窥探未解锁卡的具体机制数值
- **AC-2**: 过滤签验证
  - Setup: 点击“兵种卡”分页签
  - Verify: 网格中只显示所有存在于兵种图鉴池的卡牌，不出现攻击或技能卡
  - Pass condition: 分类过滤工作正确且无遗漏

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/compendium-ui-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: None