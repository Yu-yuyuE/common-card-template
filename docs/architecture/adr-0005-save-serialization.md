# ADR-0005: 存档序列化方案

## Status
Accepted

## Date
2026-04-08

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / Persistence |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None (FileAccess API 稳定) |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略) — GameState 结构 |
| **Enables** | 所有需要持久化的系统 |
| **Blocks** | 无直接阻塞 |
| **Ordering Note** | 本 ADR 是最后一项 Foundation ADRs |

## Context

### Problem Statement
游戏需要双层存档系统：

1. **Run Save (局内存档)**: 战役进行中的状态
   - 自动保存，不手动存档
   - 战役结束时删除
   - 文件: `user://saves/run_{heroId}.json`

2. **Meta Save (元存档)**: 永久数据
   - 跨战役保留
   - 永不删除
   - 文件: `user://saves/meta.json`

### Constraints
- **原子写入**: 防止崩溃导致存档损坏
- **版本兼容**: 支持 minor 升级，major 不兼容时提示
- **自动保存**: 无需玩家手动操作

### Requirements
- Run Save 必须包含: 资源、卡组、武将、地图进度
- Meta Save 必须包含: 图鉴、武将解锁、通关记录
- 支持崩溃恢复

## Decision

### 方案: 双 JSON 文件 + 原子写入

#### 文件结构

```
user://saves/
├── run_cao_cao.json    # Run Save (战役中)
├── run_liu_bei.json
├── meta.json           # Meta Save (永久)
└── run_*.tmp           # 临时文件 (写入中)
```

#### Run Save JSON 结构

```json
{
  "version": "1.0.0",
  "heroId": "cao_cao",
  "timestamp": 1704067200,

  "resources": {
    "hp": 45,
    "maxHp": 50,
    "provisions": 120,
    "gold": 500,
    "actionPoints": 3,
    "maxActionPoints": 4
  },

  "campaignDeck": {  // 战役层卡组快照（权威状态）
    "version": 1,
    "cards": {
      "AC0001": {"level": 1, "special_attrs": [], "is_permanent": true, "source": "initial"},
      "AC0002": {"level": 1, "special_attrs": [], "is_permanent": true, "source": "shop"},
      "SC0001": {"level": 1, "special_attrs": [], "is_permanent": true, "source": "reward"},
      "CC0001": {"level": 1, "special_attrs": [], "is_permanent": true, "source": "event"}
    }
  },

  "hero": {
    "id": "cao_cao",
    "level": 3,
    "exclusiveDeck": ["ZY-001", "ZY-002", ...]
  },

  "equipment": [
    {"id": "EQ001", "slot": "weapon"},
    {"id": "EQ002", "slot": "armor"}
  ],

  "map": {
    "campaignId": "c1",
    "currentMap": 2,
    "currentNode": 5,
    "mapStructure": { ... },
    "visitedNodes": [1, 2, 3, 4, 5]
  },

  "battleState": null,
  "triggeredEvents": ["EV010", "EV025"],
  "campaignEnded": false
}
```

> **重要变更**：原 `deck` 字段已替换为 `campaignDeck`，代表战役层卡组的权威状态。战斗层卡组（draw_pile, hand_cards, discard_pile, removed_cards, exhaust_cards）仅在战斗中临时存在，**不持久化**，战斗结束后从战役层快照重新初始化。

> **设计依据**：ADR-0020 卡组两层管理架构

> **持久化原则**：
> - 战役层快照（campaignDeck）是唯一持久化状态
> - 战斗层快照（临时卡组）是内存中的临时状态，不写入存档
> - 消耗卡、永久加入卡等变更都反映在战役层快照中
> - 战斗开始时，从战役层快照复制生成战斗层卡组
> - 战斗结束时，战斗层卡组丢弃，仅将"消耗"的卡牌从战役层移除
> - 所有卡牌状态（等级、特殊属性）都在战役层快照中记录
> - 卡牌来源（initial/shop/event/reward）用于统计和成就系统

