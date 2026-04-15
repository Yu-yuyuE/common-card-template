## SkillActions.gd
## 技能卡牌行动处理
class_name SkillActions extends RefCounted

func execute(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	var events: Array[CardActionExecutor.EffectEvent] = []
	var target = context.targets[0] if context.targets.size() > 0 else null
	
	var event = CardActionExecutor.EffectEvent.new()
	event.action_id = card_data.id
	event.action_type = "SKILL"
	event.caster = context.caster
	event.target = target
	
	event.success = true
	event.message = "使用技能: %s" % card_data.name
	
	events.append(event)
	return events