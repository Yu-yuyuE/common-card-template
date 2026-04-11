## StatusManager.gd
## 状态效果系统（C1）——运行时状态管理核心
##
## 职责：管理单个战斗单位身上所有激活状态的施加、刷新、消耗、覆盖、
##       持续伤害结算与回合衰减。每个需要持有状态的单位应各自持有一个
##       StatusManager 实例（依赖注入，不使用单例）。
##
## 设计文档：design/gdd/status-design.md
## 依赖：
##   - StatusEffect（数据层）
##   - ResourceManager（持续伤害写入 HP/护盾）
##
## 使用示例：
##   var sm := StatusManager.new()
##   sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
##   sm.on_round_end(resource_manager)   # 每回合末调用一次

class_name StatusManager extends RefCounted

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## 成功施加或刷新了某状态时发射
## 参数：type=状态类型，new_layers=生效后层数，source=来源描述
signal status_applied(type: StatusEffect.Type, new_layers: int, source: String)

## 状态被移除（归零或被覆盖）时发射
## 参数：type=被移除的状态类型，reason="expired"/"overridden"/"consumed"
signal status_removed(type: StatusEffect.Type, reason: String)

## 持续伤害结算时发射（用于日志与 UI 飘字）
## 参数：type=伤害来源状态，damage=本次伤害量，pierced_armor=是否穿透护盾
signal dot_dealt(type: StatusEffect.Type, damage: int, pierced_armor: bool)

## 瘟疫传播请求——由外部战场系统监听后向相邻单位施加瘟疫
## 参数：plague_layers=传播层数（固定为1）
signal plague_spread_requested(plague_layers: int)

# ---------------------------------------------------------------------------
# 内部状态表
# key: StatusEffect.Type  value: StatusEffect 实例
# ---------------------------------------------------------------------------

var _effects: Dictionary = {}   # Type(int) -> StatusEffect

# ---------------------------------------------------------------------------
# 查询接口
# ---------------------------------------------------------------------------

## 返回该单位当前是否持有指定状态。
## 示例：
##   if sm.has_status(StatusEffect.Type.IMMUNE): ...
func has_status(type: StatusEffect.Type) -> bool:
	return _effects.has(int(type))


## 返回指定状态的当前层数；若无该状态则返回 0。
## 示例：
##   var layers := sm.get_layers(StatusEffect.Type.BURN)
func get_layers(type: StatusEffect.Type) -> int:
	if _effects.has(int(type)):
		return (_effects[int(type)] as StatusEffect).layers
	return 0


## 返回当前所有激活状态的只读列表（Array[StatusEffect]）。
## 调用方不应修改返回的元素。
func get_all_effects() -> Array:
	return _effects.values()


## 返回单位当前是否处于免疫状态（B7）。
func is_immune() -> bool:
	return has_status(StatusEffect.Type.IMMUNE)


## 返回单位当前是否眩晕（D11）。
func is_stunned() -> bool:
	return has_status(StatusEffect.Type.STUN)


## 返回单位当前是否滑倒（D6，无法使用攻击卡）。
func is_slipped() -> bool:
	return has_status(StatusEffect.Type.SLIP)

# ---------------------------------------------------------------------------
# 施加状态——核心入口
# ---------------------------------------------------------------------------

## 向该单位施加一个状态，内部自动处理叠加/刷新/覆盖/免疫逻辑。
##
## 参数：
##   type    — 状态类型
##   layers  — 施加层数（≥ 1）
##   source  — 来源描述（用于日志，如 "火攻卡"）
##
## 返回：
##   true  = 状态施加/刷新成功
##   false = 被免疫或其他原因未生效
##
## 示例：
##   sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
func apply(type: StatusEffect.Type, layers: int, source: String = "") -> bool:
	assert(layers >= 1, "施加层数必须 >= 1")

	# E5：免疫状态阻止所有负面状态施加（正面状态不受影响）
	if StatusEffect.is_debuff(type) and is_immune():
		return false

	# 分发到具体规则
	if _effects.has(int(type)):
		_apply_existing(type, layers, source)
	else:
		_apply_new(type, layers, source)
	return true


# 施加一个当前已存在的状态
func _apply_existing(type: StatusEffect.Type, layers: int, source: String) -> void:
	var existing := _effects[int(type)] as StatusEffect

	# 同类叠加：层数相加（设计文档 §4）
	existing.layers += layers
	existing.source  = source
	status_applied.emit(type, existing.layers, source)


