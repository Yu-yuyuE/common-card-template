## CardActionExecutor.gd
## 卡牌行动效果执行器（C2 - 卡牌战斗系统）
## 实现 ADR-0020: 卡牌行动参数系统
## 作者: Claude Code
## 创建日期: 2026-04-13

class_name CardActionExecutor extends RefCounted

const ACTION_DIR = "res://src/core/card/actions/"

var melee_actions: MeleeAttackActions = null
var ranged_actions: RangedAttackActions = null
var skill_actions: SkillActions = null
var troop_actions: TroopActions = null
var curse_actions: CurseActions = null

func _init() -> void:
	melee_actions = MeleeAttackActions.new(self)
	ranged_actions = RangedAttackActions.new(self)
	skill_actions = SkillActions.new()
	troop_actions = TroopActions.new()
	curse_actions = CurseActions.new()

class CardSpecialContext:
	var caster: BattleEntity = null           # 施法者
	var targets: Array[BattleEntity] = []    # 目标列表
	var card_id: String = ""                  # 卡牌ID
	var card_level: int = 1                   # 卡牌等级
	var battle_manager: Node = null           # 战斗管理器
	var status_manager: StatusManager = null  # 状态管理器
	var resource_manager: ResourceManager = null  # 资源管理器
	var damage_calculator: DamageCalculator = null  # 伤害计算器
	var current_terrain: String = "PLAINS"    # 当前地形
	var current_weather: String = "CLEAR"     # 当前天气

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

## 执行卡牌效果（主入口）
## card_data: CardData - 卡牌数据
## caster: BattleEntity - 打出卡牌的单位
## target: BattleEntity - 目标单位
## card_level: int - 卡牌等级（1或2）
## context: BattleContext - 战场上下文
func execute_card(
	card_data: CardData,
	caster: BattleEntity,
	targets: Array[BattleEntity],
	card_level: int,
	context: BattleContext
) -> Array[EffectEvent]:
	return _execute_by_type(card_data, caster, targets, card_level, context)

func _execute_by_type(
	card_data: CardData,
	caster: BattleEntity,
	targets: Array[BattleEntity],
	card_level: int,
	context: BattleContext
) -> Array[EffectEvent]:
	var special_context = CardSpecialContext.new()
	special_context.caster = caster
	special_context.targets = targets
	special_context.card_id = card_data.id
	special_context.card_level = card_level
	special_context.battle_manager = battle_manager
	special_context.status_manager = status_manager
	special_context.resource_manager = resource_manager
	special_context.damage_calculator = damage_calculator
	special_context.current_terrain = context.current_terrain
	special_context.current_weather = context.current_weather
	
	var card_type = card_data.type
	
	match card_type:
		CardData.CardType.MELEE_ATTACK:
			return melee_actions.execute(card_data, special_context)
		CardData.CardType.RANGED_ATTACK:
			return ranged_actions.execute(card_data, special_context)
		CardData.CardType.SKILL:
			return skill_actions.execute(card_data, special_context)
		CardData.CardType.TROOP:
			return troop_actions.execute(card_data, special_context)
		CardData.CardType.CURSE:
			return curse_actions.execute(card_data, special_context)
		_:
			push_warning("CardActionExecutor: 未知的卡牌类型 — " + str(card_type))
			return []

## 执行特殊处理函数（保留用于特定卡的特殊逻辑）
## TODO: 实现 CardSpecialAction 专卡专用处理
func _execute_card_action(
	card_data: CardData,
	caster: BattleEntity,
	target: BattleEntity,
	card_level: int,
	context: BattleContext
) -> Array[EffectEvent]:
	push_warning("CardActionExecutor: 未实现特殊卡牌处理 — " + card_data.id)
	return []

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
