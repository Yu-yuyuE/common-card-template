## BattleContext.gd
## 战场上下文 - 在卡牌效果执行时传递战场状态
## 作者: Claude Code
## 创建日期: 2026-04-13

class_name BattleContext extends RefCounted

## 地形类型枚举
enum Terrain {
	PLAINS,    # 平原
	MOUNTAIN,  # 山地
	FOREST,    # 森林
	WATER,     # 水域
	DESERT,    # 沙漠
	FORTRESS,  # 关隘
	SNOW       # 雪地
}

## 天气类型枚举
enum Weather {
	CLEAR,  # 晴朗
	WIND,   # 大风
	RAIN,   # 下雨
	FOG     # 雾
}

## 当前地形
var current_terrain: String = "PLAINS"

## 当前天气
var current_weather: String = "CLEAR"

## 打出卡牌的单位
var caster: BattleEntity = null

## 目标单位
var target: BattleEntity = null

## 手牌列表（用于状态检测）
var hand_cards: Array[CardData] = []

## 当前战斗状态
var battle_state: Dictionary = {}

## 当前回合数
var current_turn: int = 1

## 当前阶段（PLAYER_PHASE / ENEMY_PHASE）
var current_phase: String = "PLAYER_PHASE"

## 构造函数
func _init() -> void:
	pass

## 静态工厂方法 - 从游戏状态创建上下文
static func from_game_state(
	p_terrain: String,
	p_weather: String,
	p_caster: BattleEntity,
	p_target: BattleEntity,
	p_hand_cards: Array[CardData] = []
) -> BattleContext:
	var context = BattleContext.new()
	context.current_terrain = p_terrain
	context.current_weather = p_weather
	context.caster = p_caster
	context.target = p_target
	context.hand_cards = p_hand_cards
	return context

## 获取地形枚举值
func get_terrain_enum() -> Terrain:
	match current_terrain.to_upper():
		"MOUNTAIN":
			return Terrain.MOUNTAIN
		"FOREST":
			return Terrain.FOREST
		"WATER":
			return Terrain.WATER
		"DESERT":
			return Terrain.DESERT
		"FORTRESS":
			return Terrain.FORTRESS
		"SNOW":
			return Terrain.SNOW
		_:
			return Terrain.PLAINS

## 获取天气枚举值
func get_weather_enum() -> Weather:
	match current_weather.to_upper():
		"WIND":
			return Weather.WIND
		"RAIN":
			return Weather.RAIN
		"FOG":
			return Weather.FOG
		_:
			return Weather.CLEAR

## 检查目标是否有特定状态
func target_has_status(status_id: String) -> bool:
	# 这个方法需要由外部的 StatusManager 调用
	# 这里只是提供一个接口
	return false

## 检查施法者是否有特定状态
func caster_has_status(status_id: String) -> bool:
	# 这个方法需要由外部的 StatusManager 调用
	# 这里只是提供一个接口
	return false
