## TroopActions.gd
## 兵种卡牌行动处理
class_name TroopActions extends RefCounted

func execute(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	var events: Array[CardActionExecutor.EffectEvent] = []
	
	var event = CardActionExecutor.EffectEvent.new()
	event.action_id = card_data.id
	event.action_type = "TROOP"
	event.caster = context.caster
	event.target = null
	
	event.success = true
	event.message = "召唤兵种: %s" % card_data.name
	
	events.append(event)
	return events