## PassiveSkillManager.gd
## 武将系统（D3）——被动技能管理器
##
## 职责：管理所有被动技能的注册和事件分发
## 位置：作为BattleManager的子组件
##
## 设计文档：design/gdd/heroes-design.md
##
## 使用示例：
##   var psm := PassiveSkillManager.new()
##   psm.register_skill(skill)
##   psm.trigger_event(PassiveSkill.TriggerTiming.ON_ROUND_START, hero, battle_manager)

class_name PassiveSkillManager extends Node

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## 被动技能触发时发射
## 参数：skill_name, trigger_timing, effect_applied
signal skill_triggered(skill_name: String, trigger_timing: int, effect_applied: bool)

# ---------------------------------------------------------------------------
# 内部状态
# ---------------------------------------------------------------------------

## 注册的被动技能列表
var _registered_skills: Array[PassiveSkill] = []

## 当前武将引用
var _current_hero: HeroManager.HeroData = null

## BattleManager引用
var _battle_manager: Node = null

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 设置BattleManager引用
func set_battle_manager(battle_mgr: Node) -> void:
	_battle_manager = battle_mgr


## 设置当前武将
func set_current_hero(hero: HeroManager.HeroData) -> void:
	_current_hero = hero


## 注册被动技能
func register_skill(skill: PassiveSkill) -> void:
	if skill != null and not _registered_skills.has(skill):
		_registered_skills.append(skill)
		print("PassiveSkillManager: 注册被动技能 '%s'" % skill.skill_name)


## 注销被动技能
func unregister_skill(skill: PassiveSkill) -> void:
	if skill != null and _registered_skills.has(skill):
		_registered_skills.erase(skill)


## 清空所有技能
func clear_skills() -> void:
	_registered_skills.clear()


## 获取所有注册的技能
func get_registered_skills() -> Array[PassiveSkill]:
	return _registered_skills

# ---------------------------------------------------------------------------
# 事件触发接口
# ---------------------------------------------------------------------------

## 触发回合开始事件
func trigger_round_start() -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_ROUND_START):
			var result = skill.on_round_start(_current_hero, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_ROUND_START, result)


## 触发回合结束事件
func trigger_round_end() -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_ROUND_END):
			var result = skill.on_round_end(_current_hero, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_ROUND_END, result)


## 触发出牌事件
func trigger_card_played(card: Node, target: Node) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_CARD_PLAYED):
			var result = skill.on_card_played(_current_hero, card, target, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_CARD_PLAYED, result)


## 触发受击事件
func trigger_damage_taken(damage: int, source: Node) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_DAMAGE_TAKEN):
			var result = skill.on_damage_taken(_current_hero, damage, source, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_DAMAGE_TAKEN, result)


## 触发造成伤害事件
func trigger_damage_dealt(damage: int, target: Node) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_DAMAGE_DEALT):
			var result = skill.on_damage_dealt(_current_hero, damage, target, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_DAMAGE_DEALT, result)


## 触发抽牌事件
func trigger_card_drawn(card: Node) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_CARD_DRAWN):
			var result = skill.on_card_drawn(_current_hero, card, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_CARD_DRAWN, result)


## 触发状态施加事件
func trigger_status_applied(status_type: int) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_STATUS_APPLIED):
			var result = skill.on_status_applied(_current_hero, status_type, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_STATUS_APPLIED, result)


## 触发敌人死亡事件
func trigger_enemy_killed(enemy: Node) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_ENEMY_KILLED):
			var result = skill.on_enemy_killed(_current_hero, enemy, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_ENEMY_KILLED, result)


## 触发受到治疗事件
func trigger_heal_received(heal_amount: int) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_HEAL_RECEIVED):
			var result = skill.on_heal_received(_current_hero, heal_amount, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_HEAL_RECEIVED, result)


## 触发获得护盾事件
func trigger_shield_gained(shield_amount: int) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_SHIELD_GAINED):
			var result = skill.on_shield_gained(_current_hero, shield_amount, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_SHIELD_GAINED, result)


## 触发闪避成功事件
func trigger_dodge_success() -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_DODGE_SUCCESS):
			var result = skill.on_dodge_success(_current_hero, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_DODGE_SUCCESS, result)


## 触发暴击事件
func trigger_critical_hit(damage: int, target: Node) -> void:
	for skill in _registered_skills:
		if skill.is_active and skill.supports_trigger(PassiveSkill.TriggerTiming.ON_CRITICAL_HIT):
			var result = skill.on_critical_hit(_current_hero, damage, target, _battle_manager)
			skill_triggered.emit(skill.skill_name, PassiveSkill.TriggerTiming.ON_CRITICAL_HIT, result)