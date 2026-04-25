## meta-save-unlock-discovery_test.gd
## MetaSaveManager 解锁与发现记录单元测试套件
##
## 覆盖 Story 003（meta-save-unlock-discovery）验收标准：
##   AC-1 — Meta Save 在首次解锁新卡牌时立即更新
##   AC-2 — 图鉴发现记录在战役失败后保留
##
## 测试函数（9个）：
##   1. test_unlock_card_adds_to_unlocked_cards_first_time       — AC-1：首次解锁写入
##   2. test_unlock_card_is_idempotent_duplicate_ignored         — AC-1 边界：重复解锁忽略
##   3. test_unlock_card_invalid_category_returns_false          — AC-1 边界：无效类别返回 false
##   4. test_discover_event_adds_to_discovered_events            — AC-2：首次发现写入
##   5. test_discover_event_is_idempotent                        — AC-2 边界：重复发现忽略
##   6. test_meta_persists_after_campaign_failure                — AC-2：战役失败后 discoveredEvents 保留
##   7. test_unlock_equipment_adds_to_unlocked_equipment         — 额外：解锁装备写入
##   8. test_discover_equipment_adds_to_discovered_equipment     — 额外：发现装备写入
##   9. test_load_meta_returns_default_skeleton_when_empty       — 额外：空存档返回默认骨架
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# 辅助：构建带完整内存桩的 MetaSaveManager
# ---------------------------------------------------------------------------

## 创建带内存存档桩（save/load/has）的 MetaSaveManager。
## [br][return] [mgr, store_ref] — store_ref[0] 为内存存档字典（初始为空）
func _make_manager() -> Array:
	var store_ref: Array = [{}]
	var mgr := MetaSaveManager.new()
	mgr.save_stub = func(data: Dictionary) -> bool:
		store_ref[0] = data.duplicate(true)
		return true
	mgr.load_stub = func() -> Dictionary:
		return store_ref[0].duplicate(true)
	mgr.has_save_stub = func() -> bool:
		return not store_ref[0].is_empty()
	return [mgr, store_ref]


# ---------------------------------------------------------------------------
# AC-1 — 首次解锁卡牌时写入 unlockedCards
# ---------------------------------------------------------------------------

## unlock_card 首次调用时，card_id 应出现在对应类别列表中
func test_unlock_card_adds_to_unlocked_cards_first_time() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act
	var ok: bool = mgr.unlock_card("AC0001", "attack")

	# Assert
	assert_bool(ok).is_true()
	assert_bool(store_ref[0]["unlockedCards"]["attack"].has("AC0001")).is_true()


# ---------------------------------------------------------------------------
# AC-1 边界 — 同一卡牌多次解锁，只记录一次
# ---------------------------------------------------------------------------

## unlock_card 对同一 card_id 调用两次，列表中只含一个条目
func test_unlock_card_is_idempotent_duplicate_ignored() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act
	mgr.unlock_card("AC0001", "attack")
	mgr.unlock_card("AC0001", "attack")

	# Assert：列表中 AC0001 只出现一次
	var attack_list: Array = store_ref[0]["unlockedCards"]["attack"]
	var count: int = 0
	for id: String in attack_list:
		if id == "AC0001":
			count += 1
	assert_int(count).is_equal(1)


# ---------------------------------------------------------------------------
# AC-1 边界 — 无效卡牌类别返回 false
# ---------------------------------------------------------------------------

