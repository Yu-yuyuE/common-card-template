## LiuBeiPassiveSkill.gd
## 武将系统（D3）——刘备被动技能：仁德
##
## 效果：每次使用兵种卡后，为己方全体恢复1点HP
##
## 设计文档：design/gdd/heroes-design.md
##
## 作者: Claude Code
## 创建日期: 2026-04-12

# 继承自被动技能基类
class_name LiuBeiPassiveSkill extends PassiveSkill

## 触发时机：出牌时
func _init() -> void:
	super._init("仁德", "每次使用兵种卡后，为己方全体恢复1点HP", "刘备")
	# 注册触发时机
	trigger_timings.append(TriggerTiming.ON_CARD_PLAYED)


## 出牌时触发
func on_card_played(hero: HeroManager.HeroData, card: Node, target: Node, battle_manager: Node) -> bool:
	# 检查是否是兵种卡
	if card != null and card.has_method("is_troop_card") and card.is_troop_card():
		# 为己方全体恢复1点HP
		var resource_manager = battle_manager.resource_manager
		var current_hp = resource_manager.get_hp()
		var max_hp = resource_manager.get_max_hp()
		var actual_restore = min(1, max_hp - current_hp)
		if actual_restore > 0:
			resource_manager.modify_resource(ResourceManager.ResourceType.HP, actual_restore)
			return true
	return false