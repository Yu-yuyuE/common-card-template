## CaoCaoPassiveSkill.gd
## 武将系统（D3）——曹操被动技能：挟令诸侯
##
## 效果：每次使用兵种卡可对随机敌人施加1层虚弱；对虚弱敌人攻击额外造成50%伤害
##
## 设计文档：design/gdd/heroes-design.md
##
## 作者: fixed by Claude

class_name CaoCaoPassiveSkill extends PassiveSkill

## 触发时机：出牌时
func _init() -> void:
	super._init("挟令诸侯", "每次使用兵种卡可对随机敌人施加1层虚弱；对虚弱敌人的攻击伤害增加50%", "曹操")
	trigger_timings.append(TriggerTiming.ON_CARD_PLAYED)

func on_card_played(hero: HeroManager.HeroData, card: Node, target: Node, battle_manager: Node) -> bool:
	if card == null:
		return false
	
	# 检查是否是兵种卡
	if not card.has_method("is_troop_card") or not card.is_troop_card():
		return false
	
	var status_manager = battle_manager.status_manager
	if status_manager == null:
		return false
	
	# 对目标敌人施加虚弱（如果是敌人目标）
	if target != null and target.is_enemy:
		status_manager.apply(StatusEffect.Type.WEAKEN, 1, "曹操：挟令诸侯", target)
		return true
	
	# 否则随机选择一个敌人
	var enemies = battle_manager.enemy_entities
	if enemies.size() > 0:
		var random_enemy = enemies[randi() % enemies.size()]
		if random_enemy != null:
			status_manager.apply(StatusEffect.Type.WEAKEN, 1, "曹操：挟令诸侯", random_enemy)
			return true
	
	return false
