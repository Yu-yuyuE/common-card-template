## MeleeAttackActions.gd
## 近战攻击卡牌行动处理
class_name MeleeAttackActions extends RefCounted

var _executor: CardActionExecutor = null

func _init(executor: CardActionExecutor) -> void:
	_executor = executor

func execute(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	match card_data.id:
		"AC0001": return _handle_ac0001(card_data, context)
		_: return _handle_default(card_data, context)

## 赤手空拳 - 基础近战攻击
func _handle_ac0001(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	return _execute_melee(card_data, context, 6 if context.card_level == 1 else 8, false)

## 默认处理
func _handle_default(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	var damage = _get_base_damage(card_data, context.card_level)
	return _execute_melee(card_data, context, damage, false)

## 执行近战攻击
func _execute_melee(card_data: CardData, context: CardActionExecutor.CardSpecialContext, base_damage: int, piercing: bool) -> Array[CardActionExecutor.EffectEvent]:
	var events: Array[CardActionExecutor.EffectEvent] = []
	var target = context.targets[0] if context.targets.size() > 0 else null
	
	var event = CardActionExecutor.EffectEvent.new()
	event.action_id = card_data.id
	event.action_type = "MELEE_ATTACK"
	event.caster = context.caster
	event.target = target
	
	if target != null and context.damage_calculator != null:
		var actual_damage = context.damage_calculator.calculate(
			base_damage,
			"physical",
			context.caster,
			target,
			piercing
		)
		event.value = actual_damage
		event.success = true
		context.resource_manager.modify_hp(target, -actual_damage)
		event.message = "对 %s 造成 %d 点近战伤害" % [target.entity_id, actual_damage]
	else:
		event.value = 0
		event.success = false
	
	events.append(event)
	return events

func _get_base_damage(card_data: CardData, level: int) -> int:
	if level == 1:
		return card_data.cost
	return card_data.cost