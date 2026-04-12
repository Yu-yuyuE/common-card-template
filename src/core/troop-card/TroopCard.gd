## TroopCard.gd
## 兵种卡系统（D2）——兵种卡数据结构
##
## 职责：定义兵种卡的属性和效果
## 位置：作为Card的子类或独立数据结构
##
## 设计文档：design/gdd/troop-cards-design.md
## 依赖：
##   - CardData（卡牌基础数据）
##   - BattleManager（战斗管理器）
##
## 使用示例：
##   var troop := TroopCard.new(troop_data)
##   troop.execute_lv1_effect(battle_manager, target_pos)

# 继承自Card基类
class_name TroopCard extends Card

# ---------------------------------------------------------------------------
# 兵种类型枚举
# ---------------------------------------------------------------------------

## 兵种类型
enum TroopType {
	INFANTRY = 0,    ## 步兵
	CAVALRY = 1,     ## 骑兵
	ARCHER = 2,      ## 弓兵
	STRATEGIST = 3,  ## 谋士
	SHIELD = 4,      ## 盾兵
}

# ---------------------------------------------------------------------------
# 兵种卡数据
# ---------------------------------------------------------------------------

## 兵种类型
var troop_type: TroopType = TroopType.INFANTRY

## Lv1伤害值
var lv1_damage: int = 0

## Lv1护盾值（盾兵专用）
var lv1_shield: int = 0

## Lv1特殊效果描述
var lv1_effect: String = ""

## Lv2伤害值
var lv2_damage: int = 0

## Lv2护盾值
var lv2_shield: int = 0

## Lv2效果描述
var lv2_effect: String = ""

## 当前等级（1-3）
var current_level: int = 1

## Lv3分支（如果有）
var lv3_branch: String = ""

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 创建兵种卡实例
func _init(card_data: CardData) -> void:
	super._init(card_data)
	# 从CardData中解析兵种卡特定属性
	# 实际实现需要根据CardData的结构来提取
	current_level = 1


## 设置兵种类型
func set_troop_type(type: TroopType) -> void:
	troop_type = type


## 设置Lv1属性
func set_lv1_stats(damage: int, shield: int = 0, effect: String = "") -> void:
	lv1_damage = damage
	lv1_shield = shield
	lv1_effect = effect


## 设置Lv2属性
func set_lv2_stats(damage: int, shield: int = 0, effect: String = "") -> void:
	lv2_damage = damage
	lv2_shield = shield
	lv2_effect = effect


## 升级到Lv2
func upgrade_to_lv2() -> bool:
	if current_level != 1:
		return false
	current_level = 2
	return true


## 升级到Lv3（带分支选择）
func upgrade_to_lv3(branch: String) -> bool:
	if current_level != 2:
		return false
	current_level = 3
	lv3_branch = branch
	return true

# ---------------------------------------------------------------------------
# 效果执行
# ---------------------------------------------------------------------------

## 执行当前等级的效果
## 参数：
##   battle_manager: 战斗管理器
##   target_pos: 目标位置（0-2为敌人，-1为己方）
## 返回：是否成功执行
func execute_effect(battle_manager: Node, target_pos: int) -> bool:
	match current_level:
		1:
			return execute_lv1_effect(battle_manager, target_pos)
		2:
			return execute_lv2_effect(battle_manager, target_pos)
		3:
			return execute_lv3_effect(battle_manager, target_pos)
		_:
			return false


## 执行Lv1效果
func execute_lv1_effect(battle_manager: Node, target_pos: int) -> bool:
	match troop_type:
		TroopType.ARCHER:
			# 弓兵：对任意目标造成7点伤害
			return _execute_damage_effect(battle_manager, target_pos, lv1_damage, true)

		TroopType.INFANTRY:
			# 步兵：对目标造成8点伤害
			return _execute_damage_effect(battle_manager, target_pos, lv1_damage, false)

		TroopType.CAVALRY:
			# 骑兵：造成5点伤害 + 击退
			var damage_result = _execute_damage_effect(battle_manager, target_pos, lv1_damage, false)
			var knockback_result = _execute_knockback(battle_manager, target_pos)
			return damage_result or knockback_result

		TroopType.STRATEGIST:
			# 谋士：对任意目标造成7点伤害
			return _execute_damage_effect(battle_manager, target_pos, lv1_damage, true)

		TroopType.SHIELD:
			# 盾兵：获得8点护盾
			return _execute_shield_effect(battle_manager, lv1_shield)

		_:
			return false


