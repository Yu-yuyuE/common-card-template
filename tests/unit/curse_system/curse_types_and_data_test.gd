## curse_types_and_data_test.gd
## 诅咒类型与数据结构测试 (Story 4-5)
## 验证三种诅咒类型及其数据结构的正确性
## 作者: Claude Code
## 创建日期: 2026-04-12

class_name CurseTypesAndDataTest
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# 测试数据
# ---------------------------------------------------------------------------

var _curse_manager: CurseManager

# ---------------------------------------------------------------------------
# 测试生命周期
# ---------------------------------------------------------------------------

func before_test() -> void:
	# 创建 CurseManager
	_curse_manager = CurseManager.new()
	_curse_manager._ready()

	# 添加到场景树
	add_child(_curse_manager)


func after_test() -> void:
	# 清理测试实例
	if _curse_manager and is_instance_valid(_curse_manager):
		_curse_manager.queue_free()
	_curse_manager = null


# ---------------------------------------------------------------------------
# AC-1: 三种诅咒类型可正确区分
# ---------------------------------------------------------------------------

## AC-1.1: 抽到触发型诅咒可正确识别
func test_draw_trigger_type_identification() -> void:
	# Arrange
	var poison_data = _curse_manager.get_curse("CC0001")
	assert_not_null(poison_data, "毒药诅咒卡应该存在")

	# Act
	var is_trigger = poison_data.is_draw_trigger()

	# Assert
	assert_true(is_trigger, "毒药应该是抽到触发型诅咒")


## AC-1.2: 常驻牌库型诅咒可正确识别
func test_persistent_library_type_identification() -> void:
	# Arrange
	var plague_data = _curse_manager.get_curse("CC0010")
	assert_not_null(plague_data, "镣铐应该是常驻牌库型")

	# Act
	var is_library = plague_data.is_persistent_library()

	# Assert
	assert_true(is_library, "镣铐应该是常驻牌库型诅咒")


## AC-1.3: 常驻手牌型诅咒可正确识别
func test_persistent_hand_type_identification() -> void:
	# Arrange
	var shackle_data = _curse_manager.get_curse("CC0019")
	assert_not_null(shackle_data, "枷梏应该是常驻手牌型")

	# Act
	var is_hand = shackle_data.is_persistent_hand()

	# Assert
	assert_true(is_hand, "枷梏应该是常驻手牌型诅咒")


## AC-1.4: 枚举名称获取正确
func test_curse_type_names() -> void:
	assert_string(CurseCardData.get_curse_type_name(CurseCardData.CurseType.DRAW_TRIGGER)).is_equal("抽到触发型")
	assert_string(CurseCardData.get_curse_type_name(CurseCardData.CurseType.PERSISTENT_LIBRARY)).is_equal("常驻牌库型")
	assert_string(CurseCardData.get_curse_type_name(CurseCardData.CurseType.PERSISTENT_HAND)).is_equal("常驻手牌型")


# ---------------------------------------------------------------------------
# AC-2: 诅咒卡数据结构包含所有必需字段
# ---------------------------------------------------------------------------

## AC-2.1: 诅咒卡包含 card_id 字段
func test_curse_has_card_id() -> void:
	var curse = _curse_manager.get_curse("CC0001")
	assert_string(curse.card_id).is_equal("CC0001")


## AC-2.2: 诅咒卡包含 type 字段
func test_curse_has_type() -> void:
	var curse = _curse_manager.get_curse("CC0001")
	assert_int(curse.curse_type).is_equal(CurseCardData.CurseType.DRAW_TRIGGER)


## AC-2.3: 诅咒卡包含 discard_cost 字段
func test_curse_has_discard_cost() -> void:
	# 常驻手牌型诅咒应有discard_cost
	var shackle = _curse_manager.get_curse("CC0019")
	assert_int(shackle.discard_cost).is_equal(2)

	# 抽到触发型诅咒discard_cost应为0
	var poison = _curse_manager.get_curse("CC0001")
	assert_int(poison.discard_cost).is_equal(0)


