# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Last Updated**: 2026-04-27（Sprint 8 — 纳入存档/酒馆/地图/Meta Save 系统）
**Update**: Add new entries when new core systems are implemented.

---

## Core Stability（每次必跑）

1. 游戏启动至主菜单无崩溃
2. 从主菜单可以发起新游戏 / 新战役
3. 主菜单对所有输入无卡死响应

---

## 战斗核心（Core Mechanic）

4. 选择武将 → 进入战斗 → 使用卡牌 → 战斗结算流程完整（无崩溃）
5. 武将受到伤害后 HP 正确减少，HP 归零后战斗结束
6. 回合结束时行动点归零、护盾清零（ResourceManager 回合重置）

---

## 存档系统（Sprint 7/8 — save-persistence-system）

> 覆盖 ADR-0005 双 JSON 原子写入架构

7. **Run Save 写入**：节点离开后，`user://saves/run_<heroId>.json` 文件正确生成
   - 相关测试：`tests/integration/save-persistence-system/run_save_write_restore_test.gd`

8. **Run Save 恢复**：强制退出后重启，资源/卡组/地图进度与退出前完全一致（round-trip）
   - 相关测试：`tests/integration/save-persistence-system/run_save_write_restore_test.gd`

9. **战役结束删除 Run Save**：通关或失败后 `run_<heroId>.json` 被删除
   - 相关测试：`tests/unit/save-persistence-system/delete_run_save_test.gd`

10. **Meta Save 通关记录**：通关战役章节后，`meta.json` 中 `heroRecords[heroId].completedCampaigns` 包含对应 ID
    - 相关测试：`tests/unit/save-persistence-system/meta-save-victory-settings_test.gd`

11. **Meta Save 设置持久化**：修改音量后重启，音量设置保持修改后的值
    - 相关测试：`tests/unit/save-persistence-system/meta-save-victory-settings_test.gd`

12. **原子写入完整性**：���档写入过程中模拟中断，`*.json` 文件不损坏
    - 相关测试：`tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd`

---

## 酒馆系统（Sprint 7 — inn-system）

> 对应 sprint-status.yaml 任务 7-3 / 7-8（酒馆服务 + 持久化）

13. **歇息恢复 HP**：普通歇息 +15 HP，强化休整 +20 HP（消耗 60 金币）
    - 相关测试：`tests/unit/inn_system/inn_services_test.gd`

14. **章节歇息限制**：同一章节内第 2 次歇息被拒绝（rest_count = 1 上限）
    - 相关测试：`tests/unit/inn_system/inn_services_test.gd`

15. **酒馆状态持久化**：保存酒馆 rest_count 状态 → 重载后 rest_count 正确恢复
    - 相关测试：`tests/integration/inn_system/inn_persistence_test.gd`

---

## 地图 / 战役进度（Sprint 7 — map-node-system）

16. **节点导航**：移动至相邻节点消耗粮草，前置节点未访问时导航被阻止
    - 相关测试：`tests/unit/map_system/map_navigator_test.gd`

17. **战役 5 章结构**：CampaignManager 正确管理 5 场战役（TOTAL_CAMPAIGNS = 5），全部通关后触发完成信号
    - 相关测试：`tests/integration/map_system/campaign_management_test.gd`

18. **战役进度持久化**：地图 visitedNodes 写入 Run Save，重载后路径历史正确恢复
    - 相关测试：`tests/integration/save-persistence-system/run_save_write_restore_test.gd`

---

## 数据完整性

19. 存档版本兼容：v1.0 存档 → v1.1 读取时缺失字段取默认值，不崩溃
    - 相关测试：`tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd`

20. 损坏 JSON 存档：手动写入非法 JSON → 读取返回空数据 + 不崩溃（E2 边界）
    - 相关测试：`tests/unit/save-persistence-system/save_atomic_write_version_compat_test.gd`

---

## 性能

21. 战斗回合循环无可见帧率下降（目标 60fps / 16.6ms/frame）
22. Meta Save 加载时间 < 3ms（Control Manifest Foundation 层守护）
    - 相关测试：`tests/unit/save-persistence-system/meta-save-victory-settings_test.gd::test_meta_save_load_under_3ms`
23. Run Save 加载时间 < 5ms
    - 相关测试：`tests/integration/save-persistence-system/run_save_write_restore_test.gd`

---

## 通过标准

| 等级 | 定义 | QA 手交影响 |
|------|------|------------|
| **PASS** | 所有路径通过，无 FAIL | 可以继续 |
| **PASS WITH WARNINGS** | 有 WARNING 但无 FAIL | 可以继续，记录并追踪 |
| **FAIL** | 任意路径 FAIL | 阻塞 QA 手交，必须修复后重跑 |

---

## 历史修订

| 日期 | 修订内容 | 操作人 |
|------|---------|--------|
| 2026-04-27 | Sprint 8 更新：用真实系统内容替换占位符，纳入存档/酒馆/地图/Meta Save 系统（路径 7-23），覆盖 Sprint 8 G4 要求 | qa-tester |
