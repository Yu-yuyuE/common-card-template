# ADR-0001: 场景管理策略

## Status
Accepted

## Date
2026-04-08

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / Scene Management |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/physics.md` (for reference only, 2D game) |
| **Post-Cutoff APIs Used** | None — standard SceneTree API unchanged since Godot 4.0 |
| **Verification Required** | None — standard API |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0005 (存档序列化方案) |
| **Blocks** | 所有需要场景切换的系统: M1 地图节点, C2 卡牌战斗, M2 商店, D6 军营, D7 酒馆 |
| **Ordering Note** | 本ADR是Foundation层基础，其他场景相关ADRs必须在本ADR Accepted后才能开始 |

## Context

### Problem Statement
游戏需要在以下场景类型之间切换：
- **地图场景** — 战役地图节点导航
- **战斗场景** — 1v3卡牌战斗
- **商店场景** — 买卡/升级/买装备
- **军营场景** — 兵种添加/升级/移出
- **酒馆场景** — 歇息/粮草/休整

核心问题：
1. 如何在场景切换时保持游戏状态（资源、卡组、武将数据）？
2. 如何高效加载和切换场景？
3. 如何在不同场景间传递数据（敌人信息、地形天气等）？

### Constraints
- **数据持久化**: Run Save (战役内) 和 Meta Save (永久) 需要隔离
- **性能**: 场景切换应尽量流畅，避免长时间黑屏
- **开发效率**: 场景切换逻辑应便于程序员实现和调试

### Requirements
- 必须支持场景间数据传递
- 必须支持存档/读档
- 必须支持从任意场景返回地图

## Decision

### 方案: 主场景 + 图层实例化模式 (Layered Scene Pattern)

采用 **单主场景 + 多图层实例化** 模式：

```
┌─────────────────────────────────────────────┐
│  Main (Node2D)                              │
│  ├── WorldMap (Node) — 地图层               │
│  │   └── MapScene.tscn (实例化)             │
│  ├── BattleLayer (Node) — 战斗层            │
│  │   └── BattleScene.tscn (按需实例化)      │
│  ├── ShopLayer (Node) — 商店层              │
│  │   └── ShopScene.tscn (按需实例化)        │
│  ├── BarracksLayer (Node) — 军营层          │
│  │   └── BarracksScene.tscn (按需实例化)    │
│  ├── InnLayer (Node) — 酒馆层               │
│  │   └── InnScene.tscn (按需实例化)         │
│  └── GameState (Node) — 全局游戏状态        │
│      ├── ResourceManager                    │
│      ├── DeckManager                        │
│      └── HeroManager                        │
└─────────────────────────────────────────────┘
```

**关键设计**:

1. **Main 节点常驻**: 游戏启动后创建，整个会话期间不销毁
2. **GameState 管理全局数据**: ResourceManager, DeckManager, HeroManager 作为子节点
3. **按需实例化子场景**: 战斗/商店/军营/酒馆场景在需要时从 `Main` 节点 `instantiate()`
4. **图层显隐控制**: 使用 `visible` 属性控制当前激活的场景层
5. **数据传递**: 通过 `instantiate()` 后调用初始化方法传递数据

### 初始化接口示例

```gdscript
# Main.gd
func _ready():
    # 初始化全局状态
    var game_state = GameState.new()
    add_child(game_state)
    
    # 默认显示地图
    show_map()

func show_map():
    hide_all_layers()
    if not map_layer:
        map_layer = map_scene.instantiate()
        add_child(map_layer)
    map_layer.visible = true
    map_layer.initialize(current_map_data)

func show_battle(enemy_data: Dictionary, terrain: String, weather: String):
    hide_all_layers()
    if not battle_layer:
        battle_layer = battle_scene.instantiate()
        add_child(battle_layer)
    battle_layer.visible = true
    battle_layer.initialize(enemy_data, terrain, weather)

func hide_all_layers():
    if map_layer: map_layer.visible = false
    if battle_layer: battle_layer.visible = false
    if shop_layer: shop_layer.visible = false
    if barracks_layer: barracks_layer.visible = false
    if inn_layer: inn_layer.visible = false
```

### 场景切换流程

```
[地图节点] → 选择目标节点
    ↓
[判断节点类型]
    ├─ 战斗节点 → show_battle(enemies, terrain, weather)
    ├─ 商店节点 → show_shop()
    ├─ 军营节点 → show_barracks()
    ├─ 酒馆节点 → show_inn()
    └─ 奇遇/事件 → show_event()
    ↓
