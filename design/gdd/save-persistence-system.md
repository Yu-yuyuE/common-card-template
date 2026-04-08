# F1 — 存档持久化系统（Save & Persistence System）

_Created: 2026-04-08_
_Updated: 2026-04-08_
_Status: Complete_
_Priority: Alpha / 基础层_

---

## Overview

存档持久化系统定义《三国称雄》**游戏状态的保存与恢复**机制，分为两个独立层：

**Run Save（局内存档）**：记录当前进行中战役的全部状态，单一自动存档，战役结束时清除。每位武将一个文件：`user://saves/run_{heroId}.json`

**Meta Save（元存档）**：记录跨局永久数据——图鉴解锁、武将解锁、通关记录、游戏设置。单一文件，永不因战役结束被清除：`user://saves/meta.json`

游戏在关键节点自动写入，无手动存档，无多槽位。玩家不需要管理存档——进度自动保存，随时可以退出并继续。

**系统职责边界：**
- 负责：两层存档的结构定义、写入时机、读取与恢复、版本兼容策略
- 不负责：各系统的游戏逻辑；仅负责状态的序列化与反序列化

---

## Player Fantasy

**"我可以随时放下——下次打开，一切都在原地；通关的成就，永远留着。"**

**① 零焦虑退出（安全感层）**
玩家不需要找存档点。关掉游戏，当前战役的每一步进度都安全保存。重新打开直接还原到上次离开的节点，卡组、装备、地图状态全部完好。

**② 永久性决策的重量（Roguelike 层）**
局内存档不可回滚。花掉的金币、移除的卡牌、损失的 HP——这些选择无法撤销。这种永久性是 Roguelike 核心张力的来源：每个决策都是真实的承诺。

**③ 积累感与收藏欲（元游戏层）**
每局结束后图鉴慢慢填满——见过的事件、获得过的装备、通关的武将。即使这局失败，"首次遇到这个事件"的发现永远被记录下来。玩家能感受到每局都在积累一些东西。

**不应有的感受：**
- 游戏崩溃后丢失当前节点进度
- 通关记录或图鉴因 bug 被重置
- 读取存档后状态异常（卡组乱序、HP 归零）

---

## Detailed Rules

### 1. 双层存档结构

| 层 | 文件 | 生命周期 | 内容 |
|----|------|---------|------|
| **Run Save** | `run_{heroId}.json` | 战役开始创建，战役结束删除 | 当前战役全部状态 |
| **Meta Save** | `meta.json` | 首次启动创建，永不删除 | 图鉴、解锁、通关记录、设置 |

---

### 2. Run Save 数据结构

```
RunSave {
  // 元数据
  version:   string       // 存档版本号（如 "1.0.0"）
  timestamp: int          // 最后写入时间（Unix 秒）

  // 战役进度
  heroId:     string      // 武将 ID（如 "cao_cao"）
  currentHp:  int         // 当前 HP
  gold:       int         // 当前金币
  cargo:      int         // 当前粮草
  campaignId: string      // 当前战役 ID（如 "wei_campaign_1"）
  mapId:      string      // 当前小地图 ID（如 "map_2_1"）

  // 卡组状态
  deck: [
    { cardId: string, level: int }  // level: 1 or 2
  ]

  // 地图进度
  currentNodeId:   string    // 当前所在节点 ID
  visitedNodes:    string[]  // 已访问节点 ID 列表
  triggeredEvents: string[]  // 本图已触发事件 ID（去重用）
  pendingWeather:  string    // 待生效天气（""=无）
  removedCardIds:  string[]  // 本战役已移除的卡牌实例 ID

  // 地图拓扑结构（进入该地图时生成，整图固定）
  mapStructure: {
    nodes: [
      {
        id:       string    // 节点 ID
        type:     string    // "battle"/"elite"/"shop"/"inn"/"barracks"/"event"/"boss"
        children: string[]  // 下一可到达节点 ID
        terrain:  string    // 地形类型
        weather:  string    // 初始天气类型
      }
    ]
    startNodeId: string
    bossNodeId:  string
  }

  // 装备状态
  equipment: string[]  // 当前携带装备 ID 列表（长度 ≤ 5，袁绍 ≤ 6）
}
```

---

### 3. Meta Save 数据结构

