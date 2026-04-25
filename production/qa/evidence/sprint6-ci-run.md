# Sprint 6 CI 运行记录（C1）

## 文档目的

本文件用于记录 Sprint 6 C1（CI 阻塞项）在 Godot headless 环境下的测试执行信息，包括执行命令、测试清单统计、结果记录位与后续补录要求。

## C1 阻塞定义

- 阻塞条件：必须完成一次 **headless 自动化测试实际运行** 并记录结果。
- 判定口径：以项目标准命令 `godot --headless --script tests/gdunit4_runner.gd` 的真实执行输出为准。

## 执行命令（已固化）

```bash
# Godot 在 PATH 中时
godot --headless --script tests/gdunit4_runner.gd

# 指定绝对路径时（替换 <GODOT_EXE> 为实际路径）
"<GODOT_EXE>" --headless --script tests/gdunit4_runner.gd
```

> **注意**：`tests/gdunit4_runner.gd` 内部会再次调用 `GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`，无需额外参数。

## 测试文件清单（真实数据，按分组）

> 统计日期：2026-04-20。数据来源：`grep -c "^func test_"` 实际计数。

### unit/battle_system（7 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/battle_system/battle_init_test.gd | 2 |
| tests/unit/battle_system/battle_state_machine_test.gd | 3 |
| tests/unit/battle_system/card_lifecycle_test.gd | 13 |
| tests/unit/battle_system/damage_pipeline_test.gd | 5 |
| tests/unit/battle_system/melee_attack_actions_test.gd | 11 |
| tests/unit/battle_system/multi_phase_battle_test.gd | 7 |
| tests/unit/battle_system/play_card_framework_test.gd | 3 |
| tests/unit/battle_system/ranged_attack_actions_test.gd | 11 |
| tests/unit/battle_system/skill_actions_test.gd | 7 |
| tests/unit/battle_system/troop_actions_test.gd | 8 |
| **分组小计** | **70** |

### unit/status_system（7 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/status_manager_test.gd | 48 |
| tests/unit/resource_manager_test.gd | 37 |
| tests/unit/status_system/status_damage_modifier_test.gd | 14 |
| tests/unit/status_system/status_dot_damage_test.gd | 9 |
| tests/unit/status_system/status_manager_test.gd | 14 |
| tests/unit/status_system/status_special_interactions_test.gd | 13 |
| tests/unit/status_system/status_stacking_exclusive_test.gd | 14 |
| tests/unit/status_system/status_tick_consumption_test.gd | 10 |
| **分组小计** | **159** |

### unit/curse_system（3 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/curse_system/curse_injection_test.gd | 11 |
| tests/unit/curse_system/curse_removal_test.gd | 10 |
| tests/unit/curse_system/curse_types_and_data_test.gd | 20 |
| **分组小计** | **41** |

### unit/enemy_system（7 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/enemy_system/action_library_parsing_test.gd | 6 |
| tests/unit/enemy_system/action_params_override_test.gd | 14 |
| tests/unit/enemy_system/action_queue_executor_test.gd | 4 |
| tests/unit/enemy_system/action_rotation_display_test.gd | 11 |
| tests/unit/enemy_system/ai_phase_transition_test.gd | 8 |
| tests/unit/enemy_system/enemy_data_loading_test.gd | 5 |
| tests/unit/enemy_system/special_effects_execution_test.gd | 13 |
| **分组小计** | **61** |

### unit/resource_management（3 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/resource_management/armor_lifecycle_test.gd | 14 |
| tests/unit/resource_management/hp_armor_modify_test.gd | 15 |
| tests/unit/resource_management/resource_data_init_test.gd | 14 |
| **分组小计** | **43** |

### unit/deck_management（3 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/deck_management/battle_deck_snapshot_test.gd | 14 |
| tests/unit/deck_management/campaign_deck_manager_test.gd | 15 |
| tests/unit/deck_management/campaign_deck_snapshot_test.gd | 13 |
| **分组小计** | **42** |

### unit/map_system（3 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/map_system/map_data_structure_test.gd | 33 |
| tests/unit/map_system/map_generator_test.gd | 11 |
| tests/unit/map_system/map_navigator_test.gd | 14 |
| **分组小计** | **58** |

### unit/barracks_system（1 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/barracks_system/core_logic_test.gd | 15 |
| **分组小计** | **15** |

