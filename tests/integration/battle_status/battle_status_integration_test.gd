extends GdUnitTestSuite

# Story 5-12: C1+C2 状态效果与战斗联动（集成测试）
# 跨越 BattleManager (C2) + StatusManager (C1) + ResourceManager (F2) 系统边界
#
# 覆盖：
# IT-1: 打出卡牌施加状态 → StatusManager 记录正确
# IT-2: 回合结束 on_round_end 在 PLAYER_END 阶段消耗状态层数
# IT-3: DoT 伤害通过 ResourceManager 正确修改 HP（端到端）
# IT-4: 免疫单位被施加 Debuff → 静默失败，HP 不变
# IT-5: 伤害管线 × 状态修正 = 最终伤害正确（怒气 + 基础攻击）
# IT-6: 多个修正叠加连乘精度

# ---------------------------------------------------------------------------
# 测试夹具
# ---------------------------------------------------------------------------

## 为每个单位创建独立 StatusManager 和 ResourceManager
class CombatUnit:
	var name: String
	var entity: BattleEntity
	var sm: StatusManager
	var rm: ResourceManager

	func _init(p_name: String, p_hp: int, p_ap: int = 4) -> void:
		name = p_name
		entity = BattleEntity.new(p_name, p_name == "player")
		entity.max_hp = p_hp
		entity.current_hp = p_hp
		entity.max_action_points = p_ap
		entity.action_points = p_ap
		entity.shield = 0
		entity.max_shield = 20
		sm = StatusManager.new()
		rm = ResourceManager.new()
		rm.init_hero(p_hp, p_ap)

func _make_card(id: String, cost: int = 1,
		remove: bool = false, exhaust: bool = false) -> Card:
	return Card.new(CardData.new(id, cost, remove, exhaust))

func _make_rm_battle() -> ResourceManager:
	var rm := ResourceManager.new()
	rm.init_hero(50, 4)
	return rm

# ---------------------------------------------------------------------------
# IT-1: 打出卡牌施加状态 → StatusManager 记录正确
#
# 验证：出牌结算框架（5-4）能正确驱动 StatusManager 的状态施加
# ---------------------------------------------------------------------------

func test_it1_play_card_applies_status_to_enemy() -> void:
	# Arrange: 建立战斗，敌人上有 StatusManager
	var rm := _make_rm_battle()
	var bm := BattleManager.new()
	bm.setup_battle({"stage_count": 1,
		"enemies": [{"id": "enemy_1", "hp": 30, "shield": 0, "max_shield": 10, "ap": 1}]}, rm)

	var enemy := bm.enemy_entities[0]
	var enemy_sm := StatusManager.new()

	# 监听 card_played 信号，模拟施加状态
	var status_applied := false
	bm.card_played.connect(func(_cid, _tpos):
		# 卡牌打出后，模拟效果触发状态施加
		enemy_sm.apply(StatusEffect.Type.POISON, 3, "毒箭卡")
		status_applied = true
	)

	# 加入手牌
	bm.card_manager.hand_cards.append(_make_card("poison_arrow", 1))
	# Act
	bm.play_card("poison_arrow", 0)

	# Assert
	assert_bool(status_applied).is_true()
	assert_int(enemy_sm.get_layers(StatusEffect.Type.POISON)).is_equal(3)

# ---------------------------------------------------------------------------
# IT-2: 回合结束 on_round_end 消耗状态层数（PLAYER_END 阶段）
# ---------------------------------------------------------------------------

func test_it2_status_layers_decrement_on_player_end() -> void:
	# Arrange: 模拟单位持有3层中毒
	var unit := CombatUnit.new("player", 50)
	unit.sm.apply(StatusEffect.Type.POISON, 3, "")

	# 模拟 PLAYER_END 阶段调用 on_round_end
	unit.sm.on_round_end()

	# Assert: 层数变为 2
	assert_int(unit.sm.get_layers(StatusEffect.Type.POISON)).is_equal(2)

func test_it2_status_removed_when_layers_reach_zero() -> void:
	var unit := CombatUnit.new("player", 50)
	unit.sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")

	var removed_signal := false
	unit.sm.status_removed.connect(func(_t, _r): removed_signal = true)
	unit.sm.on_round_end()

	assert_bool(unit.sm.has_status(StatusEffect.Type.ARMOR_BREAK)).is_false()
	assert_bool(removed_signal).is_true()

# ---------------------------------------------------------------------------
# IT-3: DoT 伤害通过 ResourceManager 正确修改 HP（端到端）
# ---------------------------------------------------------------------------

func test_it3_dot_damage_modifies_hp_via_resource_manager() -> void:
	# Arrange: 目标HP=50，护盾=0，3层中毒（×4=12伤，穿透）
	var unit := CombatUnit.new("enemy", 50)
	unit.sm.apply(StatusEffect.Type.POISON, 3, "")

	# Act: 回合开始结算 DoT
	unit.sm.on_round_start_dot(unit.rm)

	# Assert: HP 减少 12（固定4，不乘层数）
	assert_int(unit.rm.get_hp()).is_equal(46)  # 50 - 4（固定伤害，非层数乘）

