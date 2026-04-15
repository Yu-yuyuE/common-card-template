## ResourceManager.gd
## 资源管理系统（F2）——HP / 护盾 / 粮草 / 金币 / 行动点
##
## 职责：集中管理游戏核心资源，提供统一的增减接口和信号通知
## 位置：作为 GameState 的子节点
##
## 设计文档：design/gdd/resource-management-system.md
## 依赖：HeroManager（提供武将 MaxHP 和基础行动点）

class_name ResourceManager extends Node

# ---------------------------------------------------------------------------
# 资源类型枚举
# ---------------------------------------------------------------------------

## 资源类型
enum ResourceType {
	HP = 0,           ## 生命值
	ARMOR = 1,        ## 护盾
	PROVISIONS = 2,   ## 粮草
	GOLD = 3,         ## 金币
	ACTION_POINTS = 4 ## 行动点
}

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## 资源变化时发射（统一信号）
## 参数：resource_type, old_value, new_value, delta
signal resource_changed(resource_type: int, old_value: int, new_value: int, delta: int)

## HP 归零时发射（战斗失败触发点）
signal hp_depleted()

## 粮草归零且需额外扣 HP 时发射
signal food_penalty_applied(hp_cost: int)

# ---------------------------------------------------------------------------
# 常量
# ---------------------------------------------------------------------------

const FOOD_MAX: int = 150              ## 粮草上限
const GOLD_MAX: int = 99999            ## 金币上限

# ---------------------------------------------------------------------------
# 资源存储
# ---------------------------------------------------------------------------

## 当前资源值
var resources: Dictionary = {}

## 资源上限
var max_values: Dictionary = {}

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

func _ready() -> void:
	# 查找 HeroManager（作为父节点）
	# 优先检查父节点是否就是 HeroManager
	var hero_manager = get_parent()
	if hero_manager == null or hero_manager.name != "HeroManager":
		push_error("ResourceManager: HeroManager not found as parent node. Resource initialization requires hero data.")
		return

	# 从 HeroManager 获取武将属性
	var max_hp: int = hero_manager.max_hp
	var base_ap: int = hero_manager.base_ap
	var armor_max: int = hero_manager.get_armor_max()  # Story 003: 根据武将类型决定护盾上限

	# 初始化资源值
	_init_resource(ResourceType.HP, max_hp, max_hp)
	_init_resource(ResourceType.ARMOR, 0, armor_max)  # Story 003: 护盾上限按武将类型决定
	_init_resource(ResourceType.PROVISIONS, FOOD_MAX, FOOD_MAX)
	_init_resource(ResourceType.GOLD, 0, GOLD_MAX)
	_init_resource(ResourceType.ACTION_POINTS, base_ap, base_ap)


## 初始化单个资源
func _init_resource(type: int, initial_value: int, max_value: int) -> void:
	resources[type] = initial_value
	max_values[type] = max_value

# ---------------------------------------------------------------------------
# 公共接口
# ---------------------------------------------------------------------------

## 获取资源当前值
func get_resource(type: int) -> int:
	return resources.get(type, 0)


## 获取资源上限
func get_max_resource(type: int) -> int:
	return max_values.get(type, 0)


## 修改资源值（统一接口）
## 返回：实际变化量（可能因上限/下限而与请求的不同）
func modify_resource(type: int, delta: int) -> int:
	var old_value = resources.get(type, 0)
	var max_value = max_values.get(type, 0)

	var new_value: int
	# 处理护盾无上限的情况 (max_value == -1)
	if type == ResourceType.ARMOR and max_value == -1:
		new_value = max(0, old_value + delta)
	else:
		new_value = clamp(old_value + delta, 0, max_value)

	var actual_delta = new_value - old_value

	if actual_delta != 0:
		resources[type] = new_value
		resource_changed.emit(type, old_value, new_value, actual_delta)

		# 特殊事件
		if type == ResourceType.HP and new_value <= 0:
			hp_depleted.emit()
		elif type == ResourceType.PROVISIONS and new_value == 0 and delta < 0:
			# 粮草归零，但不在这里发射 food_penalty_applied 信号
			# 该信号由 consume_provisions() 方法在地图移动场景中发射
			# 因为只有那时才知道具体的移动代价和 HP 惩罚金额
			pass

	return actual_delta

