## GuanYuPassiveSkill.gd
## 武将系统（D3）——关羽被动技能：武圣
##
## 效果：攻击带有恐惧状态的敌人时，恢复1点行动点
##
## 设计文档：design/gdd/heroes-design.md

class_name GuanYuPassiveSkill extends PassiveSkill

func _init() -> void:
	super._init("武圣", "攻击带有恐惧状态的敌人时恢复1点行动点", "关羽")
	trigger_timings.append(TriggerTiming.ON_ATTACK)

func on_attack(hero: HeroManager.HeroData, target: Node, damage: int, battle_manager: Node) -> bool:
	if target == null:
		return false
	
	var status_manager = battle_manager.status_manager
	if status_manager == null:
		return false
	
	# 先检查目标是否已有恐惧状态
	var fear_layers = status_manager.get_layers(StatusEffect.Type.FEAR)
	if fear_layers > 0:
		# 目标已有恐惧，触发恢复效果
		var rm = battle_manager.resource_manager
		if rm != null:
			rm.modify_resource(ResourceManager.ResourceType.ACTION_POINTS, 1, "关羽：武圣")
		return true
	
	return false
