## ResourceManager.gd
## 资源管理系统（F2）——HP / 护盾 / 行动点 / 粮草核心管理
##
## 职责：追踪并结算四类原始资源（HP、护盾、行动点、粮草）的读写。
##       本系统是纯状态容器与数值接口，不含游戏逻辑决策。
##       每个需要资源管理的实体（英雄、敌人）各自持有一个实例。
##
## 设计文档：design/gdd/resource-management-system.md
## 依赖：无（StatusManager 依赖本类，本类不依赖 StatusManager）
##
## 使用示例（战斗内）：
##   var rm := ResourceManager.new()
##   rm.init_hero(max_hp, base_ap)
##   rm.apply_damage(10, false)   # 普通攻击，走护盾
##   rm.apply_damage(4,  true)    # 中毒穿透护盾
##   rm.spend_ap(2)               # 出牌消耗行动点

class_name ResourceManager extends RefCounted

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## HP 变化时发射（回复为正值，伤害为负值）
signal hp_changed(new_hp: int, delta: int)

## 护盾变化时发射
signal armor_changed(new_armor: int, delta: int)

## 行动点变化时发射
signal ap_changed(new_ap: int, delta: int)

## 粮草变化时发射
signal food_changed(new_food: int, delta: int)

## HP 归零时发射（战斗失败触发点）
signal hp_depleted()

## 粮草归零且需额外扣 HP 时发射（参数：hp_cost = 本次扣 HP 量）
signal food_penalty_applied(hp_cost: int)

# ---------------------------------------------------------------------------
# 常量（数据驱动调节旋钮——可从外部配置覆盖）
# ---------------------------------------------------------------------------

## 粮草全局上限
const FOOD_MAX: int = 150
## Boss 奖励粮草量
const FOOD_BOSS_REWARD: int = 50

# ---------------------------------------------------------------------------
# 资源字段（私有，通过属性/方法读写）
# ---------------------------------------------------------------------------

var _max_hp    : int = 50
var _hp        : int = 50
var _armor     : int = 0
var _armor_max : int = 50   # 默认 = MaxHP；曹仁 = MaxHP+30；张角 = -1（无上限）

var _base_ap   : int = 3    # 武将基础行动点（3–4）
var _max_ap    : int = 3    # 当前上限（base + 装备增量）
var _ap        : int = 0

var _food      : int = 0

# 装备持久增量（跨战斗累积）
var _equipment_ap_bonus  : int = 0
var _equipment_hp_bonus  : int = 0

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 以英雄属性初始化资源管理器，在每场战斗开始前调用。
##
## 参数：
##   p_max_hp   — 武将 HP 上限（40–60）
##   p_base_ap  — 武将基础行动点（3–4）
##   p_armor_max_override — 护盾上限覆盖值：
##                          -1 = 无上限（张角），
##                           0 = 使用默认（= MaxHP），
##                          >0 = 具体值（如曹仁 MaxHP+30）
##
## 示例：
##   rm.init_hero(50, 3)              # 普通武将
##   rm.init_hero(60, 4, 90)          # 曹仁（MaxHP+30）
##   rm.init_hero(45, 3, -1)          # 张角（无护盾上限）
func init_hero(
	p_max_hp          : int,
	p_base_ap         : int,
	p_armor_max_override: int = 0
) -> void:
	_base_ap = p_base_ap
	_max_hp  = p_max_hp + _equipment_hp_bonus
	_hp      = _max_hp
	_armor   = 0
	_armor_max = _calc_armor_max(p_armor_max_override)
	_max_ap  = _base_ap + _equipment_ap_bonus
	_ap      = _max_ap   # 战斗开始时行动点加满（设计文档 §3）
	# 粮草不在战斗内初始化，由地图系统管理


## 大地图切换时调用，粮草重置为满值（设计文档 §3.4）。
func init_map() -> void:
	_set_food(FOOD_MAX)


# ---------------------------------------------------------------------------
# 只读属性访问器
# ---------------------------------------------------------------------------

## 当前 HP
func get_hp()       -> int: return _hp
## HP 上限
func get_max_hp()   -> int: return _max_hp
## 当前护盾值
func get_armor()    -> int: return _armor
## 护盾上限（-1 = 无上限）
func get_armor_max()-> int: return _armor_max
## 当前行动点
func get_ap()       -> int: return _ap
## 行动点上限
func get_max_ap()   -> int: return _max_ap
## 当前粮草
func get_food()     -> int: return _food