```
MetaSave {
  version:   string
  timestamp: int

  // 解锁与图鉴
  unlockedHeroes:      string[]  // 已解锁武将 ID
  unlockedCards:       string[]  // 已解锁（可在商店出现）卡牌 ID
  discoveredEvents:    string[]  // 已见过的事件 ID（图鉴用）
  discoveredEquipment: string[]  // 已见过的装备 ID（图鉴用）

  // 武将通关记录
  heroProgress: {
    [heroId: string]: {
      completedCampaigns: string[]  // 已完成的战役章节 ID（如 ["wei_1","wei_2"]）
      totalRuns:          int       // 总游戏次数（含失败）
      totalWins:          int       // 总通关次数
    }
  }

  // 全局设置
  settings: {
    masterVolume: float  // 0.0 ~ 1.0
    musicVolume:  float
    sfxVolume:    float
    language:     string  // "zh_CN" / "en"
  }
}
```

---

### 4. 写入时机

#### Run Save 写入时机

| 触发事件 | 写入内容 |
|---------|---------|
| 战斗结束（胜利/失败） | HP、金币、卡组、装备 |
| 离开商店节点 | 金币、卡组、装备 |
| 离开奇遇节点 | HP、金币、粮草、卡组、已触发事件、待生效天气 |
| 离开酒馆节点 | HP、粮草 |
| 离开军营节点 | 卡组、粮草 |
| 进入新小地图 | 全量写入（含新 mapStructure） |
| 战役结束（胜利/死亡） | **删除** Run Save 文件 |

#### Meta Save 写入时机

| 触发事件 | 写入内容 |
|---------|---------|
| 首次解锁新武将 | `unlockedHeroes` |
| 首次解锁新卡牌 | `unlockedCards` |
| 首次遇到某事件 | `discoveredEvents` |
| 首次获得某装备 | `discoveredEquipment` |
| 战役胜利 | `heroProgress`（completedCampaigns + totalWins） |
| 战役失败 | `heroProgress`（totalRuns） |
| 修改设置 | `settings`（立即写入） |

---

### 5. 启动读取逻辑

```
游戏启动
  → 读取 meta.json（若不存在则创建默认值）
  → 主菜单显示已解锁武将列表
  → 玩家选择武将
      → 检查 run_{heroId}.json 是否存在
          存在  → 询问"继续上次战役？"→ 确认则加载 RunSave
          不存在 → 开始新战役，创建新 RunSave
```

---

## Formulas

### F1. 存档文件大小估算

```
RunSaveSize ≈ BaseSize + DeckSize + NodeSize + MapSize

变量：
  BaseSize  = 固定字段（heroId、HP、gold、cargo 等）≈ 200 bytes
  DeckSize  = 卡组张数 × 30 bytes（cardId + level）
              典型卡组 40 张 = 1200 bytes
  NodeSize  = visitedNodes + triggeredEvents + removedCards
              典型值 ≈ 50 个节点 × 15 bytes = 750 bytes
  MapSize   = mapStructure 节点数 × 80 bytes
              典型 20 节点地图 = 1600 bytes

典型 RunSave 总大小 ≈ 3.5~5 KB（远低于任何平台限制）
```

### F2. Meta Save 大小估算

```
MetaSaveSize ≈ CardPool + EventPool + EquipPool + HeroRecords

变量：
  CardPool    = 解锁卡牌数 × 15 bytes（最多 217 张）≈ 3.2 KB
  EventPool   = 已发现事件数 × 10 bytes（最多 50 个）≈ 0.5 KB
  EquipPool   = 已发现装备数 × 10 bytes（最多 60 件）≈ 0.6 KB
  HeroRecords = 武将数 × 100 bytes（最多 23 位）≈ 2.3 KB

典型 MetaSave 总大小 ≈ 6~8 KB（满解锁时）
```

### F3. 版本兼容性判断

```
isCompatible = (savedMajor == currentMajor)

版本号格式："{major}.{minor}.{patch}"
  major 变更：存档结构破坏性变更，不兼容，提示玩家重置
  minor 变更：新增字段，向前兼容（读取时缺失字段使用默认值）
  patch 变更：无结构变化，完全兼容

示例：
  存档版本 "1.2.0"，当前版本 "1.3.0" → major 相同 → 兼容，缺失字段填默认值
  存档版本 "1.2.0"，当前版本 "2.0.0" → major 不同 → 不兼容，提示玩家
```

---

## Edge Cases

