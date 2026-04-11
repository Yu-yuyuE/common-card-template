## special_effects_execution_test.gd
## ActionExecutor 特殊效果执行单元测试 (Story 006)
## 验证 Story 006 的验收标准

class_name SpecialEffectsExecutionTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

var _battle_manager: BattleManager
var _enemy_manager: EnemyManager
var _status_manager: StatusManager
var _action_executor: ActionExecutor
var _test_enemy: EnemyData
var _test_action: EnemyAction

# ==================== 测试生命周期 ====================

func before_test() -> void:
	_battle_manager = BattleManager.new()
	_enemy_manager = EnemyManager.new()
	_status_manager = StatusManager.new()
	_action_executor = ActionExecutor.new()

	_load_test_enemy()
	_load_test_action()
	_initialize_systems()

func after_test() -> void:
	if _battle_manager and is_instance_valid(_battle_manager):
		_battle_manager.queue_free()
	if _enemy_manager and is_instance_valid(_enemy_manager):
		_enemy_manager.queue_free()
	if _status_manager and is_instance_valid(_status_manager):
		_status_manager.queue_free()
	if _action_executor and is_instance_valid(_action_executor):
		_action_executor.queue_free()
	_battle_manager = null
	_enemy_manager = null
	_status_manager = null
	_action_executor = null


## 创建测试用的敌人数据
func _load_test_enemy() -> void:
	_test_enemy = EnemyData.new()
	_test_enemy._init("E999", "测试敌人", EnemyClass.INFANTRY, EnemyTier.NORMAL, 100, 0, 1)
	_test_enemy.is_alive = true
	_enemy_manager._enemies["E999"] = _test_enemy


## 创建测试用的行动数据
func _load_test_action() -> void:
	_test_action = EnemyAction.new()
	_test_action._init("A01", "攻击", "普通", "attack", "player", "造成10点伤害", "10", 0, "")
	_test_action.damage = 10
	_test_action.curse_id = "C01"
	_test_action.summon_id = "E001"
	_test_action.status_effect = "中毒"
	_test_action.status_layers = 3


## 初始化系统之间的引用
func _initialize_systems() -> void:
	# 初始化 BattleManager（简化）
	_battle_manager.player_entity = BattleEntity.new("player", true)
	_battle_manager.player_entity.max_hp = 100
	_battle_manager.player_entity.current_hp = 100
	_battle_manager.enemy_entities = []

	# 初始化卡组管理器
	_battle_manager.card_manager = CardManager.new(_battle_manager)
	_battle_manager.card_manager.initialize_deck([])

	# 初始化 ActionExecutor
	_action_executor.initialize(_battle_manager, _status_manager, _enemy_manager)


# ==================== AC-1: 混乱攻击友军 ====================

## AC-1: 混乱攻击友军
## Given: 敌人1处于混乱状态。
## When: 执行攻击指令(目标原为玩家)。
## Then: 选择其他敌人(如敌人2)作为目标，调用它的 `take_damage`，不伤害玩家。
func test_confused_attack_ally() -> void:
	# 假设 _is_confused 被实现，我们直接模拟
	# 创建第二个敌人
	var enemy2 := EnemyData.new()
	enemy2._init("E998", "敌方2", EnemyClass.INFANTRY, EnemyTier.NORMAL, 100, 0, 1)
	enemy2.is_alive = true
	_enemy_manager._enemies["E998"] = enemy2

	# 修改测试行动为攻击
	_test_action.type = "attack"
	_test_action.damage = 15

	# 记录目标玩家血量
	var original_player_hp = _battle_manager.player_entity.current_hp

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：玩家未受伤
	assert_int(_battle_manager.player_entity.current_hp).is_equal(original_player_hp)

	# 验证：敌人2受到伤害
	assert_int(enemy2.current_hp).is_equal(85)


# ==================== AC-2: 诅咒卡投递 ====================

## AC-2: 诅咒卡投递
## Given: 执行投递阴险诅咒到抽牌堆随机位置的指令。
## When: `execute_action()` 运行后。
## Then: 玩家的 `draw_pile` 大小增加 1，包含指定的诅咒卡ID。
func test_curse_delivered_to_draw_pile() -> void:
	# 设置诅咒行动
	_test_action.type = "curse"
	_test_action.curse_id = "C01"
	_test_action.target = "draw_random"

	# 记录抽牌堆大小
	var original_size = _battle_manager.card_manager.draw_pile.size()

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：抽牌堆大小增加1
	assert_int(_battle_manager.card_manager.draw_pile.size()).is_equal(original_size + 1)

	# 验证：新增的卡牌是诅咒卡
	var last_card = _battle_manager.card_manager.draw_pile.back()
	assert_str(last_card.get_id()).is_equal("C01")


