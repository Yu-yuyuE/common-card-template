# ADR-0006: 状态效果系统架构

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Core / Game Logic |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None — standard GDScript Dictionary/Array APIs |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0002 (系统间通信模式), ADR-0003 (资源变更通知机制) |
| **Enables** | C2 卡牌战斗系统, C3 敌人系统, D2 兵种卡系统, D3 武将系统, D1 地形天气系统 |
| **Blocks** | 所有依赖状态效果的系统 |
| **Ordering Note** | 本 ADR 是 Core 层核心系统，在战斗和敌人系统之前完成 |

## Context

### Problem Statement

游戏需要管理**24种状态效果**（7种Buff + 17种Debuff），包括：
- 状态的施加、持续、消耗、覆盖、刷新机制
- 同类状态叠加，不同类互斥
- 状态伤害计算（穿透护盾 vs 走护盾）
- **治疗与护盾修正**（新增：流血-50%治疗，生锈-50%护盾）
- 状态与战斗、资源、地图等系统的集成

### Constraints
- **性能**: 状态计算每回合执行，需高效
- **一致性**: 所有状态遵循统一规则
- **可调试**: 状态变化需可追踪

### Requirements
- 必须支持22种状态（7 Buff + 15 Debuff）
- 必须支持同类叠加、不同类互斥
- 必须支持状态伤害穿透/走护盾
- 必须支持治疗/护盾修正（流血/生锈）
- 必须支持回合结束时状态消耗

## Decision

### 方案: 集中式 StatusManager + 事件驱动

采用 **统一状态管理器 + Signal 驱动** 模式：

