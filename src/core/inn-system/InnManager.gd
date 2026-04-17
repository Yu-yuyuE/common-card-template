## InnManager — 酒馆服务管理器
##
## 集中处理酒馆所有服务逻辑：歇息、强化休整、购买粮草。
## 以实例方式使用（RefCounted），不作为全局单例。
## 所有方法通过参数注入接收状态值，不直接调用 ResourceManager，保证可测试性。
##
## ADR 对齐：ADR-0013（Control Manifest Feature Layer — Inn System）
class_name InnManager
extends RefCounted

# ============================================================
# 常量（对齐 ADR-0013）
# ============================================================

## 基础歇息每次恢复 HP 量
const REST_BASE_HEAL: int = 15

## 强化休整每次恢复 HP 量
const ENHANCED_HEAL: int = 20

## 每次购买粮草数量
const PROVISIONS_AMOUNT: int = 40

## 购买粮草所需金币
const PROVISIONS_PRICE: int = 40

## 强化休整所需金币
const ENHANCED_PRICE: int = 60

## 每章允许歇息（非强化）次数上限
const REST_LIMIT: int = 1

# ============================================================
# 实例状态
# ============================================================

## 本章已歇息次数（每章通过 reset_chapter() 重置）
var rest_count: int = 0

# ============================================================
# 公开接口
# ============================================================

## 歇息服务。
## 返回实际恢复 HP 量；HP 已满或已达本章歇息次数上限时返回 0。
## 成功歇息后 rest_count 自增 1。
## [br]
## [param current_hp] 当前 HP
## [param max_hp] 最大 HP
func rest(current_hp: int, max_hp: int) -> int:
	# HP 已满，无需歇息
	if current_hp >= max_hp:
		return 0
	# 已达本章次数上限
	if rest_count >= REST_LIMIT:
		return 0

	var heal: int = mini(REST_BASE_HEAL, max_hp - current_hp)
	rest_count += 1
	return heal


## 强化休整服务。
## 返回结果字典：
## [br]  success      — 是否成功
## [br]  hp_gained    — 实际恢复 HP（失败时为 0）
## [br]  gold_spent   — 实际扣除金币（失败时为 0）
## [br]  reason       — 失败原因（成功时为空字符串）
## [br]
## [param current_hp] 当前 HP
## [param max_hp] 最大 HP
## [param current_gold] 当前持有金币
func fortify(current_hp: int, max_hp: int, current_gold: int) -> Dictionary:
	if current_hp >= max_hp:
		return {
			"success": false,
			"hp_gained": 0,
			"gold_spent": 0,
			"reason": "HP_FULL"
		}
	if current_gold < ENHANCED_PRICE:
		return {
			"success": false,
			"hp_gained": 0,
			"gold_spent": 0,
			"reason": "INSUFFICIENT_GOLD"
		}

	var heal: int = mini(ENHANCED_HEAL, max_hp - current_hp)
	return {
		"success": true,
		"hp_gained": heal,
		"gold_spent": ENHANCED_PRICE,
		"reason": ""
	}


## 购买粮草服务。
## 返回结果字典：
## [br]  success           — 是否成功
## [br]  provisions_gained — 实际获得粮草量（失败时为 0）
## [br]  gold_spent        — 实际扣除金币（失败时为 0）
## [br]  reason            — 失败原因（成功时为空字符串）
## [br]
## [param current_gold] 当前持有金币
## [param current_provisions] 当前粮草数量
## [param max_provisions] 粮草上限（由调用方传入）
func buy_provisions(current_gold: int, current_provisions: int, max_provisions: int) -> Dictionary:
	if current_gold < PROVISIONS_PRICE:
		return {
			"success": false,
			"provisions_gained": 0,
			"gold_spent": 0,
			"reason": "INSUFFICIENT_GOLD"
		}
	if current_provisions >= max_provisions:
		return {
			"success": false,
			"provisions_gained": 0,
			"gold_spent": 0,
			"reason": "PROVISIONS_AT_CAP"
		}

	return {
		"success": true,
		"provisions_gained": PROVISIONS_AMOUNT,
		"gold_spent": PROVISIONS_PRICE,
		"reason": ""
	}


## 判断当前是否可以歇息（未超章节次数限制且 HP 未满）。
## [br]
## [param current_hp] 当前 HP
## [param max_hp] 最大 HP
func can_rest(current_hp: int, max_hp: int) -> bool:
	if current_hp >= max_hp:
		return false
	return rest_count < REST_LIMIT


## 判断当前是否可以强化休整（HP 未满且金币充足）。
## [br]
## [param current_hp] 当前 HP
## [param max_hp] 最大 HP
## [param current_gold] 当前持有金币
func can_fortify(current_hp: int, max_hp: int, current_gold: int) -> bool:
	if current_hp >= max_hp:
		return false
	return current_gold >= ENHANCED_PRICE


## 章节重置：将 rest_count 清零，允许下一章再次歇息。
func reset_chapter() -> void:
	rest_count = 0
