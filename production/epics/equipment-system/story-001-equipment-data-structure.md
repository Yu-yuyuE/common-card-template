# Story: 装备数据结构与部位定义

> **Type**: Logic
> **Epic**: equipment-system
> **ADR**: ADR-0004, ADR-0007
> **Status**: Ready

## Context

装备系统需要定义5个部位的装备数据结构。60件装备分布在武器、防具、坐骑、兵符、奇物五个部位。每件装备包含常驻被动和可选的条件触发效果。

**依赖**：
- ADR-0004 (Card Data Format) - 数据格式参考
- ADR-0007 (Card Battle System) - 装备效果触发结构

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 5个装备部位（武器/防具/坐骑/兵符/奇物）正确定义 | 单元测试：验证5种部位枚举 |
| AC2 | 60件装备数据完整加载（每部位12件） | 数据验证：遍历装备表确认总数 |
| AC3 | 每件装备包含：常驻被动效果、条件触发效果、触发条件 | 单元测试：检查装备数据结构字段 |
| AC4 | 装备可按部位筛选查询 | 单元测试：按部位查询返回正确列表 |

## Implementation Notes

### 数据结构设计

```gdscript
enum EquipmentSlot {
    WEAPON,      # 武器：12件
    ARMOR,       # 防具：12件
    MOUNT,       # 坐骑：12件
    INSIGNIA,    # 兵符：12件
    RELIC        # 奇物：12件
}

enum TriggerCondition {
    NONE,                    # 无条件（常驻被动）
    ROUND_START,             # 回合开始
    ROUND_END,               # 回合结束
    ON_ATTACK_HIT,           # 攻击命中时
    ON_CARD_PLAYED,          # 打出卡时
    ON_FIRST_DAMAGE,         # 首次受击
    LOW_HP                   # 低血时（HP≤30%）
}

class EquipmentData:
    var equipment_id: String
    var slot: EquipmentSlot
    var name: String
    var description: String

    # 常驻被动
    var passive_stat_modifiers: Dictionary  # {stat: value/percent}

    # 条件触发
    var trigger_condition: TriggerCondition
    var trigger_chance: float  # 0.0~1.0
    var trigger_effect: Dictionary
```

### 核心方法

- `get_equipment_by_slot(slot: EquipmentSlot) -> Array[EquipmentData]`
- `get_all_equipment() -> Array[EquipmentData]`
- `get_equipment_by_id(id: String) -> EquipmentData`

## QA Test Cases

1. **test_all_5_slots_defined** - 验证5种部位枚举完整
2. **test_60_equipment_loaded** - 验证60件装备数据加载
3. **test_equipment_data_fields** - 验证数据结构字段完整性
4. **test_equipment_filter_by_slot** - 按部位筛选功能
