## save_manager_e2e_test.gd
## RunSaveManager + AtomicSaveWriter 端到端集成测试
##
## 覆盖 Sprint 8 Story 8-2（G3：SaveManager 端到端集成）全部验收标准：
##   AC1 — test_run_save_uses_real_atomic_writer
##   AC2 — test_run_restore_round_trip_with_real_writer
##   AC3 — test_atomic_write_survives_interrupted_write
##   AC4 — test_two_heroes_saves_do_not_collide
##   AC5 — test_version_compat_minor_bump
##   AC6 — test_corrupted_json_returns_empty_data_no_crash
##   AC7 — test_run_save_load_under_5ms
##
## 与现有 run_save_write_restore_test.gd 的区别：
##   本文件不使用任何内存桩，save_stub / load_stub 均接入真实 AtomicSaveWriter，
##   验证完整的 write → disk → read round-trip 行为。
##
## 运行方式：GdUnit4（godot --headless --script tests/gdunit4_runner.gd）
## 注意：所有测试文件均写入 user://saves/ 目录，after_each() 自动清理。
extends GdUnitTestSuite


# ============================================================
# 常量：测试用文件路径（加 _e2e 后缀，避免与其他测试冲突）
# ============================================================

const _HERO_RT: String       = "run_test_e2e_rt"       # round-trip 测试用英雄 ID
const _HERO_CAO: String      = "cao_cao_e2e"            # 多存档碰撞测试：曹操
const _HERO_LIU: String      = "liu_bei_e2e"            # 多存档碰撞测试：刘备
const _HERO_COMPAT: String   = "run_test_e2e_compat"    # 版本兼容测试
const _HERO_CORRUPT: String  = "run_test_e2e_corrupt"   # 损坏 JSON 测试
const _HERO_PERF: String     = "run_test_e2e_perf"      # 性能测试

## 获取英雄 ID 对应的存档路径
func _save_path(hero_id: String) -> String:
	return "user://saves/run_%s.json" % hero_id


# ============================================================
# 测试夹具：构建接线了真实 AtomicSaveWriter 的 RunSaveManager
# ============================================================

## 构建将 RunSaveManager 接线到真实 AtomicSaveWriter 的管理器。
## 同时返回 writer 引用，供需要注入故障桩的测试使用。
## [br][return] [mgr: RunSaveManager, writer: AtomicSaveWriter]
func _make_real_manager() -> Array:
	var writer := AtomicSaveWriter.new()
	var mgr := RunSaveManager.new()

	mgr.save_stub = func(hero_id: String, data: Dictionary) -> bool:
		return writer.write_atomic(_save_path(hero_id), data)

	mgr.load_stub = func(hero_id: String) -> Dictionary:
		return writer.read_json(_save_path(hero_id))

	mgr.has_save_stub = func(hero_id: String) -> bool:
		return FileAccess.file_exists(_save_path(hero_id))

	mgr.delete_run_stub = func(hero_id: String) -> bool:
		var p: String = _save_path(hero_id)
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
			return true
		return false

	return [mgr, writer]


# ============================================================
# 测试生命周期：after_each 清理所有 e2e 测试文件
# ============================================================

## 每个测试结束后清理在 user://saves/ 下创建的所有 e2e 文件，确保测试隔离
func after_each() -> void:
	var heroes: Array[String] = [
		_HERO_RT, _HERO_CAO, _HERO_LIU,
		_HERO_COMPAT, _HERO_CORRUPT, _HERO_PERF,
	]
	for hero_id: String in heroes:
		var p: String = _save_path(hero_id)
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
		# 同时清理可能残留的 .tmp 临时文件（AC3 rename 失败后会残留）
		var tmp_p: String = p + ".tmp"
		if FileAccess.file_exists(tmp_p):
			DirAccess.remove_absolute(tmp_p)


# ============================================================
# AC1 — save_run 通过真实 AtomicSaveWriter 将文件写入磁盘
# ============================================================

