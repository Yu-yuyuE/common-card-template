## RunSaveManager — Run Save 序列化与反序列化管理器
##
## 负责将战役运行状态序列化为字典并恢复，支持多武将独立存档。
## 不依赖 FileAccess（通过注入桩隔离）；不依赖任何全局单例。
##
## 职责边界：
##   - 序列化 run data 字典（含 resources/deck/equipment/map/battleState）
##   - 版本戳注入（version / timestamp 字段）
##   - 存档键校验：缺失字段填默认值，不抛异常
##   - 通过 save_stub / load_stub 与实际存储层解耦
##
## Out of Scope（本类不实现）：
##   - FileAccess 文件 I/O（由 Story 005 的 AtomicFileWriter 负责）
##   - Meta Save（由 Story 003/004 负责）
##   - 战役结束删除存档（由 Story 002 负责）
##
## 使用示例（生产环境）：
##   var mgr := RunSaveManager.new()
##   mgr.save_stub = func(hero_id, data): return SaveManager.save_run(hero_id, data)
##   mgr.load_stub = func(hero_id): return SaveManager.load_run(hero_id)
##
## 使用示例（测试环境）：
##   var store: Dictionary = {}
##   mgr.save_stub = func(hero_id, data): store[hero_id] = data; return true
##   mgr.load_stub = func(hero_id): return store.get(hero_id, {})
##
## ADR 对齐：ADR-0005（存档序列化）
class_name RunSaveManager extends RefCounted

# ============================================================
# 常量
# ============================================================

## 当前存档版本号
const CURRENT_VERSION: String = "1.0.0"

# ============================================================
# 依赖注入桩
# ============================================================

## 写入存档的回调；签名：func(hero_id: String, data: Dictionary) -> bool
## 默认 no-op，返回 true
var save_stub: Callable = func(_hero_id: String, _data: Dictionary) -> bool:
	return true

## 读取存档的回调；签名：func(hero_id: String) -> Dictionary
## 默认返回空字典（视为无存档）
var load_stub: Callable = func(_hero_id: String) -> Dictionary:
	return {}

## 检查存档是否存在的回调；签名：func(hero_id: String) -> bool
## 默认返回 false
var has_save_stub: Callable = func(_hero_id: String) -> bool:
	return false

## 删除存档的回调；签名：func(hero_id: String) -> bool
## 默认 no-op，返回 false（视为无文件可删）
var delete_run_stub: Callable = func(_hero_id: String) -> bool:
	return false

# ============================================================
# 公开接口
# ============================================================

## 保存 Run Save。
## 注入 version / heroId / timestamp；若 battleState 非 null 则强制置 null（崩溃恢复语义）。
## 随后调用 save_stub 写入存储层。
## [br][param hero_id] 武将唯一 ID（对应存档文件 run_{heroId}.json）
## [br][param data] 当前游戏状态字典
## [br][return] save_stub 返回值；stub 出错时返回 false
func save_run(hero_id: String, data: Dictionary) -> bool:
	var payload: Dictionary = data.duplicate(true)

	# 注入版本戳
	payload["version"] = CURRENT_VERSION
	payload["heroId"] = hero_id
	payload["timestamp"] = Time.get_unix_time_from_system()

	# AC2：战斗崩溃恢复 — 存档时清除战斗中间状态，恢复到战斗开始前
	if payload.get("battleState") != null:
		payload["battleState"] = null

	return save_stub.call(hero_id, payload)


## 加载 Run Save。
## 调用 load_stub；若返回空字典则直接返回 {}（无存档，不报错）。
## 否则补全所有缺失字段后返回完整字典。
## [br][param hero_id] 武将唯一 ID
## [br][return] 完整存档字典，或 {} 表示无存档
func load_run(hero_id: String) -> Dictionary:
	var raw: Dictionary = load_stub.call(hero_id)
	if raw.is_empty():
		return {}
	return _fill_missing_fields(raw, hero_id)


## 检查指定武将是否存在 Run Save。
## [br][param hero_id] 武将唯一 ID
func has_run_save(hero_id: String) -> bool:
	return has_save_stub.call(hero_id)


## 战役结束后删除 Run Save（胜利或死亡均调用）。
## 调用 delete_run_stub 执行实际删除；若存档不存在或删除失败，返回 false 但不抛异常。
## [br][param hero_id] 武将唯一 ID
## [br][return] true 表示成功删除，false 表示不存在或删除失败
func delete_run(hero_id: String) -> bool:
	return delete_run_stub.call(hero_id)

# ============================================================
# 私有辅助
# ============================================================

## 构建默认 run data 骨架（全零/空值，不含真实游戏状态）。
## [br][param hero_id] 武将唯一 ID
func _build_default_run_data(hero_id: String) -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"heroId": hero_id,
		"timestamp": 0,
		"resources": {
			"hp": 0,
			"maxHp": 0,
			"provisions": 0,
			"gold": 0,
			"actionPoints": 0,
			"maxActionPoints": 0,
		},
		"campaignDeck": {
			"version": 1,
			"cards": {},
		},
		"hero": {"id": hero_id, "level": 1},
		"equipment": [],
		"map": {
			"campaignId": "",
			"currentMap": 0,
			"currentNode": 0,
			"mapStructure": {},
			"visitedNodes": [],
		},
		"battleState": null,
		"triggeredEvents": [],
		"campaignEnded": false,
	}


## 确保 data 包含所有必要键；缺失字段从默认骨架填入，不覆盖已有字段。
## [br][param data] 原始存档字典
## [br][param hero_id] 武将唯一 ID（用于构建默认骨架）
func _fill_missing_fields(data: Dictionary, hero_id: String) -> Dictionary:
	var defaults: Dictionary = _build_default_run_data(hero_id)
	var result: Dictionary = data.duplicate(true)
	for key: String in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key]
	return result
