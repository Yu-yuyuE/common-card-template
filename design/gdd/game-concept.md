# Game Concept: 三国称雄 (Three Kingdoms Ascendant)

*Created: 2026-03-27*
*Status: Draft*

---

## Elevator Pitch

> 一款Roguelike卡牌游戏，玩家扮演三国历史武将体验其生平战役。每位武将有独特技能与卡组，在树形地图中通过卡牌战斗、奇遇与决策，逐步成长为一代枭雄。融合三国情怀与Roguelike策略深度，每次游玩都是新的故事篇章。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Roguelike卡牌游戏 |
| **Platform** | PC (Steam) |
| **Target Audience** | 策略卡牌玩家、三国题材爱好者、Roguelike爱好者 |
| **Player Count** | 单人游戏 |
| **Session Length** | 30-60分钟/单局 |
| **Monetization** | 付费买断制 |
| **Estimated Scope** | Medium (6-12个月) |
| **Comparable Titles** | 《杀戮尖塔》、《博德之门3》(卡牌MOD风格)、《霓虹之血》 |

---

## Core Fantasy

**"运筹帷幄之中，决胜千里之外"**

玩家扮演三国名将，在有限的体力资源下合理规划每轮出牌，通过卡牌组合与策略思考战胜敌人。核心幻想是成为三国传奇军师/武将——体验三国英雄在历史转折点的关键战役，用智慧与勇气改写或重温三国历史。

---

## Unique Hook

**"武将生平即是关卡"** —— 与传统Roguelike随机生成关卡不同，本游戏每个武将的战役路线基于其真实历史事件，玩家在推进过程中体验三国武将的人生故事线。每个武将拥有独特的卡组机制，体现其历史性格：诸葛亮的智慧、吕布的勇武、刘备的仁德。

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (感官愉悦) | 4 | 拖拽卡牌的手感、打击特效、卡牌翻转音效 |
| **Fantasy** (扮演想象) | 2 | 代入三国武将角色，体验历史名将人生 |
| **Narrative** (叙事) | 1 |武将生平故事线，历史事件的戏剧性呈现 |
| **Challenge** (挑战) | 3 | 卡牌资源管理难度，Roguelike死亡惩罚 |
| **Fellowship** (社交) | N/A | 无多人模式，专注单人体验 |
| **Discovery** (探索) | 5 | 隐藏奇遇事件、隐藏卡牌、成就系统 |
| **Expression** (表达) | 6 | 卡组构建、玩家风格体现 |
| **Submission** (放松) | 7 | 可选简单难度、休闲模式 |

### Key Dynamics (Emergent player behaviors)

- 玩家会研究不同武将卡组组合，寻找最优策略
- 玩家会反复尝试不同奇遇选择，探索所有可能性
- 玩家会分享不同武将的开局策略和剧情体验

### Core Mechanics (Systems we build)

1. **卡牌战斗系统**: 回合制抽卡出牌，体力消耗管理，拖拽释放
2. **武将系统**: 独特技能树+专属卡组，体力和生命值管理
3. **树形地图系统**: 基于历史事件的战役节点图，战斗/奇遇/商店/恢复节点
4. **剧情推进系统**: 武将生平事件选择，影响后续战斗和结局

---

## Player Motivation Profile

### Primary Psychological Needs Satisfied

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (自由选择) | 多条路线选择、武将技能树天赋选择 | Core |
| **Competence** (精通成长) | 卡牌Combo构建、战斗策略深度、难度挑战 | Core |
| **Relatedness** (情感联系) | 与三国角色的情感连接、历史沉浸感 | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- **Achievers** (成就者): 收集全部武将、通关所有难度、达成成就 —— 通过武将收集、卡牌图鉴、成就系统满足
- **Explorers** (探索者): 探索所有奇遇路线、发现隐藏内容 —— 通过树形地图探索、隐藏事件满足
- **Killers/Competitors** (竞技者): 高难度速通、卡组构筑竞技 —— 通过挑战模式、排行榜满足

### Flow State Design

- **Onboarding curve**: 第一位武将(刘备)教学局，前3场战斗引导玩家理解核心机制
- **Difficulty scaling**: 随战役推进敌人变强，卡牌资源管理难度递进
- **Feedback clarity**: 战斗结算画面清晰展示本轮表现，卡组构筑优化建议
- **Recovery from failure**: 死亡后立即可选重新开始或更换武将，死亡无惩罚性损失

---

## Core Loop

### Moment-to-Moment (30秒)

玩家每回合抽5张手牌，拖拽卡牌到目标(敌人或自身)上释放。核心动作是**卡牌拖拽释放**，需考虑：
- 当前剩余体力是否能打出
- 优先击杀目标选择
- 是否保留某些卡牌等待更好时机

### Short-Term (5-15分钟)

一个完整战役节点(从起点到Boss战)，包含3-5场战斗+1-2个奇遇/商店点。玩家需要在这几场战斗中管理卡组资源，寻找最佳通过的路线。

### Session-Level (30-60分钟)

完整通关一个武将的全部战役路线。从虎牢关到赤壁，每场战役都是一次完整Roguelike体验。

### Long-Term Progression

- **武将解锁**: 通关一位武将后解锁下一位武将
- **卡牌收集**: 通关过程中获得新卡牌，丰富卡组
- **难度提升**: 更高难度解锁，考验玩家策略深度

### Retention Hooks

- **Curiosity**: 每个武将都有独特剧情线和隐藏事件
- **Investment**: 已解锁武将和卡牌需要继续投入时间
- **Mastery**: 高难度挑战、通关时间排行榜

---

## Game Pillars

