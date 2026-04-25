## CampaignManager — 战役流程管理器
##
## 负责跨地图、跨战役的进度推进，响应 Boss 击败事件，
## 发出战役完成与游戏通关信号，协调存档与新局初始化。
##
## 职责边界：
## - 维护当前战役索引与当前地图索引
## - 监听 Boss 击败信号，推进地图/战役
## - 提供存档与读档的序列化接口
## - 不依赖任何全局单例（依赖注入友好）
##
## 信号：
##   map_completed(campaign_index, map_index)  — 当前地图所有节点已通关
##   campaign_completed(campaign_index)         — 当前战役所有地图已通关
##   game_completed                             — 全部战役通关
##
## 使用示例：
##   var mgr := CampaignManager.new()
##   mgr.save_meta_stub   = func(k, v): meta[k] = v
##   mgr.clear_run_stub   = func(): meta.clear()
##   mgr.on_boss_defeated()

class_name CampaignManager extends Node

# ---------------------------------------------------------------------------
# 战役结构常量
# ---------------------------------------------------------------------------

## 每场战役包含的地图数量
const MAPS_PER_CAMPAIGN: int = 3

## 游戏总战役数量
const TOTAL_CAMPAIGNS: int = 5

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## 当前地图全部节点通关（含 Boss）时触发
## [br]campaign_index: 当前战役索引（0-based）
## [br]map_index: 已完成的地图索引（0-based）
signal map_completed(campaign_index: int, map_index: int)

## 当前战役所有地图通关时触发
## [br]campaign_index: 已完成的战役索引（0-based）
signal campaign_completed(campaign_index: int)

## 全部战役通关时触发（游戏通关）
signal game_completed

## 当前地图的所有节点均已完成（含非 Boss 节点）时触发
signal all_nodes_completed

# ---------------------------------------------------------------------------
# 状态
# ---------------------------------------------------------------------------

## 当前战役索引（0-based，范围 0 .. TOTAL_CAMPAIGNS-1）
var current_campaign_index: int = 0

## 当前地图索引（0-based，范围 0 .. MAPS_PER_CAMPAIGN-1）
var current_map_index: int = 0

# ---------------------------------------------------------------------------
# 依赖注入桩（用于测试时替换存档/清档行为）
# ---------------------------------------------------------------------------

## 写入元数据的回调；签名：func(key: String, value: Variant) -> void
## 默认实现使用 ProjectSettings.set_setting（可替换为存档系统）
var save_meta_stub: Callable = func(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(key, value)

## 清除本局运行数据的回调；签名：func() -> void
var clear_run_stub: Callable = func() -> void:
	pass

# ---------------------------------------------------------------------------
# 核心业务方法
# ---------------------------------------------------------------------------

## Boss 被击败时调用。
## 推进地图索引；若当前战役所有地图已完成则推进战役索引。
## 同时发出对应信号。
func on_boss_defeated() -> void:
	# 发出当前地图节点全部完成信号
	all_nodes_completed.emit()

	var finished_campaign: int = current_campaign_index
	var finished_map: int = current_map_index

	# 推进地图
	current_map_index += 1

	if current_map_index >= MAPS_PER_CAMPAIGN:
		# 当前战役所有地图已通关
		map_completed.emit(finished_campaign, finished_map)
		campaign_completed.emit(finished_campaign)

		current_map_index = 0
		current_campaign_index += 1

		if current_campaign_index >= TOTAL_CAMPAIGNS:
			# 全部战役通关
			game_completed.emit()
	else:
		map_completed.emit(finished_campaign, finished_map)


## 开始新战役（新局）。
## 重置进度并调用依赖桩以写入初始元数据与清除旧运行数据。
## [br]hero_id: 玩家选择的英雄 ID
func start_new_campaign(hero_id: String) -> void:
	current_campaign_index = 0
	current_map_index = 0

	# 写入元数据（存档系统桩）
	save_meta_stub.call("hero_id", hero_id)
	save_meta_stub.call("campaign_index", current_campaign_index)
	save_meta_stub.call("map_index", current_map_index)

	# 清除上局运行数据
	clear_run_stub.call()


## 将当前战役进度序列化为字典（供存档系统使用）。
## [br]返回包含 campaign_index 与 map_index 的字典。
func save_campaign_progress() -> Dictionary:
	return {
		"campaign_index": current_campaign_index,
		"map_index": current_map_index,
	}


## 从字典恢复战役进度（供读档系统使用）。
## [br]data: 由 save_campaign_progress() 产生的字典
## [br]返回 true 表示成功恢复，false 表示 data 为空或格式错误
func load_campaign_progress(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	if data.has("campaign_index"):
		current_campaign_index = int(data["campaign_index"])
	if data.has("map_index"):
		current_map_index = int(data["map_index"])
	return true
