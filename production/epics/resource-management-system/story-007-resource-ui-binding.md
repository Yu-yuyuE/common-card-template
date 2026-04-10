# Story 007: 资源变化UI响应

> **Epic**: 资源管理系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/resource-management-system.md`
**Requirement**: `TR-resource-management-system-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: 系统间通信模式
**ADR Decision Summary**: 采用双层通信架构，全局事件使用EventBus，UI订阅resource_changed信号更新显示。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: UI必须通过Signal驱动的响应式模式：数据变化→Signal广播→UI订阅更新
- Required: UI必须响应资源变化（HP、金币、粮草、行动点等）
- Forbidden: 禁止在代码中使用硬编码字符串
- Forbidden: 禁止使用手动刷新(Polling)方式更新UI

---

## Acceptance Criteria

*From GDD `design/gdd/resource-management-system.md`, scoped to this story:*

- [ ] HP条响应resource_changed信号，显示当前/上限数值
- [ ] 护盾值在HP条上方显示，独立颜色（蓝色）
- [ ] 行动点用离散图标显示（每点一个图标），当前费用高亮
- [ ] 粮草在地图界面显示图标+数字，低于30时变色警示
- [ ] HP归零时触发战斗失败UI提示

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

1. UI订阅EventBus.resource_changed信号：
   ```gdscript
   # HUD.gd
   func _ready():
       EventBus.resource_changed.connect(_on_resource_changed)
   
   func _on_resource_changed(type: String, old_val: int, new_val: int, delta: int):
       match type:
           ResourceManager.ResourceType.HP:
               update_hp_display(new_val)
           ResourceManager.ResourceType.ARMOR:
               update_armor_display(new_val)
           ResourceManager.ResourceType.ACTION_POINTS:
               update_ap_display(new_val)
           ResourceManager.ResourceType.PROVISIONS:
               update_provisions_display(new_val)
   ```

2. HP条实现：
   ```gdscript
   func update_hp_display(new_val: int):
       $HealthBar.value = new_val
       $HealthBar.max_value = resource_manager.get_max_hp()
       $HealthLabel.text = str(new_val) + "/" + str(resource_manager.get_max_hp())
       
       # 低血量警示（<30%）
       if new_val < resource_manager.get_max_hp() * 0.3:
           $HealthBar.modulate = Color.RED  # 或播放闪烁动画
   ```

3. 护盾显示：
   ```gdscript
   func update_armor_display(new_val: int):
       $ArmorLabel.text = str(new_val)
       $ArmorLabel.modulate = Color.BLUE
       $ArmorLabel.visible = new_val > 0
   ```

4. 行动点图标：
   ```gdscript
   func update_ap_display(new_val: int):
       for i in range($APIcons.get_child_count()):
           var icon = $APIcons.get_child(i)
           icon.visible = i < new_val
           icon.modulate = Color.WHITE if i < new_val else Color.GRAY
   ```

5. 粮草警示：
   ```gdscript
   func update_provisions_display(new_val: int):
       $ProvisionsLabel.text = str(new_val)
       $ProvisionsLabel.modulate = Color.RED if new_val < 30 else Color.WHITE
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: resource_changed信号的触发逻辑
- Story 007: 其他UI元素（手牌显示、敌人血量）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — manual verification steps]:**

- **AC-1**: HP条响应
  - Setup: 启动战斗，HP=50/50
  - Verify: 受到10点伤害后，HP条变为40/50，数字更新
  - Pass condition: HP条平滑过渡，数字正确

- **AC-2**: 护盾显示
  - Setup: 获得10护盾
  - Verify: 护盾值显示在HP条上方，颜色为蓝色
  - Pass condition: 护盾值正确显示，颜色区分明显

- **AC-3**: 行动点图标
  - Setup: 武将基础AP=4，当前AP=3
  - Verify: 3个图标高亮（白色），1个灰色
  - Pass condition: 图标数量正确，颜色区分明显

- **AC-4**: 粮草警示
  - Setup: 粮草=35
  - Verify: 粮草颜色为白色
  - Pass condition: 粮草=29时变为红色

- **AC-5**: HP归零提示
  - Setup: HP=5
  - Verify: 受到10点伤害，HP归零
  - Pass condition: 战斗失败UI提示弹出

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/resource-ui-binding-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002（resource_changed信号触发）
- Unlocks: 无（UI层是最终消费者）
