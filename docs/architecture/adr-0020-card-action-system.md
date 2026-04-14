# ADR-0020: 卡牌行动参数系统 (Card Action System)

**日期**: 2026-04-13
**状态**: Proposed
**作者**: Claude Code
**相关文档**: 
- `design/gdd/cards-design.md` - 卡牌行动参数系统章节
- `design/gdd/enemies-design.md` - 敌人行动参数系统（参考）

---

## 摘要

为卡牌效果设计结构化的行动参数系统，参考 `enemies-design.md` 的敌人行动参数机制，实现从文本描述到可程序化执行参数的转换。

---

## 问题陈述

### 当前问题

1. **文本描述不可执行**：当前 `all_cards.csv` 中卡牌效果以文本存储（如"对目标造成6点伤害"），无法被代码直接执行
2. **维护困难**：每次调整数值需要修改文本描述，容易出现描述与实际效果不一致
3. **测试困难**：无法对效果进行自动化单元测试
4. **扩展性差**：复杂效果（多目标、条件触发）难以用文本描述

### 影响范围

- 卡牌战斗系统（C2）
- 卡牌升级系统（M5）
- 状态效果系统（C1）
- 地形天气系统（D1）
- 资源管理系统（F2）

---

## 解决方案

### 核心思路

参考敌人行动系统（`enemies-design.md` 第245-277行）的设计模式：

```
敌人行动模板: enemy_actions.csv
  A01: 普通劈砍 → damage=6~10, target=PLAYER

敌人实例: enemies.csv
  action_params_json: "A01:damage=6"
```

转换为卡牌系统：

```
卡牌行动模板: card_actions.csv
  CA01: ATK_PHYSICAL → damage:int, target, piercing

卡牌实例: all_cards.csv
  effect_lv1: "CA01:damage=6"
```

---

## 关键决策

### 决策 1: 行动模板与实例分离

**选择**: 创建独立的 `card_actions.csv` 模板文件

**理由**:
- 与敌人系统保持一致的设计模式
- 模板可复用，减少数据冗余
- 便于调整平衡（修改模板影响所有使用该行动的卡牌）

**替代方案**:
- 内联定义所有行动 → 数据冗余大
- 使用代码定义行动 → 修改需要重新编译

---

### 决策 2: 参数格式规范

**选择**: `action_id:param1=value1&param2=value2;action_id2...`

**理由**:
- 与敌人系统的 `action_params_json` 格式兼容
- 支持多行动（用 `;` 分隔）
- 支持多参数（用 `&` 连接）

**示例**:
```
CA01:damage=6                           # 单行动
CA01:damage=8;CA06:status_id=POISON    # 多行动
CA01:damage=6&target=ENEMY             # 多参数
```

---

### 决策 3: 条件参数语法

**选择**: `IF(condition):true_value;ELSE:false_value`

**理由**:
- 简洁易读
- 支持嵌套
- 与敌人系统的地形/天气修正机制互补

**支持的条件**:
- `terrain=MOUNTAIN` - 当前地形
- `weather=RAIN` - 当前天气
- `target_has_status=POISON` - 目标状态检测

---

### 决策 4: 执行器设计

**选择**: 独立的 `CardActionExecutor` 类

**职责**:
1. 解析参数字符串 → `CardAction` 对象数组
2. 解析条件参数 → 基于 `BattleContext` 动态解析
3. 执行行动 → 调用对应系统接口
4. 返回效果事件 → 用于UI反馈和日志

**依赖**:
- `CardActionRegistry` - 行动模板加载
- `BattleContext` - 战场状态读取
- 各系统接口（DamageCalculator, StatusManager, ResourceManager）

---

### 决策 5: 与现有系统兼容

#### 5.1 卡牌升级系统（M5）

- Lv2 效果存储在独立的 `effect_lv2` 列
- 执行器根据卡牌等级自动选择对应参数
- 不影响现有的升级逻辑

#### 5.2 状态系统（C1）

- `status_id` 参数引用 `status-design.md` 中的状态定义
- 层数、持续时间由状态系统规则处理

#### 5.3 地形天气系统（D1）

- 条件参数执行前查询当前地形/天气
- 与现有的地形修正机制互补（非替代）

#### 5.4 资源管理系统（F2）

- 资源修改行动（HEAL, GAIN_GOLD等）调用对应接口
- 不绕过现有的资源变化验证

