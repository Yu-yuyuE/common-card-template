## 军营管理器
## 负责兵种卡候选池生成、Lv2升级概率判定及前置条件校验。
##
## 设计原则：
##   - extends RefCounted（不依赖场景树，纯逻辑层）
##   - 不引用 HeroManager / ResourceManager 单例——所有外部数据通过参数注入
##   - 所有公共方法可独立单元测试
##
## GDD 参考：design/gdd/barracks-system.md（F3 兵种倾向权重公式）
## ADR 参考：ADR-0010（武将系统架构）
## 作者: Claude Code
## 创建日期: 2026-04-16
class_name BarracksManager extends RefCounted

# ===========================================================================
# 内嵌数据结构
# ===========================================================================

## 兵种卡候选数据
## 传给生成器的轻量数据结构，独立于卡牌渲染层
class TroopCardData extends RefCounted:
	## 唯一卡牌 ID（同一 card_id 在候选结果中不重复出现）
	var card_id: String
	## 兵种类型（HeroManager.TroopType 枚举值）
	var troop_type: int
	## 卡牌等级：1 或 2
	var level: int = 1


# ===========================================================================
# 常量（禁止裸魔数）
# ===========================================================================

## 每次生成的候选卡数量上限
const CANDIDATE_COUNT: int = 3

## Lv2 升级概率（15%）
const LV2_CHANCE: float = 0.15

## 升级金币消耗
const UPGRADE_COST: int = 50

## 主修兵种权重（对应 GDD F3 WEIGHT_PRIMARY）
const WEIGHT_PRIMARY: float = 2.0

## 次修兵种权重（对应 GDD F3 WEIGHT_SECONDARY）
const WEIGHT_SECONDARY: float = 1.0

## 非倾向兵种权重（对应 GDD F3 WEIGHT_NON_AFFINITY）
const WEIGHT_NON_AFFINITY: float = 0.5


# ===========================================================================
# 公共方法
# ===========================================================================

## 按兵种倾向权重无放回加权随机抽取候选卡。
##
## 参数：
##   available_cards     — 当前可用兵种卡池（原始数组，方法内不修改）
##   affinity_primary    — 武将主修兵种列表（Array[int]，元素为 TroopType 枚举值）
##   affinity_secondary  — 武将次修兵种（int，TroopType 枚举值）
##   leadership          — 统帅值（仅作为外部上下文，本方法不校验上限）
##
## 返回：
##   候选卡数组（TroopCardData 副本），长度为 min(CANDIDATE_COUNT, available_cards.size())
##   每张卡已通过 _roll_lv2() 决定是否升为 Lv2
##   同一 card_id 在结果中不重复
##
## 示例：
##   var candidates := barracks.generate_candidates(
##       pool, [TroopType.INFANTRY, TroopType.CAVALRY], TroopType.STRATEGIST, 5
##   )
func generate_candidates(
	available_cards: Array,
	affinity_primary: Array,
	affinity_secondary: int,
	_leadership: int
) -> Array:
	if available_cards.is_empty():
		return []

	# 构建工作副本，避免修改调用方的原始数组
	var pool: Array = available_cards.duplicate(false)

	var draw_count: int = mini(CANDIDATE_COUNT, pool.size())
	var result: Array = []

	for _i: int in range(draw_count):
		# 计算当前池中每张卡的权重
		var total_weight: float = 0.0
		var weights: Array = []
		for card: TroopCardData in pool:
			var w: float = _get_weight(card.troop_type, affinity_primary, affinity_secondary)
			weights.append(w)
			total_weight += w

		# 加权随机选取
		var roll: float = randf() * total_weight
		var accumulated: float = 0.0
		var chosen_index: int = pool.size() - 1  # 保底：浮点误差兜底取最后一张
		for idx: int in range(pool.size()):
			accumulated += weights[idx]
			if roll <= accumulated:
				chosen_index = idx
				break

		# 创建副本，决定等级
		var source: TroopCardData = pool[chosen_index]
		var candidate := TroopCardData.new()
		candidate.card_id   = source.card_id
		candidate.troop_type = source.troop_type
		candidate.level      = 2 if _roll_lv2() else 1

		result.append(candidate)

		# 无放回：从工作副本中移除已选项
		pool.remove_at(chosen_index)

	return result


## 判定候选卡是否升为 Lv2（15% 概率）。
##
## 返回：
##   true  — 该候选卡应为 Lv2
##   false — 该候选卡保持 Lv1
func _roll_lv2() -> bool:
	return randf() < LV2_CHANCE


## 校验当前金币是否满足升级消耗（AC3 前置校验）。
##
## 参数：
##   current_gold — 当前持有金币数量
##
## 返回：
##   true  — 金币 >= UPGRADE_COST（50），可执行升级
##   false — 金币不足，禁止升级
##
## 示例：
##   if barracks.can_upgrade_card(resource_manager.get_gold()):
##       barracks.execute_upgrade(card)
func can_upgrade_card(current_gold: int) -> bool:
	return current_gold >= UPGRADE_COST


## 校验当前兵种卡数量是否未达统帅上限（AC4 前置校验）。
##
## 参数：
##   current_troop_count — 卡组中已有兵种卡数量
##   leadership          — 武将统帅值（兵种卡携带上限）
##
## 返回：
##   true  — current_troop_count < leadership，可以添加新兵种卡
##   false — 已达或超过上限，禁止添加
##
## 示例：
##   if barracks.can_add_troop_card(deck.troop_count(), hero.leadership):
##       deck.add_troop_card(selected_card)
func can_add_troop_card(current_troop_count: int, leadership: int) -> bool:
	return current_troop_count < leadership


# ===========================================================================
# 私有辅助
# ===========================================================================