```gdscript
# status_manager.gd
class_name StatusManager extends Node

# 状态类型枚举
enum StatusType { BUFF, DEBUFF }

# 状态分类
enum StatusCategory {
    # Buffs
    FURY,        # 怒气 - 攻击伤害+25%
    SWIFT,       # 迅捷 - 50%闪避
    BLOCK,       # 格挡 - 抵挡一次攻击
    DEFEND,      # 坚守 - 受到伤害-25%
    COUNTER,     # 反击 - 受击反击50%伤害
    PIERCE,      # 穿透 - 无视护甲
    IMMUNE,      # 免疫 - 免疫负面状态
    
    # Debuffs
    POISON,      # 中毒 - 4伤害/层，穿透护盾
    TOXIC,       # 剧毒 - 7伤害/层，穿透护盾
    FEAR,        # 恐惧 - 额外伤害=层数
    CONFUSION,   # 混乱 - 攻击友军
    BLIND,       # 盲目 - 命中率50%
    SLIP,        # 滑倒 - 无法攻击
    BROKEN,      # 破甲 - 受伤害+25%
    WEAK,        # 虚弱 - 攻击伤害-25%
    BURN,        # 灼烧 - 5伤害/层，走护盾
    PLAGUE,      # 瘟疫 - 3伤害/层，传播
    STUN,        # 眩晕 - 停止行动
    BLEED,       # 重伤 - 1伤害/层
    BLEEDING,    # 流血 - 治疗量-50%
    RUST,        # 生锈 - 护盾量-50%
    FROSTBITE    # 冻伤 - 攻击HP-1
}

# 状态数据结构
class StatusEffect:
    var type: StatusType          # BUFF or DEBUFF
    var category: StatusCategory  # 具体状态
    var layers: int               # 层数
    var max_layers: int           # 最大层数（可选）
    var damage_per_layer: int     # 每层伤害
    var penetrates_shield: bool   # 是否穿透护盾
    var is_consumable: bool       # 是否消耗型（触发后消失）
    var source: String            # 施加来源

# Signal 定义
signal status_applied(target: Node, status: StatusEffect)
signal status_removed(target: Node, category: StatusCategory)
signal status_refreshed(target: Node, category: StatusCategory, new_layers: int)
signal status_damage_dealt(target: Node, damage: int, category: StatusCategory)

# 状态存储: target_node -> [StatusEffect...]
var _status_map: Dictionary = {}

# === 核心接口 ===

func apply_status(target: Node, category: StatusCategory, layers: int, source: String = "") -> void:
    var status = _create_status(category, layers, source)
    
    if not _status_map.has(target):
        _status_map[target] = []
    
    var existing = _find_status(target, category)
    
    if existing != null:
        # 同类状态：刷新（取较高层数）
        existing.layers = max(existing.layers, layers)
        status_refreshed.emit(target, category, existing.layers)
    else:
        # 检查不同类互斥
        _handle_exclusive(target, status)
        _status_map[target].append(status)
    
    status_applied.emit(target, status)

func remove_status(target: Node, category: StatusCategory) -> bool:
    if not _status_map.has(target):
        return false
    
    var status_list = _status_map[target]
    for i in range(status_list.size()):
        if status_list[i].category == category:
            var removed = status_list.pop_at(i)
            status_removed.emit(target, category)
            
            if status_list.is_empty():
                _status_map.erase(target)
            return true
    return false

func get_status(target: Node, category: StatusCategory) -> int:
    if not _status_map.has(target):
        return 0
    var status = _find_status(target, category)
    return status.layers if status != null else 0

func has_status_type(target: Node, status_type: StatusType) -> bool:
    if not _status_map.has(target):
        return false
    for s in _status_map[target]:
        if s.type == status_type:
            return true
    return false

func is_immune(target: Node) -> bool:
    return get_status(target, StatusCategory.IMMUNE) > 0

# === 回合结算 ===

func tick_status(target: Node) -> void:
    """回合结束时调用，处理状态消耗和持续伤害"""
    if not _status_map.has(target):
        return
    
    var status_list = _status_map[target].duplicate()
    var to_remove: Array[StatusCategory] = []
    
    # 先处理持续伤害
    for status in status_list:
        if status.damage_per_layer > 0:
            var total_damage = status.layers * status.damage_per_layer
            _apply_damage(target, total_damage, status)
    
    # 再处理层数消耗
    for status in status_list:
        if status.is_consumable:
            # 消耗型状态消耗1层
            status.layers -= 1
            if status.layers <= 0:
                to_remove.append(status.category)
        else:
            # 持续型状态每回合-1层
            status.layers -= 1
            if status.layers <= 0:
                to_remove.append(status.category)
    
    # 移除过期状态
    for category in to_remove:
        remove_status(target, category)

# === 伤害计算 ===

func calculate_damage_modifier(target: Node, base_damage: int) -> int:
    """计算状态修正后的伤害（用于攻击方）"""
    if not _status_map.has(target):
        return base_damage
    
    var modifier = 1.0
    var status_list = _status_map[target]
    
    for status in status_list:
        match status.category:
            StatusCategory.FURY:
                modifier *= 1.25  # +25%
            StatusCategory.WEAK:
                modifier *= 0.75  # -25%
            StatusCategory.BROKEN:
                modifier *= 1.25  # +25% 受击
    
    return int(base_damage * modifier)

func calculate_incoming_damage(target: Node, incoming_damage: int) -> int:
    """计算受到攻击时的最终伤害（考虑状态）"""
    if not _status_map.has(target):
        return incoming_damage
    
    var final_damage = incoming_damage
    var status_list = _status_map[target]
    
    # 先计算固定修正
    for status in status_list:
        match status.category:
            StatusCategory.DEFEND:
                final_damage = int(final_damage * 0.75)  # -25%
            StatusCategory.FEAR:
                final_damage += get_status(target, StatusCategory.FEAR)
            StatusCategory.BROKEN:
                final_damage = int(final_damage * 1.25)  # +25%
    
    # 盲目：50%命中率
    if get_status(target, StatusCategory.BLIND) > 0:
        if randf() > 0.5:
            return 0  # 闪避
    
    return max(0, final_damage)

# === 内部方法 ===

func _create_status(category: StatusCategory, layers: int, source: String) -> StatusEffect:
    var status = StatusEffect.new()
    status.category = category
    status.layers = layers
    status.source = source
    
    # 根据类别初始化属性
    match category:
        StatusCategory.FURY:
            status.type = StatusType.BUFF
        StatusCategory.SWIFT:
            status.type = StatusType.BUFF
        StatusCategory.BLOCK:
            status.type = StatusType.BUFF
            status.is_consumable = true
        StatusCategory.DEFEND:
            status.type = StatusType.BUFF
        StatusCategory.COUNTER:
            status.type = StatusType.BUFF
            status.is_consumable = true
        StatusCategory.PIERCE:
            status.type = StatusType.BUFF
            status.is_consumable = true
        StatusCategory.IMMUNE:
            status.type = StatusType.BUFF
        
        StatusCategory.POISON:
            status.type = StatusType.DEBUFF
            status.damage_per_layer = 4
            status.penetrates_shield = true
        StatusCategory.TOXIC:
            status.type = StatusType.DEBUFF
            status.damage_per_layer = 7
            status.penetrates_shield = true
        StatusCategory.FEAR:
            status.type = StatusType.DEBUFF
        StatusCategory.CONFUSION:
            status.type = StatusType.DEBUFF
            status.is_consumable = true
        StatusCategory.BLIND:
            status.type = StatusType.DEBUFF
        StatusCategory.SLIP:
            status.type = StatusType.DEBUFF
        StatusCategory.BROKEN:
            status.type = StatusType.DEBUFF
        StatusCategory.WEAK:
            status.type = StatusType.DEBUFF
        StatusCategory.BURN:
            status.type = StatusType.DEBUFF
            status.damage_per_layer = 5
            status.penetrates_shield = false  # 走护盾
        StatusCategory.PLAGUE:
            status.type = StatusType.DEBUFF
            status.damage_per_layer = 3
            status.penetrates_shield = true
        StatusCategory.STUN:
            status.type = StatusType.DEBUFF
        StatusCategory.BLEED:
            status.type = StatusType.DEBUFF
            status.damage_per_layer = 1
            status.penetrates_shield = true
        StatusCategory.BLEEDING:
            status.type = StatusType.DEBUFF
            status.is_consumable = false
            status.damage_per_layer = 0
            status.penetrates_shield = false
            # 治疗修正：-50%
        StatusCategory.RUST:
            status.type = StatusType.DEBUFF
            status.is_consumable = false
            status.damage_per_layer = 0
            status.penetrates_shield = false
            # 护盾修正：-50%
        StatusCategory.FROSTBITE:
            status.type = StatusType.DEBUFF
    
    return status

func _find_status(target: Node, category: StatusCategory) -> StatusEffect:
    if not _status_map.has(target):
        return null
    for s in _status_map[target]:
        if s.category == category:
            return s
    return null

func _handle_exclusive(target: Node, new_status: StatusEffect) -> void:
    """处理不同类状态互斥"""
    if not _status_map.has(target):
        return
    
    var status_list = _status_map[target]
    var to_remove: Array[StatusCategory] = []
    
    # Buff 只与 Debuff 互斥，Debuff 之间互斥
    for existing in status_list:
        if new_status.type != existing.type:
            to_remove.append(existing.category)
    
    # 移除互斥状态
    for category in to_remove:
        remove_status(target, category)

func calculate_heal_modifier(target: Node, base_heal: int) -> int:
    """计算状态修正后的治疗量（考虑流血状态）"""
    if not _status_map.has(target):
        return base_heal
    
    var modifier = 1.0
    var status_list = _status_map[target]
    
    # 流血状态：治疗量-50%
    if get_status(target, StatusCategory.BLEEDING) > 0:
        modifier *= 0.5
    
    return int(base_heal * modifier)

func calculate_shield_modifier(target: Node, base_shield: int) -> int:
    """计算状态修正后的护盾量（考虑生锈状态）"""
    if not _status_map.has(target):
        return base_shield
    
    var modifier = 1.0
    var status_list = _status_map[target]
    
    # 生锈状态：护盾量-50%
    if get_status(target, StatusCategory.RUST) > 0:
        modifier *= 0.5
    
    return int(base_shield * modifier)

func _apply_damage(target: Node, damage: int, status: StatusEffect) -> void:
    """应用状态伤害"""
    if status.penetrates_shield:
        # 穿透护盾：直接扣HP
        ResourceManager.modify_resource(ResourceManager.ResourceType.HP, -damage)
    else:
        # 走护盾：护盾先抵挡
        var current_shield = ResourceManager.get_resource(ResourceManager.ResourceType.SHIELD)
        if current_shield > 0:
            var remaining = current_shield - damage
            if remaining >= 0:
                ResourceManager.set_resource(ResourceManager.ResourceType.SHIELD, remaining)
                damage = 0
            else:
                ResourceManager.set_resource(ResourceManager.ResourceType.SHIELD, 0)
                damage = -remaining
        
        if damage > 0:
            ResourceManager.modify_resource(ResourceManager.ResourceType.HP, -damage)
    
    status_damage_dealt.emit(target, damage, status.category)
```