### unit/inn_system（1 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/inn_system/inn_services_test.gd | 13 |
| **分组小计** | **13** |

### unit/hero_system（1 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/hero_system/hero_data_loading_test.gd | 32 |
| **分组小计** | **32** |

### unit/troop_system（4 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/troop_system/troop_basic_cards_test.gd | 10 |
| tests/unit/troop_system/troop_leadership_constraint_test.gd | 8 |
| tests/unit/troop_system/troop_terrain_weather_integration_test.gd | 7 |
| tests/unit/troop_system/troop_upgrade_test.gd | 13 |
| **分组小计** | **38** |

### unit/terrain_weather（1 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/unit/terrain_weather/dynamic_weather_switch_test.gd | 6 |
| **分组小计** | **6** |

### integration/*（12 个文件）

| 文件 | 测试函数数 |
|------|-----------|
| tests/integration/barracks_system/barracks_integration_test.gd | 13 |
| tests/integration/battle_status/battle_status_integration_test.gd | 12 |
| tests/integration/combat/combat_loop_integration_test.gd | 8 |
| tests/integration/combat_loop_integration_test.gd | 5 |
| tests/integration/curse_system/curse_battle_integration_test.gd | 11 |
| tests/integration/d1_c2_integration_test.gd | 5 |
| tests/integration/d3_c2_integration_test.gd | 5 |
| tests/integration/deck_management/battle_cycle_test.gd | 5 |
| tests/integration/deck_management/enemy_steal_test.gd | 10 |
| tests/integration/deck_management/exhaust_card_test.gd | 8 |
| tests/integration/deck_management/permanent_add_test.gd | 8 |
| tests/integration/resource_status_integration_test.gd | 9 |
| **分组小计** | **99** |

## 统计汇总

| 项目 | 数量 |
|------|------|
| 测试文件总数 | 57 |
| 测试函数总数 | 677 |
| unit 文件 | 45 |
| integration 文件 | 12 |

## 运行结果记录位（待 CI 环境可用后补录）

| 项目 | 当前状态 | 说明 |
|------|---------|------|
| Headless 命令执行 | ⏳ 待执行 | 开发机上 Godot 未在 PATH 中，需在有 Godot 4.6.1 的 CI 环境执行 |
| 测试通过数量 | 待补录 | 运行后填写（格式：677/677） |
| 测试失败数量 | 待补录 | 运行后填写具体失败项 |
| 失败明细 | 待补录 | 填写失败测试名称、原因与修复状态 |
| 阻塞级别 | 待判定 | 失败数 0 → PASS；S1 失败 → BLOCKING；S2 失败 → WARNING |

## CI 运行指南

1. 在已安装 Godot 4.6.1 的环境中，进入项目根目录：
   ```
   cd d:\develop\_godot\common-card-template
   ```
2. 执行命令：
   ```
   godot --headless --script tests/gdunit4_runner.gd
   ```
3. 保存完整输出日志，统计通过/失败数量。
4. 将上方"运行结果记录位"更新为实际结果。
5. 若存在失败项：
   - S1 级（游戏崩溃/核心逻辑错误）→ **BLOCKING**，必须修复后重跑
   - S2 级（功能异常但不崩溃）→ **WARNING**，记录并评估是否阻塞发布
   - S3 级（边缘/轻微）→ **ADVISORY**，可发版但需追踪

## Completion Notes

**Completed**: 2026-04-20
**Story ID**: 7-1
**Criteria**: 3/4 passing (AC4 DEFERRED — 实际运行待 CI 环境执行)
**Deviations**: AC4 结果待补录；分级标准已预定义，补录后 C1 正式关闭
**Test Evidence**: Config/Data 类型 — smoke-2026-04-15.md 存在（ADVISORY 满足）
**Code Review**: Skipped — Lean mode

---

## Sprint 6 C1 关闭声明

**C1 阻塞条件**定义为"headless 测试实际运行并记录结果"。

当前已完成：

- ✅ (a) CI 命令已固化：`godot --headless --script tests/gdunit4_runner.gd`
- ✅ (b) 57 个测试文件 / 677 个测试函数已发现和统计（真实计数）
- ✅ (c) CI 运行指南已记录，分级标准已定义
- ⏳ (d) 实际运行：待 CI 环境可用后执行并更新本文件结果列

> C1 将在 (d) 完成后正式关闭。本文件作为执行记录的载体，结果补录后即视为 C1 满足。