#### Meta Save JSON 结构

```json
{
  "version": "1.0.0",
  "timestamp": 1704067200,

  "unlockedHeroes": ["cao_cao", "liu_bei", "sun_quan", ...],
  "unlockedCards": {
    "attack": ["AC0001", "AC0002", ...],
    "skill": ["SC0001", ...],
    "troop": ["TC0001", ...],
    "curse": []
  },
  "unlockedEquipment": ["EQ001", "EQ005", ...],

  "heroRecords": {
    "cao_cao": {
      "bestMapReached": 5,
      "victories": 2,
      "defeats": 5
    }
  },

  "settings": {
    "masterVolume": 0.8,
    "musicVolume": 0.7,
    "sfxVolume": 0.9,
    "fullscreen": true
  },

  "statistics": {
    "totalRuns": 15,
    "totalVictories": 3
  }
}
```

#### 核心 SaveManager 实现

```gdscript
# save_manager.gd
class_name SaveManager extends Node

const SAVE_DIR = "user://saves/"
const RUN_SAVE_PREFIX = "run_"
const META_SAVE_NAME = "meta.json"
const CURRENT_VERSION = "1.0.0"

enum SaveType { RUN, META }

func _ready():
    _ensure_save_directory()

func _ensure_save_directory():
    var dir = DirAccess.open(SAVE_DIR)
    if dir == null:
        DirAccess.make_dir_recursive(SAVE_DIR)

# === Run Save ===

func save_run(hero_id: String, data: Dictionary) -> bool:
    data["version"] = CURRENT_VERSION
    data["heroId"] = hero_id
    data["timestamp"] = Time.get_unix_time_from_system()

    var path = SAVE_DIR + RUN_SAVE_PREFIX + hero_id + ".json"
    var temp_path = path + ".tmp"

    # 写入临时文件
    var temp_file = FileAccess.open(temp_path, FileAccess.WRITE)
    if temp_file == null:
        push_error("Failed to create temp save file")
        return false

    var json_string = JSON.stringify(data, "\t")
    temp_file.store_string(json_string)
    temp_file.close()

    # 原子替换
    var dir = DirAccess.open(SAVE_DIR)
    var error = dir.rename(temp_path, path)
    return error == OK

func load_run(hero_id: String) -> Dictionary:
    var path = SAVE_DIR + RUN_SAVE_PREFIX + hero_id + ".json"
    return _load_json(path)

func delete_run(hero_id: String) -> bool:
    var path = SAVE_DIR + RUN_SAVE_PREFIX + hero_id + ".json"
    var dir = DirAccess.open(SAVE_DIR)
    return dir.remove(path) == OK

# === Meta Save ===

func save_meta(data: Dictionary) -> bool:
    data["version"] = CURRENT_VERSION
    data["timestamp"] = Time.get_unix_time_from_system()

    var path = SAVE_DIR + META_SAVE_NAME
    var temp_path = path + ".tmp"

    var temp_file = FileAccess.open(temp_path, FileAccess.WRITE)
    if temp_file == null:
        return false

    var json_string = JSON.stringify(data, "\t")
    temp_file.store_string(json_string)
    temp_file.close()

    var dir = DirAccess.open(SAVE_DIR)
    return dir.rename(temp_path, path) == OK

func load_meta() -> Dictionary:
    var path = SAVE_DIR + META_SAVE_NAME
    return _load_json(path)

# === 辅助方法 ===

func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}

    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to open save file: " + path)
        return {}

    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result != OK:
        push_error("Failed to parse save file: " + path)
        return {}

    var data = json.get_data()
    if typeof(data) != TYPE_DICTIONARY:
        return {}

    # 版本兼容性检查
    return _migrate_if_needed(data)

func _migrate_if_needed(data: Dictionary) -> Dictionary:
    var saved_version = data.get("version", "1.0.0")
    var saved_major = saved_version.split(".")[0].to_int()
    var current_major = CURRENT_VERSION.split(".")[0].to_int()

    if saved_major < current_major:
        # major 版本不兼容，返回空数据
        push_error("Save version " + saved_version + " incompatible with " + CURRENT_VERSION)
        return {}

    # minor 版本兼容，缺失字段填默认值
    var default_data = _get_default_meta()
    for key in default_data:
        if not data.has(key):
            data[key] = default_data[key]

    return data

func _get_default_meta() -> Dictionary:
    return {
        "version": CURRENT_VERSION,
        "timestamp": 0,
        "unlockedHeroes": ["cao_cao"],
        "unlockedCards": {"attack": [], "skill": [], "troop": [], "curse": []},
        "unlockedEquipment": [],
        "heroRecords": {},
        "settings": {
            "masterVolume": 0.8,
            "musicVolume": 0.7,
            "sfxVolume": 0.9,
            "fullscreen": true
        },
        "statistics": {"totalRuns": 0, "totalVictories": 0}
    }

# === 存档检查 ===

func has_run_save(hero_id: String) -> bool:
    return FileAccess.file_exists(SAVE_DIR + RUN_SAVE_PREFIX + hero_id + ".json")

func has_meta_save() -> bool:
    return FileAccess.file_exists(SAVE_DIR + META_SAVE_NAME)
```

