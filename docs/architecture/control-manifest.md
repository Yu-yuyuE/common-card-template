# Control Manifest

> **Engine**: Godot 4.6.1
> **Last Updated**: 2026-04-09
> **Manifest Version**: 2026-04-09
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0013, ADR-0014, ADR-0015, ADR-0016, ADR-0017
> **Status**: Active — regenerate with `/create-control-manifest` when ADRs change

This manifest is a programmer's quick-reference extracted from all Accepted ADRs, technical preferences, and engine reference docs. For the reasoning behind each rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine init*

### Required Patterns

#### Scene Management (ADR-0001)
- 必须采用"主场景+多图层实例化"模式
- Main节点必须常驻，整个会话期间不销毁
- GameState必须管理全局数据(ResourceManager, DeckManager, HeroManager)
- 子场景必须按需实例化，通过`instantiate()`加载
- 场景切换必须通过图层显隐控制，使用`visible`属性
- 数据传递必须通过`instantiate()`后调用初始化方法实现

#### System Communication (ADR-0002)
- 必须采用双层通信架构：场景内使用Node Signal，全局使用EventBus
- 优先使用Node Signal进行同一场景层级内相邻节点间的直接通信
- EventBus仅用于跨场景的全局事件广播
- 系统间禁止直接引用，必须通过Signal通信
- Signal命名必须遵循格式: `[subject]_[action]_[past_tense]`

#### Resource Management (ADR-0003)
- 必须采用集中式资源管理+Signal广播模式
- 所有资源变化必须通过ResourceManager统一接口
- 资源变化时必须触发resource_changed信号，携带旧值、新值、变化量参数
- 监听者可以过滤关注的具体资源类型
- 必须使用强类型Signal: `signal resource_changed(resource_type: String, old_value: int, new_value: int, delta: int)`

#### Data Configuration (ADR-0004)
- 必须采用CSV配置+CardData class模式
- 卡牌数据必须存储在CSV文件中，便于设计师查看/编辑
- 运行时必须使用CardData类封装卡牌数据
- 卡牌必须按ID快速查找，支持按类型过滤
- 必须支持Lv1/Lv2效果切换

#### Save Serialization (ADR-0005)
- 必须采用双JSON文件+原子写入模式
- 实现双层存档系统：Run Save(战役中)+Meta Save(永久)
- Run Save文件必须为`user://saves/run_{heroId}.json`
- Meta Save文件必须为`user://saves/meta.json`
- 存档写入必须使用临时文件+重命名保证原子性
- 必须支持版本兼容性检查和迁移

### Forbidden Approaches

#### Scene Management (ADR-0001)
- 禁止使用完整场景切换(change_scene_to_file)作为主要场景管理方式
- 禁止在单一场景中使用UI面板切换来实现复杂场景功能
- 禁止在场景切换时不正确管理子场景的生命周期导致内存泄漏

#### System Communication (ADR-0002)
- 禁止使用纯直接方法调用实现系统间通信(强耦合)
- 禁止使用纯EventBus进行所有通信(过度工程化)
- 禁止在子场景销毁时不断开Signal连接导致Signal泄漏

#### Resource Management (ADR-0003)
- 禁止使用轮询检查方式监控资源变化
- 禁止使用方法回调方式实现资源变化通知
- 禁止ResourceManager直接知道所有回调者

#### Data Configuration (ADR-0004)
- 禁止使用纯JSON配置（需保持与GDD的CSV设计一致）
- 禁止使用Godot Resource文件(.tres)存储每张卡牌（文件过多）

#### Save Serialization (ADR-0005)
- 禁止使用Godot Resource序列化作为主要存档方式
- 禁止使用SQLite数据库存储游戏数据
- 禁止在写入存档时不检查返回值和错误处理

### Performance Guardrails

#### Scene Management (ADR-0001)
- 场景实例化时间：< 50ms
- 场景文件大小：10-100KB
- 5个子场景总内存占用：约500KB

#### System Communication (ADR-0002)
- Signal调用开销：< 0.01ms
- 每个Signal连接内存：约32字节
- Signal vs Method Call性能差异：< 5%

#### Resource Management (ADR-0003)
- Signal emit开销：< 0.001ms
- 每个监听者Signal连接：约32字节

#### Save Serialization (ADR-0005)
- Run Save加载时间：< 5ms
- Meta Save加载时间：< 3ms
- 存档写入时间：< 10ms
- Run Save文件大小：3-5KB
- Meta Save文件大小：6-8KB

