## AtomicSaveWriter — 原子写入与版本兼容 JSON 存档工具类
##
## 负责将字典以原子方式写入 JSON 文件，并在读取时做版本兼容处理。
## 写入流程：先写 .tmp 临时文件 → rename() 原子替换 → 失败时保留原文件
## 读取流程：解析 JSON → 检查 major 版本兼容 → minor 升级时填默认值 → 损坏时返回 {}
##
## 与 RunSaveManager 的关系：
##   AtomicSaveWriter 是纯 I/O 层工具，可作为 RunSaveManager.save_stub/load_stub 的实际实现注入。
##   Story 7-7 仅实现此工具类；RunSaveManager 的桩替换在生产集成时进行（Out of Scope）。
##
## 使用示例（生产环境）：
##   var writer := AtomicSaveWriter.new()
##   var mgr := RunSaveManager.new()
##   mgr.save_stub = func(hero_id, data): return writer.write_atomic("user://saves/run_%s.json" % hero_id, data)
##   mgr.load_stub = func(hero_id): return writer.read_json("user://saves/run_%s.json" % hero_id)
##
## 使用示例（测试故障路径）：
##   writer._rename_callable = func(_src, _dst): return ERR_FILE_NO_PERMISSION
##
## ADR 对齐：ADR-0005（存档序列化）
class_name AtomicSaveWriter extends RefCounted

# ============================================================
# 常量
# ============================================================

## 当前存档格式版本号；与 RunSaveManager.CURRENT_VERSION 保持一致
const CURRENT_VERSION: String = "1.0.0"

# ============================================================
# 信号
# ============================================================

## 当 JSON 文件无法解析（内容损坏或格式错误）时触发
## [br][param path] 损坏文件的路径
signal file_corrupted(path: String)

## 当存档 major 版本与当前版本不兼容时触发
## [br][param path] 存档文件路径
## [br][param saved_version] 存档中记录的版本号字符串
signal version_incompatible(path: String, saved_version: String)

# ============================================================
# 可配置属性
# ============================================================

## 当前版本号（可覆盖以支持测试不同版本场景）；默认与 CURRENT_VERSION 一致
var current_version: String = CURRENT_VERSION

## 返回字段默认值字典的回调；签名：func() -> Dictionary
## 读取时用于补全 minor 升级导致的缺失字段。
## 默认返回空字典（不补任何字段）。
var default_fields_provider: Callable = func() -> Dictionary:
	return {}

# ============================================================
# 故障注入桩（仅用于测试；生产代码不替换）
# ============================================================

## rename 回调；签名：func(from: String, to: String) -> int（Error 枚举）
## 默认使用 DirAccess.rename_absolute()。
## 测试可替换此桩来模拟 rename 失败。
var _rename_callable: Callable = func(from: String, to: String) -> int:
	return DirAccess.rename_absolute(from, to)

# ============================================================
# 公开接口
# ============================================================

## 原子写入：将 data 序列化为格式化 JSON，先写 [path].tmp，成功后 rename 替换目标路径。
## 若 rename 失败，临时文件保留（原文件完全不受影响）。
## [br][param path] 目标存档路径（如 "user://saves/run_cao_cao.json"）
## [br][param data] 要写入的字典数据
## [br][return] true 表示写入并替换成功；false 表示失败
func write_atomic(path: String, data: Dictionary) -> bool:
	var temp_path: String = path + ".tmp"

	# 写入临时文件
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		push_error("AtomicSaveWriter: 无法创建临时文件 %s，错误码：%d" % [
			temp_path, FileAccess.get_open_error()
		])
		return false

	temp_file.store_string(JSON.stringify(data, "\t"))
	temp_file.close()

	# 原子替换：rename .tmp → 目标路径
	var err: int = _rename_callable.call(temp_path, path)
	if err != OK:
		push_error("AtomicSaveWriter: rename 失败，错误码：%d，from=%s，to=%s" % [
			err, temp_path, path
		])
		return false

	return true


## 读取 JSON 文件并做版本兼容处理。
## - 文件不存在 → 返回 {}（视为无存档，不报错）
## - 读取或解析失败 → 返回 {}，发出 file_corrupted 信号
## - major 版本不兼容 → 返回 {}，发出 version_incompatible 信号
## - minor/patch 版本升级 → 补全缺失字段后返回完整字典
## [br][param path] 存档文件路径
## [br][return] 兼容处理后的字典；{} 表示无有效数据
func read_json(path: String) -> Dictionary:
	# 文件不存在 → 正常返回空字典（无存档）
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("AtomicSaveWriter: 无法打开文件 %s，错误码：%d" % [
			path, FileAccess.get_open_error()
		])
		file_corrupted.emit(path)
		return {}

	var content: String = file.get_as_text()
	file.close()

	# 解析 JSON
	var json := JSON.new()
	var parse_err: int = json.parse(content)
	if parse_err != OK:
		push_error("AtomicSaveWriter: JSON 解析失败，文件：%s，行：%d，原因：%s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		file_corrupted.emit(path)
		return {}

	var parsed = json.get_data()
	if not parsed is Dictionary:
		push_error("AtomicSaveWriter: 文件顶层不是 Dictionary：%s" % path)
		file_corrupted.emit(path)
		return {}

	# 版本兼容检查与字段补全
	return _migrate_if_needed(path, parsed as Dictionary)

# ============================================================
# 私有辅助
# ============================================================

## 版本兼容迁移：
##   major 不同 → 发出 version_incompatible 并返回 {}
##   minor/patch 不同 → 补全缺失字段后返回
## [br][param path] 文件路径（用于信号参数）
## [br][param data] 已解析的存档字典
func _migrate_if_needed(path: String, data: Dictionary) -> Dictionary:
	var saved_version: String = data.get("version", "1.0.0")
	var saved_major: int = _parse_major(saved_version)
	var current_major: int = _parse_major(current_version)

	if saved_major != current_major:
		push_error("AtomicSaveWriter: 版本不兼容，存档=%s，当前=%s，文件=%s" % [
			saved_version, current_version, path
		])
		version_incompatible.emit(path, saved_version)
		return {}

	# minor/patch 升级：补全缺失字段
	var defaults: Dictionary = default_fields_provider.call()
	var result: Dictionary = data.duplicate(true)
	for key: String in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key]
	return result


## 从版本字符串解析 major 数值（如 "2.1.0" → 2）。
## 格式不合法时返回 0。
## [br][param version] 版本字符串（"major.minor.patch"）
func _parse_major(version: String) -> int:
	var parts: PackedStringArray = version.split(".")
	if parts.size() == 0:
		return 0
	return parts[0].to_int()