## 执行Lv2效果（占位，由Story 4-2实现）
func execute_lv2_effect(battle_manager: Node, target_pos: int) -> bool:
	# 待Story 4-2实现
	return false


## 执行Lv3效果（占位，由Story 4-5/4-6实现）
func execute_lv3_effect(battle_manager: Node, target_pos: int) -> bool:
	# 待Story 4-5/4-6实现
	return false

# ---------------------------------------------------------------------------
# 内部效果实现
# ---------------------------------------------------------------------------

## 执行伤害效果
## 参数：
##   battle_manager: 战斗管理器
##   target_pos: 目标位置
##   base_damage: 基础伤害值
##   can_target_any: 是否可以攻击任意目标
## 返回：是否成功执行
func _execute_damage_effect(battle_manager: Node, target_pos: int, base_damage: int, can_target_any: bool) -> bool:
	# 获取目标实体
	var target_entity = null

	if target_pos >= 0 and target_pos < battle_manager.enemy_entities.size():
		target_entity = battle_manager.enemy_entities[target_pos]
	else:
		push_warning("TroopCard: 无效的目标位置 %d" % target_pos)
		return false

	# 应用伤害
	if target_entity != null:
		# 使用DamageCalculator计算最终伤害（集成地形天气修正）
		var final_damage: int

		if battle_manager.terrain_weather_manager != null:
			var damage_calculator = DamageCalculator.new()
			final_damage = damage_calculator.calculate_damage(
				base_damage,
				troop_type,
				battle_manager.terrain_weather_manager
			)
		else:
			# 如果没有地形天气管理器，使用基础伤害
			final_damage = base_damage

		# 应用伤害到目标
		target_entity.current_hp -= final_damage
		if target_entity.current_hp < 0:
			target_entity.current_hp = 0

		return true

	return false


## 执行护盾效果
## 参数：
##   battle_manager: 战斗管理器
##   shield_amount: 护盾值
## 返回：是否成功执行
func _execute_shield_effect(battle_manager: Node, shield_amount: int) -> bool:
	var resource_manager = battle_manager.resource_manager

	if resource_manager != null:
		# 增加护盾
		resource_manager.modify_resource(ResourceManager.ResourceType.ARMOR, shield_amount)
		return true

	return false


## 执行击退效果
## 参数：
##   battle_manager: 战斗管理器
##   target_pos: 目标位置
## 返回：是否成功执行
func _execute_knockback(battle_manager: Node, target_pos: int) -> bool:
	# 击退逻辑：
	# 1. 如果目标在后排（position > 0），无效果
	# 2. 如果目标在前排（position == 0），移动到后排
	# 3. 如果后排有敌人，互换位置

	# 这里需要战场阵型管理器支持
	# 暂时发送信号或简单处理

	# 发射击退信号，由BattleManager处理
	if battle_manager.has_signal("knockback_triggered"):
		battle_manager.knockback_triggered.emit(target_pos)
		return true

	return false


# ---------------------------------------------------------------------------
# 工具方法
# ---------------------------------------------------------------------------

## 获取兵种类型名称
static func get_troop_type_name(type: TroopType) -> String:
	match type:
		TroopType.INFANTRY: return "步兵"
		TroopType.CAVALRY: return "骑兵"
		TroopType.ARCHER: return "弓兵"
		TroopType.STRATEGIST: return "谋士"
		TroopType.SHIELD: return "盾兵"
		_: return "未知兵种"


## 检查是否是兵种卡
func is_troop_card() -> bool:
	return true


## 获取当前等级的伤害值
func get_current_damage() -> int:
	match current_level:
		1: return lv1_damage
		2: return lv2_damage
		_: return lv1_damage


## 获取当前等级的护盾值
func get_current_shield() -> int:
	match current_level:
		1: return lv1_shield
		2: return lv2_shield
		_: return lv1_shield