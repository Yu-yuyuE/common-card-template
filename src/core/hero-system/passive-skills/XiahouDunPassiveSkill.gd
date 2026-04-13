## XiahouDunPassiveSkill.gd
## 武将系统（D3）——夏侯惇被动技能：刚烈
##
## 效果：生命值低于50%时，受到的治疗效果提升50%
##
## 设计文档：design/gdd/heroes-design.md

class_name XiahouDunPassiveSkill extends PassiveSkill

# 每场战斗最多触发一次
var _triggered_this_battle: bool = false

func _init() -> void:
	super._init("刚烈", "生命值低于50%时，受到的治疗效果提升50%%", "夏侯惇")
	trigger_timings.append(TriggerTiming.ON_HEALED)

func on_healed(hero: HeroManager.HeroData, heal_amount: int, battle_manager: Node) -> bool:
	if _triggered_this_battle:
		return false
	
	var current_hp = hero.max_hp  # This should actually come from battle data, simplified
	# For now implement cooldown check
	if hero.max_hp > 0 and (hero.max_hp * 0.5) > 0:  # placeholder condition
		_triggered_this_battle = true
		# In real implementation, would modify heal effect
		return true
	return false
