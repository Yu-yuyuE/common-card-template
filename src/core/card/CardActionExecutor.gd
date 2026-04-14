## CardActionExecutor.gd
## 卡牌行动效果执行器（C2 - 卡牌战斗系统）
## 实现 ADR-0020: 卡牌行动参数系统
## 作者: Claude Code
## 创建日期: 2026-04-13

class_name CardActionExecutor extends RefCounted

## 信号
# 效果执行完成信号
signal effect_executed(action: CardAction, events: Array[EffectEvent])
# 单个行动执行信号
signal action_executed(action: CardAction, event: EffectEvent)

## 引用（由外部注入）
var battle_manager: Node = null
var status_manager: StatusManager = null
var resource_manager: ResourceManager = null
var damage_calculator: DamageCalculator = null
var special_action_handler: CardSpecialAction = null

## 行动模板缓存
var _action_templates: Dictionary = {}
var _templates_loaded: bool = false

## 解析器引用
var _parser: CardActionParser = null

## 初始化
func _init() -> void:
	_parser = CardActionParser.new()

## 设置依赖（由外部注入）
func setup(
	p_battle_manager: Node,
	p_status_manager: StatusManager,
	p_resource_manager: ResourceManager,
	p_damage_calculator: DamageCalculator
) -> void:
	battle_manager = p_battle_manager
	status_manager = p_status_manager
	resource_manager = p_resource_manager
	damage_calculator = p_damage_calculator

## 加载行动模板（从 CSV）
func load_action_templates() -> void:
	if _templates_loaded:
		return

	var csv_path = "res://assets/csv_data/card_actions.csv"
	var csv_file = FileAccess.open(csv_path, FileAccess.READ)
	if csv_file == null:
		push_error("CardActionExecutor: 无法加载行动模板文件 — " + csv_path)
		return

	var headers = csv_file.get_csv_line()

	while not csv_file.eof_reached():
		var line = csv_file.get_csv_line()
		if line.size() < 5:
			continue

		var template = CardActionTemplate.new()
		template.action_id = line[0].strip_edges()
		template.action_type = line[1].strip_edges()
		template.required_params = _parse_params(line[2].strip_edges())
		template.optional_params = _parse_params(line[3].strip_edges())
		template.description = line[4].strip_edges()

		_action_templates[template.action_id] = template

	_templates_loaded = true
	csv_file.close()

## 解析参数字符串
func _parse_params(params_str: String) -> Array[String]:
	if params_str.is_empty():
		return []

	var params: Array[String] = []
	var parts = params_str.split(",")
	for part in parts:
		var trimmed = part.strip_edges()
		if not trimmed.is_empty():
			params.append(trimmed)
	return params

## 执行卡牌效果（主入口）
## card_data: CardData - 卡牌数据
## caster: BattleEntity - 打出卡牌的单位
## target: BattleEntity - 目标单位
## card_level: int - 卡牌等级（1或2）
## context: BattleContext - 战场上下文
func execute_card(
	card_data: CardData,
	caster: BattleEntity,
	target: BattleEntity,
	card_level: int,
	context: BattleContext
) -> Array[EffectEvent]:
	# 检查是否使用特殊处理函数
	if card_data.card_action_func == true:
		return _execute_special_action(card_data, caster, target, card_level, context)

	# 使用模板字符串方式
	return _execute_template_action(card_data, caster, target, card_level, context)

## 执行特殊处理函数
func _execute_special_action(
	card_data: CardData,
	caster: BattleEntity,
	target: BattleEntity,
	card_level: int,
	context: BattleContext
) -> Array[EffectEvent]:
	if special_action_handler == null:
		special_action_handler = CardSpecialAction.new()

	if not special_action_handler.has_special_action(card_data.card_id):
		push_warning("CardActionExecutor: 卡牌标记为特殊处理但未找到处理函数 — " + card_data.card_id)
		return []

	# 创建特殊处理上下文
	var special_context = CardSpecialAction.CardSpecialContext.new()
	special_context.caster = caster
	special_context.target = target
	special_context.card_id = card_data.card_id
	special_context.card_level = card_level
	special_context.battle_manager = battle_manager
	special_context.status_manager = status_manager
	special_context.resource_manager = resource_manager
	special_context.damage_calculator = damage_calculator
	special_context.current_terrain = context.current_terrain
	special_context.current_weather = context.current_weather

	return special_action_handler.execute_special(card_data.card_id, special_context)