# 施加一个当前不存在的状态
func _apply_new(type: StatusEffect.Type, layers: int, source: String) -> void:
	# 检查不同类互斥覆盖（§4 F5）
	# 同类已在 _apply_existing 处理；此处只处理"全局只允许一个异类状态"规则
	# 特例：剧毒(TOXIC)覆盖中毒(POISON)时合并层数
	if StatusEffect.is_debuff(type):
		_resolve_debuff_exclusion(type, layers, source)
		return
	if StatusEffect.is_buff(type):
		_resolve_buff_exclusion(type, layers, source)
		return


# 负面状态互斥逻辑
# 不同类负面状态互斥；剧毒与中毒特殊：剧毒覆盖中毒且合并层数
func _resolve_debuff_exclusion(
	new_type  : StatusEffect.Type,
	new_layers: int,
	source    : String
) -> void:
	# 剧毒 vs 中毒特例（§4）
	if new_type == StatusEffect.Type.TOXIC and _effects.has(int(StatusEffect.Type.POISON)):
		var poison_layers: int = get_layers(StatusEffect.Type.POISON)
		_remove_effect(StatusEffect.Type.POISON, "overridden")
		new_layers += poison_layers   # 层数合并

	# 移除现有的**异类**负面状态（同类已在上层处理）
	# 设计规则：单位同时只能持有一种负面状态（同类可叠加，不同类互斥）
	elif not _effects.has(int(new_type)):
		# 找到第一个存在的异类负面状态并移除
		var to_remove: Array[StatusEffect.Type] = []
		for key: int in _effects:
			var eff := _effects[key] as StatusEffect
			if StatusEffect.is_debuff(eff.type) and eff.type != new_type:
				to_remove.append(eff.type)
		for t: StatusEffect.Type in to_remove:
			_remove_effect(t, "overridden")

	_add_effect(new_type, new_layers, source)


# 正面状态互斥逻辑（同类 Buff 已叠加；不同类 Buff 之间无互斥规则，可共存）
func _resolve_buff_exclusion(
	new_type  : StatusEffect.Type,
	new_layers: int,
	source    : String
) -> void:
	_add_effect(new_type, new_layers, source)


# 实际写入 _effects 表
func _add_effect(type: StatusEffect.Type, layers: int, source: String) -> void:
	var eff := StatusEffect.make(type, layers, source)
	_effects[int(type)] = eff
	status_applied.emit(type, layers, source)

# ---------------------------------------------------------------------------
# 消耗型状态触发（由战斗系统在合适时机调用）
# ---------------------------------------------------------------------------

## 消耗1层指定的消耗型状态，层数归零后自动移除。
## 若状态不存在，静默返回 false。
##
## 示例：
##   sm.consume(StatusEffect.Type.BLOCK)  # 触发格挡消耗
func consume(type: StatusEffect.Type) -> bool:
	if not _effects.has(int(type)):
		return false
	var eff := _effects[int(type)] as StatusEffect
	assert(
		StatusEffect.get_status_meta(type).decay_mode == StatusEffect.DecayMode.CONSUME,
		"consume() 只能用于消耗型状态"
	)
	eff.layers -= 1
	if eff.layers <= 0:
		_remove_effect(type, "consumed")
	return true


## 强制清除指定状态（如眩晕在受攻击后消失 E11）。
## reason 用于日志（默认 "forced"）。
func force_remove(type: StatusEffect.Type, reason: String = "forced") -> void:
	if _effects.has(int(type)):
		_remove_effect(type, reason)

# ---------------------------------------------------------------------------
# 回合结算——由战斗系统在规定时序调用
# ---------------------------------------------------------------------------

## 回合开始阶段：结算持续伤害（DoT）。
## 调用方：卡牌战斗系统（C2），在玩家出牌阶段**之前**调用。
##
## 参数：
##   resource_mgr — 目标单位的 ResourceManager 实例，DoT 伤害写入此处
##
## 示例：
##   status_manager.on_round_start_dot(hero_resource_manager)
func on_round_start_dot(resource_mgr: ResourceManager) -> void:
	# 按状态编号顺序结算，确保日志可读（Edge Case §8）
	var sorted_keys := _effects.keys()
	sorted_keys.sort()

	for key: int in sorted_keys:
		var eff := _effects[key] as StatusEffect
		var meta := StatusEffect.get_status_meta(eff.type)
		if meta.dot_base_damage == 0:
			continue
		# 计算伤害：固定伤害 vs 层数伤害
		var damage: int
		if meta.dot_layers_multiply:
			# 重伤：伤害 = 层数 × 基础值
			damage = eff.layers * meta.dot_base_damage
		else:
			# 中毒/剧毒/灼烧/瘟疫：固定伤害
			damage = meta.dot_base_damage
		if meta.dot_uses_armor:
			# 走护盾（灼烧）
			resource_mgr.apply_damage(damage, false)
		else:
			# 穿透护盾（中毒/剧毒/瘟疫/重伤）
			resource_mgr.apply_damage(damage, true)
		dot_dealt.emit(eff.type, damage, not meta.dot_uses_armor)

	# 瘟疫：回合开始 DoT 结算后请求传播
	if _effects.has(int(StatusEffect.Type.PLAGUE)):
		plague_spread_requested.emit(1)