### 状态叠加与互斥规则

```
施加新状态时:
  IF 新状态.category == 已有状态.category:
      已有状态.layers = max(已有状态.layers, 新状态.layers)  # 刷新
  ELSE IF 新状态.type != 已有状态.type:
      移除已有状态  # 不同类型互斥
  ELSE:
      # 同为 BUFF 或同为 DEBUFF，但类别不同
      移除已有状态  # 不同类互斥
```

### 特殊状态交互

| 交互 | 规则 |
|------|------|
| 穿透 vs 格挡 | 穿透攻击绕过格挡，不消耗格挡层数 |
| 免疫 vs 负面 | 免疫状态下无法施加任何 Debuff |
| 免疫 vs 正面 | 免疫状态下仍可施加 Buff |
| 混乱目标无友军 | 攻击取消，混乱层数-1 |
| 瘟疫传播 | 回合结束时，感染单位周围紧邻单位获得1层瘟疫 |
| 流血修正治疗 | 流血状态存在时，所有治疗量-50% |
| 生锈修正护盾 | 生锈状态存在时，所有获得的护盾量-50% |

## Alternatives Considered

### Alternative 1: 分布式状态管理
- **描述**: 每个单位自己管理状态
- **优点**: 简单
- **缺点**: 难以统一跟踪和调试
- **未采用原因**: 不符合 ADR-0003 的集中式资源管理原则

