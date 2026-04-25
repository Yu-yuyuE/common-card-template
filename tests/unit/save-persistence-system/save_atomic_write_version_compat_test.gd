## save_atomic_write_version_compat_test.gd
## AtomicSaveWriter 原子写入与版本兼容单元测试（Story 7-7）
##
## 覆盖验收标准：
##   AC1 — 原子写入（先写 .tmp，成功后 rename）
##   AC2 — minor 版本升级后旧存档可正常读取，缺失字段填默认值
##   AC3 — major 版本不兼容时返回 {} 并发出 version_incompatible 信号
##   AC4 — 存档损坏时返回 {} 并发出 file_corrupted 信号，不崩溃
##
## 运行方式：GdUnit4（--headless）
extends GdUnitTestSuite


# ============================================================
# 常量
# ============================================================

## 测试用临时目录（user:// 路径，headless VFS 可用）
const TEST_DIR: String = "user://saves/test_atomic/"
const TEST_PATH: String = TEST_DIR + "test_save.json"
const TEST_TMP_PATH: String = TEST_PATH + ".tmp"


# ============================================================
# 测试夹具
# ============================================================

var _writer: AtomicSaveWriter


# ============================================================
# 生命周期
# ============================================================

func before_test() -> void:
	_writer = AtomicSaveWriter.new()
	_writer.current_version = "1.0.0"
	_writer.default_fields_provider = func() -> Dictionary:
		return {
			"version": "1.0.0",
			"heroId": "",
			"hp": 100,
			"pendingWeather": "none",
		}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIR))


func after_test() -> void:
	_cleanup_file(TEST_PATH)
	_cleanup_file(TEST_TMP_PATH)
	_writer = null


# ============================================================
# 辅助方法
# ============================================================

## 删除文件（若存在）
func _cleanup_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## 直接写入原始字符串（绕过原子逻辑，用于构造测试数据）
func _write_raw(path: String, content: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIR))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("_write_raw: 无法写入 %s" % path)
		return
	f.store_string(content)
	f.close()


# ============================================================
# AC1：原子写入
# ============================================================

## 写入成功时返回 true，目标文件存在，临时文件已被清除
func test_write_atomic_creates_temp_then_renames() -> void:
	var data := {"version": "1.0.0", "hp": 50}

	var result: bool = _writer.write_atomic(TEST_PATH, data)

	assert_bool(result).is_true()
	assert_bool(FileAccess.file_exists(TEST_PATH)).is_true()
	assert_bool(FileAccess.file_exists(TEST_TMP_PATH)).is_false()


## rename 失败时原文件不变，write_atomic 返回 false
func test_write_atomic_preserves_original_on_failure() -> void:
	var original_content: String = '{"version":"1.0.0","hp":99}'
	_write_raw(TEST_PATH, original_content)

	var writer_fail := AtomicSaveWriter.new()
	writer_fail.current_version = "1.0.0"
	writer_fail._rename_callable = func(_from: String, _to: String) -> int:
		return ERR_CANT_CREATE

	var result: bool = writer_fail.write_atomic(TEST_PATH, {"version": "1.0.0", "hp": 1})

	assert_bool(result).is_false()

	var f := FileAccess.open(TEST_PATH, FileAccess.READ)
	assert_not_null(f)
	var content: String = f.get_as_text()
	f.close()
	assert_str(content).is_equal(original_content)


# ============================================================
# AC2：minor 版本升级
# ============================================================

## minor 升级时缺失字段被填入默认值
func test_read_json_fills_missing_fields_on_minor_upgrade() -> void:
	var old_data := {"version": "1.0.0", "heroId": "hero_01", "hp": 80}
	_write_raw(TEST_PATH, JSON.stringify(old_data))
	_writer.current_version = "1.1.0"

	var result := _writer.read_json(TEST_PATH)

	assert_int(int(result.get("hp", -1))).is_equal(80)
	assert_str(str(result.get("heroId", ""))).is_equal("hero_01")
	assert_str(str(result.get("pendingWeather", "MISSING"))).is_equal("none")


## 已有字段不被默认值覆盖
func test_read_json_existing_fields_not_overwritten_on_minor_upgrade() -> void:
	var data := {"version": "1.0.0", "heroId": "hero_02", "hp": 60, "pendingWeather": "rain"}
	_write_raw(TEST_PATH, JSON.stringify(data))
	_writer.current_version = "1.1.0"

	var result := _writer.read_json(TEST_PATH)

	assert_str(str(result.get("pendingWeather", ""))).is_equal("rain")


# ============================================================
# AC3：major 版本不兼容
# ============================================================

## major 不兼容时返回空字典
func test_read_json_returns_empty_on_major_version_mismatch() -> void:
	_write_raw(TEST_PATH, '{"version":"1.0.0","hp":50}')
	_writer.current_version = "2.0.0"

	var result := _writer.read_json(TEST_PATH)

	assert_dict(result).is_empty()


## major 不兼容时发出 version_incompatible 信号
func test_read_json_emits_version_incompatible_signal() -> void:
	_write_raw(TEST_PATH, '{"version":"1.0.0","hp":50}')
	_writer.current_version = "2.0.0"

	var signal_emitted: bool = false
	var captured_version: String = ""
	_writer.version_incompatible.connect(
		func(_p: String, v: String) -> void:
			signal_emitted = true
			captured_version = v
	)

	_writer.read_json(TEST_PATH)

	assert_bool(signal_emitted).is_true()
	assert_str(captured_version).is_equal("1.0.0")


# ============================================================
# AC4：存档损坏
# ============================================================

## 损坏 JSON 时返回空字典
func test_read_json_returns_empty_on_corrupt_file() -> void:
	_write_raw(TEST_PATH, "{ this is not valid json !!!")

	var result := _writer.read_json(TEST_PATH)

	assert_dict(result).is_empty()


## 损坏文件时发出 file_corrupted 信号
func test_read_json_emits_file_corrupted_signal() -> void:
	_write_raw(TEST_PATH, "not json at all")

	var signal_emitted: bool = false
	_writer.file_corrupted.connect(
		func(_p: String) -> void:
			signal_emitted = true
	)

	_writer.read_json(TEST_PATH)

	assert_bool(signal_emitted).is_true()


## 顶层是数组（非 Dictionary）时触发 corrupt 信号且返回 {}
func test_read_json_returns_empty_on_non_dict_json() -> void:
	_write_raw(TEST_PATH, "[1, 2, 3]")

	var signal_emitted: bool = false
	_writer.file_corrupted.connect(func(_p: String) -> void: signal_emitted = true)

	var result := _writer.read_json(TEST_PATH)

	assert_dict(result).is_empty()
	assert_bool(signal_emitted).is_true()


## 函数正常返回，不抛异常
func test_read_json_does_not_crash_on_corrupt_file() -> void:
	_write_raw(TEST_PATH, "{{{{invalid}}")

	var result := _writer.read_json(TEST_PATH)

	assert_bool(result is Dictionary).is_true()


# ============================================================
# 边界：文件不存在
# ============================================================

## 文件不存在时返回空字典，不报错
func test_read_json_returns_empty_when_file_not_exists() -> void:
	_cleanup_file(TEST_PATH)

	var result := _writer.read_json(TEST_PATH)

	assert_dict(result).is_empty()
