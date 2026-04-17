## SkillActions.gd
## 技能卡牌行动处理器。
## 由 CardActionExecutor 实例化，处理所有技能类卡牌的效果逻辑。
## 注意：技能效果的具体实现（治疗、增益、抽卡等）通过卡牌行动参数系统（ADR-0020）
## 或 card_action_func 专卡处理函数完成；此处仅构造基础事件骨架。
class_name SkillActions extends RefCounted

## 执行技能卡牌行动，构造并返回效果事件。
## [param card_data] 当前打出的卡牌数据。
## [param context] 行动上下文，包含施法者、目标列表及各依赖管理器。
## 返回本次行动产生的所有效果事件列表。
func execute(card_data: CardData, context: CardActionExecutor.CardSpecialContext) -> Array[CardActionExecutor.EffectEvent]:
	var events: Array[CardActionExecutor.EffectEvent] = []
	var target: BattleEntity = context.targets[0] if not context.targets.is_empty() else null

	var event := CardActionExecutor.EffectEvent.new()
	event.action_id = card_data.id
	event.action_type = "SKILL"
	event.caster = context.caster
	event.target = target
	event.success = true
	event.message = "使用技能: %s" % card_data.name

	events.append(event)
	return events