### Engine API Constraints

#### General (All Foundation ADRs)
- **Engine**: Godot 4.6.1
- **Knowledge Risk**: LOW — standard APIs in training data
- **Post-Cutoff APIs**: None — using standard SceneTree, Signal, FileAccess, JSON APIs

#### Deprecated APIs (Must NOT Use)
From `docs/engine-reference/godot/deprecated-apis.md`:
- `yield()` → 使用 `await signal`
- `connect("signal", obj, "method")` → 使用 `signal.connect(callable)`
- `instance()` → 使用 `instantiate()`
- `PackedScene.instance()` → 使用 `PackedScene.instantiate()`
- `get_world()` → 使用 `get_world_3d()`
- `OS.get_ticks_msec()` → 使用 `Time.get_ticks_msec()`
- `TileMap` → 使用 `TileMapLayer`
- `VisibilityNotifier2D` → 使用 `VisibleOnScreenNotifier2D`
- `YSort` → 使用 `Node2D.y_sort_enabled`
- 字符串连接 → 使用类型化Signal连接

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns

#### Status System (ADR-0006)
- 必须采用集中式StatusManager+事件驱动模式
- 状态效果必须分为Buff和Debuff两类
- 同类状态必须叠加层数，不同类状态必须互斥
- 回合结束时必须调用tick_status()处理状态消耗和持续伤害
- 状态伤害必须区分穿透护盾和走护盾两种类型
- 必须支持20种状态（7种Buff + 13种Debuff）

#### Card Battle System (ADR-0007)
- 必须采用集中式BattleManager+阶段状态机模式
- 战斗必须支持1vs最多3个敌人的战场结构
- 必须实现完整的回合流程：玩家回合→敌人回合→阶段检查
- 卡牌生命周期必须按抽牌堆→手牌→弃牌堆→移除区→消耗区管理
- 伤害计算必须采用护盾优先，溢出扣HP的公式
- 必须支持多阶段战斗（精英/Boss）

#### Enemy System (ADR-0008)
- 必须采用集中式EnemyManager+固定行动序列模式
- 敌人必须支持5种职业和3种级别分类
- 敌人行动必须按固定序列循环，确保可预测性
- 行动必须支持冷却机制和备用行动选择
- 敌人必须支持行动公示机制，让玩家可预判

#### Damage Calculation (ADR-0014)
- 伤害计算必须遵循：基础伤害×地形系数×天气系数×状态系数的顺序
- 地形修正必须在天气修正之前应用
- 状态效果修正必须在所有基础修正之后应用
- 最终伤害不能为负数，最小值必须为1
- 计算过程必须记录日志以便调试

#### Enemy AI Executor (ADR-0015)
- 敌人AI必须采用决策树→行动队列→顺序执行的三层架构
- 行动必须支持条件触发（如HP阈值、状态效果）
- 行动必须支持随机选择（如随机目标）
- 敌人行动之间必须有视觉间隔（0.5-1秒）
- 敌人行动必须支持被打断或延迟

### Forbidden Approaches

#### Status System (ADR-0006)
- 禁止分布式状态管理难以统一跟踪
- 禁止组件式状态导致性能开销大
- 禁止状态组合未经测试导致bug
- 禁止不按需计算状态造成性能浪费

#### Card Battle System (ADR-0007)
- 禁止分布式战斗实体难以协调全局状态
- 禁止纯事件驱动难以追踪执行顺序
- 禁止状态同步不及时导致数据不一致
- 禁止伤害计算不按公式执行导致结果错误

#### Enemy System (ADR-0008)
- 禁止随机行动选择违背可预测原则
- 禁止纯AI决策增加复杂度
- 禁止序列完全泄露让玩家无挑战感
- 禁止平衡未测试导致某些序列过强

#### Damage Calculation (ADR-0014)
- 禁止一次性计算公式导致难以调试
- 禁止加法累计模式不符合游戏设计惯例
- 禁止系数配置错误导致伤害异常
- 禁止状态效果遗漏导致计算逻辑不完整

#### Enemy AI Executor (ADR-0015)
- 禁止纯随机行动缺乏策略性
- 禁止硬编码状态机扩展性差
- 禁止条件函数导致无限行动
- 禁止行动间隔过短或过长影响体验

### Performance Guardrails

#### Status System (ADR-0006)
- 状态查找必须为O(1)时间复杂度
- 每回合状态结算必须<1ms
- 每个单位状态约占用200字节内存

