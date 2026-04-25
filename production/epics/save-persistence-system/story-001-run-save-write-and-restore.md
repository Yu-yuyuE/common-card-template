# Story 001: Run Save 自动写入与恢复

> **Epic**: 存档持久化系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-09
> **Estimate**: 8 hours

## Context

**GDD**: `design/gdd/save-persistence-system.md`
**Requirement**: `TR-save-persistence-system-001, TR-save-persistence-system-002, TR-save-persistence-system-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Save Serialization
**ADR Decision Summary**: 双JSON文件+原子写入

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准 FileAccess API

**Control Manifest Rules (this layer)**:
- Required: 必须采用双JSON文件+原子写入模式
- Forbidden: 禁止使用Godot Resource序列化作为主要存档方式
- Guardrail: Run Save加载时间：< 5ms

---

## Acceptance Criteria

*From GDD `design/gdd/save-persistence-system.md`, scoped to this story:*

- [ ] 离开任意节点后强制退出，重启游戏后状态完整恢复（HP/金币/粮草/卡组/装备/节点位置）
- [ ] 战斗中途强制退出后重启，恢复到战斗开始前状态（需重打该战斗）
- [ ] 两位武将同时有进行中战役，互不影响
- [ ] mapStructure 正确持久化，重载后地图拓扑与存档前完全一致（节点类型、连接关系）

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- 为每个关键节点离开事件（商店、奇遇、酒馆、军营、战斗结束）添加触发器
- 在每个触发器中，调用 `SaveManager.save_run()`，传入当前 `GameState` 的完整快照
- 传入的快照必须包含：
  - `HeroManager` 的 HP、金币、粮草、行动点
  - `DeckManager` 的卡组（抽牌堆、手牌、弃牌堆）
  - `EquipmentSystem` 的当前携带装备列表
  - `MapNodeSystem` 的当前节点ID、已访问节点列表、地图拓扑结构
- `SaveManager` 必须使用原子写入（临时文件+重命名）
- 重启游戏时，`Main` 节点加载 `run_{heroId}.json` 文件，重建 `GameState` 所有子系统

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 002]: 战役结束删除 Run Save 文件
- [Story 003]: Meta Save 解锁与发现记录更新
- [Story 004]: Meta Save 通关与设置更新
- [Story 005]: 存档文件的原子写入与版本兼容

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: 离开任意节点后强制退出，重启游戏后状态完整恢复
  - Given: 玩家在商店节点购买了一张卡牌（金币减少50，卡组增加一张）
  - When: 玩家按下 Alt+F4 强制退出，然后重新启动游戏
  - Then: 重启后，当前金币为购买后数值，卡组中包含新购买的卡牌，当前节点为商店节点
  - Edge cases: 玩家在进入商店节点前、购买过程中、离开后强制退出，都应恢复到购买后状态

- **AC-2**: 战斗中途强制退出后重启，恢复到战斗开始前状态
  - Given: 玩家在战斗中打出一张卡牌，手牌减少，费用消耗
  - When: 玩家按下 Alt+F4 强制退出，然后重新启动游戏
  - Then: 重启后，HP、金币、粮草、卡组与战斗开始前完全一致，且玩家处于地图节点状态
  - Edge cases: 玩家在战斗中打出最后一张卡牌、对手使用了特殊能力后强制退出，都应恢复到战斗开始前状态

- **AC-3**: 两位武将同时有进行中战役，互不影响
  - Given: 玩家已解锁曹操和刘备
  - When: 玩家选择曹操进行战役，进行到第二张地图，然后切换到刘备开始新战役，再切回曹操
  - Then: 曹操的战役进度（节点、资源、卡组）保持不变，刘备的进度独立存在
  - Edge cases: 两个战役的当前地图相同，资源消耗导致金币为0，都应保持独立

- **AC-4**: mapStructure 正确持久化，重载后地图拓扑与存档前完全一致
  - Given: 玩家进入一个新地图，包含5个节点，其中1个为BOSS节点
  - When: 玩家到达第3个节点后强制退出，然后重新启动游戏
  - Then: 重启后，地图拓扑结构（节点ID、类型、连接关系）与退出前完全一致，当前节点为第3个节点
  - Edge cases: 地图为环形结构，有多个入口，拓扑结构应保持一致

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/save-persistence-system/run_save_write_restore_test.gd` — must exist and pass
**Coverage**: 所有 AC 均须有对应测试函数（test_run_save_restores_full_state / test_battle_crash_restores_pre_battle_state / test_two_heroes_saves_independent / test_map_structure_persists）

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005（7-7）: 存档文件的原子写入与版本兼容 — **尚未完成**
  - 隔离策略：原子写入部分通过 `save_run_stub` Callable 注入，本 Story 的序列化/反序列化/恢复主体逻辑可独立开发与测试；7-7 完成后替换桩为真实 SaveManager 实现
- Depends on: Story 7-2（CampaignManager）— Complete ✅
- Depends on: Story 7-3（InnPersistenceManager）— Complete ✅
- Unlocks: Story 002（7-5）: 战役结束删除 Run Save 文件

## Completion Notes

**Completed**: 2026-04-20
**Criteria**: 4/4 passing
**Deviations**: ADVISORY — Story 005（7-7）原子写入尚未完成，save_stub 使用桩隔离，生产环境接线由 7-7 负责（已在 Dependencies 中记录）
**Test Evidence**: Integration — tests/integration/save-persistence-system/run_save_write_restore_test.gd（7个测试函数，覆盖 AC1~AC4）
**Code Review**: Skipped — Lean mode