| # | 边界情况 | 裁定规则 |
|---|---------|---------|
| E1 | **游戏在写入存档过程中崩溃（写入中断）** | 采用"先写临时文件，写入完成后原子替换"策略（写入 `run_{heroId}.tmp`，成功后重命名为 `.json`）；读取时若发现 `.tmp` 文件存在而 `.json` 不存在，视为写入中断，使用上一次成功存档，提示玩家"检测到异常退出，已恢复到上一节点" |
| E2 | **存档文件被手动删除或损坏（JSON 解析失败）** | Run Save 损坏：提示"存档损坏，该武将战役进度无法恢复"，返回主菜单，不自动开始新局；Meta Save 损坏：提示"元数据损坏，图鉴与解锁记录已重置"，创建新的默认 MetaSave，不影响已进行中的战役 |
| E3 | **存档版本 major 不兼容（如 v1→v2 大版本更新）** | 显示"存档版本不兼容，无法继续上次战役"；旧 Run Save 自动删除；Meta Save 尝试字段迁移，迁移失败则重置并提示 |
| E4 | **存档版本 minor 向前兼容（新增字段）** | 读取时对缺失字段赋予默认值（如新增 `pendingWeather` 字段，旧存档读取时默认为 `""`）；写入时补全所有字段，存档自动升级到当前版本 |
| E5 | **两个武将同时有进行中战役（run_cao_cao.json 和 run_liu_bei.json 同时存在）** | 完全支持；每个文件独立，互不影响；主菜单对每位武将分别显示"继续"或"新战役"选项 |
| E6 | **战役结束时删除 Run Save 失败（磁盘权限问题）** | 记录删除失败到日志；下次启动时检测到该 Run Save，校验战役结束标志位（`campaignEnded: true`）则跳过"继续"选项，直接视为新战役 |
| E7 | **Meta Save 写入时游戏崩溃（图鉴更新丢失）** | 同 E1，使用临时文件原子替换；最坏情况是本次新发现的图鉴条目未记录，下次再遇到同一事件/装备时重新写入；图鉴丢失不影响游戏进度 |
| E8 | **磁盘空间不足，写入存档失败** | 显示警告"存档失败：磁盘空间不足，当前进度可能无法保存"；游戏继续运行（不强制退出）；下次写入时重试 |
| E9 | **玩家在战斗中途（出牌阶段中）强制退出** | 战斗中不写入存档（写入时机为战斗**结束**后）；重新进入游戏后读取上一次存档，即战斗开始前的节点状态；玩家需重打该场战斗 |
| E10 | **Steam Cloud 同步与本地存档冲突（云存档更新）** | 以 Steam Cloud 存档为准（timestamp 更新的优先）；本地存档作为备份保留 24 小时后清除；不提供手动选择界面（保持简单） |
| E11 | **heroProgress 中的 completedCampaigns 包含已不存在的战役 ID（版本更新删除了某战役）** | 保留记录（不删除），仅在 UI 展示时过滤掉无效 ID；不影响通关计数 |
| E12 | **首次启动时 meta.json 不存在** | 自动创建默认 MetaSave：初始解锁武将列表（硬编码默认值）、空图鉴、空通关记录、默认设置；对玩家无感知 |

---

## Dependencies

### 系统依赖

| 系统 | 方向 | 接口内容 |
|------|------|---------|
| 资源管理系统（F2） | 读 | HP、金币、粮草由 F2 管理；战役关键节点结束时 F2 将当前值推送给 F1 写入 Run Save |
| 卡牌战斗系统（C2） | 读 | 卡组列表（cardId + level）由 C2 管理；每次写入时机触发时 C2 提供当前卡组快照 |
| 地图节点系统（M1） | 读 | mapStructure、currentNodeId、visitedNodes 由 M1 管理；进入新地图时 M1 提供完整地图拓扑；节点导航后推送更新 |
| 事件系统（M4） | 读/写 | triggeredEvents 由 M4 维护并推送给 F1；F1 在存档中持久化，重载时返还给 M4 恢复去重状态 |
| 装备系统（M3） | 读 | equipment 列表由 M3 管理；写入时机触发时 M3 提供当前携带装备快照 |
| 地形天气系统（D1） | 读 | pendingWeather 由 D1 管理；写入时 D1 提供当前待生效天气状态 |
| 卡牌解锁系统（D5） | 写 | 解锁新卡牌时 D5 调用 F1 接口更新 Meta Save 的 `unlockedCards` |
| 武将系统（D3） | 写 | 解锁新武将时 D3 调用 F1 接口更新 Meta Save 的 `unlockedHeroes` |
| 卡牌升级系统（M5） | 读 | 卡牌升级记录（level 字段）由 M5 维护，通过 C2 卡组快照一并写入，不单独接口 |