# ---------------------------------------------------------------------------
# 伤害结算（F1 / F6）
# ---------------------------------------------------------------------------

## 对该单位施加伤害，自动处理护盾/HP 扣减。
##
## 参数：
##   amount        — 伤害量（>= 0）
##   pierce_armor  — true = 穿透护盾（中毒/剧毒/瘟疫/重伤）；
##                   false = 走护盾（普通攻击 / 灼烧）
##
## 返回：实际扣除的 HP 量（护盾全挡时为 0）
##
## 公式（F1）：
##   DamageToHP = max(0, amount - CurrentArmor)
##   NewArmor   = max(0, CurrentArmor - amount)
##   NewHP      = CurrentHP - DamageToHP
##
## 示例：
##   rm.apply_damage(15, false)  # 15点灼烧，护盾先挡
##   rm.apply_damage(12, true)   # 12点中毒，直接扣HP
func apply_damage(amount: int, pierce_armor: bool) -> int:
	assert(amount >= 0, "伤害量不能为负数")
	if amount == 0:
		return 0

	var hp_cost: int = 0
	if pierce_armor:
		# 穿透护盾：直接扣 HP
		hp_cost = amount
		_set_hp(_hp - hp_cost)
	else:
		# 走护盾：护盾先抵挡，溢出扣 HP（F1）
		var armor_absorbed: int = mini(amount, _armor)
		hp_cost = amount - armor_absorbed
		if armor_absorbed > 0:
			_set_armor(_armor - armor_absorbed)
		if hp_cost > 0:
			_set_hp(_hp - hp_cost)
	return hp_cost


## 施加坚守（B4）修正后的伤害。
## 依据设计文档 E10：先乘修正系数，再调用 apply_damage 走护盾流程。
##
## 参数：
##   raw_damage        — 基础伤害
##   damage_multiplier — 来自 StatusManager.get_incoming_damage_multiplier()
##   pierce_armor      — 是否穿透护盾
##
## 示例：
##   var mult := hero_sm.get_incoming_damage_multiplier()  # 包含坚守/破甲
##   rm.apply_modified_damage(20, mult, false)
func apply_modified_damage(
	raw_damage        : int,
	damage_multiplier : float,
	pierce_armor      : bool
) -> int:
	var final_dmg := roundi(float(raw_damage) * damage_multiplier)
	return apply_damage(maxi(0, final_dmg), pierce_armor)

# ---------------------------------------------------------------------------
# 治疗与护盾恢复
# ---------------------------------------------------------------------------

## 恢复 HP，不超过 HP 上限。
##
## 示例：
##   rm.heal(10)   # 酒馆节点治疗
func heal(amount: int) -> void:
	assert(amount >= 0)
	_set_hp(mini(_hp + amount, _max_hp))


## 增加护盾值，受护盾上限约束。
##
## 示例：
##   rm.add_armor(5)   # 防御卡施加护盾
func add_armor(amount: int) -> void:
	assert(amount >= 0)
	if _armor_max == -1:
		# 无上限（张角）
		_set_armor(_armor + amount)
	else:
		_set_armor(mini(_armor + amount, _armor_max))


## Boss 战胜后完全恢复 HP（F7）。
func restore_hp_full() -> void:
	_set_hp(_max_hp)

# ---------------------------------------------------------------------------
# 行动点管理（F2 / F3）
# ---------------------------------------------------------------------------

## 消耗行动点（出牌时调用）。
##
## 返回：
##   true  = 消耗成功
##   false = 行动点不足
##
## 示例：
##   if rm.spend_ap(2): play_card(card)
func spend_ap(cost: int) -> bool:
	assert(cost >= 0)
	if _ap < cost:
		return false
	_set_ap(_ap - cost)
	return true


## 恢复指定量行动点（不超过上限）。
##
## 示例：
##   rm.restore_ap(1)  # 武将被动恢复行动点
func restore_ap(amount: int) -> void:
	assert(amount >= 0)
	_set_ap(mini(_ap + amount, _max_ap))


## X 费卡打出时调用：X = 当前全部行动点，打出后归零（F3）。
##
## 返回：X 的实际值（打出时的行动点数量）
##
## 示例：
##   var x := rm.spend_all_ap()
##   apply_x_card_effect(x)
func spend_all_ap() -> int:
	var x := _ap
	_set_ap(0)
	return x


