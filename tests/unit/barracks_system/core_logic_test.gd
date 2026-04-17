## core_logic_test.gd
## 军营系统核心逻辑单元测试（Story 001）
##
## 覆盖验收标准：
##   AC1 — 候选池生成：按兵种权重无放回抽取 3 张，不重复
##   AC2 — Lv2 出现概率判定：每张候选卡 15% 概率为 Lv2
##   AC3 — 前置校验：金币 >= 50 才可升级
##   AC4 — 前置校验：兵种卡数量 < 统帅值才可添加
##
## 测试策略：
##   - BarracksManager extends RefCounted，直接 .new() 实例化，无场景树依赖
##   - 所有英雄数据通过参数注入（不依赖 HeroManager 单例）
##   - 统计测试跑 1000 次以验证概率合理区间
##
## 设计文档：design/gdd/barracks-system.md
## ADR：ADR-0010（武将系统架构）
## 作者: Claude Code
## 创建日期: 2026-04-16

class_name BarracksCoreLogicTest
extends GdUnitTestSuite

# ===========================================================================
# 测试夹具
# ===========================================================================

## 被测实例
var _barracks: BarracksManager

## 固定武将倾向数据（模拟曹操：主修步兵+骑兵，次修谋士，统帅 6）
const AFFINITY_PRIMARY: Array    = [0, 1]  # INFANTRY=0, CAVALRY=1
const AFFINITY_SECONDARY: int    = 3       # STRATEGIST=3
const TEST_LEADERSHIP: int       = 6

## 概率统计测试迭代次数
const STAT_ITERATIONS: int = 1000

## 固定 Mock 卡池（共 21 张）
## 步兵系：10 张（card_id: inf_01 ~ inf_10）
## 骑兵系：5 张（card_id: cav_01 ~ cav_05）
## 弓兵系：2 张（card_id: arc_01 ~ arc_02）
## 谋士系：2 张（card_id: str_01 ~ str_02）
## 盾兵系：2 张（card_id: shd_01 ~ shd_02）
var _mock_pool: Array = []

# ===========================================================================
# 生命周期
# ===========================================================================

func before_test() -> void:
	_barracks = BarracksManager.new()
	_mock_pool = _build_mock_pool()


func after_test() -> void:
	_barracks = null
	_mock_pool = []


# ===========================================================================
# 辅助方法
# ===========================================================================

## 构建固定 Mock 卡池
func _build_mock_pool() -> Array:
	var pool: Array = []

	# 步兵系 10 张（TroopType.INFANTRY = 0）
	for i: int in range(1, 11):
		var card := BarracksManager.TroopCardData.new()
		card.card_id    = "inf_%02d" % i
		card.troop_type = 0  # INFANTRY
		card.level      = 1
		pool.append(card)

	# 骑兵系 5 张（TroopType.CAVALRY = 1）
	for i: int in range(1, 6):
		var card := BarracksManager.TroopCardData.new()
		card.card_id    = "cav_%02d" % i
		card.troop_type = 1  # CAVALRY
		card.level      = 1
		pool.append(card)

	# 弓兵系 2 张（TroopType.ARCHER = 2）
	for i: int in range(1, 3):
		var card := BarracksManager.TroopCardData.new()
		card.card_id    = "arc_%02d" % i
		card.troop_type = 2  # ARCHER
		card.level      = 1
		pool.append(card)

	# 谋士系 2 张（TroopType.STRATEGIST = 3）
	for i: int in range(1, 3):
		var card := BarracksManager.TroopCardData.new()
		card.card_id    = "str_%02d" % i
		card.troop_type = 3  # STRATEGIST
		card.level      = 1
		pool.append(card)

	# 盾兵系 2 张（TroopType.SHIELD = 4）
	for i: int in range(1, 3):
		var card := BarracksManager.TroopCardData.new()
		card.card_id    = "shd_%02d" % i
		card.troop_type = 4  # SHIELD
		card.level      = 1
		pool.append(card)

	return pool


# ===========================================================================
# AC1 — 候选池生成
# ===========================================================================

## AC1: 正常卡池下生成恰好 3 张候选卡
## Given: 21 张可用卡，武将倾向曹操配置
## When:  generate_candidates(pool, primary, secondary, leadership)
## Then:  返回数组长度恰好为 3
func test_barracks_generate_candidates_returns_three_cards() -> void:
	# Arrange
	var pool: Array = _mock_pool.duplicate(false)

	# Act
	var result: Array = _barracks.generate_candidates(
		pool, AFFINITY_PRIMARY, AFFINITY_SECONDARY, TEST_LEADERSHIP
	)

	# Assert
	assert_int(result.size()).is_equal(3)