# ---------------------------------------------------------------------------
# 便捷方法
# ---------------------------------------------------------------------------

## 获取 HP
func get_hp() -> int:
	return get_resource(ResourceType.HP)

## 获取 HP 上限
func get_max_hp() -> int:
	return get_max_resource(ResourceType.HP)

## 获取护盾
func get_armor() -> int:
	return get_resource(ResourceType.ARMOR)

## 获取护盾上限
func get_armor_max() -> int:
	return get_max_resource(ResourceType.ARMOR)

## 获取粮草
func get_provisions() -> int:
	return get_resource(ResourceType.PROVISIONS)

## 获取金币
func get_gold() -> int:
	return get_resource(ResourceType.GOLD)

## 获取行动点
func get_action_points() -> int:
	return get_resource(ResourceType.ACTION_POINTS)

## 获取行动点上限
func get_max_action_points() -> int:
	return get_max_resource(ResourceType.ACTION_POINTS)

## 减少 HP（伤害）
func damage_hp(amount: int) -> int:
	return modify_resource(ResourceType.HP, -amount)


## 受到伤害（护盾优先吸收，溢出扣 HP）
## AC-2: 护盾吸收伤害，AC-3: 护盾溢出扣 HP
##
## 伤害结算公式（非穿透模式）：
##   armor_damage = min(damage, current_armor)
##   hp_damage = max(0, damage - current_armor)
##   new_armor = current_armor - armor_damage
##   new_hp = current_hp - hp_damage
##
## 参数：
##   damage — 伤害值（正数）
##   pierce — 是否穿透护盾（true=直接扣HP，false=护盾优先）
## 返回：实际受到的 HP 伤害（非穿透模式下包含溢出部分）
func apply_damage(damage: int, pierce: bool = false) -> int:
	if damage <= 0:
		return 0

	var current_armor: int = get_armor()
	var current_hp: int = get_hp()

	var hp_damage: int = 0
	var total_damage: int = 0

	if pierce:
		# 穿透模式：直接扣 HP，护盾不变
		hp_damage = damage
	else:
		# 非穿透模式：护盾优先吸收，溢出扣 HP
		# 计算护盾吸收的伤害
		var armor_damage: int = min(damage, current_armor)
		# 计算溢出到 HP 的伤害
		hp_damage = max(0, damage - current_armor)

		# 先扣护盾
		if armor_damage > 0:
			var actual_armor_delta: int = modify_resource(ResourceType.ARMOR, -armor_damage)
			total_damage += -actual_armor_delta

	# 扣 HP（无论穿透与否）
	if hp_damage > 0:
		var actual_hp_delta: int = modify_resource(ResourceType.HP, -hp_damage)
		total_damage += -actual_hp_delta

	return total_damage

## 恢复 HP
func heal_hp(amount: int) -> int:
	return modify_resource(ResourceType.HP, amount)

## 增加护盾
func add_armor(amount: int) -> int:
	return modify_resource(ResourceType.ARMOR, amount)

## 消耗行动点
func spend_action_points(amount: int) -> bool:
	var current = get_action_points()
	if current < amount:
		return false
	modify_resource(ResourceType.ACTION_POINTS, -amount)
	return true

## 恢复行动点
func restore_action_points(amount: int) -> int:
	return modify_resource(ResourceType.ACTION_POINTS, amount)

## 消耗粮草（用于地图移动）
## 返回：是否成功（HP 未耗尽）
func consume_provisions(amount: int) -> bool:
	var current = get_provisions()
	if current >= amount:
		modify_resource(ResourceType.PROVISIONS, -amount)
		return true
	else:
		# 粮草不足，差额扣 HP
		var hp_cost = amount - current
		modify_resource(ResourceType.PROVISIONS, -current)  # 粮草归零
		modify_resource(ResourceType.HP, -hp_cost)
		food_penalty_applied.emit(hp_cost)
		return get_hp() > 0

