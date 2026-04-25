## MetaSaveManager — Meta Save 解锁与发现记录管理器
##
## 负责管理持久化的 Meta Save 数据，包括：
##   - 已解锁卡牌（按类别分组）
##   - 已解锁装备
##   - 事件图鉴发现记录
##   - 装备图鉴发现记录
##
## 所有写入操作均为幂等：同一 ID 多次解锁/发现，只记录一次。
## 内部维护缓存字典 _meta_cache，避免频繁 I/O。
## 通过注入 save_stub / load_stub / has_save_stub 与存储层完全解耦。
##
## 职责边界：
##   - 仅管理 Meta Save 逻辑（解锁/发现/默认骨架）
##   - 不负责文件 I/O（由注入的 save_stub/load_stub 实现）
##   - 不管理 Run Save（RunSaveManager 负责）
##
## 使用示例（生产环境）：
##   var writer := AtomicSaveWriter.new()
##   var mgr := MetaSaveManager.new()
##   mgr.save_stub = func(data): return writer.write_atomic("user://saves/meta.json", data)
##   mgr.load_stub = func(): return writer.read_json("user://saves/meta.json")
##   mgr.has_save_stub = func(): return FileAccess.file_exists("user://saves/meta.json")
##
## 使用示例（测试环境）：
##   var store_ref: Array = [{}]
##   mgr.save_stub = func(data): store_ref[0] = data; return true
##   mgr.load_stub = func(): return store_ref[0].duplicate(true)
##   mgr.has_save_stub = func(): return not store_ref[0].is_empty()
##
## ADR 对齐：ADR-0005（存档序列化）
class_name MetaSaveManager extends RefCounted

# ============================================================
# 常量
# ============================================================

## 当前 Meta Save 格式版本号
const CURRENT_VERSION: String = "1.0.0"

## 有效卡牌类别列表
const VALID_CARD_CATEGORIES: Array[String] = ["attack", "skill", "troop", "curse"]

# ============================================================
# 依赖注入桩
# ============================================================

## 写入 Meta Save 的回调；签名：func(data: Dictionary) -> bool
## 默认 no-op，返回 true
var save_stub: Callable = func(_data: Dictionary) -> bool:
	return true

## 读取 Meta Save 的回调；签名：func() -> Dictionary
## 默认返回空字典（视为无存档）
var load_stub: Callable = func() -> Dictionary:
	return {}

## 检查 Meta Save 是否存在的回调；签名：func() -> bool
## 默认返回 false
var has_save_stub: Callable = func() -> bool:
	return false

# ============================================================
# 内部缓存
# ============================================================

## 内存缓存；首次调用 load_meta() 时填充，每次写入后同步更新
var _meta_cache: Dictionary = {}

## 标记缓存是否已从存储层加载（避免空字典和"未加载"的歧义）
var _cache_loaded: bool = false

# ============================================================
# 公开接口
# ============================================================

## 解锁指定卡牌，写入 unlockedCards[card_category]。
## 操作为幂等：同一 card_id 多次调用只记录一次。
## card_category 必须是 ["attack", "skill", "troop", "curse"] 之一，否则返回 false。
## [br][param card_id] 卡牌唯一 ID（如 "AC0001"）
## [br][param card_category] 卡牌类别（"attack" / "skill" / "troop" / "curse"）
## [br][return] true 表示写入成功；false 表示类别无效或 save_stub 失败
func unlock_card(card_id: String, card_category: String) -> bool:
	if not card_category in VALID_CARD_CATEGORIES:
		push_error("MetaSaveManager: 无效的卡牌类别 '%s'，合法值：%s" % [
			card_category, VALID_CARD_CATEGORIES
		])
		return false

	var meta: Dictionary = _ensure_cache()
	var category_list: Array = meta["unlockedCards"][card_category]

	# 幂等：已存在则跳过
	if card_id in category_list:
		return true

	category_list.append(card_id)
	return _persist(meta)