## Alternatives Considered

### Alternative 1: Godot Resource 序列化
- **描述**: 使用 Godot 的 .tres Resource 文件存储
- **优点**:
  - 类型安全
  - 编辑器支持
- **缺点**:
  - 难以手动编辑/调试
  - 跨平台兼容性问题
- **未采用原因**: JSON 更通用且易于调试

### Alternative 2: SQLite 数据库
- **描述**: 使用 SQLite 存储游戏数据
- **优点**:
  - 查询方便
  - 性能好
- **缺点**:
  - 需要额外依赖
  - 过度工程化
- **未采用原因**: 数据量小，不需要数据库

### Alternative 3: 双 JSON + 原子写入 (推荐方案)
- **描述**: 两个 JSON 文件，写入使用临时文件+重命名
- **优点**:
  - 简单通用
  - 崩溃安全
  - 易于调试
- **采用原因**: 满足所有需求，复杂度适中

## Consequences

### Positive
- **崩溃安全**: 临时文件+原子替换保证不会损坏
- **版本兼容**: minor 升级自动兼容
- **自动保存**: 玩家无需手动操作
- **易于调试**: JSON 可直接查看

### Negative
- **手动编辑风险**: 玩家可能误修改 JSON
- **大文件风险**: 大量数据时 JSON 解析变慢
  - **缓解**: 当前数据量小 (<10KB)，不成问题

### Risks
- **磁盘空间不足**: 写入失败
  - **缓解**: 检查返回值，提示用户
- **并发写入**: 多处同时写入
  - **缓解**: 使用 Mutex 或队列

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| save-persistence-system.md | Run Save + Meta Save 双层结构 | 双 JSON 文件实现 |
| save-persistence-system.md | 原子写入 | 临时文件 + rename |
| save-persistence-system.md | 版本兼容 | _migrate_if_needed() |
| save-persistence-system.md | 战役结束删除 Run Save | delete_run() |

## Performance Implications
- **Load Time**: Run Save < 5ms, Meta Save < 3ms (典型大小)
- **Save Time**: < 10ms
- **Disk Space**: Run Save ~3-5KB, Meta Save ~6-8KB

## Migration Plan
1. 实现 SaveManager.gd
2. 创建默认 Meta Save 创建逻辑
3. 集成到资源管理节点保存时机
4. 测试版本兼容性

## Validation Criteria
- [ ] Run Save 正确保存战役进度
- [ ] Meta Save 正确保存图鉴/解锁
- [ ] 写入崩溃不损坏已有存档
- [ ] 版本不兼容时正确提示

## Related Decisions
- ADR-0001 (已创建): 场景管理策略 — GameState 结构
- ADR-0002 (已创建): 系统间通信模式
- ADR-0003 (已创建): 资源变更通知机制
