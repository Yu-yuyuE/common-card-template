# Story: 事件数据结构与分类

> **Type**: Logic
> **Epic**: event-system
> **ADR**: ADR-0004
> **Status**: Ready

## Context

事件系统需要定义5大类50个事件的数据结构。事件分为无选项和有选项两类，每类事件有不同的后果结构。

**依赖**：
- ADR-0004 (Card Data Format) - 数据格式参考

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 5大类事件（政治/军略/民心/人物/转折）正确定义 | 单元测试：验证5种事件类别枚举 |
| AC2 | 50个事件数据完整加载 | 数据验证：遍历事件表确认总数 |
| AC3 | 事件包含：ID、名称、类别、类型、权重、前置条件、后果 | 单元测试：检查事件数据结构字段 |
| AC4 | 事件可按类别筛选查询 | 单元测试：按类别查询返回正确列表 |

## Implementation Notes

### 数据结构设计

```gdscript
enum EventCategory {
    POLITICAL,   # 政治抉择：10件
    MILITARY,    # 军略抉择：10件
    PEOPLE,      # 民心抉择：10件
    CHARACTER,   # 人物抉择：10件
    TURNING      # 转折事件：10件
}

enum EventType {
    NO_OPTION,   # 无选项事件：~70%
    WITH_OPTION  # 有选项事件：~30%
}

class EventData:
    var event_id: String
    var name: String
    var category: EventCategory
    var event_type: EventType
    var weight: int  # 1~3

    # 前置条件（可选）
    var prerequisites: Dictionary  # {resource: min_value, terrain: type, ...}

    # 后果定义
    var consequences: Array[ConsequenceData]

class ConsequenceData:
    var type: ConsequenceType  # RESOURCE, BATTLE, DECK_CHANGE, WEATHER
    var value: Variant  # 具体数值或配置
    var target: String  # 资源类型/敌人配置/卡牌池等
```

### 核心方法

- `get_events_by_category(category: EventCategory) -> Array[EventData]`
- `get_available_events(prerequisites: Dictionary) -> Array[EventData]`
- `select_random_event(available_events: Array) -> EventData`

## QA Test Cases

1. **test_all_5_categories_defined** - 验证5种类别枚举完整
2. **test_50_events_loaded** - 验证50个事件数据加载
3. **test_event_data_fields** - 验证数据结构字段完整性
4. **test_event_filter_by_category** - 按类别筛选功能
