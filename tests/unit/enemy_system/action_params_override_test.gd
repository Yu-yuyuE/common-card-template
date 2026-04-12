## action_params_override_test.gd
## 测试敌人行动参数覆盖功能
## 验证 JSON 参数能正确覆盖基础行动数值
## 作者: Claude Code
## 创建日期: 2026-04-12

extends GdUnitTestSuite

var enemy_manager: EnemyManager


func before_test() -> void:
	# 创建 EnemyManager 实例
	enemy_manager = EnemyManager.new()
	add_child(enemy_manager)
	# 等待 _ready 执行完成
	await get_tree().process_frame


func after_test() -> void:
	if enemy_manager != null:
		enemy_manager.queue_free()
		enemy_manager = null


## 测试 JSON 解析：有效JSON
func test_parse_valid_json() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST001",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		[],
		"",
		"{\"A01\": {\"damage\": 12, \"armor\": 15}}"
	)

	# 验证解析成功
	assert_dict(enemy_data.action_params).has_key("A01")
	assert_dict(enemy_data.action_params["A01"]).contains({
		"damage": 12,
		"armor": 15
	})


## 测试 JSON 解析：空字符串
func test_parse_empty_json() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST002",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		[],
		"",
		""
	)

	# 验证空字典
	assert_dict(enemy_data.action_params).is_empty()


## 测试 JSON 解析：无效JSON
func test_parse_invalid_json() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST003",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		[],
		"",
		"{invalid json}"
	)

	# 验证解析失败时返回空字典
	assert_dict(enemy_data.action_params).is_empty()


## 测试行动参数覆盖：伤害值
func test_damage_override() -> void:
	# 创建带参数覆盖的敌人
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST004",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		["A01"],
		"",
		"{\"A01\": {\"damage\": 20}}"
	)

	# 创建行动
	var action := EnemyAction.new()
	action.id = "A01"
	action.type = "attack"
	action.value_reference = "6~10"  # 基础值：8
	action.source_enemy_id = enemy_data.id
	action.enemy_manager = enemy_manager

	# 将敌人添加到管理器
	enemy_manager._enemies[enemy_data.id] = enemy_data

	# 解析参数
	action._parse_value_reference()

	# 验证伤害被覆盖为20
	assert_int(action.damage).is_equal(20)


## 测试行动参数覆盖：护甲值
func test_armor_override() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST005",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		["A03"],
		"",
		"{\"A03\": {\"armor\": 12}}"
	)

	var action := EnemyAction.new()
	action.id = "A03"
	action.type = "defend"
	action.value_reference = "护甲+6~10"  # 基础值：8
	action.source_enemy_id = enemy_data.id
	action.enemy_manager = enemy_manager

	enemy_manager._enemies[enemy_data.id] = enemy_data

	action._parse_value_reference()

	# 验证护甲被覆盖为12
	assert_int(action.armor).is_equal(12)


## 测试行动参数覆盖：状态层数
func test_status_layers_override() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST006",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		["A05"],
		"",
		"{\"A05\": {\"status_layers\": 3}}"
	)

	var action := EnemyAction.new()
	action.id = "A05"
	action.type = "debuff"
	action.value_reference = "中毒×2层"  # 基础值：2层
	action.source_enemy_id = enemy_data.id
	action.enemy_manager = enemy_manager

	enemy_manager._enemies[enemy_data.id] = enemy_data

	action._parse_value_reference()

	# 验证状态层数被覆盖为3
	assert_int(action.status_layers).is_equal(3)


## 测试行动参数覆盖：治疗值
func test_heal_override() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST007",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		["A11"],
		"",
		"{\"A11\": {\"heal\": 10}}"
	)

	var action := EnemyAction.new()
	action.id = "A11"
	action.type = "heal"
	action.value_reference = "回血4~8"  # 基础值：6
	action.source_enemy_id = enemy_data.id
	action.enemy_manager = enemy_manager

	enemy_manager._enemies[enemy_data.id] = enemy_data

	action._parse_value_reference()

	# 验证治疗值被覆盖为10
	assert_int(action.heal).is_equal(10)


