## CardSpecialAction.gd
## 复杂卡牌效果处理函数
## 对于无法用模板字符串表示的复杂效果，在这里定义处理函数
## 作者: Claude Code
## 创建日期: 2026-04-13

class_name CardSpecialAction extends RefCounted

## 特殊卡牌处理函数映射
## key: card_id
## value: Callable - 处理函数，参数为 CardSpecialContext，返回 Array[EffectEvent]
var _special_actions: Dictionary = {}

func _init() -> void:
	_register_all_actions()

## 注册所有特殊动作
func _register_all_actions() -> void:
	# 趁虚而入 - AC0016
	# 效果：对目标造成6点伤害；若目标有负面状态，额外造成3点伤害
	_special_actions["AC0016"] = _handle_ac0016

	# 在这里添加更多复杂卡牌的处理函数...

## 处理函数注册入口
func register_action(card_id: String, handler: Callable) -> void:
	_special_actions[card_id] = handler

## 检查是否有特殊处理
func has_special_action(card_id: String) -> bool:
	return _special_actions.has(card_id)

## 执行特殊处理
func execute_special(card_id: String, context: CardSpecialContext) -> Array[EffectEvent]:
	var handler = _special_actions.get(card_id)
	if handler == null:
		push_warning("CardSpecialAction: 未找到特殊处理函数 — " + card_id)
		return []

	if not handler.is_valid():
		push_error("CardSpecialAction: 处理函数无效 — " + card_id)
		return []

	return handler.call(context)

## ============ 特殊处理函数实现 ============

## AC0016: 趁虚而入
## 对目标造成6点伤害；若目标有负面状态，额外造成3点伤害
func _handle_ac0016(ctx: CardSpecialContext) -> Array[EffectEvent]:
	var events: Array[EffectEvent] = []

	# 基础伤害
	var base_damage = 6
	if ctx.card_level == 2:
		base_damage = 8

	# 检查目标是否有负面状态
	var has_debuff = false
	if ctx.status_manager != null and ctx.target != null:
		has_debuff = ctx.status_manager.has_any_debuff(ctx.target)

	# 额外伤害
	var extra_damage = 3
	if ctx.card_level == 2:
		extra_damage = 4

	# 总伤害
	var total_damage = base_damage
	if has_debuff:
		total_damage += extra_damage

	# 执行伤害
	if ctx.resource_manager != null and ctx.target != null:
		ctx.resource_manager.modify_hp(ctx.target, -total_damage)

	# 创建事件
	var event = EffectEvent.new()
	event.action_id = "AC0016_SPECIAL"
	event.action_type = "ATK_PHYSICAL"
	event.caster = ctx.caster
	event.target = ctx.target
	event.value = total_damage
	event.success = true
	event.message = "造成 %d 点伤害" % total_damage

	if has_debuff:
		event.message += "（含额外 %d 点）" % extra_damage

	events.append(event)
	return events


# ============ 上下文类 ============

class CardSpecialContext:
	var caster: BattleEntity = null           # 施法者
	var target: BattleEntity = null           # 目标
	var card_id: String = ""                  # 卡牌ID
	var card_level: int = 1                   # 卡牌等级
	var battle_manager: Node = null           # 战斗管理器
	var status_manager: StatusManager = null  # 状态管理器
	var resource_manager: ResourceManager = null  # 资源管理器
	var damage_calculator: DamageCalculator = null  # 伤害计算器
	var current_terrain: String = "PLAINS"    # 当前地形
	var current_weather: String = "CLEAR"     # 当前天气

# ============ 效果事件类 ============
class EffectEvent:
	var action_id: String = ""
	var action_type: String = ""
	var caster: Object = null
	var target: Object = null
	var value: int = 0  # 效果数值（伤害值、治疗量等）
	var success: bool = false
	var message: String = ""  # 用于UI显示的消息