## AC-2.4: 诅咒卡包含对应类型的 effect 字段
func test_curse_has_correct_effect_field() -> void:
	# 抽到触发型应有effect_text
	var poison = _curse_manager.get_curse("CC0001")
	assert_string(poison.effect_text).is_equal("抽入手牌时立即受到2点伤害")

	# 常驻牌库型应有effect_text
	var plague = _curse_manager.get_curse("CC0010")
	assert_string(plague.effect_text).is_equal("在牌库中持续生效：我方HP上限-3（每有1张叠加1次）")

	# 常驻手牌型应有effect_text
	var shackle = _curse_manager.get_curse("CC0019")
	assert_string(shackle.effect_text).is_equal("无效果；常驻手牌")


# ---------------------------------------------------------------------------
# AC-3: 诅咒卡类型可被序列化和反序列化
# ---------------------------------------------------------------------------

## AC-3.1: 诅咒卡数据可以被保存到字典
func test_curse_serialization() -> void:
	var curse = _curse_manager.get_curse("CC0001")
	assert_not_null(curse)

	# 模拟序列化到字典
	var data = {
		"card_id": curse.card_id,
		"card_type": curse.card_type,
		"curse_type": curse.curse_type,
		"discard_cost": curse.discard_cost,
		"effect_text": curse.effect_text,
		"special_attribute": curse.special_attribute,
		"catalog": curse.catalog,
	}

	# 检查所有字段都被正确保存
	assert_string(data["card_id"]).is_equal("CC0001")
	assert_int(data["curse_type"]).is_equal(CurseCardData.CurseType.DRAW_TRIGGER)
	assert_int(data["discard_cost"]).is_equal(0)
	assert_string(data["effect_text"]).is_equal("抽入手牌时立即受到2点伤害")


## AC-3.2: 诅咒卡可以从字典恢复
func test_curse_deserialization() -> void:
	# 模拟从字典恢复
	var saved_data = {
		"card_id": "CC0005",
		"card_type": CardData.CardType.CURSE,
		"curse_type": CurseCardData.CurseType.DRAW_TRIGGER,
		"discard_cost": 0,
		"effect_text": "抽入手牌时获得1层虚弱",
		"special_attribute": "—",
		"catalog": "初始通用"
	}

	var restored = CurseCardData.new(saved_data["card_id"], 0, "军心涣散", 0)
	restored.curse_type = saved_data["curse_type"]
	restored.discard_cost = saved_data["discard_cost"]
	restored.effect_text = saved_data["effect_text"]
	restored.special_attribute = saved_data["special_attribute"]
	restored.catalog = saved_data["catalog"]

	# 验证反序列化正确
	assert_string(restored.card_id).is_equal("CC0005")
	assert_int(restored.curse_type).is_equal(CurseCardData.CurseType.DRAW_TRIGGER)
	assert_string(restored.effect_text).is_equal("抽入手牌时获得1层虚弱")


# ---------------------------------------------------------------------------
# AC-4: CurseManager提供正确的查询接口
# ---------------------------------------------------------------------------

## AC-4.1: 可以通过卡ID获取诅咒数据
func test_get_curse_by_id() -> void:
	var curse = _curse_manager.get_curse("CC0001")
	assert_not_null(curse, "应该能通过card_id获取诅咒卡数据")
	assert_string(curse.card_id).is_equal("CC0001")


## AC-4.2: 获取不存在的诅咒返回null
func test_get_nonexistent_curse_returns_null() -> void:
	var curse = _curse_manager.get_curse("CC9999")
	assert_null(curse, "不存在的诅咒卡应返回null")


## AC-4.3: 可以获取所有诅咒卡
func test_get_all_curses() -> void:
	var all_curses = _curse_manager.get_all_curses()
	assert_int(all_curses.size()).is_greater_than(0, "应该至少加载1张诅咒卡")


