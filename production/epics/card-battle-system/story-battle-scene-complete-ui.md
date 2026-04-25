# Story: BattleScene.tscn 完整 UI 结构补全

**ID**: sprint-8-ui-battle-scene-complete
**Status**: Complete
**Type**: UI
**Layer**: Presentation
**Manifest Version**: 2026-04-09
**ADR Governing Implementation**: docs/architecture/adr-0016-ui-data-binding.md
**TR-ID**: TR-UI-BATTLE-001
**Epic**: card-battle-system
**Sprint**: Sprint 8

---

## Background（背景）

`/gate-check` (2026-04-24) 判定 Production → Polish 门控 **FAIL**，主要原因之一是 `BattleScene.tscn` 只有骨架结构，缺少 `design/ux/battle-hud.md` 中定义的核心 UI 区域：

- 我方武将状态区（HeroZone）— 左侧，含 HP 条、护盾数值占位、专属计数器占位、装备图标占位
- 费用与战局资源区（APZone）— 左下角，含 AP 能量球、抽牌堆数量、弃牌堆数量
- 全局环境与提示区（EnvironmentZone）— 屏幕顶部，含地形天气标签、轮次计数器

同时，`BattleUI.gd` 需要相应扩展绑定接口，让上述区域能响应游戏信号。

---

## Acceptance Criteria（验收标准）

- [x] **AC-1 HeroZone**：BattleScene.tscn 包含 `HeroZone`（VBoxContainer，屏幕左侧），下含：`HeroHpBar`（ProgressBar）、`HeroArmorLabel`（Label，初始文本"🛡️0"）、`HeroCounterLabel`（Label，初始文本""）
- [x] **AC-2 APZone**：BattleScene.tscn 包含 `APZone`（HBoxContainer，左下角），下含：`APLabel`（Label，初始文本"AP: --"）、`DrawPileLabel`（Label，初始文本"🎴--"）、`DiscardPileLabel`（Label，初始文本"🗑️--"）
- [x] **AC-3 EnvironmentZone**：BattleScene.tscn 包含 `EnvironmentZone`（HBoxContainer，顶部），下含：`TerrainWeatherLabel`（Label，初始文本"⛰️-- / ☀️--"）、`RoundLabel`（Label，初始文本"回合 1"）
- [x] **AC-4 BattleUI 绑定接口**：`BattleUI.gd` 新增以下方法：
  - `update_hero_hp(current: int, max_val: int)` — 更新 HeroHpBar
  - `update_hero_armor(armor: int)` — 更新 HeroArmorLabel（0时隐藏）
  - `update_ap(current: int, max_val: int)` — 更新 APLabel
  - `update_pile_counts(draw: int, discard: int)` — 更新抽/弃牌堆标签
  - `update_terrain_weather(terrain: String, weather: String)` — 更新 TerrainWeatherLabel
  - `update_round(round_num: int)` — 更新 RoundLabel
- [x] **AC-5 已有 AC 不回退**：现有节点（PhaseLabel、EnemyArea、HandContainer）不被移除或结构改变；`bind()`、`refresh_hand()`、`register_enemy_hp_bar()` 行为不变

---

## Implementation Notes（实现指引）

按 **ADR-0016 Signal驱动绑定** 架构：
- UI 层只做展示，不修改游戏数据
- 新增方法均为外部调用（由 BattleManager/外部绑定层调用，不自行订阅信号）
- 所有用户可见字符串须通过本地化系统；占位默认值可为字面量（占位状态）
- 不应使用 `Particles2D`（Godot 4 已废弃），若有粒子特效需求使用 `GPUParticles2D`

### 节点布局参考（来自 design/ux/battle-hud.md）

```
BattleScene (Control, full-screen)
├── Background (ColorRect) — 保持现有
├── EnvironmentZone (HBoxContainer) — 顶部居中或左上
│   ├── TerrainWeatherLabel (Label)
│   └── RoundLabel (Label)
├── PhaseLabel (Label) — 保持现有位置
├── HeroZone (VBoxContainer) — 左侧中部
│   ├── HeroHpBar (ProgressBar)
│   ├── HeroArmorLabel (Label)
│   └── HeroCounterLabel (Label)
├── EnemyArea (HBoxContainer) — 保持现有（右侧）
│   └── ... (Enemy0/1/2 Area 保持不变)
├── HandContainer (HBoxContainer) — 保持现有（底部）
└── APZone (HBoxContainer) — 左下角（HandContainer 左侧）
    ├── APLabel (Label)
    ├── DrawPileLabel (Label)
    └── DiscardPileLabel (Label)
```

---

## Out of Scope（范围外）

- 不实现实际动画特效（兵种卡入场、天气切换转场等）
- 不实现状态图标（Buff/Debuff 图标栏）—— 单独 story
- 不实现诅咒卡警示特效 —— 单独 story
- 不实现敌方意图预测计算（"12->4"）—— 单独 story
- 不修改 `BattleManager.gd` 或任何 Core 层逻辑
- 不编写自动化测试（UI/Visual 类型，证明文件手动验证）

---

## Test Evidence（测试证明）

**Type**: UI/Visual — 手动验证
**Evidence doc**: `production/qa/evidence/battle-scene-complete-evidence.md`

---

## Dependencies（依赖）

- 7-6 完成（BattleScene.tscn 骨架已存在） — **Done**
- ADR-0016 (Accepted) — **Done**
