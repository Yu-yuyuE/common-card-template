# Story 001: 军营核心状态与权重算法

> **Epic**: 军营系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/barracks-system.md`
**Requirement**: `TR-barracks-system-001`

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 采用集中式 HeroManager 存储武将倾向权重；统帅值读取。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 遵循基础算法和 RandomNumberGenerator 生成。

**Control Manifest Rules (this layer)**:
- Required: 必须支持兵种倾向权重计算 `get_troop_weights(hero_id)`
- Forbidden: 禁止纯随机行动缺乏策略性（需体现权重）

---

## Acceptance Criteria

- [ ] 候选池生成算法：按兵种权重无放回抽取3张兵种卡，不出现同名卡
- [ ] Lv2出现概率判定：在生成的候选卡中，每张有 15% 概率为 Lv2
- [ ] 逻辑层方法：提供检查当前金币是否满足 50 的前置校验
- [ ] 逻辑层方法：检查卡组兵种卡数量是否达到统帅上限

---

## Implementation Notes

新建 `barracks_manager.gd` 作为纯逻辑的核心单例。
实现 `generate_candidates(hero_id)`，需要查询 `HeroManager` 获取倾向系数，构造加权随机池。利用 `randf()` 判断 0.15 作为升级判定。
暴露验证接口：`can_add_troop_card()` 和 `can_upgrade_card(cost)`。

---

## Out of Scope

- 界面展示和信号发送。
- 全局金币资源的实际扣除和卡组的实际修改（见 Story 002）。

---

## QA Test Cases

- **AC-1**: 候选池生成
  - Given: 一个拥有极高步兵权重的武将
  - When: 生成1000次候选卡
  - Then: 步兵出现频率符合加权概率分布，单次抽取内3张卡ID互不相同
  - Edge cases: 统帅满时依然能正确生成候选（但外部将阻止添加）
- **AC-2**: Lv2概率
  - Given: 生成1000次候选卡
  - When: 统计Lv2卡的数量
  - Then: 整体约为15%比例

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/barracks_system/core_logic_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: HeroManager 初始化完毕
- Unlocks: Story 002, Story 003