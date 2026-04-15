# Story 001: 战斗数据结构与实体初始化

Epic: 卡牌战斗系统
Estimate: 4 hours
Status: Complete
Layer: Core
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/card-battle-system.md`
**Requirement**: TR-card-battle-system-001 (1v3战场结构), TR-card-battle-system-004
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: 卡牌战斗系统架构
**ADR Decision Summary**: 采用集中式 BattleManager 进行全局状态管理，使用 BattleEntity 数据结构定义玩家和敌人的状态数据。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须支持1vs最多3个敌人的战场结构
- Forbidden: 禁止分布式战斗实体难以协调全局状态

---

## Acceptance Criteria

*From GDD `design/gdd/card-battle-system.md`, scoped to this story:*

- [x] 定义 `BattleEntity` 数据类，包含：id, max_hp, current_hp, shield, max_shield, action_points, max_action_points, is_player, status_effects 字段。
- [x] 初始化 `BattleManager` (Autoload 或场景主节点)，包含玩家实体(1个)和敌人实体数组(最多3个)。
- [x] 实现 `setup_battle(stage_config: Dictionary)` 方法，能够解析节点传入的阶段配置。
- [x] 初始化时，玩家HP/MaxHP和行动点从 `ResourceManager` 获取。玩家初始护盾清零。
- [x] 初始化时，根据阶段配置生成敌人实体，默认生命值正确赋值。
- [x] 发射 `battle_started` 信号，携带阶段总数和敌方实体列表。

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

1. `BattleEntity` 的实现应当是一个 `RefCounted` 或内部类，仅保存战斗逻辑数据。
2. 玩家的 `action_points` 初始值等于 `max_action_points`。
3. `setup_battle` 需要从 `stage_config` 字典读取：
   - "stage_count": int (默认1)
   - "terrain": String (默认"plain")
   - "weather": String (默认"clear")
   - "enemies": Array[Dictionary] (最多读取前3个)
4. 不在此时实现卡牌抽取逻辑（由卡牌生命周期故事完成），只做数据容器的装配。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 状态机流程 (回合开始、敌人回合等)
- Story 003: 洗牌、抽牌和手牌区初始化
- 实体 `take_damage` 方法（放入伤害计算故事）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 1v3战场初始化
  - Given: `stage_config` 包含 4 个敌人
  - When: 调用 `setup_battle`
  - Then: `enemy_entities` 数组长度为 3，丢弃第 4 个。
  - Edge cases: 只有 1 个敌人，数组长度为 1。

- **AC-2**: 玩家资源同步
  - Given: ResourceManager 当前 HP=45, MaxHP=50, MaxAP=4
  - When: 调用 `setup_battle`
  - Then: 玩家实体的 current_hp=45, max_hp=50, action_points=4, shield=0

- **AC-3**: 信号发射
  - Given: 一场2个阶段、3名敌人的战斗
  - When: 执行 `setup_battle`
  - Then: 收到 `battle_started` 信号，携带 total_stages=2 和正确的敌人数组引用。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle_system/battle_init_test.gd` — must exist and pass

**Status**: [x] Implemented in src/core/battle/BattleManager.gd and BattleEntity.gd

---

## Dependencies

- Depends on: F2 资源管理系统
- Unlocks: Story 002 (状态机), Story 003 (卡牌流转)
