## XiahouDunPassiveSkill.gd
## 武将系统（D3）——夏侯惇被动技能：骁勇
##
## 效果：受到攻击时，若HP低于50%，则恢复20%最大HP
##
## 设计文档：design/gdd/heroes-design.md
##
## 作者: Claude Code
## 创建日期: 2026-04-12

# 继承自被动技能基类
class_name XiahouDunPassiveSkill extends PassiveSkill

## 触发时机：受击时
func _init() -> void:
	super._init("骁勇", "受到攻击时，若HP低于50%，则恢复20%最大HP", "夏侯惇")
	# 注册触发时机
	trigger_timings.append(TriggerTiming.ON_DAMAGE_TAKEN)


## 受击时触发
func on_damage_taken(hero: HeroManager.HeroData, damage: int, source: Node, battle_manager: Node) -> bool:
	# 检查是否HP低于50%
	var resource_manager = battle_manager.resource_manager
	var current_hp = resource_manager.get_hp()
	var max_hp = resource_manager.get_max_hp()
	var hp_percent = float(current_hp) / float(max_hp)

	if hp_percent < 0.5:
		# 恢复20%最大HP
		var restore_amount = int(max_hp * 0.2)
		var actual_restore = min(restore_amount, max_hp - current_hp)
		if actual_restore > 0:
			resource_manager.modify_resource(ResourceManager.ResourceType.HP, actual_restore)
			return true
	return false