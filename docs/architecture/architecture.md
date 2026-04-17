# 三国称雄 — Master Architecture

## Document Status

- **Version**: 2.0
- **Last Updated**: 2026-04-17
- **Engine**: Godot 4.6.1 (stable)
- **GDDs Covered**: 17 systems (F1-F2, C1-C3, D1-D7, M1-M5)
- **ADRs Referenced**: ADR-0001 through ADR-0020 (全部已 Accepted)

## Engine Knowledge Gap Summary

**Engine**: Godot 4.6.1 | **LLM Training Cutoff**: ~4.3

### HIGH RISK (Verify Before Use)

| Domain | Risk | Note |
|--------|------|------|
| Rendering | HIGH | D3D12默认(Windows), Glow在tonemapping前处理 |
| UI | HIGH | 双焦点系统(鼠标/触控与键盘/手柄分离) |

### MEDIUM RISK

| Domain | Risk | Note |
|--------|------|------|
| GDScript | MEDIUM | @abstract, variadic参数 (4.5+) |
| Resources | MEDIUM | duplicate_deep() for nested resources |

### 2D Game Mitigation

本项目为2D游戏，使用Godot 2D渲染器：
- ✅ 不受Jolt Physics影响
- ✅ 不受D3D12/Vulkan切换影响
- ⚠️ UI需关注双焦点系统兼容性

---

## System Layer Map

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                         │  ← UI层 (待定义)
├─────────────────────────────────────────────┤
│  FEATURE LAYER                              │  ← D1-D7, M1-M5
│    地形天气 | 兵种卡 | 武将 | 诅咒 | 卡牌解锁 │
│    军营 | 酒馆 | 地图节点 | 商店 | 装备 | 事件 | 卡牌升级
├─────────────────────────────────────────────┤
│  CORE LAYER                                 │  ← C1-C3
│    状态效果系统 | 卡牌战斗系统 | 敌人系统
├─────────────────────────────────────────────┤
│  FOUNDATION LAYER                           │  ← F1-F2
│    存档持久化系统 | 资源管理系统
├─────────────────────────────────────────────┤
│  PLATFORM LAYER                             │  ← Godot 4.6.1
└─────────────────────────────────────────────┘
```

---

## Module Ownership

### Foundation Layer

| Module | Owns | Exposes | Consumes |
|--------|------|---------|----------|
| **SaveManager** | Run Save (战役内), Meta Save (永久), 存档版本号 | `load_game()`, `save_game()`, `get_version()` | FileAccess API |
| **ResourceManager** | HP(40-60), 粮草(0-150), 行动点, 金币 | `get_resource()`, `set_resource()`, `resource_changed` signal | SaveManager |

### Core Layer

| Module | Owns | Exposes | Consumes |
|--------|------|---------|----------|
| **StatusSystem** | 7种Buff + 13种Debuff, 同类叠加, 异类互斥 | `apply_status()`, `remove_status()`, `get_status()` | ResourceManager |
| **CardBattleSystem** | 手牌, 费用, 出牌, 1v3战场结算 | `play_card()`, `end_turn()`, `get_hand()`, `battle_started` signal | StatusSystem, ResourceManager |
| **EnemySystem** | 100名敌人(E001-E100), 71种行动(A/B/C三类) | `get_enemy()`, `execute_action()`, `action_queue` | StatusSystem, ResourceManager |

### Feature Layer

| Module | Owns | Exposes | Consumes |
|--------|------|---------|----------|
| **TerrainWeatherSystem** | 7地形×4天气, 动态切换(冷却2回合) | `get_terrain()`, `get_weather()`, `apply_terrain_effect()` | StatusSystem, CardBattleSystem |
| **TroopCardSystem** | 41种兵种卡, 统帅验证(3-6) | `get_troop_cards()`, `can_add_troop()`, `upgrade_troop()` | CardBattleSystem, TerrainWeatherSystem |
| **HeroSystem** | 23名武将, 被动技能, 专属卡组 | `get_hero()`, `get_passive()`, `get_exclusive_deck()` | CardBattleSystem, StatusSystem |
| **CurseSystem** | 25+30张诅咒卡, 3种类型 | `apply_curse()`, `purify()`, `OnCurseCardDrawn` signal | CardBattleSystem, StatusSystem |
| **BarracksSystem** | 兵种添加/升级/移出 | `add_troop()`, `upgrade_troop()`, `remove_card()` | TroopCardSystem, HeroSystem, ResourceManager |
| **InnSystem** | 歇息(+15HP), 买粮草(40金/40粮), 强化休整(60金+20HP) | `rest()`, `buy_provisions()`, `enhanced_rest()` | ResourceManager, HeroSystem |
| **MapNodeSystem** | 节点导航, 战役进度, 资源消耗 | `navigate_to()`, `get_current_node()`, `get_available_nodes()` | ResourceManager, CardBattleSystem |
| **ShopSystem** | 买攻击卡/技能卡, 升级卡, 买装备 | `buy_card()`, `upgrade_card()`, `buy_equipment()` | ResourceManager, CardBattleSystem, CardUpgradeSystem |
| **EquipmentSystem** | 5部位, 60件装备, 携带上限5件 | `equip()`, `unequip()`, `get_equipment_bonus()` | CardBattleSystem |
| **EventSystem** | 50个事件(5大类) | `trigger_event()`, `get_available_events()`, `OnEventChoice` signal | MapNodeSystem, ResourceManager |
| **CardUpgradeSystem** | Lv1→Lv2单次升级, 系数1.20-1.35 | `upgrade_card()`, `get_upgrade_cost()`, `can_upgrade()` | CardBattleSystem |
| **CardUnlockSystem** | 图鉴, 解锁状态 | `unlock_card()`, `is_unlocked()`, `get_collection()` | SaveManager |

---

## Data Flow

### 1. 战斗回合流程

```
玩家输入 → CardBattleSystem.play_card(card)
         → StatusSystem.apply_status() [计算状态效果]
         → CardBattleSystem.calculate_damage() [FinalDamage公式]
         → EnemySystem.take_damage() 或 HeroSystem.take_damage()
         → StatusSystem.tick_status() [回合结束时状态结算]
         → UI层刷新 (手牌/HP/状态图标)