### Pillar 1: 三国沉浸感
每个武将的战役路线、卡组设计、事件文本都基于三国历史故事，让玩家感受到这是"三国游戏"而非"套皮三国"

*Design test*: 如果在设计一张新卡牌时，可以做一张纯数值强化的攻击牌，或一张体现武将性格的技能牌， pillar 1 指引我们选择后者

### Pillar 2: 策略深度优先于数值堆砌
游戏核心乐趣在于卡牌组合与资源管理决策，而非数值碾压

*Design test*: 当玩家反映"某关卡太简单"时，优先通过增加策略选项(新卡牌/新机制)而非简单提高敌人血量来解决

### Pillar 3: 武将即是游戏体验
每位武将应该有截然不同的玩法体验——玩诸葛亮和玩吕布应该是两款不同的游戏

*Design test*: 如果某个设计让所有武将都能通用，pillar 3 要求我们重新思考是否削弱了武将独特性

### Pillar 4: 尊重玩家时间
单局30-60分钟，有自然停止点；死亡惩罚极低，鼓励快速重开

*Design test*: 在设计新功能时，如果会显著延长单局时间，需要评估是否值得

### Anti-Pillars (What This Game Is NOT)

- **NOT 抽卡氪金**: 不做任何形式收费抽卡，游戏内所有卡牌通过游戏过程获取
- **NOT 数值碾压**: 不设计需要"刷装备"才能过的内容
- **NOT 复杂连招教学**: 不要求玩家背复杂连招表才能玩
- **NOT 强制重复看剧情**: 首次剧情阅读后可跳过

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| 杀戮尖塔 | 优秀的卡牌战斗Roguelike框架 | 三国历史题材+武将系统 | 验证此类游戏市场可行性 |
| 炉石传说 | 卡牌拖拽交互、卡牌特效表现 | 回合制+体力限制+无随机池 | 简化上手难度，深耕策略 |
| 博德之门3 | 角色扮演+历史叙事融合 | 武将生平即是关卡 | 增加角色代入感和重复可玩性 |
| 霓虹之血 | 快速战斗节奏 | 短单局节奏 | 尊重玩家时间设计 |

**Non-game inspirations**: 三国演义原著、央视三国电视剧、音乐游戏(节奏反馈参考)

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-40 |
| **Gaming experience** | Mid-core / Hardcore |
| **Time availability** | 30-60分钟 sessions, 晚间/周末 |
| **Platform preference** | PC Steam |
| **Current games they play** | 杀戮尖塔、哈迪斯、博德之门3 |
| **What they're looking for** | 有深度的策略游戏+三国题材代入感 |
| **What would turn them away** | 数值氪金、无脑刷、复杂教学 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.x - 轻量高效，2D支持优秀，社区资源丰富 |
| **Key Technical Challenges** | 树形地图数据驱动设计、卡牌效果系统架构 |
| **Art Style** | 介于像素与水墨之间 - 像素武将立绘+水墨UI元素 |
| **Art Pipeline Complexity** | Medium - 需要大量卡牌插画和武将立绘 |
| **Audio Needs** | Moderate - 卡牌音效、武将语音、背景音乐 |
| **Networking** | None - 纯单机游戏 |
| **Content Volume** | 5-8位武将，每位3-5个战役节点，约200+张卡牌 |
| **Procedural Systems** | 战斗敌人随机组合、掉落卡牌随机池 |

---

## Risks and Open Questions

### Design Risks

- 卡牌Combo深度可能不足 - 需要丰富卡牌设计
- 多线叙事可能导致内容创作工作量巨大 - 考虑AI辅助
- 每个武将玩法差异度可能不够 - 需要详细设计验证

### Technical Risks

- 卡牌效果系统扩展性 - 需要良好的架构设计
- 树形地图编辑器工具开发 - 需要自研关卡编辑器

### Market Risks

- 三国题材在海外市场接受度 - 定位中文市场为主
- Roguelike卡牌品类竞争激烈 - 差异化在武将系统和三国题材

### Scope Risks

- 美术资源需求量高 - 考虑与美术外包合作
- 8位武将开发周期可能超出预期 - MVP先做3位武将验证

### Open Questions

- 卡牌Combo平衡性如何验证? —— 通过prototype测试
- 玩家对多线叙事接受度如何? —— 通过playtest反馈
- 武将解锁节奏? —— 通过用户测试调整

---

## MVP Definition

**Core hypothesis**: 玩家是否享受"武将技能+卡组构筑+回合制战斗"的策略体验

**Required for MVP**:

1. 1位完整武将(刘备)战役流程
2. 30张核心卡牌+基本Combo
3. 3个树形地图节点(战斗->奇遇->Boss)
4. 基础UI和卡牌拖拽交互

**Explicitly NOT in MVP**:

- 多人游戏/排行榜
- 完整的8位武将
- 成就系统
- 隐藏剧情

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1武将+3节点 | 核心卡牌战斗 | 2个月 |
| **Vertical Slice** | 3武将+完整战役 | 卡牌收集+简单剧情 | 4个月 |
| **Alpha** | 5武将 | 成就+难度系统 | 6个月 |
| **Full Vision** | 8武将+全部 | 完整系统+配音 | 12个月 |

---

## Next Steps

- [ ] 与 creative-director 确认概念方向
- [ ] 使用 /setup-engine godot 4.x 配置引擎环境
- [ ] 使用 /design-review design/gdd/game-concept.md 验证完整性
- [ ] 使用 /map-systems 将概念分解为系统模块
- [ ] 使用 /architecture-decision 记录关键技术决策
- [ ] 使用 /prototype 核心卡牌战斗机制
- [ ] 使用 /playtest-report 测试核心玩法
- [ ] 使用 /sprint-plan new 规划第一个冲刺
