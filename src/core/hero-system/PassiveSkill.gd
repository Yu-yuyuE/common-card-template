## PassiveSkill.gd
## 武将系统（D3）——被动技能基类
##
## 职责：定义被动技能的事件钩子和触发逻辑
## 位置：作为HeroManager的子组件
##
## 设计文档：design/gdd/heroes-design.md
##
## 使用示例：
##   var skill := PassiveSkill.new("挟令诸侯", "每次使用兵种卡可对随机敌人施加1层虚弱")
##   skill.on_card_played(hero, card, target, battle_manager)

class_name PassiveSkill extends RefCounted

# ---------------------------------------------------------------------------
# 被动技能类型枚举
# ---------------------------------------------------------------------------

## 触发时机类型
enum TriggerTiming {
	ON_ROUND_START,      ## 回合开始
	ON_ROUND_END,        ## 回合结束
	ON_CARD_PLAYED,      ## 出牌时
	ON_DAMAGE_TAKEN,     ## 受击时
	ON_DAMAGE_DEALT,     ## 造成伤害时
	ON_CARD_DRAWN,       ## 抽牌时
	ON_STATUS_APPLIED,   ## 状态施加时
	ON_ENEMY_KILLED,     ## 敌人死亡时
	ON_HEAL_RECEIVED,    ## 受到治疗时
	ON_SHIELD_GAINED,    ## 获得护盾时
	ON_DODGE_SUCCESS,    ## 闪避成功时
	ON_CRITICAL_HIT,     ## 暴击时
}

# ---------------------------------------------------------------------------
# 被动技能数据
# ---------------------------------------------------------------------------

## 技能名称
var skill_name: String = ""

## 技能效果描述
var skill_description: String = ""

## 所属武将
var owner_hero: String = ""

## 触发时机列表
var trigger_timings: Array[TriggerTiming] = []

## 是否激活
var is_active: bool = true

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 创建被动技能实例
func _init(p_name: String, p_description: String, p_owner: String = "") -> void:
	skill_name = p_name
	skill_description = p_description
	owner_hero = p_owner
	is_active = true

# ---------------------------------------------------------------------------
# 事件钩子 - 由子类重写
# ---------------------------------------------------------------------------

## 回合开始时触发
## 参数：
##   hero: 当前武将数据
##   battle_manager: 战斗管理器引用
## 返回：是否成功触发
func on_round_start(hero: HeroManager.HeroData, battle_manager: Node) -> bool:
	return false


## 回合结束时触发
func on_round_end(hero: HeroManager.HeroData, battle_manager: Node) -> bool:
	return false


## 出牌时触发
## 参数：
##   card: 打出的卡牌
##   target: 目标
func on_card_played(hero: HeroManager.HeroData, card: Node, target: Node, battle_manager: Node) -> bool:
	return false


## 受击时触发
## 参数：
##   damage: 伤害值
##   source: 伤害来源
func on_damage_taken(hero: HeroManager.HeroData, damage: int, source: Node, battle_manager: Node) -> bool:
	return false


## 造成伤害时触发
func on_damage_dealt(hero: HeroManager.HeroData, damage: int, target: Node, battle_manager: Node) -> bool:
	return false


## 抽牌时触发
func on_card_drawn(hero: HeroManager.HeroData, card: Node, battle_manager: Node) -> bool:
	return false


## 状态施加时触发
func on_status_applied(hero: HeroManager.HeroData, status_type: int, battle_manager: Node) -> bool:
	return false


## 敌人死亡时触发
func on_enemy_killed(hero: HeroManager.HeroData, enemy: Node, battle_manager: Node) -> bool:
	return false


## 受到治疗时触发
func on_heal_received(hero: HeroManager.HeroData, heal_amount: int, battle_manager: Node) -> bool:
	return false


## 获得护盾时触发
func on_shield_gained(hero: HeroManager.HeroData, shield_amount: int, battle_manager: Node) -> bool:
	return false


## 闪避成功时触发
func on_dodge_success(hero: HeroManager.HeroData, battle_manager: Node) -> bool:
	return false


## 暴击时触发
func on_critical_hit(hero: HeroManager.HeroData, damage: int, target: Node, battle_manager: Node) -> bool:
	return false

# ---------------------------------------------------------------------------
# 工具方法
# ---------------------------------------------------------------------------

## 检查是否支持指定触发时机
func supports_trigger(timing: TriggerTiming) -> bool:
	return timing in trigger_timings


## 激活技能
func activate() -> void:
	is_active = true


## 停用技能
func deactivate() -> void:
	is_active = false


## 获取技能信息
func get_info() -> Dictionary:
	return {
		"name": skill_name,
		"description": skill_description,
		"owner": owner_hero,
		"active": is_active,
		"triggers": trigger_timings
	}