```

### 2. 存档/读档流程

```
[存档]
SaveManager.save_game()
    → 收集所有模块状态 (JSON序列化)
    → FileAccess.store_var() 
    → 原子写入: temp文件 → rename完成

[读档]
FileAccess.open() → 校验版本号
    → SaveManager.deserialize()
    → 分发给各模块恢复状态
    → ResourceManager.load()
    → CardBattleSystem.load()
    → EnemySystem.load()
    → MapNodeSystem.load()
```

### 3. 地图节点切换

```
MapNodeSystem.navigate_to(target_node)
    → ResourceManager.consume_provisions(消耗粮草2-8)
    → EventSystem.trigger_node_event(node_type)
    → 根据节点类型:
        - 战斗节点: CardBattleSystem.setup_battle(enemies)
        - 商店节点: ShopSystem.setup_shop()
        - 军营节点: BarracksSystem.setup_barracks()
        - 酒馆节点: InnSystem.setup_inn()
```

### 4. 敌人行动执行

```
EnemySystem.execute_turn()
    → 按行动队列顺序执行
    → 条件触发判断 (如 HP<50% 触发特定行动)
    → CardBattleSystem.process_enemy_action(action)
    → StatusSystem.apply_enemy_status()
    → 广播 action_completed signal
```

---

## API Boundaries (Key Interfaces)

### CardBattleSystem

```gdscript
class_name CardBattleSystem extends Node

signal card_played(card: Card, target: Node)
signal turn_ended(is_player_turn: bool)
signal battle_started(enemies: Array[Enemy])
signal battle_ended(victory: bool)

func play_card(card_id: String, target_position: int) -> void:
    """打出卡牌, target_position=目标位置(0-2)"""

func end_turn() -> void:
    """玩家结束回合, 触发敌人行动"""

func get_hand() -> Array[Card]:
    """获取当前手牌"""

func get_playable_cards() -> Array[Card]:
    """获取可打出的卡牌(费用足够)"""
```

### StatusSystem

```gdscript
class_name StatusSystem extends Node

signal status_applied(target: Node, status: Status)
signal status_removed(target: Node, status_type: String)

enum StatusType { BUFF, DEBUFF }

func apply_status(target: Node, status_type: String, stacks: int = 1) -> void:
    """应用状态, 同类叠加, 异类互斥"""

func remove_status(target: Node, status_type: String) -> void:
    """移除指定状态"""

