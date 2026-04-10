# Story: 诅咒数据结构与类型定义

> **Type**: Logic
> **Epic**: curse-system
> **ADR**: ADR-0006, ADR-0007
> **Status**: Ready

## Context

诅咒系统需要定义诅咒卡的三种类型及其数据结构。三种类型在触发时机、持续方式和消除方式上完全不同，需要清晰的数据结构来区分。

**现有依赖**：
- ADR-0006 (Status System) - 诅咒作为状态效果管理
- ADR-0007 (Card Battle System) - 诅咒卡集成到战斗系统

## Acceptance Criteria

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC1 | 三种诅咒类型（抽到触发型、常驻牌库型、常驻手牌型）可正确区分 | 单元测试：创建三种类型实例，验证 type 字段 |
| AC2 | 诅咒卡数据结构包含：card_id, type, effect_text, discard_cost | 单元测试：检查数据结构字段完整性 |
| AC3 | 诅咒卡 type 字段可被序列化和反序列化 | 集成测试：保存/加载后 type 一致 |

## Implementation Notes

### 数据结构设计

```gdscript
enum CurseType {
    DRAW_TRIGGER,    # 抽到触发型
    PERSISTENT_LIBRARY,  # 常驻牌库型
    PERSISTENT_HAND      # 常驻手牌型
}

class CurseCardData extends CardData:
    var curse_type: CurseType
    var discard_cost: int  # 仅常驻手牌型使用
    var trigger_effect: String  # 抽到触发型的效果文本
    var persistent_effect: String  # 常驻牌库型的持续效果文本
```

### 核心方法

- `get_curse_type(card_id: String) -> CurseType`
- `is_curse_card(card_id: String) -> bool`
- `get_discard_cost(card_id: String) -> int`

## QA Test Cases

1. **test_curse_type_enum_completeness** - 验证三种类型都被正确定义
2. **test_curse_data_serialization** - 测试诅咒数据序列化
3. **test_curse_identification** - 验证 can_identify_curse_card() 正确识别诅咒卡