## 验证 save_run 经由真实 AtomicSaveWriter 成功将文件写入磁盘，
## 且写入内容为合法 JSON 格式
func test_run_save_uses_real_atomic_writer() -> void:
	# Arrange
	var r: Array = _make_real_manager()
	var mgr: RunSaveManager = r[0]
	var data: Dictionary = {
		"resources": {
			"hp": 30, "maxHp": 50, "provisions": 80,
			"gold": 200, "actionPoints": 3, "maxActionPoints": 4,
		},
	}

	# Act
	var ok: bool = mgr.save_run(_HERO_RT, data)

	# Assert — 返回值为 true
	assert_bool(ok).is_true()
	# Assert — 文件确实写入磁盘
	assert_bool(FileAccess.file_exists(_save_path(_HERO_RT))).is_true()
	# Assert — 文件内容为合法 JSON（parse_string 不返回 null）
	var file := FileAccess.open(_save_path(_HERO_RT), FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	assert_object(JSON.parse_string(content)).is_not_null()


# ============================================================
# AC2 — 完整 round-trip：save → 磁盘 → load，数据与写入前完全一致
# ============================================================

## 验证包含 resources / campaignDeck / equipment / map 的完整状态
## 经由真实文件 I/O 保存再读回后，所有字段值与写入前一致；
## 同时验证 battleState 在 load 后为 null（崩溃恢复语义）
func test_run_restore_round_trip_with_real_writer() -> void:
	# Arrange
	var r: Array = _make_real_manager()
	var mgr: RunSaveManager = r[0]
	var data: Dictionary = {
		"resources": {
			"hp": 45,
			"maxHp": 60,
			"provisions": 120,
			"gold": 500,
			"actionPoints": 3,
			"maxActionPoints": 4,
		},
		"campaignDeck": {
			"version": 1,
			"cards": {"card_001": 2, "card_002": 1},
		},
		"equipment": [
			{"id": "EQ001", "slot": "weapon"},
			{"id": "EQ002", "slot": "armor"},
		],
		"map": {
			"campaignId": "c1",
			"currentMap": 2,
			"currentNode": 7,
			"mapStructure": {},
			"visitedNodes": [1, 3, 5],
		},
		"battleState": {"enemyId": "enemy_boss", "turn": 2},
	}

	# Act
	var ok: bool = mgr.save_run(_HERO_RT, data)
	var loaded: Dictionary = mgr.load_run(_HERO_RT)

	# Assert — 写入成功
	assert_bool(ok).is_true()
	# Assert — resources 字段完全一致
	assert_int(loaded["resources"]["hp"]).is_equal(45)
	assert_int(loaded["resources"]["maxHp"]).is_equal(60)
	assert_int(loaded["resources"]["provisions"]).is_equal(120)
	assert_int(loaded["resources"]["gold"]).is_equal(500)
	# Assert — campaignDeck 一致
	assert_int(loaded["campaignDeck"]["cards"]["card_001"]).is_equal(2)
	assert_int(loaded["campaignDeck"]["cards"]["card_002"]).is_equal(1)
	# Assert — equipment 数量及 ID 一致
	assert_int(loaded["equipment"].size()).is_equal(2)
	assert_str(loaded["equipment"][0]["id"]).is_equal("EQ001")
	# Assert — map currentNode 一致
	assert_int(loaded["map"]["currentNode"]).is_equal(7)
	assert_int(loaded["map"]["currentMap"]).is_equal(2)
	# Assert — battleState 在 load 后为 null（RunSaveManager 崩溃恢复语义）
	assert_object(loaded["battleState"]).is_null()


# ============================================================
# AC3 — 原子性保证：rename 失败时目标文件不存在（不产生损坏文件）
# ============================================================

## 注入 _rename_callable 返回 ERR_FILE_NO_PERMISSION，模拟 rename 失败；
## 验证 write_atomic 返回 false，且目标文件不存在（写失败不产生损坏文件）。
## 本测试直接操作 AtomicSaveWriter，不经过 RunSaveManager。
func test_atomic_write_survives_interrupted_write() -> void:
	# Arrange
	var writer := AtomicSaveWriter.new()
	writer._rename_callable = func(_src: String, _dst: String) -> int:
		return ERR_FILE_NO_PERMISSION
	var path: String = _save_path(_HERO_RT)
	var data: Dictionary = {"resources": {"hp": 10}}

	# Act
	var ok: bool = writer.write_atomic(path, data)

	# Assert — write_atomic 返回 false
	assert_bool(ok).is_false()
	# Assert — 目标文件不存在（原子性：要么成功替换，要么目标文件不变）
	assert_bool(FileAccess.file_exists(path)).is_false()


# ============================================================
# AC4 — 两个武将的存档互不碰撞
# ============================================================

## 分别为 cao_cao_e2e 和 liu_bei_e2e 写入不同的 HP / gold 值；
## 验证各自 load_run 读回的数据互不影响，且两个 JSON 文件均存在于磁盘
func test_two_heroes_saves_do_not_collide() -> void:
	# Arrange
	var r: Array = _make_real_manager()
	var mgr: RunSaveManager = r[0]
	var cao_data: Dictionary = {
		"resources": {
			"hp": 40, "maxHp": 50, "provisions": 100,
			"gold": 300, "actionPoints": 3, "maxActionPoints": 4,
		},
	}
	var liu_data: Dictionary = {
		"resources": {
			"hp": 25, "maxHp": 40, "provisions": 60,
			"gold": 150, "actionPoints": 2, "maxActionPoints": 3,
		},
	}

	# Act
	var ok_cao: bool = mgr.save_run(_HERO_CAO, cao_data)
	var ok_liu: bool = mgr.save_run(_HERO_LIU, liu_data)
	var loaded_cao: Dictionary = mgr.load_run(_HERO_CAO)
	var loaded_liu: Dictionary = mgr.load_run(_HERO_LIU)

	# Assert — 两次写入均成功
	assert_bool(ok_cao).is_true()
	assert_bool(ok_liu).is_true()
	# Assert — 两个存档文件均存在于磁盘
	assert_bool(FileAccess.file_exists(_save_path(_HERO_CAO))).is_true()
	assert_bool(FileAccess.file_exists(_save_path(_HERO_LIU))).is_true()
	# Assert — 曹操存档数据正确
	assert_int(loaded_cao["resources"]["hp"]).is_equal(40)
	assert_int(loaded_cao["resources"]["gold"]).is_equal(300)
	assert_str(loaded_cao["heroId"]).is_equal(_HERO_CAO)
	# Assert — 刘备存档数据正确，与曹操互不影响
	assert_int(loaded_liu["resources"]["hp"]).is_equal(25)
	assert_int(loaded_liu["resources"]["gold"]).is_equal(150)
	assert_str(loaded_liu["heroId"]).is_equal(_HERO_LIU)


# ============================================================
# AC5 — 版本兼容：minor 升级时补全缺失字段
# ============================================================

## 手动写入一个版本为 "1.0.0" 且缺少 "triggeredEvents" 字段的存档；
## 注入 default_fields_provider 提供缺失字段的默认值；
## 验证 read_json 返回包含 "triggeredEvents" 的字典（minor 升级补全成功）
func test_version_compat_minor_bump() -> void:
	# Arrange — 手动写入缺少 triggeredEvents 字段的旧格式存档
	var path: String = _save_path(_HERO_COMPAT)
	var old_data: Dictionary = {
		"version": "1.0.0",
		"heroId": _HERO_COMPAT,
		"resources": {
			"hp": 20, "maxHp": 50, "provisions": 50,
			"gold": 100, "actionPoints": 2, "maxActionPoints": 4,
		},
		# 故意不写 triggeredEvents 字段
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_data))
	file.close()

	# 注入 default_fields_provider，提供 triggeredEvents 的默认值
	var writer := AtomicSaveWriter.new()
	writer.default_fields_provider = func() -> Dictionary:
		return {"triggeredEvents": []}

	# Act
	var loaded: Dictionary = writer.read_json(path)

	# Assert — 返回字典不为空
	assert_bool(loaded.is_empty()).is_false()
	# Assert — triggeredEvents 字段已被补全（minor 升级兼容规则）
	assert_bool(loaded.has("triggeredEvents")).is_true()
	assert_int((loaded["triggeredEvents"] as Array).size()).is_equal(0)
	# Assert — 原有字段未被破坏
	assert_int(loaded["resources"]["hp"]).is_equal(20)