func get_status(target: Node, status_type: String) -> int:
    """获取目标指定状态的层数"""

func tick_status(target: Node) -> void:
    """回合结束时结算持续伤害/效果"""
```

### SaveManager

```gdscript
class_name SaveManager extends Node

signal save_completed(save_type: String)
signal load_completed(save_type: String)

enum SaveType { RUN, META }

func save_game(save_type: int, data: Dictionary) -> bool:
    """保存游戏, 返回是否成功"""

func load_game(save_type: int) -> Dictionary:
    """加载游戏, 返回存档数据"""

func get_save_version() -> String:
    """获取当前存档版本号"""

func has_save(save_type: int) -> bool:
    """检查是否存在存档"""
```

---

## ADR Audit

| ADR | 标题 | Engine Compat | Godot版本 | GDD Linkage | Status |
|-----|------|--------------|-----------|-------------|--------|
| ADR-0001 | 场景管理策略 | ✅ | 4.6.1 | TR-map-001, TR-save-001 | Accepted |
| ADR-0002 | 系统间通信模式 | ✅ | 4.6.1 | TR-battle-001, TR-status-001, TR-enemy-001 | Accepted |
| ADR-0003 | 资源变更通知机制 | ✅ | 4.6.1 | TR-res-001 | Accepted |
| ADR-0004 | 卡牌数据配置格式 | ✅ | 4.6.1 | TR-battle-001 | Accepted |
| ADR-0005 | 存档序列化方案 | ✅ | 4.6.1 | TR-save-001 | Accepted |
| ADR-0006 | 状态效果系统架构 | ✅ | 4.6.1 | TR-status-001 | Accepted |
| ADR-0007 | 卡牌战斗系统架构 | ✅ | 4.6.1 | TR-battle-001 | Accepted |
| ADR-0008 | 敌人系统架构 | ✅ | 4.6.1 | TR-enemy-001 | Accepted |
| ADR-0009 | 地形天气系统架构 | ✅ | 4.6.1 | TR-terrain-001 | Accepted |
| ADR-0010 | 武将系统架构 | ✅ | 4.6.1 | TR-hero-001 | Accepted |
| ADR-0011 | 地图节点系统架构 | ✅ | 4.6.1 | TR-map-001 | Accepted |
| ADR-0012 | 商店系统架构 | ✅ | 4.6.1 | TR-shop-001 | Accepted |
| ADR-0013 | 酒馆系统架构 | ✅ | 4.6.1 | TR-inn-001 | Accepted |
| ADR-0014 | 兵种地形伤害计算顺序 | ✅ | 4.6.1 | TR-troop-001, TR-terrain-001 | Accepted |
| ADR-0015 | 敌人AI行动执行器架构 | ✅ | 4.6.1 | TR-enemy-001 | Accepted |
| ADR-0016 | UI数据绑定方案 | ✅ | 4.6.1 | TR-battle-001 (UI层) | Accepted |
| ADR-0017 | 本地化系统架构 | ✅ | 4.6.1 | TR-loc-001 | Accepted |
| ADR-0018 | 状态机架构 | ✅ | 4.6.1 | TR-battle-001 (状态机) | Accepted |
| ADR-0019 | 敌人行动参数设计 | ✅ | 4.6.1 | TR-enemy-001 | Accepted |
| ADR-0020 | 卡组双层管理架构 | ✅ | 4.6.1 | TR-battle-001 (卡组) | Accepted |

### Traceability Coverage

| Req ID | Requirement | ADR Coverage | Status |
|--------|-------------|--------------|--------|
| TR-save-001 | 双层存档(Run/Meta) | ADR-0001, ADR-0005 | ✅ COVERED |
| TR-res-001 | 4种资源管理 | ADR-0003 | ✅ COVERED |
| TR-battle-001 | 1v3战场,手牌/费用/结算 | ADR-0002, ADR-0004, ADR-0007, ADR-0016, ADR-0018, ADR-0020 | ✅ COVERED |
| TR-enemy-001 | 100敌人,71种行动 | ADR-0002, ADR-0008, ADR-0015, ADR-0019 | ✅ COVERED |
| TR-status-001 | 20种状态效果 | ADR-0002, ADR-0006 | ✅ COVERED |
| TR-terrain-001 | 7地形×4天气 | ADR-0009, ADR-0014 | ✅ COVERED |
| TR-hero-001 | 23武将,专属卡组 | ADR-0010 | ✅ COVERED |
| TR-map-001 | 树形地图,节点导航 | ADR-0001, ADR-0011 | ✅ COVERED |
| TR-troop-001 | 兵种卡系统 | ADR-0014 | ✅ COVERED |
| TR-shop-001 | 商店系统 | ADR-0012 | ✅ COVERED |
| TR-inn-001 | 酒馆系统 | ADR-0013 | ✅ COVERED |
| TR-loc-001 | 本地化(中/英/日) | ADR-0017 | ✅ COVERED |

---

## Required ADRs

### ✅ 全部已完成（ADR-0001 ~ ADR-0020）

所有必须的 ADR 均已在 Pre-Production 阶段创建并通过 `/architecture-review` 验证：

- ✅ ADR-0001: 场景管理策略
- ✅ ADR-0002: 系统间通信模式  
- ✅ ADR-0003: 资源变更通知机制
- ✅ ADR-0004: 卡牌数据配置格式
- ✅ ADR-0005: 存档序列化方案
- ✅ ADR-0006 ~ ADR-0020: 所有 Core/Feature 层 ADR

Production 阶段新增系统如需 ADR，运行 `/architecture-decision [系统名]` 创建。

---

## Open Questions

> **已解决 (2026-04-17):**

| 问题 | 决策结论 | 依据 |
|------|----------|------|
| ~~UI层技术选型~~: Control节点 vs 自定义渲染 | **已决**: 使用 Godot Control 节点树（ADR-0016 规定 Signal 驱动，ADR-0002 规定事件总线）。Sprint 6 UI stories 已按此实现。 | ADR-0016, Sprint 6 实现 |
| ~~网络功能~~: 是否需要 Steam 云存档集成 | **已决**: 本版本不实现。单机存档由 ADR-0005 双层存档覆盖；Steam 云存档作为 Post-Launch 功能列入 backlog。 | ADR-0005, GDD-save-persistence |
| ~~性能优化策略~~: 卡牌战斗结算是否异步 | **已决**: 同步执行。当前实测帧时间在 16.6ms 预算内（Sprint 5 压测无异常）。如结算超过 5ms 再引入 `call_deferred`。 | 性能预算 16.6ms，Sprint 5 QA 报告 |
| ~~插件系统~~: 是否支持 Modding | **已决**: 本版本不支持。游戏规模（单机战棋卡牌）不需要 Mod 生态；数据驱动设计（CSV）已预留扩展性。 | GDD 范围定义，production 里程碑 |

1. **数据驱动设计**
   - 所有游戏数值从CSV加载, 运行时不硬编码
   - 修改平衡参数无需修改代码

2. **单向下行依赖**
   - Foundation → Core → Feature → Presentation
   - 上层依赖下层, 下层不关心上层

3. **事件驱动通信**
   - 系统间通过Signal通信, 避免直接引用
   - 便于单元测试和模块替换

4. **状态与表现分离**
   - 游戏逻辑(数值计算)在Core/Feature层
   - UI渲染在Presentation层, 通过Signal响应

5. **原子化存档**
   - 写入使用临时文件+rename, 防止崩溃导致存档损坏
   - 双层存档隔离: Run Save(战役) vs Meta Save(永久)

---

## Open Questions

1. **UI层技术选型**: 使用Godot Control节点还是自定义渲染?
2. **网络功能**: 是否需要Steam云存档集成? (GDD已预留接口)
3. **性能优化策略**: 卡牌战斗结算是否需要异步处理?
4. **插件系统**: 是否支持Modding?

---

## Handoff

### 立即执行 (Foundation ADRs)
1. `/architecture-decision 场景管理策略`
2. `/architecture-decision 系统间通信模式`
3. `/architecture-decision 资源变更通知机制`
4. `/architecture-decision 卡牌数据配置格式`
5. `/architecture-decision 存档序列化方案`

### 后续执行 (Core + Feature ADRs)
6. `/architecture-decision 兵种伤害计算顺序`
7. `/architecture-decision 敌人AI执行器架构`
8. `/architecture-decision UI数据绑定方案`

### 验证命令
- 全部ADRs完成后: `/gate-check pre-production`
- 创建Control Manifest: `/create-control-manifest`
