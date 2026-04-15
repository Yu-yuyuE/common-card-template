## RangedAttackActions.gd
## 远程攻击卡牌行动处理
class_name RangedAttackActions extends RefCounted

func execute(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	var events: Array[CardActionExecutor.EffectEvent] = []
	var target = context.targets[0] if context.targets.size() > 0 else null
	
	var damage = _get_base_damage(card_data, context.card_level)
	
	var event = CardActionExecutor.EffectEvent.new()
	event.action_id = card_data.id
	event.action_type = "RANGED_ATTACK"
	event.caster = context.caster
	event.target = target
	
	if target != null and context.damage_calculator != null:
		var actual_damage = context.damage_calculator.calculate(
			damage,
			"physical",
			context.caster,
			target,
			true
		)
		event.value = actual_damage
		event.success = true
		context.resource_manager.modify_hp(target, -actual_damage)
		event.message = "对 %s 造成 %d 点远程伤害" % [target.entity_id, actual_damage]
	else:
		event.value = 0
		event.success = false
	
	events.append(event)
	return events

func _get_base_damage(card_data: CardData, level: int) -> int:
	if level == 1:
		return card_data.cost
	return card_data.cost