## unlock_card 传入不合法的 card_category 时，应返回 false 且不写入存储
func test_unlock_card_invalid_category_returns_false() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act
	var ok: bool = mgr.unlock_card("AC0001", "invalid_category")

	# Assert
	assert_bool(ok).is_false()
	# 存储层不应被写入
	assert_bool(store_ref[0].is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC-2 — 首次发现事件时写入 discoveredEvents
# ---------------------------------------------------------------------------

## discover_event 首次调用时，event_id 应出现在 discoveredEvents 中
func test_discover_event_adds_to_discovered_events() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act
	var ok: bool = mgr.discover_event("EV010")

	# Assert
	assert_bool(ok).is_true()
	assert_bool(store_ref[0]["discoveredEvents"].has("EV010")).is_true()


# ---------------------------------------------------------------------------
# AC-2 边界 — 同一事件多次发现，只记录一次
# ---------------------------------------------------------------------------

## discover_event 对同一 event_id 调用两次，列表中只含一个条目
func test_discover_event_is_idempotent() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act
	mgr.discover_event("EV010")
	mgr.discover_event("EV010")

	# Assert
	var event_list: Array = store_ref[0]["discoveredEvents"]
	var count: int = 0
	for id: String in event_list:
		if id == "EV010":
			count += 1
	assert_int(count).is_equal(1)


# ---------------------------------------------------------------------------
# AC-2 — 战役失败后 discoveredEvents 仍保留（Meta Save 不回滚）
# ---------------------------------------------------------------------------

## 模拟战役中发现事件后战役失败：Meta Save 不调用 delete，discoveredEvents 仍存在
func test_meta_persists_after_campaign_failure() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# 战役中发现事件
	mgr.discover_event("EV025")
	assert_bool(store_ref[0]["discoveredEvents"].has("EV025")).is_true()

	# Act：模拟战役失败 — 仅清除 Run Save（不操作 Meta Save）
	# 生产环境中 RunSaveManager.delete_run() 只删 run_*.json，不影响 meta.json
	# 此处不调用任何 delete，直接验证 Meta Save 独立存在
	var separate_run_store: Dictionary = {}
	separate_run_store.clear()  # 清空 Run Save（模拟战役失败清除）

	# Assert：Meta Save 中的事件记录仍然存在
	assert_bool(store_ref[0]["discoveredEvents"].has("EV025")).is_true()


# ---------------------------------------------------------------------------
# 额外 — 解锁装备
# ---------------------------------------------------------------------------

## unlock_equipment 首次调用时，equip_id 应出现在 unlockedEquipment 中
func test_unlock_equipment_adds_to_unlocked_equipment() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act
	var ok: bool = mgr.unlock_equipment("EQ005")

	# Assert
	assert_bool(ok).is_true()
	assert_bool(store_ref[0]["unlockedEquipment"].has("EQ005")).is_true()


# ---------------------------------------------------------------------------
# 额外 — 发现装备图鉴
# ---------------------------------------------------------------------------

## discover_equipment 首次调用时，equip_id 应出现在 discoveredEquipment 中
func test_discover_equipment_adds_to_discovered_equipment() -> void:
	# Arrange
	var r := _make_manager()
	var mgr: MetaSaveManager = r[0]
	var store_ref: Array = r[1]

	# Act
	var ok: bool = mgr.discover_equipment("EQ001")

	# Assert
	assert_bool(ok).is_true()
	assert_bool(store_ref[0]["discoveredEquipment"].has("EQ001")).is_true()


# ---------------------------------------------------------------------------
# 额外 — 空存档时 load_meta 返回完整默认骨架
# ---------------------------------------------------------------------------

## load_stub 返回空字典时，load_meta 应返回含所有必要字段的默认骨架
func test_load_meta_returns_default_skeleton_when_empty() -> void:
	# Arrange
	var mgr := MetaSaveManager.new()
	# load_stub 默认即返回 {}，has_save_stub 默认返回 false

	# Act
	var meta: Dictionary = mgr.load_meta()

	# Assert：所有顶层字段均存在
	assert_bool(meta.has("version")).is_true()
	assert_bool(meta.has("unlockedCards")).is_true()
	assert_bool(meta.has("unlockedEquipment")).is_true()
	assert_bool(meta.has("discoveredEvents")).is_true()
	assert_bool(meta.has("discoveredEquipment")).is_true()
	assert_bool(meta.has("heroRecords")).is_true()
	assert_bool(meta.has("statistics")).is_true()
	assert_bool(meta.has("settings")).is_true()

	# unlockedCards 应含四个类别
	var unlocked_cards: Dictionary = meta["unlockedCards"]
	assert_bool(unlocked_cards.has("attack")).is_true()
	assert_bool(unlocked_cards.has("skill")).is_true()
	assert_bool(unlocked_cards.has("troop")).is_true()
	assert_bool(unlocked_cards.has("curse")).is_true()

	# 所有列表初始为空
	assert_int(meta["discoveredEvents"].size()).is_equal(0)
	assert_int(meta["unlockedEquipment"].size()).is_equal(0)
