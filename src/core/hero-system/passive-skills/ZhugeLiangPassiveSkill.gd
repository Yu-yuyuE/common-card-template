## ZhugeLiangPassiveSkill.gd
## 武将系统（D3）——诸葛亮被动技能：卧龙
##
## 效果：每回合开始时恢复1点行动点；每使用一张技能卡额外抽1张牌
##
## 设计文档：design/gdd/heroes-design.md

class_name ZhugeLiangPassiveSkill extends PassiveSkill

func _init() -> void:
	super._init("卧龙", "每回合开始时恢复1点行动点；每使用一张技能卡额外抽1张牌", "诸葛亮")
	trigger_timings.append(TriggerTiming.ON_TURN_START)
	trigger_timings.append(TriggerTiming.ON_SKILL_CARD_PLAYED)

func on_turn_start(hero: HeroManager.HeroData, battle_manager: Node) -> bool:
	var rm = battle_manager.resource_manager
	if rm != null:
		rm.modify_resource(ResourceManager.ResourceType.ACTION_POINTS, 1, "诸葛亮：卧龙")
	return true

func on_skill_card_played(hero: HeroManager.HeroData, card: Node, battle_manager: Node) -> bool:
	# 通知抽1张牌
	if battle_manager.has_signal("request_draw_card"):
		battle_manager.request_draw_card.emit(1)
	return true
