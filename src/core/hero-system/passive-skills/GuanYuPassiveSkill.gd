## GuanYuPassiveSkill.gd
## 武将系统（D3）——关羽被动技能：武圣
##
## 效果：攻击使目标恐惧1回合；攻击恐惧目标恢复1点行动点
##
## 设计文档：design/gdd/heroes-design.md
##
## 作者: Claude Code
## 创建日期: 2026-04-12

# 继承自被动技能基类
class_name GuanYuPassiveSkill extends PassiveSkill

## 触发时机：造成伤害时
func _init() -> void:
	super._init("武圣", "攻击使目标恐惧1回合；攻击恐惧目标恢复1点行动点", "关羽")
	# 注册触发时机
	trigger_timings.append(TriggerTiming.ON_DAMAGE_DEALT)


## 造成伤害时触发
## 参数：
##   damage: 伤害值
##   target: 目标
func on_damage_dealt(hero: HeroManager.HeroData, damage: int, target: Node, battle_manager: Node) -> bool:
	# 检查是否攻击了敌人
	if target != null and target.is_enemy:
		# 获取StatusManager
		var status_manager = battle_manager.status_manager

		# 施加恐惧状态
		status_manager.apply(StatusEffect.Type.FEAR, 1, "关羽：武圣")

		# 检查目标是否处于恐惧状态
		if status_manager.get_layers(StatusEffect.Type.FEAR) > 0:
			# 恢复1点行动点
			var resource_manager = battle_manager.resource_manager
			var current_ap = resource_manager.get_action_points()
			var max_ap = resource_manager.get_max_action_points()
			var actual_restore = min(1, max_ap - current_ap)
			if actual_restore > 0:
				resource_manager.modify_resource(ResourceManager.ResourceType.ACTION_POINTS, actual_restore)
				return true

	return false