## 测试行动参数覆盖：冷却回合
func test_cooldown_override() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST008",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		["B16"],
		"",
		"{\"B16\": {\"cooldown\": 3}}"
	)

	var action := EnemyAction.new()
	action.id = "B16"
	action.type = "summon"
	action.value_reference = "召唤1普通"
	action.cooldown = 2  # 基础冷却：2回合
	action.source_enemy_id = enemy_data.id
	action.enemy_manager = enemy_manager

	enemy_manager._enemies[enemy_data.id] = enemy_data

	action._parse_value_reference()

	# 验证冷却被覆盖为3
	assert_int(action.cooldown).is_equal(3)


## 测试多个参数覆盖
func test_multiple_params_override() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST009",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		["A07"],
		"",
		"{\"A07\": {\"damage\": 8, \"status_layers\": 2}}"
	)

	var action := EnemyAction.new()
	action.id = "A07"
	action.type = "attack"
	action.value_reference = "伤害4~6+盲目×1"  # 基础值：伤害5，状态1层
	action.source_enemy_id = enemy_data.id
	action.enemy_manager = enemy_manager

	enemy_manager._enemies[enemy_data.id] = enemy_data

	action._parse_value_reference()

	# 验证两个参数都被覆盖
	assert_int(action.damage).is_equal(8)
	assert_int(action.status_layers).is_equal(2)


## 测试无覆盖时使用基础值
func test_no_override_uses_base_value() -> void:
	var enemy_data := EnemyData.new()
	enemy_data._init(
		"TEST010",
		"测试敌人",
		EnemyManager.EnemyClass.INFANTRY,
		EnemyManager.EnemyTier.NORMAL,
		100,
		10,
		["A01"],
		"",
		""  # 无JSON覆盖
	)

	var action := EnemyAction.new()
	action.id = "A01"
	action.type = "attack"
	action.value_reference = "6~10"  # 基础值：8
	action.source_enemy_id = enemy_data.id
	action.enemy_manager = enemy_manager

	enemy_manager._enemies[enemy_data.id] = enemy_data

	action._parse_value_reference()

	# 验证使用基础值8（6和10的中值）
	assert_int(action.damage).is_equal(8)


## 测试从CSV加载带JSON参数的敌人
func test_load_enemy_with_json_params_from_csv() -> void:
	# 读取 E002 (黄巾道士)，它有 action_params_json
	var enemy: EnemyData = enemy_manager.get_enemy("E002")

	assert_object(enemy).is_not_null()
	assert_str(enemy.id).is_equal("E002")
	assert_dict(enemy.action_params).has_key("A05")
	assert_dict(enemy.action_params["A05"]).contains({"status_layers": 3})


## 测试从CSV加载带JSON参数的敌人：关隘戍卒
func test_load_enemy_e013_with_json_params() -> void:
	var enemy: EnemyData = enemy_manager.get_enemy("E013")

	assert_object(enemy).is_not_null()
	assert_str(enemy.id).is_equal("E013")
	assert_dict(enemy.action_params).has_key("A03")
	assert_dict(enemy.action_params["A03"]).contains({"armor": 12})


## 测试从CSV加载带JSON参数的敌人：关隘守将
func test_load_enemy_e041_with_json_params() -> void:
	var enemy: EnemyData = enemy_manager.get_enemy("E041")

	assert_object(enemy).is_not_null()
	assert_str(enemy.id).is_equal("E041")
	assert_dict(enemy.action_params).has_key("C01")
	assert_dict(enemy.action_params["C01"]).contains({"damage": 40})


## 测试浮点数转整数
func test_float_to_int_conversion() -> void:
	var action := EnemyAction.new()

	# 测试整数
	assert_int(action._to_int(15)).is_equal(15)

	# 测试浮点数
	assert_int(action._to_int(15.7)).is_equal(15)

	# 测试字符串
	assert_int(action._to_int("20")).is_equal(20)

	# 测试其他类型
	assert_int(action._to_int(null)).is_equal(0)