## 执行模板字符串
func _execute_template_action(
	card_data: CardData,
	caster: BattleEntity,
	target: BattleEntity,
	card_level: int,
	context: BattleContext
) -> Array[EffectEvent]:
	var events: Array[EffectEvent] = []

	# 加载模板（如未加载）
	if not _templates_loaded:
		load_action_templates()

	# 获取效果参数字符串
	var effect_str = card_data.card_action_str if card_data.card_action_str != "" else card_data.effect_lv1

	if effect_str.is_empty():
		push_warning("CardActionExecutor: 卡牌无效果 — " + card_data.card_id)
		return events

	# 解析行动字符串
	var actions = _parser.parse_action_string(effect_str)

	# 设置上下文
	context.caster = caster
	context.target = target

	# 执行每个行动
	for action in actions:
		# 解析条件参数
		var resolved_action = _resolve_conditions(action, context)

		# 解析动态参数（在执行前将 $variable 替换为实际值）
		resolved_action.params = _resolve_dynamic_params(resolved_action.params, context, target)

		# 执行行动
		var event = _execute_action(resolved_action, caster, target, context)
		if event != null:
			events.append(event)
			action_executed.emit(resolved_action, event)

	effect_executed.emit(actions[0] if actions.size() > 0 else null, events)
	return events

## 解析条件参数
func _resolve_conditions(action: CardAction, context: BattleContext) -> CardAction:
	if action.conditions.is_empty():
		return action

	# 复制行动对象
	var resolved = action.duplicate()

	# 逐个处理条件
	for condition in action.conditions:
		var should_apply_true = _evaluate_condition(condition, context)

		# 应用对应分支的参数
		if should_apply_true and condition.true_branch.size() > 0:
			_merge_params(resolved.params, condition.true_branch)
		elif not should_apply_true and condition.false_branch.size() > 0:
			_merge_params(resolved.params, condition.false_branch)

	return resolved

## 解析动态参数（在执行前调用）
func _resolve_dynamic_params(params: Dictionary, context: BattleContext, target: BattleEntity) -> Dictionary:
	var resolved: Dictionary = {}

	for key in params.keys():
		var value = params[key]

		# 处理三元表达式: condition?true_value:false_value
		if typeof(value) == TYPE_DICTIONARY and value.get("type") == "ternary":
			resolved[key] = _resolve_ternary(value, context, target)
		# 处理动态变量
		elif typeof(value) == TYPE_DICTIONARY and value.get("type") == "dynamic":
			resolved[key] = _resolve_dynamic_value(value, context, target)
		# 处理表达式
		elif typeof(value) == TYPE_DICTIONARY and value.get("type") == "expression":
			resolved[key] = _resolve_expression(value, context, target)
		# 普通值直接复制
		else:
			resolved[key] = value

	return resolved

## 解析三元表达式
func _resolve_ternary(ternary: Dictionary, context: BattleContext, target: BattleEntity) -> Variant:
	var condition = ternary.get("condition", null)
	var true_value = ternary.get("true_value", "0")
	var false_value = ternary.get("false_value", "0")

	if condition == null:
		return 0

	# 评估条件
	var condition_result = _evaluate_ternary_condition(condition, context, target)

	# 根据结果选择对应的值
	var selected_value = true_value if condition_result else false_value

	# 解析选中的值（可能是数字或动态变量）
	if typeof(selected_value) == TYPE_STRING:
		# 尝试解析为动态变量
		if selected_value.begins_with("$"):
			var dynamic_var = {"type": "dynamic", "variable": selected_value.substr(1), "multiplier": 1.0}
			return _resolve_dynamic_value(dynamic_var, context, target)
		# 尝试解析为数字
		elif selected_value.is_valid_int():
			return selected_value.to_int()
		elif selected_value.is_valid_float():
			return int(selected_value.to_float())

	return selected_value