## AC1: 同一次生成结果中不包含重复 card_id
## Given: 21 张可用卡（card_id 全唯一）
## When:  generate_candidates 执行一次
## Then:  结果中 3 张卡的 card_id 互不相同
func test_barracks_generate_candidates_no_duplicate_ids() -> void:
	# Arrange
	var pool: Array = _mock_pool.duplicate(false)

	# Act
	var result: Array = _barracks.generate_candidates(
		pool, AFFINITY_PRIMARY, AFFINITY_SECONDARY, TEST_LEADERSHIP
	)

	# Assert
	var seen_ids: Dictionary = {}
	for card: BarracksManager.TroopCardData in result:
		assert_bool(seen_ids.has(card.card_id)).is_false()
		seen_ids[card.card_id] = true


## AC1: 主修兵种（步兵 WEIGHT=2.0）出现频率显著高于非主修
## Given: 21 张卡，主修步兵（10 张）权重 2.0，其余权重较低
## When:  1000 次生成，统计步兵系出现率
## Then:  步兵系出现率 > 30%（理论约 40~50%，保守下限 30%）
func test_barracks_generate_candidates_high_affinity_higher_frequency() -> void:
	# Arrange
	var infantry_count: int = 0
	var total_candidates: int = 0

	# Act
	for _i: int in range(STAT_ITERATIONS):
		var pool: Array = _mock_pool.duplicate(false)
		var result: Array = _barracks.generate_candidates(
			pool, AFFINITY_PRIMARY, AFFINITY_SECONDARY, TEST_LEADERSHIP
		)
		for card: BarracksManager.TroopCardData in result:
			total_candidates += 1
			if card.troop_type == 0:  # INFANTRY
				infantry_count += 1

	# Assert
	var infantry_rate: float = float(infantry_count) / float(total_candidates)
	assert_float(infantry_rate).is_greater_equal(0.30)


## AC1: 可用卡不足 3 张时，返回实际可用数量（不越界）
## Given: 只有 2 张可用卡
## When:  generate_candidates
## Then:  返回数组长度为 2
func test_barracks_generate_candidates_fewer_than_three_available() -> void:
	# Arrange
	var small_pool: Array = []
	for i: int in range(2):
		var card := BarracksManager.TroopCardData.new()
		card.card_id    = "only_%d" % i
		card.troop_type = 0  # INFANTRY
		card.level      = 1
		small_pool.append(card)

	# Act
	var result: Array = _barracks.generate_candidates(
		small_pool, AFFINITY_PRIMARY, AFFINITY_SECONDARY, TEST_LEADERSHIP
	)

	# Assert
	assert_int(result.size()).is_equal(2)


## AC1: 空卡池返回空数组
## Given: available_cards 为空数组
## When:  generate_candidates
## Then:  返回空数组，不崩溃
func test_barracks_generate_candidates_empty_pool_returns_empty() -> void:
	# Arrange
	var empty_pool: Array = []

	# Act
	var result: Array = _barracks.generate_candidates(
		empty_pool, AFFINITY_PRIMARY, AFFINITY_SECONDARY, TEST_LEADERSHIP
	)

	# Assert
	assert_int(result.size()).is_equal(0)


# ===========================================================================
# AC2 — Lv2 概率判定
# ===========================================================================

## AC2: 1000 次生成中 Lv2 候选卡占比在 [0.10, 0.20] 区间（理论 0.15）
## Given: 21 张可用卡，每张候选卡独立 15% Lv2 概率
## When:  1000 次 generate_candidates，每次 3 张候选
## Then:  Lv2 数量 / 总候选数 in [0.10, 0.20]
func test_barracks_generate_candidates_lv2_probability_within_range() -> void:
	# Arrange
	var lv2_count: int    = 0
	var total_count: int  = 0

	# Act
	for _i: int in range(STAT_ITERATIONS):
		var pool: Array = _mock_pool.duplicate(false)
		var result: Array = _barracks.generate_candidates(
			pool, AFFINITY_PRIMARY, AFFINITY_SECONDARY, TEST_LEADERSHIP
		)
		for card: BarracksManager.TroopCardData in result:
			total_count += 1
			if card.level == 2:
				lv2_count += 1

	# Assert
	var lv2_rate: float = float(lv2_count) / float(total_count)
	assert_float(lv2_rate).is_greater_equal(0.10)
	assert_float(lv2_rate).is_less_equal(0.20)


