# Epic: 州系统整合

> **ID**: EPIC-004
> **状态**: In Design
> **优先级**: High
> **关联ADR**: ADR-0004
> **关联GDD**: state-system.md, map-design.md, cards-design.md
> **负责人**: 设计团队
> **目标完成时间**: 2026-04-18

## 1. 概述

整合十三州的地理、战役、专属卡和兵种联动信息，建立统一的元数据规范，确保设计数据一致性，为程序实现提供清晰的配置基准。

## 2. 背景

当前州相关信息分散在 `map-design.md` 和 `cards-design.md` 中，缺乏统一管理，导致：
- 设计数据容易冲突（如州专属卡数量不一致）
- 程序员难以准确定位州配置
- 新成员学习成本高

## 3. 目标

- ✅ 创建 `design/gdd/state-system.md` 作为州系统元数据规范
- ✅ 将所有州相关信息（地形、战役、专属卡、兵种联动）集中到该文件
- ✅ 明确"涉及武将"字段为在该州有战役记录的武将列表（无主次之分）
- ✅ 明确每位武将的生涯战役跨越多个州，一个州可出现在多个武将的战役中
- ✅ 明确州专属卡数量（共143张）为设计目标，解锁条件为通关包含该州小地图的战役
- ✅ 更新 `map-design.md` 和 `cards-design.md`，删除重复内容，仅引用 state-system.md
- ✅ 确保所有团队成员遵循统一的数据源

## 4. 范围

### 包含

- 创建 `state-system.md` 文件
- 定义13州的：
  - 所属区域
  - 涉及武将（在该州有战役记录的所有武将）
  - 地形
  - 默认天气
  - 专属卡数量
  - 兵种倾向
  - 备注
- 定义州与地图节点的绑定关系（武将生涯战役跨越多个州）
- 定义州与专属卡的绑定关系（解锁条件为通关包含该州小地图的战役）
- 定义州与兵种联动的间接关系
- 定义数据一致性保障机制

### 不包含

- 修改任何游戏机制
- 创建新的卡牌或地形
- 修改 `hero_campaign_maps.csv` 内容
- 实现程序代码

## 5. 成功标准

- `state-system.md` 文件创建并合并入主分支
- `map-design.md` 和 `cards-design.md` 已更新，删除所有州相关重复内容
- 设计团队已确认数据一致性
- 程序团队已确认可从 `state-system.md` 读取配置
- 执行 `/consistency-check` 无任何州相关冲突
- "涉及武将"字段基于 `hero_campaign_maps.csv` 数据准确填充

## 6. 依赖

- ADR-0004 已批准
- `map-design.md` 和 `cards-design.md` 已更新
- `hero_campaign_maps.csv` 数据准确

## 7. 风险

- 设计团队未及时更新 `map-design.md` 和 `cards-design.md` → **解决**：在完成本史诗后立即执行 `/consistency-check`
- 程序团队未正确读取 `state-system.md` → **解决**：在完成本史诗后立即执行 `/code-review` 对程序代码进行审查

## 8. 进展

- ✅ 已创建 `design/gdd/state-system.md`
- ✅ 已创建 ADR-0004
- ✅ 已修正"涉及武将"字段（删除"首选战役武将"概念）
- ✅ 已明确武将生涯战役跨越多个州的关系
- ✅ 已通知设计团队更新 `map-design.md` 和 `cards-design.md`
- ✅ 已通知程序团队准备读取配置

## 9. 下一步

- [ ] 设计团队更新 `map-design.md` 和 `cards-design.md`
- [ ] 执行 `/consistency-check`
- [ ] 执行 `/code-review`（程序代码）
- [ ] 执行 `/gate-check pre-production`
- [ ] 标记本史诗为完成

---

> **注意**：本史诗仅涉及设计文档的整合，不包含任何代码实现。代码实现将在后续史诗中完成。