## 根据武将倾向计算单张卡的权重。
##
## 参数：
##   troop_type         — 卡牌兵种类型
##   affinity_primary   — 武将主修兵种列表
##   affinity_secondary — 武将次修兵种
##
## 返回：WEIGHT_PRIMARY / WEIGHT_SECONDARY / WEIGHT_NON_AFFINITY
func _get_weight(
	troop_type: int,
	affinity_primary: Array,
	affinity_secondary: int
) -> float:
	if affinity_primary.has(troop_type):
		return WEIGHT_PRIMARY
	if troop_type == affinity_secondary:
		return WEIGHT_SECONDARY
	return WEIGHT_NON_AFFINITY


# ===========================================================================
# 集成层状态（story-002）
# ===========================================================================

## 进入军营时的初始卡组快照（card_id 字符串数组）
var _initial_deck: Array[String] = []

## 当前暂存卡组（操作在此进行，未调用 save_and_exit 前不固化）
var _pending_deck: Array[String] = []


# ===========================================================================
# 集成层公共方法（story-002）
# ===========================================================================

## 初始化本次军营会话，传入玩家当前卡组快照。
## 必须在所有 commit_* 方法前调用。
##
## 参数：
##   initial_deck — 当前卡组的 card_id 字符串数组（进入军营时的快照）
##
## 示例：
##   barracks.initialize_session(player_deck.get_card_ids())
func initialize_session(initial_deck: Array[String]) -> void:
	_initial_deck = initial_deck.duplicate()
	_pending_deck = initial_deck.duplicate()


## 添加卡牌到暂存卡组。
## current_troop_count: 暂存卡组中当前兵种卡数量（由调用方统计）
## leadership: 武将统帅值
##
## 参数：
##   card_id             — 要添加的卡牌 ID
##   current_troop_count — 暂存卡组中当前兵种卡数量（由调用方统计）
##   leadership          — 武将统帅值
##
## 返回：
##   {success: bool, reason: String}
##   失败 reason: "LEADERSHIP_CAP"
##
## 示例：
##   var result := barracks.commit_add_card("troop_001_lv1", deck.troop_count(), hero.leadership)
##   if result["success"]: deck.apply_pending()
func commit_add_card(card_id: String, current_troop_count: int, leadership: int) -> Dictionary:
	if not can_add_troop_card(current_troop_count, leadership):
		return {success = false, reason = "LEADERSHIP_CAP"}
	_pending_deck.append(card_id)
	return {success = true, reason = ""}


## 升级卡牌 Lv1→Lv2（替换 card_id）。
## 约定：Lv2 card_id = Lv1 card_id 将末尾 "_lv1" 替换为 "_lv2"；
##       若无 "_lv1" 后缀则追加 "_lv2"。
##
## 参数：
##   card_id      — 要升级的 Lv1 卡牌 ID
##   current_gold — 当前金币（校验用，不实际扣减——返回 gold_spent 由调用方执行扣减）
##
## 返回：
##   {success: bool, gold_spent: int, new_card_id: String, reason: String}
##   失败 reason: "INSUFFICIENT_GOLD" | "CARD_NOT_FOUND"
##
## 示例：
##   var result := barracks.commit_upgrade_card("sword_lv1", resource_mgr.gold)
##   if result["success"]: resource_mgr.spend_gold(result["gold_spent"])
func commit_upgrade_card(card_id: String, current_gold: int) -> Dictionary:
	if not can_upgrade_card(current_gold):
		return {success = false, gold_spent = 0, new_card_id = "", reason = "INSUFFICIENT_GOLD"}

	var idx: int = _pending_deck.find(card_id)
	if idx == -1:
		return {success = false, gold_spent = 0, new_card_id = "", reason = "CARD_NOT_FOUND"}

	# 生成 Lv2 card_id
	var new_card_id: String
	if card_id.ends_with("_lv1"):
		new_card_id = card_id.substr(0, card_id.length() - 4) + "_lv2"
	else:
		new_card_id = card_id + "_lv2"

	_pending_deck[idx] = new_card_id
	return {success = true, gold_spent = UPGRADE_COST, new_card_id = new_card_id, reason = ""}


## 从暂存卡组移除指定卡牌。
##
## 参数：
##   card_id — 要移除的卡牌 ID
##
## 返回：
##   {success: bool, reason: String}
##   失败 reason: "CARD_NOT_FOUND"
##
## 示例：
##   var result := barracks.commit_remove_card("troop_001_lv1")
##   if not result["success"]: show_error(result["reason"])
func commit_remove_card(card_id: String) -> Dictionary:
	var idx: int = _pending_deck.find(card_id)
	if idx == -1:
		return {success = false, reason = "CARD_NOT_FOUND"}
	_pending_deck.erase(card_id)
	return {success = true, reason = ""}


## 返回当前暂存卡组的副本（不修改内部状态）。
##
## 返回：
##   Array[String] — 暂存卡组 card_id 副本
##
## 示例：
##   var preview := barracks.get_pending_deck()
func get_pending_deck() -> Array[String]:
	return _pending_deck.duplicate()


## 提交所有暂存变更，返回最终卡组副本（调用方负责持久化）。
##
## 返回：
##   Array[String] — 最终确定的卡组 card_id 副本
##
## 示例：
##   var final_deck := barracks.save_and_exit()
##   player_data.deck = final_deck
func save_and_exit() -> Array[String]:
	_initial_deck = _pending_deck.duplicate()
	return _pending_deck.duplicate()


## 回滚所有暂存变更，恢复到 initialize_session 时的初始快照。
##
## 示例：
##   barracks.reset_pending()  # 玩家按"取消"时调用
func reset_pending() -> void:
	_pending_deck = _initial_deck.duplicate()
