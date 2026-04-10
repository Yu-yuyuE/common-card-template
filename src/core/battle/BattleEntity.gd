## 战斗实体数据类
## 用于存储战场上英雄和敌人的核心属性。
class_name BattleEntity extends RefCounted

var id: String
var max_hp: int
var current_hp: int
var shield: int
var max_shield: int
var action_points: int
var max_action_points: int
var is_player: bool
var status_effects: Dictionary = {}

func _init(p_id: String, p_is_player: bool) -> void:
	id = p_id
	is_player = p_is_player
