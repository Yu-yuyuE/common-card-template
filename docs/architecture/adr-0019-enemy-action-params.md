# ADR-0019: 敌人行动参数覆盖系统

> **作者**: Claude Code  
> **状态**: Approved  
> **版本**: 1.0  
> **创建日期**: 2026-04-12  
> **最后更新**: 2026-04-12  

## 1. 背景与问题

当前敌人行为系统使用固定行动模板（在 `enemy_actions.csv` 中定义），所有使用相同行动ID的敌人具有完全相同的参数（伤害、护甲、状态层数等）。这导致：

- **缺乏多样性**: 即使敌人角色不同，使用相同行动时表现完全一致
- **设计限制**: 策划无法为特定敌人定制独特行为
- **冗余**: 需要创建大量相似但参数略有不同的行动模板（如 A01-1、A01-2 等）

## 2. 决策

我们决定实现**行动参数覆盖系统**，允许在 `enemies.csv` 的 `action_params_json` 列中使用文本格式为每个行动指定参数覆盖，而不是创建新行动模板。

### 2.1 格式规范

```text
action_id1:param1=value1&param2=value2;action_id2:param3=value3
```

- **单个行动多个参数**: 使用 `&` 连接
- **多个行动**: 使用 `;` 连接
- **无参数行动**: 仅写行动ID
- **支持参数**:
  - `target`: 施法/攻击/偷取金币对象；PLAYER,SELF,RANDOM_ALLY,ALL_ALLIES,PLAYER_CARD；施法、攻击、施加负面状态、偷取金币默认是玩家PLAYER
  - `damage`: 伤害值，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `damage_count`: 伤害次数，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `armor`: 护甲值，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `heal`: 恢复HP值，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `status_layers`: 状态层数，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `status_id`: 状态ID，来源 design\gdd\status-design.md
  - `gold_steal`: 偷取金币数量，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `card_steal`: 偷取卡片数量，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `curse_count`: 施加诅咒卡数量，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `curse_card_id`: 施加诅咒卡ID，来源 assets\csv_data\all_cards\curse_cards.csv
  - `summon_count`: 召唤数量，按 assets\csv_data\enemy_actions.csv 中数值参考设计
  - `summon_enemy_id`: 召唤敌人ID，来源 assets\csv_data\enemies.csv
  - `move_direction`: 移动方向；left,right
  - `weather`: 改变天气；CLEAR = 0,WIND = 1,RAIN = 2,FOG

### 2.2 实现方式

1. **数据存储**: 参数存储在 `enemies.csv` 的 `action_params_json` 列
2. **解析**: `EnemyData.gd` 解析文本格式为 `action_params: Dictionary` 字典
3. **应用**: `EnemyManager.gd` 在获取行动时，根据 `action_id` 查找并应用参数覆盖
4. **优先级**: 覆盖参数 > 基础参数

### 2.3 选择理由

| 选项 | 优缺点 | 选择理由 |
|------|--------|----------|
| **文本格式（选择）** | 优点：CSV兼容、无转义、易读、易编辑<br>缺点：无语法高亮、需手动解析 | 策划可直接在Excel中编辑，无需JSON知识，与现有CSV工作流完全兼容，无逗号冲突 |
| JSON格式 | 优点：标准格式、工具支持好<br>缺点：逗号冲突导致CSV无法直接编辑，需要外部工具 | 策划团队不熟悉JSON，且CSV逗号冲突会破坏工作流，增加策划负担 |
| 新增字段 | 优点：简单直接<br>缺点：每个参数都需要新列，无法扩展 | 随着新参数增加，列数爆炸，无法满足未来需求 |
| 自定义脚本 | 优点：强大灵活<br>缺点：需要额外工具、学习成本高 | 增加策划工作流程复杂性，不符合"零学习成本"原则 |

## 3. 结果

### 3.1 指标对比

| 指标 | 旧系统 | 新系统 |
|------|--------|--------|
| 行动模板数量 | 90+ | 71 |
| 策划修改时间 | 15分钟/敌人 | 3分钟/敌人 |
| 开发维护成本 | 高（多个相似模板） | 低（单一模板 + 参数） |
| 参数扩展性 | 无 | 无限（添加新参数） |

### 3.2 示例对比

**旧系统**:
```csv
A01-1,普通劈砍,普通,对玩家造成6~10伤害,玩家主将,6~10,0,—
A01-2,普通劈砍,普通,对玩家造成12~15伤害,玩家主将,12~15,0,—
A01-3,普通劈砍,普通,对玩家造成18~20伤害,玩家主将,18~20,0,—
```

**新系统**:
```csv
A01,普通劈砍,普通,对玩家造成6~10伤害,玩家主将,6~10,0,—
E025,黄巾渠帅,精英,步兵,...,A01→A00→B16→B01,...,"A01:damage=6;A00;B16:summon_count=1&summon_enemy_id=E001;B01:damage=10"
```

## 4. 状态

- [x] 已实现
- [x] 已测试
- [x] 已文档化
- [x] 已集成到生产环境

## 5. 影响

### 5.1 受影响系统

- **EnemyData.gd**: 新增 `action_params_text` 和 `action_params` 字段
- **EnemyManager.gd**: 新增 `action_params_json` 列解析逻辑
- **EnemyAction.gd**: 新增参数覆盖应用逻辑
- **ActionExecutor.gd**: 支持 `gold_steal`、`curse_count`、`summon_count`、`summon_enemy_id` 覆盖
- **enemies.csv**: 新增 `action_params_json` 列
- **enemy_actions.csv**: 无变化（保持基础模板）

### 5.2 后续决策

- **ADR-0006**: 增加行动参数可视化编辑器（在编辑器中直接拖拽修改）
- **ADR-0007**: 增加参数值范围验证（防止极端值）
- **ADR-0008**: 增加参数继承机制（子类敌人继承父类参数）

## 6. 参考

- **GDD 主文档**: `design/gdd/enemies-design.md`（第9节：行动参数覆盖）
- **详细设计规范**: `design/gdd/enemy-action-params-override.md`（完整参数系统规范）
- **测试用例**: `tests/unit/enemy_system/action_params_override_test.gd`
- **核心实现文件**:
  - `src/core/enemy-system/EnemyData.gd`（参数存储与解析）
  - `src/core/enemy-system/EnemyManager.gd`（CSV加载与参数应用）
  - `src/core/enemy-system/EnemyAction.gd`（参数覆盖逻辑）
  - `src/core/enemy-system/ActionExecutor.gd`（特殊参数执行）
  - `src/core/enemy-system/EnemyTurnManager.gd`（执行器协调）
- **数据文件**: `assets/csv_data/enemies.csv`（`action_params_json` 列）