#### Card Battle System (ADR-0007)
- 每次伤害计算必须<0.1ms
- 战斗状态总内存占用约1KB

#### Enemy System (ADR-0008)
- 行动查询必须<0.01ms
- 每敌人约占用100字节内存

#### Damage Calculation (ADR-0014)
- 单次计算必须<0.01ms
- 系数表存储约1KB内存
- 计算时间复杂度必须为O(1)

#### Enemy AI Executor (ADR-0015)
- 单次决策必须<0.1ms
- 每敌人行动配置约1KB
- 行动间隔必须控制在0.5-1秒

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns

#### Terrain & Weather System (ADR-0009)
- 必须使用集中式TerrainWeatherManager管理地形和天气状态
- 必须提供get_terrain_modifier(card_category)接口返回地形修正系数
- 必须提供get_weather_modifier(card_category)接口返回天气修正系数
- 必须在战斗初始化时调用setup_battle(terrain_str, weather_str)设置环境
- 必须支持7种地形（平原、山地、森林、水域、沙漠、关隘、雪地）的枚举定义
- 必须支持4种天气（晴、风、雨、雾）的枚举定义
- 必须在特定地形下自动施加初始状态效果
- 必须实现天气切换时检查冷却机制change_weather(new_weather, source_id, cooldown)
- 必须实现每回合结束的地形/天气持续效果tick_terrain_effects()和tick_weather_effects()

#### Hero System (ADR-0010)
- 必须使用集中式HeroManager管理武将数据
- 必须定义武将阵营枚举（魏、蜀、吴、群雄）
- 必须定义兵种类型枚举（步兵、骑兵、弓兵、谋士、盾兵）
- 必须从CSV配置文件加载武将数据（22名武将）
- 必须为每名武将存储：基础HP(40-60)、费用(3-4)、统帅(3-6)、被动技能、专属卡组(≤12张)、生涯地图(5张)
- 必须支持被动技能触发机制，通过trigger_passive(trigger_type, context)调用
- 必须实现兵种倾向权重计算get_troop_weights(hero_id)
- 必须支持袁绍的特殊手牌上限（6张）
- 必须在武将选择时发送hero_selected信号

#### Map Node System (ADR-0011)
- 必须使用树形MapGraph数据结构存储节点和连接关系
- 必须定义节点类型枚举：战斗、精英、BOSS、商店、酒馆、军营、事件
- 必须实现MapNavigator导航管理器处理节点访问
- 必须在导航前检查：前置节点是否全部访问、粮草是否足够
- 必须在节点导航时消耗粮草provisions_cost
- 必须记录visited_nodes访问历史用于存档
- 必须在关卡完成时触发all_nodes_completed信号（BOSS击败后）
- 必须从JSON配置文件加载地图结构

#### Shop System (ADR-0012)
- 必须使用ShopManager集中管理商品批处理
- 必须定义商品类型枚举：攻击卡、技能卡、装备
- 必须实现批刷新机制_generate_batch()，每批6件商品
- 必须记录purchased_card_ids防止重复购买卡牌
- 必须限制装备携带上限为5件MAX_EQUIPMENT
- 必须在购买时检查金币不足并返回失败
- 必须实现升级价格计算_calculate_upgrade_price(card_data)
- 刷新商品必须消耗50金币refresh_price
- 购买成功后必须发送item_sold信号并添加到玩家卡组

#### Inn System (ADR-0013)
- 必须使用InnManager集中管理酒馆服务
- 必须实现章节重置机制，每章开始时rest_count归零
- 必须实现歇息功能：普通歇息+15HP，强化休整+20HP（消耗60金币）
- 必须限制普通歇息每章最多1次rest_limit=1
- 必须实现买粮草功能：40金币购买40粮草PROVISIONS_PRICE=40
- 必须在歇息时检查HP是否已满
- 必须在购买粮草时按数量比例计算价格
- 必须发送rested和provisions_bought信号

### Forbidden Approaches

#### Terrain & Weather System (ADR-0009)
- 禁止使用分布式环境管理（每个场景独立管理地形天气）
- 禁止无冷却机制的频繁天气切换
- 禁止不提供修正系数查询接口

#### Hero System (ADR-0010)
- 禁止分布式武将数据管理
- 禁止将被动技能逻辑硬编码在武将类中，必须使用可配置的trigger_condition和effect_function

