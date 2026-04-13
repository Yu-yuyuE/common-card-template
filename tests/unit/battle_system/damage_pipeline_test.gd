extends GdUnitTestSuite

var _calculator: DamageCalculator

func before() -> void:
	_calculator = DamageCalculator.new()

func test_ac1_shield_blocks_damage_preferentially() -> void:
	# AC-1: 护盾优先抵挡
	# Given: 敌人 HP=20, Shield=10
	var entity = BattleEntity.new("enemy_1", false)
	entity.current_hp = 20
	entity.shield = 10

	# When: 受到 15 点正常伤害
	var actual_damage = entity.take_damage(15, false)

	# Then: 敌人 Shield=0, HP=15。返回实际造成的最终穿透伤害 5。
	assert_int(entity.shield).is_equal(0)
	assert_int(entity.current_hp).is_equal(15)
	assert_int(actual_damage).is_equal(5)

func test_ac2_penetrate_ignores_shield() -> void:
	# AC-2: 无视护甲直接扣HP
	# Given: 敌人 HP=20, Shield=10
	var entity = BattleEntity.new("enemy_1", false)
	entity.current_hp = 20
	entity.shield = 10

	# When: 受到 15 点无视护甲伤害 (penetrate=true)
	var actual_damage = entity.take_damage(15, true)

	# Then: 敌人 Shield=10 (不变), HP=5。
	assert_int(entity.shield).is_equal(10)
	assert_int(entity.current_hp).is_equal(5)
	assert_int(actual_damage).is_equal(15)

func test_ac3_pipeline_calculation() -> void:
	# AC-3: 伤害分步计算
	# Given: 基础伤害=10, 假设Mock地形系数=1.5, 天气=1.0, 状态=1.0
	var base_damage = 10
	var terrain_mod = 1.5
	var weather_mod = 1.0
	var buff_mod = 1.0
	var debuff_mod = 1.0

	# When: 管道计算
	var final_damage = _calculator.calculate_pipeline_damage(base_damage, terrain_mod, weather_mod, buff_mod, debuff_mod)

	# Then: 最终伤害 = 15。
	assert_int(final_damage).is_equal(15)

func test_ac4_minimum_damage_is_one() -> void:
	# AC-4: 保底伤害
	# Given: 经过所有减免后计算结果为 0
	var base_damage = 10
	var terrain_mod = 0.0 # 极端减伤

	# When: 取 max(1, round(dmg))
	var final_damage = _calculator.calculate_pipeline_damage(base_damage, terrain_mod)

	# Then: 最终伤害为 1。
	assert_int(final_damage).is_equal(1)

func test_hp_never_below_zero() -> void:
	# 边界测试：如果 HP <= 0，确保不再出现负数。
	var entity = BattleEntity.new("enemy_1", false)
	entity.current_hp = 5
	entity.shield = 0

	var actual_damage = entity.take_damage(15, false)

	assert_int(entity.current_hp).is_equal(0)
	assert_int(actual_damage).is_equal(15)
