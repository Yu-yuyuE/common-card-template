## RangedAttackActions.gd
## 远程攻击卡牌行动处理器。
## 由 CardActionExecutor 实例化，处理所有远程攻击类卡牌的效果逻辑。
class_name RangedAttackActions extends RefCounted

## 根据卡牌 ID 分发并执行对应的远程攻击行动。
## [param card_data] 当前打出的卡牌数据。
## [param context] 行动上下文，包含施法者、目标列表、资源管理器及伤害计算器。
## 返回本次行动产生的所有效果事件列表。
func execute(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	var damage: int = _get_damage_for_level(card_data, context.card_level)
	return _execute_ranged(card_data, context, damage)

## 执行远程攻击，穿透护盾，返回效果事件列表。
## [param card_data] 卡牌数据。
## [param context] 行动上下文（含依赖注入）。
## [param base_damage] 基础伤害值。
func _execute_ranged(
	card_data: CardData,
	context: CardActionExecutor.CardSpecialContext,
	base_damage: int
) -> Array[CardActionExecutor.EffectEvent]:
	var events: Array[CardActionExecutor.EffectEvent] = []

	# 依赖 Guard：确保必要依赖已注入
	if context.damage_calculator == null:
		push_error("RangedAttackActions: damage_calculator 未注入，行动 %s 中止" % card_data.id)
		return events
	if context.resource_manager == null:
		push_error("RangedAttackActions: resource_manager 未注入，行动 %s 中止" % card_data.id)
		return events

	var event := CardActionExecutor.EffectEvent.new()
	event.action_id = card_data.id
	event.action_type = "RANGED_ATTACK"
	event.caster = context.caster

	# 目标 Guard：无目标时返回失败事件
	if context.targets.is_empty():
		push_warning("RangedAttackActions: 目标列表为空，行动 %s 跳过" % card_data.id)
		event.value = 0
		event.success = false
		event.message = "远程攻击失败：目标列表为空（行动 %s）" % card_data.id
		events.append(event)
		return events

	var target: BattleEntity = context.targets[0]
	event.target = target

	# 远程攻击固定穿透护盾（piercing = true）
	var actual_damage: int = context.damage_calculator.calculate(
		base_damage,
		"physical",
		context.caster,
		target,
		true
	)
	context.resource_manager.modify_hp(target, -actual_damage)
	event.value = actual_damage
	event.success = true
	event.message = "对 %s 造成 %d 点远程伤害" % [target.entity_id, actual_damage]

	events.append(event)
	return events

## 从卡牌配置的 damage_by_level 数组中按等级读取伤害值。
## [param card_data] 卡牌数据（须配置 damage_by_level）。
## [param level] 卡牌等级（从 1 开始）。
## 返回对应等级的伤害值；配置缺失时返回 0 并输出警告。
func _get_damage_for_level(card_data: CardData, level: int) -> int:
	if card_data.damage_by_level.is_empty():
		push_warning("RangedAttackActions: 卡牌 %s 未配置 damage_by_level，伤害为 0" % card_data.id)
		return 0
	var level_index: int = clampi(level - 1, 0, card_data.damage_by_level.size() - 1)
	return card_data.damage_by_level[level_index]