# ============================================================
# AC6 — 损坏 JSON 返回空字典，不崩溃，触发 file_corrupted 信号
# ============================================================

## 手动写入非法 JSON 内容；验证 read_json 返回空字典，
## file_corrupted 信号被触发，且整个过程不抛异常、不崩溃
func test_corrupted_json_returns_empty_data_no_crash() -> void:
	# Arrange — 写入非法 JSON
	var path: String = _save_path(_HERO_CORRUPT)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not_valid_json {{{{")
	file.close()

	var writer := AtomicSaveWriter.new()
	# 用布尔标志捕获信号，避免 GdUnit4 版本差异
	var corrupted_fired: bool = false
	writer.file_corrupted.connect(func(_p: String) -> void:
		corrupted_fired = true
	)

	# Act
	var result: Dictionary = writer.read_json(path)

	# Assert — 返回空字典
	assert_bool(result.is_empty()).is_true()
	# Assert — file_corrupted 信号已触发
	assert_bool(corrupted_fired).is_true()


# ============================================================
# AC7 — 性能守护：load_run 时间 < 5ms
# ============================================================

## 使用真实 AtomicSaveWriter 接线的 mgr，执行一次完整的 save_run + load_run；
## 断言 load_run 耗时 < 5000 微秒（Control Manifest 性能守护）
func test_run_save_load_under_5ms() -> void:
	# Arrange
	var r: Array = _make_real_manager()
	var mgr: RunSaveManager = r[0]
	var data: Dictionary = {
		"resources": {
			"hp": 50, "maxHp": 50, "provisions": 100,
			"gold": 200, "actionPoints": 4, "maxActionPoints": 4,
		},
		"campaignDeck": {"version": 1, "cards": {"card_001": 3}},
		"equipment": [],
		"map": {
			"campaignId": "c1", "currentMap": 1, "currentNode": 3,
			"mapStructure": {}, "visitedNodes": [1, 2],
		},
		"battleState": null,
	}
	# 预先写入文件，性能测试仅对 load 计时（排除写入开销干扰）
	mgr.save_run(_HERO_PERF, data)

	# Act — 仅对 load_run 计时
	var t_start: int = Time.get_ticks_usec()
	var loaded: Dictionary = mgr.load_run(_HERO_PERF)
	var elapsed_us: int = Time.get_ticks_usec() - t_start

	# Assert — load 结果有效（非空）
	assert_bool(loaded.is_empty()).is_false()
	# Assert — load 耗时 < 5000 微秒（= 5ms，Control Manifest 性能守护）
	assert_int(elapsed_us).is_less(5000)