## 解锁指定装备，写入 unlockedEquipment。
## 操作为幂等：同一 equip_id 多次调用只记录一次。
## [br][param equip_id] 装备唯一 ID（如 "EQ001"）
## [br][return] true 表示写入成功；false 表示 save_stub 失败
func unlock_equipment(equip_id: String) -> bool:
	var meta: Dictionary = _ensure_cache()
	var list: Array = meta["unlockedEquipment"]

	if equip_id in list:
		return true

	list.append(equip_id)
	return _persist(meta)


## 记录事件图鉴发现，写入 discoveredEvents。
## 操作为幂等：同一 event_id 多次调用只记录一次。
## 即使战役失败，本记录也不会回滚（Meta Save 永久保留）。
## [br][param event_id] 事件唯一 ID（如 "EV010"）
## [br][return] true 表示写入成功；false 表示 save_stub 失败
func discover_event(event_id: String) -> bool:
	var meta: Dictionary = _ensure_cache()
	var list: Array = meta["discoveredEvents"]

	if event_id in list:
		return true

	list.append(event_id)
	return _persist(meta)


## 记录装备图鉴发现，写入 discoveredEquipment。
## 操作为幂等：同一 equip_id 多次调用只记录一次。
## [br][param equip_id] 装备唯一 ID（如 "EQ001"）
## [br][return] true 表示写入成功；false 表示 save_stub 失败
func discover_equipment(equip_id: String) -> bool:
	var meta: Dictionary = _ensure_cache()
	var list: Array = meta["discoveredEquipment"]

	if equip_id in list:
		return true

	list.append(equip_id)
	return _persist(meta)


## 加载 Meta Save。
## 优先返回内存缓存；若缓存未初始化则调用 load_stub。
## load_stub 返回空字典时，返回完整默认骨架（不写入存储层）。
## [br][return] 完整 Meta Save 字典（含所有必要字段）
func load_meta() -> Dictionary:
	return _ensure_cache()


## 检查 Meta Save 是否已存在于存储层。
## [br][return] true 表示存储层已有 Meta Save 文件
func has_meta_save() -> bool:
	return has_save_stub.call()

# ============================================================
# 私有辅助
# ============================================================

## 确保缓存已初始化：首次调用时从 load_stub 加载，空时填充默认骨架。
## [br][return] 完整的内存缓存字典（引用，修改直接反映到缓存）
func _ensure_cache() -> Dictionary:
	if _cache_loaded:
		return _meta_cache

	var raw: Dictionary = load_stub.call()
	if raw.is_empty():
		_meta_cache = _build_default_meta()
	else:
		_meta_cache = _fill_missing_fields(raw)

	_cache_loaded = true
	return _meta_cache


## 将缓存写入存储层（调用 save_stub），注入时间戳后持久化。
## [br][param meta] 要持久化的 Meta Save 字典（已含所有修改）
## [br][return] save_stub 返回值
func _persist(meta: Dictionary) -> bool:
	meta["timestamp"] = int(Time.get_unix_time_from_system())
	return save_stub.call(meta)


## 构建完整默认 Meta Save 骨架（所有字段均为初始空值）。
## [br][return] 含 version / timestamp / 所有集合字段的默认字典
func _build_default_meta() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"timestamp": 0,
		"unlockedHeroes": [],
		"unlockedCards": {
			"attack": [],
			"skill":  [],
			"troop":  [],
			"curse":  [],
		},
		"unlockedEquipment": [],
		"heroRecords": {},
		"settings": {
			"masterVolume": 1.0,
			"musicVolume":  1.0,
			"sfxVolume":    1.0,
			"fullscreen":   false,
		},
		"statistics": {
			"totalRuns":      0,
			"totalVictories": 0,
		},
		"discoveredEvents":    [],
		"discoveredEquipment": [],
	}


## 补全 raw 中缺失的顶层字段（不覆盖已有值）。
## 用于 minor/patch 版本升级时向前兼容。
## [br][param raw] 从存储层读取的原始字典
## [br][return] 补全缺失字段后的完整字典
func _fill_missing_fields(raw: Dictionary) -> Dictionary:
	var defaults: Dictionary = _build_default_meta()
	var result: Dictionary = raw.duplicate(true)
	for key: String in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key]
	return result
