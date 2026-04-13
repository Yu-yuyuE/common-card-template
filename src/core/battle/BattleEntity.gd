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

## 受到伤害计算
## @param damage: 基础伤害值
## @param penetrate_shield: 是否无视护甲直接扣HP
## @return 实际扣除的HP量
func take_damage(damage: int, penetrate_shield: bool = false) -> int:
	var actual = damage
	if not penetrate_shield and shield > 0:
		var blocked = min(shield, damage)
		shield -= blocked
		actual -= blocked
	if actual > 0:
		current_hp = max(0, current_hp - actual)
	return actual