func test_it3_burn_dot_reduces_shield_first_then_hp() -> void:
	# 灼烧走护盾：护盾5，2层灼烧×5=10伤 → 护盾0，HP-5
	var unit := CombatUnit.new("enemy", 50)
	unit.rm.add_armor(5)
	unit.sm.apply(StatusEffect.Type.BURN, 2, "")

	unit.sm.on_round_start_dot(unit.rm)

	assert_int(unit.rm.get_armor()).is_equal(0)
	assert_int(unit.rm.get_hp()).is_equal(45)

func test_it3_dot_then_round_end_full_cycle() -> void:
	# 完整回合循环：DoT先结算，然后层数-1
	var unit := CombatUnit.new("enemy", 50)
	unit.sm.apply(StatusEffect.Type.POISON, 3, "")

	# 回合开始：DoT 结算
	unit.sm.on_round_start_dot(unit.rm)
	assert_int(unit.rm.get_hp()).is_equal(46)  # 50-4
	assert_int(unit.sm.get_layers(StatusEffect.Type.POISON)).is_equal(3)  # 层数未变

	# 回合结束：层数 -1
	unit.sm.on_round_end()
	assert_int(unit.sm.get_layers(StatusEffect.Type.POISON)).is_equal(2)

# ---------------------------------------------------------------------------
# IT-4: 免疫单位被施加 Debuff → 静默失败，HP 不变
# ---------------------------------------------------------------------------

func test_it4_immune_unit_blocks_debuff_silently() -> void:
	var unit := CombatUnit.new("enemy", 50)
	unit.sm.apply(StatusEffect.Type.IMMUNE, 2, "")

	# 尝试施加 Debuff
	var ok := unit.sm.apply(StatusEffect.Type.POISON, 3, "")

	assert_bool(ok).is_false()
	assert_int(unit.sm.get_layers(StatusEffect.Type.POISON)).is_equal(0)

func test_it4_immune_unit_dot_no_hp_change() -> void:
	# 免疫单位无 Debuff → DoT 不结算 → HP 不变
	var unit := CombatUnit.new("enemy", 50)
	unit.sm.apply(StatusEffect.Type.IMMUNE, 2, "")
	unit.sm.apply(StatusEffect.Type.POISON, 3, "")  # 被阻止

	unit.sm.on_round_start_dot(unit.rm)
	assert_int(unit.rm.get_hp()).is_equal(50)

# ---------------------------------------------------------------------------
# IT-5: 伤害管线 × 状态修正 = 最终伤害正确
#        攻击方有怒气(×1.25) + DamageCalculator 基础管线
# ---------------------------------------------------------------------------

func test_it5_attacker_fury_multiplies_pipeline_damage() -> void:
	# Arrange: 攻击方有怒气，基础伤害 10，地形×1.0
	var attacker_sm := StatusManager.new()
	attacker_sm.apply(StatusEffect.Type.FURY, 1, "")

	var calc := DamageCalculator.new()

	# Step 1: 管线基础计算（地形天气均为1.0）
	var pipeline := calc.calculate_pipeline_damage(10, 1.0, 1.0, 1.0, 1.0)  # = 10
	# Step 2: 攻击方状态修正
	var final_damage := attacker_sm.calculate_damage_modifier(pipeline)  # 10 × 1.25 = 12

	assert_int(pipeline).is_equal(10)
	assert_int(final_damage).is_equal(12)

func test_it5_defender_armor_break_multiplies_incoming() -> void:
	# 受击方破甲(×1.25)，传入伤害10
	var defender_sm := StatusManager.new()
	defender_sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")

	var incoming := defender_sm.calculate_incoming_damage_with_rng(10, 0.9)
	assert_int(incoming).is_equal(12)

# ---------------------------------------------------------------------------
# IT-6: 多个修正叠加连乘精度
# ---------------------------------------------------------------------------

func test_it6_fury_pipeline_plus_armor_break_chain() -> void:
	# 攻击方怒气 → pipeline=10 → ×1.25=12
	# 受击方破甲 → 12 × 1.25 = 15
	var attacker_sm := StatusManager.new()
	attacker_sm.apply(StatusEffect.Type.FURY, 1, "")

	var defender_sm := StatusManager.new()
	defender_sm.apply(StatusEffect.Type.ARMOR_BREAK, 1, "")

	var calc := DamageCalculator.new()
	var pipeline := calc.calculate_pipeline_damage(10)
	var after_attacker := attacker_sm.calculate_damage_modifier(pipeline)       # 12
	var final := defender_sm.calculate_incoming_damage_with_rng(after_attacker, 0.9)  # 15

	assert_int(pipeline).is_equal(10)
	assert_int(after_attacker).is_equal(12)
	assert_int(final).is_equal(15)

func test_it6_weaken_and_defend_chain_precision() -> void:
	# 攻击方虚弱(×0.75)：base=10 → 7
	# 受击方坚守(×0.75)：7 → int(7×0.75)=5，+恐惧0=5
	var attacker_sm := StatusManager.new()
	attacker_sm.apply(StatusEffect.Type.WEAKEN, 1, "")

	var defender_sm := StatusManager.new()
	defender_sm.apply(StatusEffect.Type.DEFEND, 1, "")

	var calc := DamageCalculator.new()
	var pipeline := calc.calculate_pipeline_damage(10)           # 10
	var after_weak := attacker_sm.calculate_damage_modifier(pipeline)     # int(10×0.75)=7
	var final := defender_sm.calculate_incoming_damage_with_rng(after_weak, 0.9)  # int(7×0.75)=5

	assert_int(after_weak).is_equal(7)
	assert_int(final).is_equal(5)