## 回合开始时保留行动点（累积规则）：
## 行动点不自动重置，但不超过上限（F2）。
## 此函数由战斗系统在每回合开始时调用，仅做上限裁剪。
##
## 示例：
##   rm.on_round_start_carry_ap()
func on_round_start_carry_ap() -> void:
	# 行动点可累积到下回合，上限 = MaxAP
	_set_ap(mini(_ap, _max_ap))


## 临时提升行动点上限（仅本战有效，不跨战斗）。
## 注：装备增量请使用 add_equipment_ap_bonus()。
##
## 示例：
##   rm.add_temp_ap_cap(1)   # 某张卡临时 +1 行动点上限
func add_temp_ap_cap(amount: int) -> void:
	_max_ap += amount


## 添加装备行动点上限加成（跨战斗累积，须在 init_hero 前设置）。
##
## 示例：
##   rm.add_equipment_ap_bonus(1)
func add_equipment_ap_bonus(amount: int) -> void:
	_equipment_ap_bonus += amount
	_max_ap = _base_ap + _equipment_ap_bonus


## 添加装备 HP 上限加成（跨战斗累积）。
func add_equipment_hp_bonus(amount: int) -> void:
	_equipment_hp_bonus += amount

# ---------------------------------------------------------------------------
# 粮草管理（地图层）
# ---------------------------------------------------------------------------

## 地图移动时消耗粮草；若粮草不足则扣 HP 补足（F4 / F5）。
##
## 参数：
##   node_cost — 该节点的粮草消耗量（2–8，由地图系统传入）
##
## 返回：
##   true  = 移动成功（HP 未归零）
##   false = HP 耗尽，游戏结束
##
## 示例：
##   if not rm.consume_food_for_move(5):
##       trigger_game_over()
func consume_food_for_move(node_cost: int) -> bool:
	assert(node_cost > 0)
	if _food >= node_cost:
		# 粮草充足：正常消耗（恰好归零也不扣 HP，Edge Case §4）
		_set_food(_food - node_cost)
		return true
	else:
		# 粮草不足：差额扣 HP（F5）
		var hp_cost: int = node_cost - _food
		_set_food(0)
		food_penalty_applied.emit(hp_cost)
		_set_hp(_hp - hp_cost)
		return _hp > 0


## 恢复粮草，不超过 FOOD_MAX = 150。
##
## 示例：
##   rm.restore_food(FOOD_BOSS_REWARD)  # Boss 奖励50粮草
func restore_food(amount: int) -> void:
	assert(amount >= 0)
	_set_food(mini(_food + amount, FOOD_MAX))

# ---------------------------------------------------------------------------
# 战斗结束结算
# ---------------------------------------------------------------------------

## 战斗结束时调用：清零护盾与行动点（设计文档 §跨战斗持久化规则）。
## HP 保留当前值（败则由 hp_depleted 信号通知）。
## 粮草不参与战斗，不在此处变动。
##
## 示例：
##   rm.on_battle_end()
func on_battle_end() -> void:
	if _armor != 0:
		_set_armor(0)
	if _ap != 0:
		_set_ap(0)

# ---------------------------------------------------------------------------
# 护盾上限辅助
# ---------------------------------------------------------------------------

func _calc_armor_max(override: int) -> int:
	if override == -1:
		return -1       # 张角：无上限
	if override > 0:
		return override # 曹仁或自定义上限
	return _max_hp      # 默认：等于 MaxHP

# ---------------------------------------------------------------------------
# 内部 setter（集中触发信号）
# ---------------------------------------------------------------------------

func _set_hp(new_val: int) -> void:
	var clamped: int = maxi(0, new_val)
	var delta  : int = clamped - _hp
	if delta == 0:
		return
	_hp = clamped
	hp_changed.emit(_hp, delta)
	if _hp <= 0:
		hp_depleted.emit()


func _set_armor(new_val: int) -> void:
	var clamped: int
	if _armor_max == -1:
		clamped = maxi(0, new_val)
	else:
		clamped = clampi(new_val, 0, _armor_max)
	var delta: int = clamped - _armor
	if delta == 0:
		return
	_armor = clamped
	armor_changed.emit(_armor, delta)


func _set_ap(new_val: int) -> void:
	var clamped: int = clampi(new_val, 0, _max_ap)
	var delta  : int = clamped - _ap
	if delta == 0:
		return
	_ap = clamped
	ap_changed.emit(_ap, delta)


func _set_food(new_val: int) -> void:
	var clamped: int = clampi(new_val, 0, FOOD_MAX)
	var delta  : int = clamped - _food
	if delta == 0:
		return
	_food = clamped
	food_changed.emit(_food, delta)