### 数据依赖

| 文件 | 用途 |
|------|------|
| `user://saves/run_{heroId}.json` | Run Save 存档文件（运行时生成） |
| `user://saves/meta.json` | Meta Save 元存档文件（运行时生成） |

---

## Tuning Knobs

| 调节项 | 当前值 | 安全区间 | 影响维度 |
|--------|--------|---------|---------|
| Run Save 写入时机粒度 | 节点离开时 | 节点进入时 ~ 每步操作后 | 过细则写入频繁影响性能；过粗则崩溃后损失更多进度 |
| 战斗中途退出的恢复点 | 战斗开始前（需重打该战斗） | 战斗开始前 / 战斗结束后 | 影响玩家对"强制退出"的代价感知；设为战斗结束后则无需重打，但增加作弊风险 |
| 临时文件原子替换 | 启用 | 固定启用 | 崩溃安全性；禁用则存档损坏风险显著上升 |
| Steam Cloud 冲突解决策略 | timestamp 最新优先 | 最新 / 本地优先 / 云端优先 | 影响多设备玩家的体验；最新优先最符合直觉 |
| Meta Save 版本迁移策略 | 尝试字段迁移，失败则重置 | 固定策略 | 大版本更新时玩家图鉴损失范围；迁移成功率越高玩家损失越少 |
| 初始解锁武将数量 | 硬编码（由 D3/D5 定义） | — | 影响新玩家第一局的选择宽度；由 D3 武将系统决定 |

---

## Acceptance Criteria

| # | 验收条件 | 验证方式 |
|---|---------|---------|
| AC1 | 离开任意节点后强制退出，重启游戏后状态完整恢复（HP/金币/粮草/卡组/装备/节点位置） | 功能测试：在商店节点购买卡牌后 Alt+F4，重启确认卡牌在卡组中且金币正确扣减 |
| AC2 | 战斗中途强制退出后重启，恢复到战斗开始前状态（需重打该战斗） | 功能测试：战斗出牌后 Alt+F4，重启确认回到战斗前节点状态，HP/卡组为战斗前数值 |
| AC3 | 战役结束（胜利或死亡）后 Run Save 文件被删除 | 文件系统测试：战役结束后检查 `user://saves/` 目录，确认 `run_{heroId}.json` 不存在 |
| AC4 | Meta Save 在首次解锁新卡牌时立即更新 | 功能测试：通过奇遇事件获得新卡牌后，检查 `meta.json` 中 `unlockedCards` 包含该卡牌 ID |
| AC5 | 武将通关后 completedCampaigns 正确追加战役章节 ID | 功能测试：通关"魏-第一章"后，确认 `heroProgress["cao_cao"].completedCampaigns` 包含对应 ID |
| AC6 | 两位武将同时有进行中战役，互不影响 | 功能测试：曹操战役进行到第3图后切换刘备开始新战役，再切回曹操确认进度完好 |
| AC7 | 存档文件损坏时显示友好提示，不崩溃 | 边界测试：手动损坏 `run_cao_cao.json`（写入非法 JSON），启动游戏确认出现提示而非崩溃 |
| AC8 | minor 版本升级后旧存档可正常读取，缺失字段填默认值 | 版本测试：用 v1.0.0 存档启动 v1.1.0 游戏（新增字段版本），确认正常进入游戏且新字段为默认值 |
| AC9 | major 版本不兼容时提示玩家，旧 Run Save 被清除 | 版本测试：用 v1.x 存档启动 v2.0.0 游戏，确认出现不兼容提示且旧存档文件被删除 |
| AC10 | mapStructure 正确持久化，重载后地图拓扑与存档前完全一致（节点类型、连接关系） | 功能测试：进入第2张地图后强制退出，重载后截图对比地图节点布局，确认完全相同 |
| AC11 | 图鉴发现记录（discoveredEvents/discoveredEquipment）在战役失败后保留 | 功能测试：战役中触发新事件后失败，确认 `meta.json` 中该事件 ID 仍存在 |
| AC12 | 设置修改（音量）立即写入 Meta Save，重启后保持 | 功能测试：调整主音量后关闭游戏，重启确认音量与调整后一致 |