## 回合结束阶段：所有 PER_ROUND 状态层数 -1，归零则移除。
## 调用方：卡牌战斗系统（C2），在敌人回合**之后**调用。
##
## 示例：
##   status_manager.on_round_end()
func on_round_end() -> void:
	# 收集需要移除的 key，避免在迭代中修改字典
	var expired: Array[StatusEffect.Type] = []

	for key: int in _effects:
		var eff := _effects[key] as StatusEffect
		var meta := StatusEffect.get_status_meta(eff.type)
		if meta.decay_mode == StatusEffect.DecayMode.PER_ROUND:
			eff.layers -= 1
			if eff.layers <= 0:
				expired.append(eff.type)

	for t: StatusEffect.Type in expired:
		_remove_effect(t, "expired")


## 战斗结束后清空所有状态（状态不跨战斗保留）。
func on_battle_end() -> void:
	var keys := _effects.keys().duplicate()
	for key: int in keys:
		_remove_effect(_effects[key].type as StatusEffect.Type, "battle_end")

# ---------------------------------------------------------------------------
# 伤害修正查询（供战斗结算系统读取）
# ---------------------------------------------------------------------------

## 查询本单位作为攻击方时，攻击伤害的乘法修正系数。
## 综合怒气(B1)+25%、虚弱(D8)-25%。
##
## 返回：最终乘数（示例：怒气时 = 1.25，虚弱时 = 0.75，两者同时 = 0.9375）
func get_attack_damage_multiplier() -> float:
	var mult := 1.0
	if has_status(StatusEffect.Type.FURY):
		mult *= 1.25
	if has_status(StatusEffect.Type.WEAKEN):
		mult *= 0.75
	return mult


## 查询本单位作为防守方时，受到伤害的乘法修正系数。
## 综合坚守(B4)-25%、破甲(D7)+25%。
##
## 设计文档 E10：先计算坚守减伤，再用护盾抵挡。
## 本函数仅返回伤害修正系数，护盾抵挡由 ResourceManager 执行。
##
## 返回：最终乘数（示例：坚守时 = 0.75，破甲时 = 1.25）
func get_incoming_damage_multiplier() -> float:
	var mult := 1.0
	if has_status(StatusEffect.Type.DEFEND):
		mult *= 0.75
	if has_status(StatusEffect.Type.ARMOR_BREAK):
		mult *= 1.25
	return mult


## 查询盲目（D5）命中率修正。
## 返回：命中概率（0.0–1.0）；正常时为 1.0，盲目时为 0.5
func get_hit_chance() -> float:
	if has_status(StatusEffect.Type.BLIND):
		return 0.5
	return 1.0


## 查询迅捷（B2）闪避概率。
## 返回：闪避概率（0.0–1.0）；有迅捷时为 0.5，否则为 0.0
func get_dodge_chance() -> float:
	if has_status(StatusEffect.Type.AGILITY):
		return 0.5
	return 0.0


## 查询恐惧（D3）附加伤害。
## 返回：附加攻击伤害点数 = 恐惧层数
func get_fear_bonus_damage() -> int:
	return get_layers(StatusEffect.Type.FEAR)


## 查询冻伤（D13）出牌 HP 扣减量。
## 每次出牌时由卡牌系统调用，HP -1/张（由 ResourceManager 扣除）。
## 返回：HP 扣减量（有冻伤时为1，否则为0）
func get_frostbite_card_cost() -> int:
	return 1 if has_status(StatusEffect.Type.FROSTBITE) else 0

# ---------------------------------------------------------------------------
# 内部工具方法
# ---------------------------------------------------------------------------

func _remove_effect(type: StatusEffect.Type, reason: String) -> void:
	_effects.erase(int(type))
	status_removed.emit(type, reason)