## AC-4.4: 可以按类型过滤诅咒卡
func test_get_curses_by_type() -> void:
	var draw_trigger = _curse_manager.get_curses_by_type(CurseCardData.CurseType.DRAW_TRIGGER)
	assert_int(draw_trigger.size()).is_greater_than(0, "应有抽到触发型诅咒")

	var library = _curse_manager.get_curses_by_type(CurseCardData.CurseType.PERSISTENT_LIBRARY)
	assert_int(library.size()).is_greater_than(0, "应有常驻牌库型诅咒")

	var hand = _curse_manager.get_curses_by_type(CurseCardData.CurseType.PERSISTENT_HAND)
	assert_int(hand.size()).is_greater_than(0, "应有常驻手牌型诅咒")


## AC-4.5: is_curse_card正确识别诅咒卡
func test_is_curse_card() -> void:
	assert_true(_curse_manager.is_curse_card("CC0001"), "CC0001应该是诅咒卡")
	assert_true(_curse_manager.is_curse_card("CC0010"), "CC0010应该是诅咒卡")
	assert_false(_curse_manager.is_curse_card("attack_card"), "非诅咒卡ID应返回false")


## AC-4.6: 获取诅咒弃置费用正确
func test_get_discard_cost() -> void:
	# 常驻手牌型应有弃置费用
	var shackle = _curse_manager.get_curse("CC0019")
	assert_int(_curse_manager.get_discard_cost("CC0019")).is_equal(2)

	var hook = _curse_manager.get_curse("CC0022")
	assert_int(_curse_manager.get_discard_cost("CC0022")).is_equal(1)

	# 抽到触发型无弃置费用
	var poison = _curse_manager.get_curse("CC0001")
	assert_int(_curse_manager.get_discard_cost("CC0001")).is_equal(0)


## AC-4.7: 获取诅咒效果文本正确
func test_get_curse_effect() -> void:
	var poison = _curse_manager.get_curse("CC0001")
	assert_string(_curse_manager.get_curse_effect("CC0001")).is_equal("抽入手牌时立即受到2点伤害")

	var plague = _curse_manager.get_curse("CC0010")
	assert_string(_curse_manager.get_curse_effect("CC0010")).is_equal("在牌库中持续生效：我方HP上限-3（每有1张叠加1次）")

	var shackle = _curse_manager.get_curse("CC0019")
	assert_string(_curse_manager.get_curse_effect("CC0019")).is_equal("无效果；常驻手牌")


# ---------------------------------------------------------------------------
# 随机验证：确保所有诅咒数据有效
# ---------------------------------------------------------------------------

## 验证所有加载的诅咒卡类型都在枚举范围内
func test_all_curses_have_valid_type() -> void:
	var all_curses = _curse_manager.get_all_curses()
	for curse in all_curses:
		var type_val = curse.curse_type
		assert_true(
			type_val >= 0 and type_val <= 2,
			"诅咒卡'%s'的类型值应在0-2范围内，实际为%d" % [curse.card_id, type_val]
		)


## 验证至少有一种每种类型的诅咒
func test_at_least_one_of_each_type() -> void:
	var draw_triggers = _curse_manager.get_draw_trigger_curses()
	var libraries = _curse_manager.get_persistent_library_curses()
	var hands = _curse_manager.get_persistent_hand_curses()

	assert_int(draw_triggers.size()).is_greater_than(0, "应至少有一种抽到触发型诅咒")
	assert_int(libraries.size()).is_greater_than(0, "应至少有一种常驻牌库型诅咒")
	assert_int(hands.size()).is_greater_than(0, "应至少有一种常驻手牌型诅咒")


## 验证诅咒卡的一致性：type字段与CardData.card_type一致
func test_curse_type_consistency() -> void:
	var all_curses = _curse_manager.get_all_curses()
	for curse in all_curses:
		assert_int(curse.card_type).is_equal(CardData.CardType.CURSE, "诅咒卡的card_type应为CURSE")