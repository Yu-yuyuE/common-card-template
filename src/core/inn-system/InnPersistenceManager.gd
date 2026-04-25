## InnPersistenceManager — 酒馆节点状态持久化管理器
##
## 负责将酒馆访问状态（歇息/强化使用标记）序列化为字典，
## 并从字典反序列化恢复。不依赖任何全局单例（依赖注入友好）。
##
## 职责边界：
##   - 维护 visited_nodes 内存字典：{node_id: {rest_used, fortify_used}}
##   - serialize() / deserialize() 供存档系统调用
##   - 通过注入桩（save_stub / load_stub）与外部存档系统解耦
##   - 存档为空或格式损坏时降级：重置为空状态，返回 false
##
## 使用示例（生产环境）：
##   var mgr := InnPersistenceManager.new()
##   mgr.save_stub = func(data: Dictionary) -> void:
##       SaveManager.save_run_field("inn", data)
##
## 使用示例（测试环境）：
##   var store: Dictionary = {}
##   mgr.save_stub = func(data: Dictionary) -> void: store = data
##   mgr.load_stub = func() -> Dictionary: return store
##
## ADR 对齐：ADR-0005（存档序列化）
class_name InnPersistenceManager
extends RefCounted

# ============================================================
# 依赖注入桩
# ============================================================

## 写入存档的回调；签名：func(data: Dictionary) -> void
## 默认为空操作（no-op），测试时注入内存字典，生产时注入 SaveManager
var save_stub: Callable = func(_data: Dictionary) -> void:
	pass

## 读取存档的回调；签名：func() -> Dictionary
## 默认返回空字典（无存档），测试时注入内存字典
var load_stub: Callable = func() -> Dictionary:
	return {}

# ============================================================
# 内部状态
# ============================================================

## 节点访问记录：{node_id: {rest_used: bool, fortify_used: bool}}
var _visited_nodes: Dictionary = {}

# ============================================================
# 公开接口
# ============================================================

## 标记酒馆节点的服务使用状态，并通过 save_stub 持久化。
## [br][param node_id] 节点唯一标识
## [br][param rest_used] 歇息是否已使用
## [br][param fortify_used] 强化休整是否已使用
func mark_visited(node_id: String, rest_used: bool, fortify_used: bool) -> void:
	_visited_nodes[node_id] = {
		"rest_used": rest_used,
		"fortify_used": fortify_used
	}
	save_stub.call(serialize())


## 获取指定节点的访问状态。
## 若节点未曾访问，返回全 false 默认字典（不视为错误）。
## [br][param node_id] 节点唯一标识
## [br][return] {rest_used: bool, fortify_used: bool}
func get_node_state(node_id: String) -> Dictionary:
	return _visited_nodes.get(node_id, {
		"rest_used": false,
		"fortify_used": false
	})


## 将当前状态序列化为字典（供 SaveManager 持久化）。
## [br][return] {"visited_nodes": Dictionary}
func serialize() -> Dictionary:
	return {"visited_nodes": _visited_nodes.duplicate(true)}


## 从字典恢复状态（从存档加载时调用）。
## 若 data 为空、不含 visited_nodes 键、或 visited_nodes 非 Dictionary，
## 则将状态重置为空并返回 false（降级为"全部未访问"）。
## [br][param data] 由 serialize() 或存档系统产生的字典
## [br][return] true 表示成功恢复，false 表示降级（损坏/空数据）
func deserialize(data: Dictionary) -> bool:
	if data.is_empty():
		_visited_nodes = {}
		return false

	var nodes: Variant = data.get("visited_nodes")
	if nodes == null or not (nodes is Dictionary):
		_visited_nodes = {}
		return false

	_visited_nodes = nodes as Dictionary
	return true


## 从 load_stub 加载并应用存档状态（一次性便捷方法）。
## [br][return] true 表示成功加载，false 表示存档为空或损坏
func load_from_stub() -> bool:
	var raw: Dictionary = load_stub.call()
	return deserialize(raw)


## 清空所有节点访问记录（用于开始新战役）。
func reset() -> void:
	_visited_nodes.clear()
	save_stub.call(serialize())