## 恢复粮草
func restore_provisions(amount: int) -> int:
	return modify_resource(ResourceType.PROVISIONS, amount)

## 增加金币
func add_gold(amount: int) -> int:
	return modify_resource(ResourceType.GOLD, amount)

## 消耗金币
func spend_gold(amount: int) -> bool:
	var current = get_gold()
	if current < amount:
		return false
	modify_resource(ResourceType.GOLD, -amount)
	return true

# ---------------------------------------------------------------------------
# 战斗相关
# ---------------------------------------------------------------------------

## 战斗结束时调用：清零护盾与行动点
func on_battle_end() -> void:
	# 护盾清零
	if get_armor() > 0:
		modify_resource(ResourceType.ARMOR, -get_armor())
	# 行动点清零
	if get_action_points() > 0:
		modify_resource(ResourceType.ACTION_POINTS, -get_action_points())


## 设置护盾上限（用于特殊武将如曹仁、张角）
func set_armor_max(new_max: int) -> void:
	if new_max == -1:
		# 无上限（张角）
		max_values[ResourceType.ARMOR] = -1
	else:
		max_values[ResourceType.ARMOR] = new_max
		# 如果当前护盾超过新上限，裁剪
		if get_armor() > new_max:
			modify_resource(ResourceType.ARMOR, get_armor() - new_max)


# ---------------------------------------------------------------------------
# 资源恢复机制 (Story 2-6)
# ---------------------------------------------------------------------------

## Boss战胜利后恢复资源
## - HP完全恢复至上限
## - 粮草恢复50点，上限150
func on_boss_victory() -> void:
	# HP完全恢复
	var max_hp = get_max_hp()
	var current_hp = get_hp()
	if current_hp < max_hp:
		modify_resource(ResourceType.HP, max_hp - current_hp)

	# 粮草恢复50点，上限150
	restore_provisions(50)


## 大地图切换时重置粮草
## - 粮草重置为150
func on_new_map() -> void:
	# 粮草重置为上限150
	var current_provisions = get_provisions()
	var target = FOOD_MAX
	if current_provisions != target:
		# 直接设置为150
		var delta = target - current_provisions
		modify_resource(ResourceType.PROVISIONS, delta)


## 完全恢复HP至上限
## 用于酒馆、卡牌、事件等场景
func full_heal() -> void:
	var max_hp = get_max_hp()
	var current_hp = get_hp()
	if current_hp < max_hp:
		modify_resource(ResourceType.HP, max_hp - current_hp)


## 恢复HP（带上限检查）
## 参数：amount - 恢复量
## 返回：实际恢复量
func restore_hp(amount: int) -> int:
	var max_hp = get_max_hp()
	var current_hp = get_hp()
	var actual_restore = min(amount, max_hp - current_hp)
	return modify_resource(ResourceType.HP, actual_restore)


# ---------------------------------------------------------------------------
# 测试便捷初始化（不依赖 HeroManager 父节点）
# ---------------------------------------------------------------------------

## 直接初始化资源，无需父节点为 HeroManager。专供单元/集成测试使用。
## 参数：
##   max_hp            — 最大生命值（当前 HP 同时设为此值）
##   base_ap           — 基础行动点上限（当前 AP 同时设为此值）
##   armor_max_override — 护盾上限（默认 20）
## 示例：
##   var rm := ResourceManager.new()
##   rm.init_hero(50, 4)
func init_hero(max_hp: int, base_ap: int, armor_max_override: int = 20) -> void:
	_init_resource(ResourceType.HP, max_hp, max_hp)
	_init_resource(ResourceType.ARMOR, 0, armor_max_override)
	_init_resource(ResourceType.PROVISIONS, FOOD_MAX, FOOD_MAX)
	_init_resource(ResourceType.GOLD, 0, GOLD_MAX)
	_init_resource(ResourceType.ACTION_POINTS, base_ap, base_ap)
