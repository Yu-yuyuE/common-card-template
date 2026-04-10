# Story 003: 商店节点UI集成

> **Epic**: 卡牌升级系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Manifest Version**: 2026-04-10

## Context

**GDD**: `design/gdd/card-upgrade-system.md`
**Requirement**: `TR-card-upgrade-001`

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 升级费用不足时必须置灰按钮并明确显示价格
- Required: 升级后卡牌必须从当前可升级列表中移除，并增加Lv2视觉标识
- Forbidden: 诅咒卡绝对不能出现在升级列表中

---

## Acceptance Criteria

- [ ] 界面展示：商店内增加"升级卡牌"入口或标签页，拉取并列出卡组中所有满足升级条件的Lv1卡（过滤诅咒卡和已升级的Lv2卡）
- [ ] 详情与价格显示：每张候选卡旁需要显示Lv1/Lv2效果对比和对应的升级价格；当玩家金币不足时按钮呈禁用置灰状态
- [ ] 升级交互：点击升级扣除金币，立刻触发卡牌升级逻辑，同时该卡实时从当前界面的"可升级列表"中移除
- [ ] 视觉反馈：所有Lv2卡牌在UI（包含商店、卡组浏览、手牌等）上拥有明确的Lv2角标、边框或其他辨识标识

---

## Implementation Notes

在商店节点 (`shop_ui.gd` 等相关UI模块) 增加升级卡牌功能区。
读取 `card_upgrade_manager` 获取过滤后的可升级卡牌列表。
根据卡牌类型/品质计算价格（使用公式或参考 `UpgradeCost_reference`）。
实现升级按钮的点击事件：验证金币是否足够 → 扣除全局金币 → 调用 `upgrade_card` 接口 → 刷新界面UI。

---

## Out of Scope

- 核心状态持久化（属于 Story 001）。
- 兵种卡在军营节点的专属升级UI展示（属于 军营系统 Epic）。

---

## QA Test Cases

- **AC-1**: 商店列表过滤规则
  - Given: 玩家卡组中含有Lv1普通卡、Lv2普通卡、诅咒卡
  - When: 打开商店的升级卡牌界面
  - Then: 仅展示并允许选择Lv1普通卡进行升级
- **AC-2**: 价格反馈与按钮状态限制
  - Given: 玩家持有 30 金币，升级对应卡牌需要 80 金币
  - When: 查看商店升级界面
  - Then: 对应卡牌升级按钮处于不可点击状态，界面明显提示需要 80 金币
- **AC-3**: 升级流程连贯性与UI刷新
  - Given: 玩家在商店成功点击升级一张Lv1卡
  - When: 升级完成
  - Then: 金币立刻扣除，被升级的卡片展示Lv2标识，并从"可升级候选列表"中消失

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- Manual walkthrough doc: `production/qa/evidence/story-003-shop-ui-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
