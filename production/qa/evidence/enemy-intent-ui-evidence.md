# Enemy Intent UI - 证据文档 (Story 007)

## 测试信息

- **Story**: production/epics/enemy-system/story-007-enemy-intent-ui.md
- **Story Type**: UI
- **测试日期**: 2026-04-11
- **测试人员**: Claude Code (AI Programmer)

---

## 验收标准验证

### AC-1: 意图显示准确

**测试步骤**:
1. 玩家回合开始
2. 观察敌人头顶显示的意图（如：防守、攻击 12）
3. 等待敌人回合执行
4. 验证实际执行的行动与显示的意图一致

**预期结果**:
- 敌人头顶显示即将执行的操作
- 显示内容与随后敌人回合实际作出的动作完全吻合

**实际实现**:
- ✅ `EnemyIntentUI.update_intent_display()` 方法实现了意图显示
- ✅ 根据行动类型（attack/defend/heal等）显示不同文本和图标颜色
- ✅ 攻击类行动提取伤害值显示为"攻击 X点"
- ✅ `EnemyView.refresh_intent_display()` 在玩家回合开始时调用 `get_displayed_action()`

**验证方式**:
- 代码逻辑正确，调用链路清晰：BattleManager.turn_started → EnemyView._on_turn_started → refresh_intent_display → EnemyIntentUI.update_intent_display
- 使用 EnemyManager.get_displayed_action() 获取公示行动，该行动不推进计数器，与实际执行行动一致

---

### AC-2: 蓄力特殊提示

**测试步骤**:
1. 敌人进入蓄力技能的前置回合
2. 检查UI上是否明确提示"蓄力"
3. 验证非普通攻击显示

**预期结果**:
- UI上明确提示"蓄力"，而非普通攻击

**实际实现**:
- ✅ `EnemyIntentUI.update_intent_display()` 检查 `is_charging` 标志
- ✅ 蓄力时显示"蓄力中..."，文本颜色设为红色
- ✅ 蓄力指示器（charging_indicator）可见
- ✅ `show_charging_preview()` 方法支持显示"蓄力：当前行动 → 下回合行动"

**验证方式**:
- 代码检查了 action_data.get("is_charging", false)
- 蓄力状态时 intent_label.text = "蓄力中..."
- charging_indicator.visible = true

---

### AC-3: 动态血量更新

**测试步骤**:
1. 使用卡牌攻击敌人
2. 观察被击中瞬间敌人血条和数值是否立即下调

**预期结果**:
- 被击中瞬间，敌人血条和数值立刻下调

**实际实现**:
- ✅ `EnemyIntentUI.update_hp_display()` 实时更新血量文本和进度条
- ✅ `EnemyView.refresh_hp_display()` 在卡牌打出后调用
- ✅ `EnemyView.on_enemy_damaged()` 播放受击动画（红色闪烁）
- ✅ 血量进度条根据百分比变色（绿>50% > 黄>25% > 红）

**验证方式**:
- update_hp_display 计算并更新 HPProgressBar.value
- hp_label.text 显示 "当前HP/最大HP" 格式
- on_enemy_damaged 使用 Tween 实现受击动画

---

## 代码实现证据

### 核心文件

1. **src/ui/EnemyIntentUI.gd** (167行)
   - 血量显示：HPLabel + HPProgressBar
   - 意图显示：IntentLabel + IntentIcon
   - 蓄力指示器：CharingIndicator
   - 支持动态颜色和图标设置

2. **src/ui/EnemyView.gd** (100行)
   - 集成 EnemyIntentUI 组件
   - 连接 BattleManager 信号（turn_started, card_played）
   - 实现点击选择目标（enemy_clicked 信号）
   - 受击动画（Tween 红色闪烁）

### 信号连接

```gdscript
# EnemyView._connect_battle_signals()
battle_manager.turn_started.connect(_on_turn_started)
battle_manager.card_played.connect(_on_card_played)
```

### 意图刷新流程

```gdscript
# 玩家回合开始时
BattleManager.turn_started(is_player=true)
  ↓
EnemyView._on_turn_started(is_player=true)
  ↓
EnemyView.refresh_intent_display()
  ↓
EnemyManager.get_displayed_action(enemy_id)
  ↓
EnemyIntentUI.update_intent_display(action_data)
```

### 血量更新流程

```gdscript
# 敌人受击时
EnemyView.on_enemy_damaged(damage)
  ↓
EnemyIntentUI.update_hp_display()
  ↓
更新 HPLabel.text 和 HPProgressBar.value
```

---

## 测试场景需求

由于这是UI Story，需要创建Godot场景文件进行可视化验证：

1. **EnemyView.tscn** (待创建)
   - Control 节点作为根节点
   - EnemyIntentUI 子节点
   - Sprite2D 用于敌人模型
   - 各UI组件布局合理

2. **测试数据**
   - 创建测试敌人数据（E001 黄巾力士）
   - 设置行动序列：A04→A01→A01
   - 验证意图轮换显示

---

## 已知限制

1. **图标资源缺失**
   - IntentIcon 当前使用颜色代替纹理
   - TODO: 添加实际的行动图标资源

2. **场景文件未创建**
   - EnemyView.tscn 和 EnemyIntentUI.tscn 需要在Godot编辑器中创建
   - 当前仅提供GDScript逻辑

3. **动画未完全实现**
   - 死亡动画未实现（on_enemy_death 仅隐藏节点）
   - TODO: 添加死亡特效或播放动画

---

## 结论

**AC-1**: ✅ 已实现
**AC-2**: ✅ 已实现
**AC-3**: ✅ 已实现

所有验收标准的代码逻辑已实现，需要创建Godot场景文件进行可视化验证。

建议下一步：
1. 在Godot编辑器中创建 EnemyView.tscn 和 EnemyIntentUI.tscn
2. 添加测试敌人进行可视化验证
3. 补充图标资源和动画