## 评估三元条件
func _evaluate_ternary_condition(condition: Condition, context: BattleContext, target: BattleEntity) -> bool:
	# 复用 _evaluate_condition 的逻辑，但需要临时设置 status_manager
	var original_status_manager = null
	if status_manager != null:
		# 需要通过 parser 的评估逻辑，但这里简化处理
		# 直接调用条件评估
		pass

	match condition.field:
		"target_has_any_debuff":
			if target != null and status_manager != null:
				return status_manager.has_any_debuff(target)
			return false
		"target_has_any_buff":
			if target != null and status_manager != null:
				return status_manager.has_any_buff(target)
			return false
		"caster_has_any_debuff":
			if context.caster != null and status_manager != null:
				return status_manager.has_any_debuff(context.caster)
			return false
		"caster_has_any_buff":
			if context.caster != null and status_manager != null:
				return status_manager.has_any_buff(context.caster)
			return false
		"target_has_status":
			if target != null and status_manager != null:
				return status_manager.has_status(target, condition.value)
			return false
		"caster_has_status":
			if context.caster != null and status_manager != null:
				return status_manager.has_status(context.caster, condition.value)
			return false
		_:
			# 检查是否为特定状态存在检查（如 target_has_POISON）
			if condition.field.begins_with("target_has_"):
				var status_id = condition.field.substr(12)  # 去掉 "target_has_" 前缀
				if target != null and status_manager != null:
					return status_manager.has_status(target, status_id)
			elif condition.field.begins_with("caster_has_"):
				var status_id = condition.field.substr(12)  # 去掉 "caster_has_" 前缀
				if context.caster != null and status_manager != null:
					return status_manager.has_status(context.caster, status_id)

	return false

## 解析动态变量值
func _resolve_dynamic_value(dynamic_var: Dictionary, context: BattleContext, target: BattleEntity) -> Variant:
	var variable = dynamic_var.get("variable", "")
	var multiplier = dynamic_var.get("multiplier", 1.0)

	var base_value: float = 0.0

	match variable:
		"target":
			return target
		"target_hp":
			base_value = target.current_hp if target != null else 0
		"target_max_hp":
			base_value = target.max_hp if target != null else 0
		"caster_hp":
			base_value = context.caster.current_hp if context.caster != null else 0
		"caster_max_hp":
			base_value = context.caster.max_hp if context.caster != null else 0
		"hand_card_count":
			base_value = context.hand_cards.size()
		"deck_card_count":
			# 从 battle_manager 获取
			if battle_manager != null and battle_manager.has_method("get_deck_count"):
				base_value = battle_manager.get_deck_count()
			else:
				base_value = 0
		"gold":
			base_value = resource_manager.get_resource("gold") if resource_manager != null else 0
		"provisions":
			base_value = resource_manager.get_resource("provisions") if resource_manager != null else 0
		"action_points":
			base_value = resource_manager.get_resource("action_points") if resource_manager != null else 0
		"current_turn":
			base_value = context.current_turn
		_:
			# 检查目标状态层数: target_status_POISON
			if variable.begins_with("target_status_"):
				var status_id = variable.substr(14)  # 去掉 "target_status_" 前缀
				if target != null and status_manager != null:
					base_value = status_manager.get_status_layers(target, status_id)
			# 检查施法者状态层数: caster_status_FURY
			elif variable.begins_with("caster_status_"):
				var status_id = variable.substr(14)  # 去掉 "caster_status_" 前缀
				if context.caster != null and status_manager != null:
					base_value = status_manager.get_status_layers(context.caster, status_id)

	# 应用乘数
	return int(base_value * multiplier)

