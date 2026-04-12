## ZhugeLiangPassiveSkill.gd
## 武将系统（D3）——诸葛亮被动技能：卧龙
##
## 效果：每回合开始时恢复1行动点；每次使用技能卡后，抽卡一张
##
## 设计文档：design/gdd/heroes-design.md
##
## 作者: Claude Code
## 创建日期: 2026-04-12

# 继承自被动技能基类
class_name ZhugeLiangPassiveSkill extends PassiveSkill

## 触发时机：回合开始、出牌时
func _init() -> void:
	super._init("卧龙", "每回合开始时恢复1行动点；每次使用技能卡后，抽卡一张", "诸葛亮")
	# 注册触发时机
	trigger_timings.append(TriggerTiming.ON_ROUND_START)
	trigger_timings.append(TriggerTiming.ON_CARD_PLAYED)


## 回合开始时触发
func on_round_start(hero: HeroManager.HeroData, battle_manager: Node) -> bool:
	# 恢复1点行动点
	var resource_manager = battle_manager.resource_manager
	var current_ap = resource_manager.get_action_points()
	var max_ap = resource_manager.get_max_action_points()
	var actual_restore = min(1, max_ap - current_ap)
	if actual_restore > 0:
		resource_manager.modify_resource(ResourceManager.ResourceType.ACTION_POINTS, actual_restore)
		return true
	return false


## 出牌时触发
func on_card_played(hero: HeroManager.HeroData, card: Node, target: Node, battle_manager: Node) -> bool:
	# 检查是否是技能卡
	if card != null and card.has_method("is_skill_card") and card.is_skill_card():
		# 抽一张卡
		var card_manager = battle_manager.card_manager
		card_manager.draw_cards(1)
		return true
	return false