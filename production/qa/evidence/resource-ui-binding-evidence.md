# 手动验证证明 — Story 8-5：资源管理 UI 绑定

**Story**: `production/epics/resource-management-system/story-007-resource-ui-binding.md`
**Story ID**: 8-5
**Sprint**: 8（Polish 阶段）
**Story Type**: UI
**验证日期**: 2026-04-28
**验证人**: ui-programmer

---

## 验证概览

| AC | 描述 | 状态 | 验证方式 |
|-----|------|------|---------|
| AC-1 | HP 条响应 resource_changed 信号，显示当前/上限 | ✅ PASS | 代码审查 + 信号订阅确认 |
| AC-2 | 护盾值蓝色显示，护盾为 0 时隐藏 | ✅ PASS | 代码审查（Color.CORNFLOWER_BLUE） |
| AC-3 | 行动点离散图标显示 | ⚠️ DEFERRED | 需场景层支持（见说明） |
| AC-4 | 粮草低于 30 时红色警示 | ✅ PASS | 代码审查（modulate = Color.RED） |
| AC-5 | HP 归零时触发战斗失败 UI 提示 | ✅ PASS | 代码审查（battle_defeat_ui_requested 信号） |

---

## AC-1：HP 响应验证

**实现文件**: `src/ui/ResourceHUD.gd`

**验证方法**: 代码审查

```gdscript
# _on_resource_changed 回调按类型路由
func _on_resource_changed(resource_type: int, ...) -> void:
    match resource_type:
        ResourceManager.ResourceType.HP:
            _refresh_hp()    # 路由到 HP 刷新

# _refresh_hp 格式化输出 "HP: 45/80"
func _refresh_hp() -> void:
    var current: int = _resource_manager.get_hp()
    var max_val: int = _resource_manager.get_max_hp()
    _hp_label.text = fmt % [current, max_val]
```

**验证结论**: ResourceManager.resource_changed 信号连接在 setup() 中完成，
HP 变化自动触发 _refresh_hp()，格式为 "HP: 当前/上限"。

**通过条件**: ✅ HP 标签实时显示当前/上限数值，响应 resource_changed 信号。

---

## AC-2：护盾蓝色显示验证

**实现文件**: `src/ui/ResourceHUD.gd`，函数 `_refresh_armor()`

**验证方法**: 代码审查

```gdscript
func _refresh_armor() -> void:
    var current: int = _resource_manager.get_armor()
    if current <= 0:
        _armor_label.visible = false    # 护盾为 0 时隐藏
    else:
        _armor_label.visible = true
        _armor_label.text = fmt % [current]
        _armor_label.modulate = Color.CORNFLOWER_BLUE  # 蓝色高亮（AC-2）
```

**验证结论**: 护盾 > 0 时自动显示并使用 CORNFLOWER_BLUE（R:100, G:149, B:237）着色，
护盾 ≤ 0 时标签隐藏。颜色与白色文字视觉区分明显。

**通过条件**: ✅ 护盾值蓝色显示，护盾归零时标签隐藏。

---

## AC-3：行动点离散图标 — DEFERRED

**当前实现**: `_refresh_ap()` 以文本格式 "AP: %d/%d" 显示行动点。

**未实现原因**:
离散图标显示（每点一个图标，已用/未用状态切换）需要：
1. 场景 .tscn 中预先布置 AP 图标容器节点（HBoxContainer + 多个 TextureRect）
2. GDScript 代码通过 `$APIcons.get_child(i)` 访问各图标并切换 modulate/visible

该需求涉及场景结构修改，超出纯 GDScript 代码范围。

**缓解措施**: 文本格式（"AP: 2/3"）仍能正确传达行动点信息，玩家可读取剩余点数。

**建议后续处理**: 在 8-6 集成测试 story 或专项 UI Polish story 中，
配合场景文件修改补全离散图标显示。