## 解析表达式
func _resolve_expression(expr: Dictionary, context: BattleContext, target: BattleEntity) -> int:
	var expression = expr.get("expression", "")
	var result = 0

	# 简单表达式解析：支持 +, -, *, / 和动态变量
	# 示例: "$target_hp*0.3" -> target.hp * 0.3
	# 示例: "$target_status_POISON+1" -> target.POISON + 1

	# 先替换所有动态变量为实际值
	var processed_expr = expression
	var var_pattern = RegEx.new()
	var_pattern.compile("\\$([a-zA-Z_][a-zA-Z0-9_]*)")

	var matches = var_pattern.search_all(processed_expr)
	# 从后往前替换，避免位置变化
	var matches_array = matches.size()
	for i in range(matches_array - 1, -1, -1):
		var match = matches[i]
		var var_name = match.get_string(1)
		var full_var = "$" + var_name

		# 获取变量值
		var temp_dynamic = {"type": "dynamic", "variable": var_name, "multiplier": 1.0}
		var var_value = _resolve_dynamic_value(temp_dynamic, context, target)

		# 替换（如果是数字）
		if typeof(var_value) == TYPE_INT or typeof(var_value) == TYPE_FLOAT:
			processed_expr = processed_expr.replace(full_var, str(var_value))

	# 计算表达式
	processed_expr = processed_expr.strip_edges()
	if processed_expr.is_valid_float():
		result = int(processed_expr.to_float())
	elif processed_expr.is_valid_int():
		result = processed_expr.to_int()
	else:
		# 尝试作为简单数学表达式计算
		result = _calculate_expression(processed_expr)

	return result

## 简单数学表达式计算（仅支持 + - * /）
func _calculate_expression(expr: String) -> int:
	# 注意：这是一个简化的实现，生产环境可能需要更安全的表达式解析器
	# 这里只处理简单的单步运算

	# 乘除优先
	var mul_div = RegEx.new()
	mul_div.compile("(-?\\d+\\.?\\d*)\\s*([*/])\\s*(-?\\d+\\.?\\d*)")

	while true:
		var match = mul_div.search(expr)
		if match == null:
			break

		var left = match.get_string(1).to_float()
		var op = match.get_string(2)
		var right = match.get_string(3).to_float()
		var result = 0.0

		match op:
			"*":
				result = left * right
			"/":
				result = left / right if right != 0 else 0

		expr = expr.replace(match.get_string(), str(int(result)))

	# 处理加减
	var add_sub = RegEx.new()
	add_sub.compile("(-?\\d+\\.?\\d*)\\s*([+-])\\s*(-?\\d+\\.?\\d*)")

	var total = 0.0
	var current_num = 0.0
	var current_op = "+"

	var num_pattern = RegEx.new()
	num_pattern.compile("(-?\\d+\\.?\\d*)")

	var nums = num_pattern.search_all(expr)
	var ops = []
	var op_pattern = RegEx.new()
	op_pattern.compile("([+-])")
	var op_matches = op_pattern.search_all(expr)

	for op_match in op_matches:
		ops.append(op_match.get_string())

	if nums.size() > 0:
		total = nums[0].get_string().to_float()

	for i in range(1, nums.size()):
		var num = nums[i].get_string().to_float()
		var op = ops[i - 1] if i - 1 < ops.size() else "+"
		match op:
			"+":
				total += num
			"-":
				total -= num

	return int(total)

## 评估条件
func _evaluate_condition(condition: Condition, context: BattleContext) -> bool:
	match condition.field:
		"terrain":
			return context.current_terrain == condition.value
		"weather":
			return context.current_weather == condition.value
		"target_has_status":
			if context.target != null and status_manager != null:
				return status_manager.has_status(context.target, condition.value)
			return false
		"caster_has_status":
			if context.caster != null and status_manager != null:
				return status_manager.has_status(context.caster, condition.value)
			return false
		_:
			push_warning("CardActionExecutor: 未知条件字段 — " + condition.field)
			return false