#### Map Node System (ADR-0011)
- 禁止线性关卡设计
- 禁止完全随机生成的关卡节点
- 禁止不检查粮草消耗的导航

#### Shop System (ADR-0012)
- 禁止固定商品不刷新
- 禁止无购买限制
- 禁止无限装备携带
- 禁止每次进入商店随机商品

#### Inn System (ADR-0013)
- 禁止无限制歇息
- 禁止永久性歇息限制（整个战役限N次）
- 禁止不恢复HP上限检查

### Performance Guardrails

#### Terrain & Weather System (ADR-0009)
- 修正系数查询必须是O(1)时间复杂度
- 地形/天气状态数据占用<100字节内存
- 单次修正计算时间<1ms

#### Hero System (ADR-0010)
- 武将数据查询必须是O(1)字典查找
- 每名武将数据占用约200字节内存（22名共约4KB）
- 被动技能触发条件判断必须在<0.1ms内完成

#### Map Node System (ADR-0011)
- 节点查找必须<1ms
- 地图配置加载必须在<50ms内完成

#### Shop System (ADR-0012)
- 商品批生成必须在<10ms完成
- 升级价格计算必须在<0.1ms完成

#### Inn System (ADR-0013)
- 歇息和购买操作必须在<5ms完成

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns

#### UI Data Binding (ADR-0016)
- 必须使用Signal驱动的响应式模式：数据变化→Signal广播→UI订阅更新
- UI必须通过语言键引用文本，禁止硬编码字符串
- 必须实现运行时语言切换功能，切换时间不超过200ms
- 所有UI元素需要遵循ADR-0016的数据绑定模式
- UI必须响应资源变化（HP、金币、粮草、行动点等）
- UI必须响应卡牌变化（手牌、弃牌堆等）
- UI必须响应战斗状态变化（敌人血量、状态等）
- UI必须响应地图节点变化

#### Localization System (ADR-0017)
- 必须使用Godot 4.6.1内置的本地化框架
- 必须通过Autoload方式实现LocalizationManager单例
- 必须使用Godot原生Translation资源存储翻译内容
- 必须支持参数化文本替换（如"{0}"、"${name}"）
- 必须实现三层翻译回退：当前语言→中文(zh)→键名
- 必须为每种语言配置独立字体资源
- 必须支持运行时语言切换并自动刷新所有绑定UI
- 所有显示文本必须通过语言键获取，禁止硬编码

### Forbidden Approaches

#### UI Data Binding (ADR-0016)
- 禁止在代码中使用硬编码字符串
- 禁止使用手动刷新(Polling)方式更新UI（每帧检查数据变化）
- 禁止使用观察者模式进行UI更新
- 禁止UI直接访问游戏逻辑数据
- 禁止在语言切换时重启游戏

#### Localization System (ADR-0017)
- 禁止使用纯手动文本管理方式（为每种语言创建独立场景和脚本）
- 禁止在语言切换时出现UI闪烁或不一致
- 禁止使用第三方本地化插件（保持Godot原生）

## Global Rules (All Layers)

### Naming Conventions
- Classes: PascalCase (e.g., BattleManager)
- Variables/Functions: snake_case (e.g., current_hp, take_damage)
- Signals: snake_case past tense (e.g., card_played, battle_ended)
- Files: snake_case matching class (e.g., battle_manager.gd)
- Scenes: PascalCase matching root node (e.g., BattleScene.tscn)
- Constants: UPPER_SNAKE_CASE (e.g., MAX_HAND_CARDS)

### Performance Budgets
- Target Framerate: 60 fps (16.6ms per frame)
- Frame Budget: 16.6ms maximum
- Draw Calls: 2000 maximum per frame
- Memory Ceiling: 512MB RAM total
- Per-System Budget: 5ms for non-rendering systems

### Testing Standards
- Framework: GUT (Godot Unit Test)
- Minimum Coverage: Core game systems, balance formulas
- Required Tests: Battle flow, Status effects, Resource management
- Test Evidence: Logic tests MUST pass for all core systems

### Forbidden Patterns
- Global variables for game state (use GameState node)
- Direct node references across scene boundaries
- Hardcoded magic numbers in game logic (use constants)
- Business logic in UI code
- UI manipulation in business logic

### Engine API Constraints
- ONLY use Godot 4.6.1 stable APIs
- File I/O MUST use FileAccess wrapper
- Scene switching MUST use Main scene layer management
- Resource loading MUST use ResourceLoader with proper error handling
- Signal connections MUST check for signal existence before connecting