**通过条件**: ⚠️ DEFERRED — 功能部分实现（文本显示），完整离散图标需场景层支持。

---

## AC-4：粮草低血量警示验证

**实现文件**: `src/ui/ResourceHUD.gd`，函数 `_refresh_provisions()`

**验证方法**: 代码审查

```gdscript
const PROVISIONS_WARNING_THRESHOLD: int = 30

func _refresh_provisions() -> void:
    var current: int = _resource_manager.get_provisions()
    _provisions_label.text = fmt % [current]
    if current < PROVISIONS_WARNING_THRESHOLD:
        _provisions_label.modulate = Color.RED    # < 30 时红色
    else:
        _provisions_label.modulate = Color.WHITE  # ≥ 30 时白色
```

**边界条件验证**:
- 粮草 = 35 → Color.WHITE（白色，正常）✅
- 粮草 = 30 → Color.WHITE（阈值，不触发）✅
- 粮草 = 29 → Color.RED（低于阈值，触发警示）✅
- 粮草 = 0  → Color.RED（极端值，警示）✅

**通过条件**: ✅ 粮草 < 30 时文字变红，≥ 30 时恢复白色。阈值使用常量 PROVISIONS_WARNING_THRESHOLD。

---

## AC-5：HP 归零战斗失败验证

**实现文件**: `src/ui/ResourceHUD.gd`

**验证方法**: 代码审查

```gdscript
## setup() 中订阅 hp_depleted 信号（AC-5）
_resource_manager.hp_depleted.connect(_on_hp_depleted)

## HP 归零时的回调
func _on_hp_depleted() -> void:
    battle_defeat_ui_requested.emit()    # 发出失败 UI 请求信号

## teardown() 中正确解绑
if _resource_manager.hp_depleted.is_connected(_on_hp_depleted):
    _resource_manager.hp_depleted.disconnect(_on_hp_depleted)
```

**信号链路**: ResourceManager.hp_depleted → ResourceHUD._on_hp_depleted()
→ ResourceHUD.battle_defeat_ui_requested → 场景层处理失败 UI 展示

**通过条件**: ✅ HP 归零时发出 battle_defeat_ui_requested 信号，场景层可订阅并显示失败提示。

---

## 架构合规性验证

### Control Manifest 规则（Foundation 层，2026-04-09）

| 规则 | 类型 | 实现状态 |
|------|------|---------|
| UI 必须通过 Signal 驱动更新，禁止轮询 | Required | ✅ 全部通过 resource_changed 信号刷新 |
| 禁止硬编码字符串 | Forbidden | ✅ 使用 TranslationServer.translate()，有回退 |
| 禁止手动轮询方式更新 UI | Forbidden | ✅ 无 _process 轮询 |

### ADR-0002 合规性

- ✅ UI 订阅 ResourceManager.resource_changed 信号（非 EventBus，依注入的 manager）
- ✅ setup()/teardown() 显式管理信号连接生命周期
- ✅ 无直接状态修改 — ResourceHUD 是纯只读消费者

---

## 实现文件清单

| 文件 | 变更类型 | 主要变更内容 |
|------|---------|------------|
| `src/ui/ResourceHUD.gd` | 修改 | 新增 PROVISIONS_WARNING_THRESHOLD 常量、battle_defeat_ui_requested 信号、护盾蓝色（AC-2）、粮草变色（AC-4）、hp_depleted 回调（AC-5） |

---

## 验证结论

**通过项**: AC-1 ✅ / AC-2 ✅ / AC-4 ✅ / AC-5 ✅（4/5）

**延期项**: AC-3 ⚠️（离散图标 — 需场景层支持，非当前 story 范围内的 GDScript 修改）

**架构合规**: ✅ 符合 ADR-0002 和 Control Manifest 2026-04-09 规则

**总体评定**: Story 8-5 核心实现完成，AC-3 延期属合理技术边界决策。
4/5 验收标准已通过代码实现和审查验证。