## AC2: _roll_lv2() 调用 100 次，每次返回值均为 bool 类型
## Given: BarracksManager 实例已初始化
## When:  调用 _roll_lv2() 100 次
## Then:  每次返回值都是 bool（true 或 false），不崩溃
func test_barracks_roll_lv2_is_bool() -> void:
	# Act & Assert
	for _i: int in range(100):
		var result = _barracks._roll_lv2()
		assert_bool(result is bool).is_true()


# ===========================================================================
# AC3 — 金币升级前置校验
# ===========================================================================

## AC3: 金币恰好等于 UPGRADE_COST（50）时可以升级
## Given: current_gold = 50
## When:  can_upgrade_card(50)
## Then:  返回 true
func test_barracks_can_upgrade_card_sufficient_gold() -> void:
	# Arrange
	var current_gold: int = 50

	# Act
	var result: bool = _barracks.can_upgrade_card(current_gold)

	# Assert
	assert_bool(result).is_true()


## AC3: 金币少于 UPGRADE_COST 1 点（49）时禁止升级
## Given: current_gold = 49
## When:  can_upgrade_card(49)
## Then:  返回 false
func test_barracks_can_upgrade_card_insufficient_gold() -> void:
	# Arrange
	var current_gold: int = 49

	# Act
	var result: bool = _barracks.can_upgrade_card(current_gold)

	# Assert
	assert_bool(result).is_false()


## AC3: 金币为 0 时禁止升级（边界值）
## Given: current_gold = 0
## When:  can_upgrade_card(0)
## Then:  返回 false
func test_barracks_can_upgrade_card_zero_gold() -> void:
	# Arrange
	var current_gold: int = 0

	# Act
	var result: bool = _barracks.can_upgrade_card(current_gold)

	# Assert
	assert_bool(result).is_false()


## AC3: 金币远超 UPGRADE_COST（200）时允许升级
## Given: current_gold = 200
## When:  can_upgrade_card(200)
## Then:  返回 true
func test_barracks_can_upgrade_card_excess_gold() -> void:
	# Arrange
	var current_gold: int = 200

	# Act
	var result: bool = _barracks.can_upgrade_card(current_gold)

	# Assert
	assert_bool(result).is_true()


# ===========================================================================
# AC4 — 统帅上限前置校验
# ===========================================================================

## AC4: 当前兵种卡数量低于统帅值时可以添加
## Given: current_troop_count = 2, leadership = 3
## When:  can_add_troop_card(2, 3)
## Then:  返回 true
func test_barracks_can_add_troop_card_below_limit() -> void:
	# Arrange
	var current_count: int = 2
	var leadership: int    = 3

	# Act
	var result: bool = _barracks.can_add_troop_card(current_count, leadership)

	# Assert
	assert_bool(result).is_true()


## AC4: 当前兵种卡数量恰好等于统帅值时禁止添加（边界值）
## Given: current_troop_count = 3, leadership = 3
## When:  can_add_troop_card(3, 3)
## Then:  返回 false
func test_barracks_can_add_troop_card_at_limit() -> void:
	# Arrange
	var current_count: int = 3
	var leadership: int    = 3

	# Act
	var result: bool = _barracks.can_add_troop_card(current_count, leadership)

	# Assert
	assert_bool(result).is_false()


## AC4: 当前兵种卡数量超过统帅值时禁止添加
## Given: current_troop_count = 4, leadership = 3
## When:  can_add_troop_card(4, 3)
## Then:  返回 false
func test_barracks_can_add_troop_card_over_limit() -> void:
	# Arrange
	var current_count: int = 4
	var leadership: int    = 3

	# Act
	var result: bool = _barracks.can_add_troop_card(current_count, leadership)

	# Assert
	assert_bool(result).is_false()


## AC4: 当前兵种卡数量为 0、统帅值为 6 时可以添加（正常开局状态）
## Given: current_troop_count = 0, leadership = 6
## When:  can_add_troop_card(0, 6)
## Then:  返回 true
func test_barracks_can_add_troop_card_zero_current() -> void:
	# Arrange
	var current_count: int = 0
	var leadership: int    = 6

	# Act
	var result: bool = _barracks.can_add_troop_card(current_count, leadership)

	# Assert
	assert_bool(result).is_true()