---

## 技术细节

### 数据结构

```gdscript
# 行动模板（card_actions.csv）
class CardActionTemplate:
    var action_id: String          # CA01, CA02, etc.
    var action_type: String        # ATK_PHYSICAL, HEAL, etc.
    var required_params: Array     # ["damage:int", "target"]
    var optional_params: Array     # ["piercing:bool"]

# 行动实例（解析后的参数）
class CardAction:
    var action_id: String
    var params: Dictionary         # {damage: 6, target: ENEMY}
    var conditions: Array[Condition]
    var trigger: String            # IMMEDIATE, AFTER_DRAW

# 条件参数
class Condition:
    var field: String              # terrain, weather, target_status
    var operator: String           # =, !=
    var value: Variant
    var true_branch: Dictionary    # 条件为真时的参数
    var false_branch: Dictionary   # 条件为假时的参数（可选）

# 战场上下文
class BattleContext:
    var current_terrain: String
    var current_weather: String
    var caster: BattleEntity
    var target: BattleEntity
    var hand_cards: Array[CardData]
```

### 执行流程

```
1. 玩家打出卡牌
       ↓
2. CardManager 加载卡牌数据
       ↓
3. CardActionExecutor 解析 effect_lv1/effect_lv2
       ↓
4. 对于每个行动：
   a. 解析条件参数（IF/ELSE）
   b. 查询 BattleContext
   c. 替换条件参数为实际值
   d. 调用对应系统接口执行
       ↓
5. 返回 EffectEvent 数组（用于UI反馈）
       ↓
6. 卡牌进入弃牌堆/手牌/移除区
```

---

## 影响分析

### 对现有系统的影响

| 系统 | 影响 | 兼容性 |
|------|------|--------|
| C2 卡牌战斗 | 需集成 CardActionExecutor | ✅ 兼容 |
| M5 卡牌升级 | effect_lv2 列需填充 | ⚠️ 需迁移 |
| C1 状态系统 | 无影响 | ✅ 兼容 |
| D1 地形天气 | 条件参数新增依赖 | ✅ 兼容 |
| F2 资源管理 | 无影响 | ✅ 兼容 |

### 数据迁移

- 现有 `effect_description` 列保留（用于UI显示）
- 新增 `effect_lv1`, `effect_lv2` 列（用于执行）
- 需批量工具将现有描述转换为参数（人工或脚本）

---

## 验收标准

| 标准 | 描述 |
|------|------|
| AC-CAS-01 | 基础攻击卡正确造成指定数值伤害 |
| AC-CAS-02 | 状态施加卡正确添加状态和层数 |
| AC-CAS-03 | 多行动卡牌按顺序执行所有效果 |
| AC-CAS-04 | 地形条件正确判断并应用对应参数 |
| AC-CAS-05 | 天气条件正确判断并应用对应参数 |
| AC-CAS-06 | Lv2效果在升级后正确加载 |
| AC-CAS-07 | 资源修改正确反映到资源管理器 |
| AC-CAS-08 | 执行器正确处理无效参数 |

---

## 风险与缓解

### 风险 1: 迁移成本

**描述**: 现有 200+ 张卡牌需要转换为新格式

**缓解**: 
- 提供批量转换工具
- 分阶段迁移（先迁移攻击卡，再迁移技能卡）
- 保留旧格式作为回退

### 风险 2: 条件语法复杂度

**描述**: 复杂的条件嵌套难以解析和维护

**缓解**:
- 限制条件嵌套深度（最多2层）
- 提供 IDE 语法高亮
- 单元测试覆盖所有条件组合

### 风险 3: 性能影响

**描述**: 每次打出卡牌需要解析参数字符串

**缓解**:
- 解析结果缓存（CardData 级别）
- 条件参数预计算（地形/天气不常变化）

---

## 相关 ADR

- **ADR-0008**: 敌人系统设计
- **ADR-0019**: 敌人行动参数系统
- **ADR-0007**: 卡牌战斗系统
- **ADR-0006**: 状态效果系统

---

## 后续工作

1. 创建 `card_actions.csv` 行动模板文件
2. 实现 `CardActionExecutor.gd` 执行器
3. 实现 `CardActionParser.gd` 解析器
4. 修改 `CardManager` 集成执行器
5. 编写单元测试覆盖所有 AC
6. 批量迁移现有卡牌数据
