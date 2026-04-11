## EnemyData.gd
## 敌人数据类（C3 - 敌人系统）
## 存储单个敌人的静态配置数据
## 依据 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyData extends RefCounted

## 敌人唯一标识
var id: String

## 敌人名称
var name: String

## 敌人职业（步兵/骑兵/弓兵/谋士/盾兵）
var enemy_class: int

## 敌人等级（普通/精英/强力）
var tier: int

## 最大生命值
var max_hp: int

## 当前生命值
var current_hp: int

## 护盾
var armor: int

## 是否存活
var is_alive: bool = true

## 行动序列（如 ["A01", "A01", "A03"]）
var action_sequence: Array[String] = []

## 当前行动索引（用于轮转序列）
var action_index: int = 0

## 冷却中的行动（Dictionary: {action_id: remaining_rounds}）
var cooldown_actions: Dictionary = {}

## 是否已完成相变（防止重复触发）
var has_transformed: bool = false

## 相变规则（如 "HP<40%:B01→C01→B14→C12"）
var phase_transition: String = ""

## 相变后的新序列（从 phase_transition 解析）
var phase2_sequence: Array[String] = []

## 初始化函数
func _init(
	p_id: String,
	p_name: String,
	p_class: int,
	p_tier: int,
	p_hp: int,
	p_armor: int = 0
) -> void:
	id = p_id
	name = p_name
	enemy_class = p_class
	tier = p_tier
	max_hp = p_hp
	current_hp = p_hp
	armor = p_armor
	is_alive = true
