## TroopActions.gd
## 兵种卡牌行动处理器。
## 由 CardActionExecutor 实例化，处理所有兵种类卡牌的效果逻辑。
## 注意：兵种召唤的具体实现（实体生成、上场逻辑）通过卡牌行动参数系统（ADR-0020）
## 或 card_action_func 专卡处理函数完成；此处仅构造基础事件骨架。
class_name TroopActions extends RefCounted

## 执行兵种卡牌行动，构造并返回效果事件。
## [param card_data] 当前打出的卡牌数据。
## [param context] 行动上下文，包含施法者及各依赖管理器。
## 返回本次行动产生的所有效果事件列表。
func execute(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	var events: Array[CardActionExecutor.EffectEvent] = []

	var event := CardActionExecutor.EffectEvent.new()
	event.action_id = card_data.id
	event.action_type = "TROOP"
	event.caster = context.caster
	event.target = null
	event.success = true
	event.message = "召唤兵种: %s" % card_data.name

	events.append(event)
	return events