[场景层显示] → 隐藏其他层，显示目标层
    ↓
[战斗/交互完成] → 返回地图 → show_map()
```

## Alternatives Considered

### Alternative 1: 完整场景切换 (change_scene_to_file)
- **描述**: 每个场景是完全独立的 `.tscn` 文件，使用 `SceneTree.change_scene_to_file()` 切换
- **优点**: 
  - 场景完全隔离，内存管理简单
  - Godot 标准方式，文档丰富
- **缺点**:
  - 场景切换时需要序列化/反序列化全局状态
  - 数据传递依赖临时存储或全局变量
  - 切换时有短暂加载时间
- **未采用原因**: 需要额外的数据序列化逻辑，增加复杂度和性能开销

### Alternative 2: 单场景 + UI面板切换
- **描述**: 保持在单一场景，通过 Control 节点的 `visible` 显示/隐藏不同 UI 面板
- **优点**:
  - 切换最快，无加载
  - 数据天然共享
- **缺点**:
  - 场景文件会变得非常大
  - 不同类型场景的根节点类型不同（Node2D vs Control），难以统一管理
  - 难以利用场景特定的编辑器功能
- **未采用原因**: 卡牌战斗场景需要复杂的节点层次（战场、手牌区、敌人区），与地图场景结构差异大

### Alternative 3: 场景实例化 + 动态加载 (推荐方案)
- **描述**: 主场景常驻，子场景作为 PackedScene 实例化，按需加载/卸载
- **优点**:
  - 数据天然在主场景中共享
  - 场景文件保持简洁
  - 可利用场景特定的编辑器功能
  - 切换速度快（只需实例化）
- **缺点**:
  - 需要管理子场景的生命周期
- **采用原因**: 平衡了数据共享和场景组织需求

## Consequences

### Positive
- **数据共享简单**: 全局状态在 Main 节点下，所有子场景可直接访问
- **切换流畅**: 实例化比完整场景加载快
- **内存可控**: 不需要的场景可以 `queue_free()` 释放
- **开发效率**: 场景文件分离，便于多人协作

### Negative
- **需要管理图层显隐**: 增加 `hide_all_layers()` 等辅助方法
- **场景初始化需要显式调用**: `initialize()` 方法必须在实例化后调用传递数据

### Risks
- **内存泄漏**: 如果子场景没有正确释放，会导致内存积累
  - **缓解**: 使用 `queue_free()` 并在切换时检查是否已有实例化
- **状态耦合**: 子场景可能意外修改全局状态
  - **缓解**: 通过接口方法访问，而非直接访问

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| map-design.md (M1) | 节点导航、场景切换 | 提供 show_map() / navigate_to() 框架 |
| card-battle-system.md (C2) | 1v3战场、出牌结算 | 提供 show_battle() 初始化接口 |
| shop-system.md (M2) | 买卡/升级/装备 | 提供 show_shop() 接口 |
| barracks-system.md (D6) | 兵种添加/升级/移出 | 提供 show_barracks() 接口 |
| inn-system.md (D7) | 歇息/粮草/休整 | 提供 show_inn() 接口 |
| save-persistence-system.md (F1) | Run Save / Meta Save | GameState 作为持久化数据的根节点 |

## Performance Implications
- **CPU**: 实例化子场景 < 50ms（取决于场景复杂度）
- **Memory**: 场景文件通常 10-100KB，5个子场景约 500KB 内存占用
- **Load Time**: 首次实例化需要加载资源，后续切换无加载

## Migration Plan
1. 创建 Main.tscn 场景文件
2. 创建 GameState.gd 脚本管理全局状态
3. 创建各子场景框架（地图、战斗、商店、军营、酒馆）
4. 实现场景切换逻辑
5. 集成存档系统

## Validation Criteria
- [ ] 主场景启动后可以切换到任意子场景
- [ ] 子场景切换后全局状态（资源、卡组）保持不变
- [ ] 从战斗返回地图后，地图状态正确恢复
- [ ] 存档/读档后场景状态正确恢复

## Related Decisions
- ADR-0005 (待创建): 存档序列化方案 — 依赖本ADR的 GameState 结构
- ADR-0002 (待创建): 系统间通信模式 — 与场景管理协调