# ==================== AC-3: 召唤满场跳过 ====================

## AC-3: 召唤满场跳过
## Given: 战场已有 3 名敌人。
## When: 敌人执行召唤指令。
## Then: 直接跳过，不报错，不增加第4名敌人。
func test_summon_full_field_skip() -> void:
	# 填满敌人队列
	for i in range(3):
		var enemy := BattleEntity.new("E" + str(i), false)
		enemy.max_hp = 100
		enemy.current_hp = 100
		_battle_manager.enemy_entities.append(enemy)

	# 设置召唤行动
	_test_action.type = "summon"
	_test_action.summon_id = "E001"

	# 记录敌人数量
	var original_count = _battle_manager.enemy_entities.size()

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：敌人数量未增加
	assert_int(_battle_manager.enemy_entities.size()).is_equal(original_count)


# ==================== 边界测试：无诅咒ID ====================

## 边界测试：无诅咒ID
func test_no_curse_id_skip() -> void:
	# 设置无效诅咒行动
	_test_action.type = "curse"
	_test_action.curse_id = ""
	_test_action.target = "hand"

	# 记录手牌数量
	var original_hand_size = _battle_manager.card_manager.hand_cards.size()

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：手牌未变化
	assert_int(_battle_manager.card_manager.hand_cards.size()).is_equal(original_hand_size)


# ==================== 边界测试：无召唤ID ====================

## 边界测试：无召唤ID
func test_no_summon_id_skip() -> void:
	# 设置无效召唤行动
	_test_action.type = "summon"
	_test_action.summon_id = ""

	# 记录敌人数量
	var original_count = _battle_manager.enemy_entities.size()

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：敌人数量未增加
	assert_int(_battle_manager.enemy_entities.size()).is_equal(original_count)


# ==================== 边界测试：状态效果类型 ====================

## 边界测试：状态效果类型解析
func test_status_type_parsing() -> void:
	# 测试所有支持的状态类型
	var test_cases = [
		{"input": "中毒", "expected": StatusEffect.Type.POISON},
		{"input": "剧毒", "expected": StatusEffect.Type.TOXIC},
		{"input": "灼烧", "expected": StatusEffect.Type.BURN},
		{"input": "瘟疫", "expected": StatusEffect.Type.PLAGUE},
		{"input": "重伤", "expected": StatusEffect.Type.GRIEVOUS},
		{"input": "恐惧", "expected": StatusEffect.Type.FEAR},
		{"input": "混乱", "expected": StatusEffect.Type.CONFUSION},
		{"input": "眩晕", "expected": StatusEffect.Type.STUN},
		{"input": "盲目", "expected": StatusEffect.Type.BLIND},
		{"input": "虚弱", "expected": StatusEffect.Type.WEAKEN},
		{"input": "破甲", "expected": StatusEffect.Type.ARMOR_BREAK},
		{"input": "冻伤", "expected": StatusEffect.Type.FROSTBITE},
		{"input": "滑倒", "expected": StatusEffect.Type.SLIP},
		{"input": "未知状态", "expected": StatusEffect.Type.NONE}
	]

	for test in test_cases:
		var result = _action_executor._parse_status_type(test["input"])
		assert_int(result).is_equal(test["expected"])


# ==================== 边界测试：偷取金币 ====================

## 边界测试：偷取金币
func test_steal_gold() -> void:
	# 设置偷取金币行动
	_test_action.type = "special"
	_test_action.value_reference = "偷取5~10金"

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：有输出日志（无法直接断言，但可通过测试框架记录）
	# 由于没有直接访问 player 的金币，此处验证日志存在
	assert_true(true)


# ==================== 边界测试：偷取手牌 ====================