### Alternative 2: 组件式状态
- **描述**: 每个状态作为一个独立组件
- **优点**: 灵活
- **缺点**: 性能开销大，管理复杂
- **未采用原因**: 20种状态会导致大量组件

### Alternative 3: 集中式 StatusManager (推荐方案)
- **描述**: 统一管理器 + 事件驱动
- **优点**: 统一接口，易于调试，符合架构原则
- **采用原因**: 与现有架构一致

## Consequences

### Positive
- **统一接口**: 所有系统通过 StatusManager 交互
- **易于调试**: Signal 可追踪所有状态变化
- **性能好**: 字典查找 O(1)
- **符合架构**: 与 ADR-0002/0003 一致

### Negative
- **单点风险**: StatusManager 是单点，需确保不崩溃
- **学习曲线**: 20种状态需要理解

### Risks
- **状态组合bug**: 某些组合可能未考虑
  - **缓解**: 详细的边界情况测试
- **性能**: 大量状态计算
  - **缓解**: 按需计算，非每帧轮询

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| status-design.md | 7种Buff + 15种Debuff | StatusCategory 枚举覆盖所有22种 |
| status-design.md | 同类叠加/不同类互斥 | _handle_exclusive() 实现互斥逻辑 |
| status-design.md | 状态伤害计算 | calculate_incoming_damage() + _apply_damage() |
| status-design.md | 回合结束消耗 | tick_status() 每回合调用 |
| status-design.md | 穿透护盾/走护盾 | penetrates_shield 字段区分 |
| status-design.md | 治疗/护盾修正 | 新增 BLEEDING 和 RUST 状态，实现治疗量-50%和护盾量-50%修正 |

## Performance Implications
- **CPU**: 状态查找 O(1)，每回合结算 < 1ms
- **Memory**: 每个单位状态约 200 字节

## Migration Plan
1. 创建 StatusManager.gd
2. 实现20种状态的数据结构
3. 实现 apply/remove/get/tick 接口
4. 与 ResourceManager 集成
5. 编写单元测试覆盖所有边界情况
6. 与战斗系统集成

## Validation Criteria
- [ ] 24种状态都可以正确施加
- [ ] 同类状态叠加层数
- [ ] 不同类状态互斥覆盖
- [ ] 回合结束时状态正确消耗
- [ ] 穿透护盾和走护盾正确区分
- [ ] 免疫状态阻止 Debuff
- [ ] Signal 正确发出所有状态变化
- [ ] 流血状态正确减少50%治疗量
- [ ] 生锈状态正确减少50%护盾量

## Related Decisions
- ADR-0001 (已 Accepted): 场景管理策略
- ADR-0002 (已 Accepted): 系统间通信模式
- ADR-0003 (已 Accepted): 资源变更通知机制
- ADR-000? (待创建): 卡牌战斗系统 — 依赖本 ADR
- ADR-000? (待创建): 敌人系统 — 依赖本 ADR
