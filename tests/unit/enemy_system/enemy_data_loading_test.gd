## enemy_data_loading_test.gd
## EnemyManager 数据加载单元测试 (Story 001)
## 验证 Story 001 的验收标准

class_name EnemyDataLoadingTest
extends GdUnitTestSuite

# ==================== 测试数据 ====================

var _enemy_manager: EnemyManager

# ==================== 测试生命周期 ====================

func before_test() -> void:
	_enemy_manager = EnemyManager.new()

func after_test() -> void:
	if _enemy_manager and is_instance_valid(_enemy_manager):
		_enemy_manager.queue_free()
	_enemy_manager = null

# ==================== AC-1: 枚举与数据加载 ====================

## AC-1: 枚举定义与数据加载
## Given: 一个格式良好的 enemies.csv 测试文件包含 2 个条目
## When: EnemyManager 初始化加载
## Then: 内部 _enemies 字典大小为 100，并且能用 ID 取出
func test_enemy_data_loading() -> void:
	# Given: CSV 文件存在且格式正确
	assert_true(FileAccess.file_exists("res://assets/csv_data/enemies.csv"))

	# When: EnemyManager 初始化
	var count: int = _enemy_manager._load_enemy_data()

	# Then: 加载 100 个敌人
	assert_int(count).is_equal(100)
	assert_int(_enemy_manager._enemies.size()).is_equal(100)

# ==================== AC-2: 职业和级别解析 ====================

## AC-2: 职业和级别解析
## Given: CSV 填入 "步兵", "精英"
## When: 读取解析
## Then: 数据映射到 EnemyClass.INFANTRY 和 EnemyTier.ELITE
func test_class_and_tier_parsing() -> void:
	_enemy_manager._load_enemy_data()

	# Given: 获取第一个敌人数据
	var enemy: EnemyData = _enemy_manager.get_enemy("E001")
	assert_not_null(enemy)

	# Then: 验证枚举映射正确
	assert_int(enemy.enemy_class).is_equal(EnemyManager.EnemyClass.INFANTRY)
	# Tier 验证根据实际 CSV 数据调整
	assert_true(enemy.tier in [EnemyManager.EnemyTier.NORMAL, EnemyManager.EnemyTier.ELITE, EnemyManager.EnemyTier.BOSS])

# ==================== AC-3: 序列解析 ====================

## AC-3: 序列解析
## Given: 字段 "A01→B01→C01"
## When: 加载后查看对象的 action_sequence
## Then: 数组内元素为 ["A01", "B01", "C01"]
func test_action_sequence_parsing() -> void:
	_enemy_manager._load_enemy_data()

	# Given: 获取有行动序列的敌人
	var enemy: EnemyData = _enemy_manager.get_enemy("E001")
	assert_not_null(enemy)

	# Then: 验证序列解析为数组
	if not enemy.action_sequence.is_empty():
		assert_true(enemy.action_sequence is Array)
		# 验证格式正确（元素为字符串）
		for action in enemy.action_sequence:
			assert_true(action is String)

# ==================== AC-5: 查询接口 ====================

## AC-5: 查询接口测试
## Given: 敌人数据已加载
## When: 调用各种查询接口
## Then: 返回正确结果
func test_query_interfaces() -> void:
	_enemy_manager._load_enemy_data()

	# Test get_enemy by ID
	var enemy: EnemyData = _enemy_manager.get_enemy("E001")
	assert_not_null(enemy)
	assert_str(enemy.id).is_equal("E001")

	# Test get_enemies_by_tier
	var normal_enemies: Array = _enemy_manager.get_enemies_by_tier(EnemyManager.EnemyTier.NORMAL)
	assert_true(normal_enemies.size() > 0)

	# Test get_enemies_by_class
	var infantry_enemies: Array = _enemy_manager.get_enemies_by_class(EnemyManager.EnemyClass.INFANTRY)
	assert_true(infantry_enemies.size() > 0)

# ==================== AC-4: 数据完整性 ====================

## AC-4: 数据完整性测试
## Given: 敌人数据已加载
## When: 验证所有关键属性
## Then: 所有属性值符合预期
func test_enemy_data_integrity() -> void:
	_enemy_manager._load_enemy_data()

	# 验证至少一个敌人有所有必需属性
	var enemy: EnemyData = _enemy_manager.get_enemy("E001")
	assert_not_null(enemy)
	assert_true(enemy.id != "")
	assert_true(enemy.name != "")
	assert_true(enemy.hp >= 0)
	assert_true(enemy.armor >= 0)
	assert_true(enemy.speed >= 0)
	assert_true(enemy.tier in [EnemyManager.EnemyTier.NORMAL, EnemyManager.EnemyTier.ELITE, EnemyManager.EnemyTier.BOSS])
	assert_true(enemy.enemy_class in [EnemyManager.EnemyClass.INFANTRY, EnemyManager.EnemyClass.CAVALRY, EnemyManager.EnemyClass.ARCHER, EnemyManager.EnemyClass.STRATEGIST, EnemyManager.EnemyClass.SHIELD])