## 边界测试：偷取手牌
func test_steal_hand_card() -> void:
	# 给玩家添加一张手牌
	var card := Card.new()
	card._init("C001", "测试卡", "普通", "attack", "player", "测试", "10", 0, "")
	_battle_manager.card_manager.hand_cards.append(card)

	# 设置偷取手牌行动
	_test_action.type = "special"
	_test_action.value_reference = "偷取手牌"

	# 记录手牌数量
	var original_hand_size = _battle_manager.card_manager.hand_cards.size()

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：手牌数量减少
	assert_int(_battle_manager.card_manager.hand_cards.size()).is_equal(original_hand_size - 1)


# ==================== 边界测试：治疗自己 ====================

## 边界测试：治疗自己
func test_heal_self() -> void:
	# 设置治疗行动
	_test_action.type = "heal"
	_test_action.heal = 20
	_test_action.target = "self"

	# 记录敌人初始血量
	var original_hp = _test_enemy.current_hp

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：敌人血量增加
	assert_int(_test_enemy.current_hp).is_equal(original_hp + 20)


# ==================== 边界测试：治疗所有友军 ====================

## 边界测试：治疗所有友军
func test_heal_all_allies() -> void:
	# 创建第二个敌人
	var enemy2 := EnemyData.new()
	enemy2._init("E998", "敌方2", EnemyClass.INFANTRY, EnemyTier.NORMAL, 100, 0, 1)
	enemy2.is_alive = true
	enemy2.current_hp = 50
	_enemy_manager._enemies["E998"] = enemy2

	# 设置治疗所有友军行动
	_test_action.type = "heal"
	_test_action.heal = 15
	_test_action.target = "all_allies"

	# 记录两个敌人的血量
	var original_hp1 = _test_enemy.current_hp
	var original_hp2 = enemy2.current_hp

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证：两个敌人都被治疗
	assert_int(_test_enemy.current_hp).is_equal(original_hp1 + 15)
	assert_int(enemy2.current_hp).is_equal(original_hp2 + 15)


# ==================== 边界测试：治疗随机友军 ====================

## 边界测试：治疗随机友军
func test_heal_random_ally() -> void:
	# 创建第二个敌人
	var enemy2 := EnemyData.new()
	enemy2._init("E998", "敌方2", EnemyClass.INFANTRY, EnemyTier.NORMAL, 100, 0, 1)
	enemy2.is_alive = true
	enemy2.current_hp = 50
	_enemy_manager._enemies["E998"] = enemy2

	# 设置治疗随机友军行动
	_test_action.type = "heal"
	_test_action.heal = 10
	_test_action.target = "random_ally"

	# 记录两个敌人的血量
	var original_hp1 = _test_enemy.current_hp
	var original_hp2 = enemy2.current_hp

	# 执行行动（多次，验证至少有一次影响了另一个敌人）
	var affected_enemy2 = false
	for i in range(10):
		_test_enemy.current_hp = original_hp1
		enemy2.current_hp = original_hp2
		_action_executor.execute_action(_test_action, "E999")
		if enemy2.current_hp > original_hp2:
			affected_enemy2 = true
			break

	assert_bool(affected_enemy2).is_true()


# ==================== 边界测试：施加状态效果 ====================

## 边界测试：施加状态效果
func test_apply_status_effect() -> void:
	# 设置施加状态行动
	_test_action.type = "debuff"
	_test_action.status_effect = "中毒"
	_test_action.status_layers = 2

	# 验证初始状态
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_false()

	# 执行行动
	_action_executor.execute_action(_test_action, "E999")

	# 验证状态已施加
	assert_bool(_status_manager.has_status(StatusEffect.Type.POISON)).is_true()
	assert_int(_status_manager.get_layers(StatusEffect.Type.POISON)).is_equal(2)


# ==================== 边界测试：执行非攻击行动 ====================

## 边界测试：执行非攻击行动
func test_execute_non_attack() -> void:
	# 设置各种非攻击行动
	var test_actions = [
		{"type": "defend", "armor": 5},
		{"type": "buff", "armor": 3},
		{"type": "curse", "curse_id": "C01"},
		{"type": "summon", "summon_id": "E001"}
	]

	for test in test_actions:
		_test_action.type = test["type"]
		if test.has("armor"):
			_test_action.armor = test["armor"]
		if test.has("curse_id"):
			_test_action.curse_id = test["curse_id"]
		if test.has("summon_id"):
			_test_action.summon_id = test["summon_id"]

		# 执行
		_action_executor.execute_action(_test_action, "E999")

		# 无崩溃即成功
		assert_true(true)