## 合并参数
func _merge_params(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = source[key]

## 执行单个行动
func _execute_action(
	action: CardAction,
	caster: BattleEntity,
	target: BattleEntity,
	context: BattleContext
) -> EffectEvent:
	var template = _action_templates.get(action.action_id)
	if template == null:
		push_error("CardActionExecutor: 未知行动ID — " + action.action_id)
		return null

	var event = EffectEvent.new()
	event.action_id = action.action_id
	event.action_type = template.action_type
	event.caster = caster
	event.target = target

	# 根据行动类型路由
	match template.action_type:
		"ATK_PHYSICAL", "ATK_RANGED", "ATK_MAGICAL":
			event = _execute_attack(action, template, caster, target, event)
		"HEAL":
			event = _execute_heal(action, caster, target, event)
		"ADD_SHIELD":
			event = _execute_add_shield(action, caster, target, event)
		"ADD_STATUS":
			event = _execute_add_status(action, caster, target, event)
		"REMOVE_STATUS":
			event = _execute_remove_status(action, caster, target, event)
		"DRAW_CARDS":
			event = _execute_draw_cards(action, caster, event)
		"GAIN_GOLD":
			event = _execute_gain_gold(action, caster, event)
		"GAIN_PROVISIONS":
			event = _execute_gain_provisions(action, caster, event)
		"GAIN_ACTION_POINTS":
			event = _execute_gain_action_points(action, caster, event)
		"DEAL_DAMAGE_TO_ALL":
			event = _execute_deal_damage_to_all(action, caster, context, event)
		"HEAL_ALL":
			event = _execute_heal_all(action, caster, context, event)
		_:
			push_warning("CardActionExecutor: 未实现的行动类型 — " + template.action_type)

	return event

## 执行攻击
func _execute_attack(
	action: CardAction,
	template: CardActionTemplate,
	caster: BattleEntity,
	target: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var damage = action.params.get("damage", 0)
	if damage <= 0:
		return event

	var piercing = action.params.get("piercing", false)
	var damage_type = template.action_type.replace("ATK_", "").to_lower()

	# 调用伤害计算器
	if damage_calculator != null and target != null:
		var actual_damage = damage_calculator.calculate(
			damage,
			damage_type,
			caster,
			target,
			piercing
		)
		event.value = actual_damage
		event.success = true

		# 应用伤害
		resource_manager.modify_hp(target, -actual_damage)
	else:
		event.value = 0
		event.success = false

	return event

## 执行治疗
func _execute_heal(
	action: CardAction,
	caster: BattleEntity,
	target: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var heal = action.params.get("heal", 0)
	if heal <= 0:
		return event

	if target != null and resource_manager != null:
		resource_manager.modify_hp(target, heal)
		event.value = heal
		event.success = true
	else:
		event.value = 0
		event.success = false

	return event

## 执行添加护盾
func _execute_add_shield(
	action: CardAction,
	caster: BattleEntity,
	target: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var shield = action.params.get("shield", 0)
	if shield <= 0:
		return event

	if target != null and resource_manager != null:
		resource_manager.add_shield(target, shield)
		event.value = shield
		event.success = true
	else:
		event.value = 0
		event.success = false

	return event

## 执行添加状态
func _execute_add_status(
	action: CardAction,
	caster: BattleEntity,
	target: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var status_id = action.params.get("status_id", "")
	var layers = action.params.get("layers", 1)

	if status_id.is_empty():
		return event

	if target != null and status_manager != null:
		status_manager.apply_status(target, status_id, layers)
		event.value = layers
		event.success = true
	else:
		event.value = 0
		event.success = false

	return event

## 执行移除状态
func _execute_remove_status(
	action: CardAction,
	caster: BattleEntity,
	target: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var status_id = action.params.get("status_id", "")

	if status_id.is_empty():
		return event

	if target != null and status_manager != null:
		status_manager.remove_status(target, status_id)
		event.success = true

	return event

## 执行抽卡
func _execute_draw_cards(
	action: CardAction,
	caster: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var count = action.params.get("count", 1)
	if count <= 0:
		return event

	# 通过 BattleManager 抽卡
	if battle_manager != null and battle_manager.has_method("draw_cards"):
		battle_manager.draw_cards(count)
		event.value = count
		event.success = true
	else:
		event.value = 0
		event.success = false

	return event

## 执行获得金币
func _execute_gain_gold(
	action: CardAction,
	caster: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var amount = action.params.get("amount", 0)
	if amount <= 0:
		return event

	if resource_manager != null:
		resource_manager.modify_resource("gold", amount)
		event.value = amount
		event.success = true
	else:
		event.value = 0
		event.success = false

	return event

## 执行获得粮草
func _execute_gain_provisions(
	action: CardAction,
	caster: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var amount = action.params.get("amount", 0)
	if amount <= 0:
		return event

	if resource_manager != null:
		resource_manager.modify_resource("provisions", amount)
		event.value = amount
		event.success = true
	else:
		event.value = 0
		event.success = false

	return event

## 执行获得行动点
func _execute_gain_action_points(
	action: CardAction,
	caster: BattleEntity,
	event: EffectEvent
) -> EffectEvent:
	var amount = action.params.get("amount", 0)
	if amount <= 0:
		return event

	if resource_manager != null:
		resource_manager.modify_resource("action_points", amount)
		event.value = amount
		event.success = true
	else:
		event.value = 0
		event.success = false

	return event

## 执行对所有敌人造成伤害
func _execute_deal_damage_to_all(
	action: CardAction,
	caster: BattleEntity,
	context: BattleContext,
	event: EffectEvent
) -> EffectEvent:
	var damage = action.params.get("damage", 0)
	if damage <= 0:
		return event

	# 获取所有敌人
	if battle_manager == null:
		event.success = false
		return event

	var all_enemies = battle_manager.get_all_enemies()
	var total_damage = 0

	for enemy in all_enemies:
		# 排除特定目标
		var exclude_target = action.params.get("exclude_target", "")
		if exclude_target != "" and enemy.entity_id == exclude_target:
			continue

		if resource_manager != null:
			resource_manager.modify_hp(enemy, -damage)
			total_damage += damage

	event.value = total_damage
	event.success = true
	return event

## 执行恢复所有我方
func _execute_heal_all(
	action: CardAction,
	caster: BattleEntity,
	context: BattleContext,
	event: EffectEvent
) -> EffectEvent:
	var heal = action.params.get("heal", 0)
	if heal <= 0:
		return event

	# 获取所有我方单位
	if battle_manager == null:
		event.success = false
		return event

	var all_allies = battle_manager.get_all_allies()
	var total_heal = 0

	for ally in all_allies:
		if resource_manager != null:
			resource_manager.modify_hp(ally, heal)
			total_heal += heal

	event.value = total_heal
	event.success = true
	return event


# ============ 数据结构类 ============

## 行动模板类
class CardActionTemplate:
	var action_id: String = ""
	var action_type: String = ""
	var required_params: Array[String] = []
	var optional_params: Array[String] = []
	var description: String = ""

## 行动实例类
class CardAction:
	var action_id: String = ""
	var params: Dictionary = {}
	var conditions: Array[Condition] = []
	var trigger: String = "IMMEDIATE"  # IMMEDIATE, AFTER_DRAW, ON_CARD_PLAYED

## 条件类
class Condition:
	var field: String = ""  # terrain, weather, target_has_status
	var operator: String = "="  # =, !=
	var value: Variant = null
	var true_branch: Dictionary = {}  # 条件为真时的参数覆盖
	var false_branch: Dictionary = {}  # 条件为假时的参数覆盖

## 效果事件类
class EffectEvent:
	var action_id: String = ""
	var action_type: String = ""
	var caster: BattleEntity = null
	var target: BattleEntity = null
	var value: int = 0  # 效果数值（伤害值、治疗量等）
	var success: bool = false
	var message: String = ""  # 用于UI显示的消息
