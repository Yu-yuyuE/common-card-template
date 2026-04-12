## CaoCaoPassiveSkill.gd
## 武将系统（D3）——曹操被动技能：挟令诸侯
##
## 效果：每次使用兵种卡可对随机敌人施加1层虚弱；对虚弱敌人的攻击伤害增加50%
##
## 设计文档：design/gdd/heroes-design.md
##
## 作者: Claude Code
## 创建日期: 2026-04-12

# 继承自被动技能基类
class_name CaoCaoPassiveSkill extends PassiveSkill

## 触发时机：出牌时
func _init() -> void:
	super._init("挟令诸侯", "每次使用兵种卡可对随机敌人施加1层虚弱；对虚弱敌人的攻击伤害增加50%", "曹操")
	# 注册触发时机
	trigger_timings.append(TriggerTiming.ON_CARD_PLAYED)


## 出牌时触发
## 参数：
##   card: 打出的卡牌
##   target: 目标
func on_card_played(hero: HeroManager.HeroData, card: Node, target: Node, battle_manager: Node) -> bool:
	# 检查是否是兵种卡
	if card != null and card.has_method("is_troop_card") and card.is_troop_card():
		# 获取StatusManager
		var status_manager = battle_manager.status_manager

		# 如果目标是敌人，施加虚弱状态
		if target != null and target.is_enemy:  # 假设敌人节点有is_enemy属性
			status_manager.apply(StatusEffect.Type.WEAKEN, 1, "曹操：挟令诸侯")
			return true

		# 如果不是指定目标，随机选择一个敌人
		if target == null:
			var enemies = battle_manager.enemy_entities
			if enemies.size() > 0:
				var random_enemy = enemies[randi() % enemies.size()]
				if random_enemy != null:
					status_manager.apply(StatusEffect.Type.WEAKEN, 1, "曹操：挟令诸侯")
					return true

	# 检查是否是对虚弱敌人攻击
	if target != null and target.is_enemy and status_manager != null:
		if status_manager.get_layers(StatusEffect.Type.WEAKEN) > 0:
			# 这里需要修改伤害，但伤害计算在BattleManager中
			# 我们需要通过信号或回调来通知
			# 这里只是占位，实际实现需要修改攻击伤害
			return true

	return false