## ActionExecutor.gd
## 敌人行动效果执行器（C3 - 敌人系统）
## 实现 Story 006: 诅咒投递与特殊效果执行
## 依据 ADR-0015 和 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name ActionExecutor extends Node

## 信号
signal action_executed(action: EnemyAction)
signal curse_delivered(curse_id: String, target_area: String)
signal enemy_summoned(enemy_id: String)

## 持有 BattleManager 引用（由外部注入）
var battle_manager: BattleManager = null
var status_manager: StatusManager = null  # 玩家的状态管理器
var enemy_manager: EnemyManager = null

## 初始化（由 EnemyTurnManager 或 BattleManager 调用）
func initialize(battle_mgr: BattleManager, status_mgr: StatusManager, enemy_mgr: EnemyManager) -> void:
	battle_manager = battle_mgr
	status_manager = status_mgr
	enemy_manager = enemy_mgr


## 执行敌人行动（主入口）
## action: EnemyAction - 要执行的行动
## source_enemy_id: String - 执行该行动的敌人ID
func execute_action(action: EnemyAction, source_enemy_id: String, enemy_data: EnemyData = null) -> void:
	if action == null:
		return

	# 检查执行者是否存活
	var source_enemy: EnemyData = enemy_manager.get_enemy(source_enemy_id)
	if source_enemy == null or not source_enemy.is_alive:
		return  # 死亡敌人不执行

	# 设置行动的敌人ID和manager引用，以便访问action_params
	action.source_enemy_id = source_enemy_id
	action.enemy_manager = enemy_manager
	action.enemy_data = source_enemy

	# 根据行动类型路由
	match action.type.to_lower():
		"attack":
			_execute_attack(action, source_enemy_id)
		"defend", "buff":
			_execute_buff(action, source_enemy_id)
		"debuff":
			_execute_debuff(action, source_enemy_id)
		"heal":
			_execute_heal(action, source_enemy_id)
		"curse":
			_execute_curse(action, source_enemy_id)
		"summon":
			_execute_summon(action, source_enemy_id)
		"special":
			_execute_special(action, source_enemy_id)
		_:
			push_warning("ActionExecutor: 未知行动类型 — %s" % action.type)

	action_executed.emit(action)


## 攻击类行动执行
func _execute_attack(action: EnemyAction, source_enemy_id: String) -> void:
	var damage: int = action.damage
	if damage <= 0:
		return

	# 混乱状态检查：如果攻击者处于混乱，目标改为友军
	var source_enemy: EnemyData = enemy_manager.get_enemy(source_enemy_id)
	if _is_confused(source_enemy):
		# 攻击随机友军
		var target_enemy: EnemyData = _get_random_ally(source_enemy_id)
		if target_enemy != null:
			_apply_damage_to_enemy(target_enemy, damage)
			# 减少1层混乱状态（如果有StatusManager集成）
		return

	# 正常攻击玩家
	_apply_damage_to_player(damage)


## Buff类行动执行（强化自身或友军）
func _execute_buff(action: EnemyAction, source_enemy_id: String) -> void:
	# 获取目标
	var target: EnemyData = null
	match action.target.to_lower():
		"self":
			target = enemy_manager.get_enemy(source_enemy_id)
		"random_ally", "all_allies":
			target = enemy_manager.get_enemy(source_enemy_id)  # 简化：暂时只强化自己
		_:
			target = enemy_manager.get_enemy(source_enemy_id)

	if target == null:
		return

	# 应用护甲
	if action.armor > 0:
		target.armor += action.armor
		print("Enemy %s gained %d armor" % [target.id, action.armor])


## Debuff类行动执行（减益玩家）
func _execute_debuff(action: EnemyAction, source_enemy_id: String) -> void:
	if status_manager == null:
		push_warning("ActionExecutor: StatusManager 未初始化，无法施加状态")
		return

	# 应用状态效果
	if not action.status_effect.is_empty():
		var status_type: StatusEffect.Type = _parse_status_type(action.status_effect)
		if status_type != StatusEffect.Type.NONE:
			status_manager.apply(status_type, action.status_layers, "敌人行动: " + action.name)


## 治疗类行动执行
func _execute_heal(action: EnemyAction, source_enemy_id: String) -> void:
	var target: EnemyData = null
	match action.target.to_lower():
		"self":
			target = enemy_manager.get_enemy(source_enemy_id)
		"random_ally":
			target = _get_random_ally(source_enemy_id)
		"all_allies":
			# 治疗所有友军
			for enemy_id in enemy_manager._enemies.keys():
				var ally: EnemyData = enemy_manager.get_enemy(enemy_id)
				if ally != null and ally.is_alive:
					_heal_enemy(ally, action.heal)
			return
		_:
			target = enemy_manager.get_enemy(source_enemy_id)

	if target != null:
		_heal_enemy(target, action.heal)


## 诅咒投递类行动执行
func _execute_curse(action: EnemyAction, source_enemy_id: String) -> void:
	if action.curse_id.is_empty():
		return

	if battle_manager == null or battle_manager.card_manager == null:
		push_warning("ActionExecutor: BattleManager 或 CardManager 未初始化，无法投递诅咒")
		return

	# 解析投递方式（hand, draw_top, draw_random, discard）
	var delivery_method: String = "draw_random"  # 默认随机加入抽牌堆
	if ("手牌" in action.description or "hand" in action.description) or "hand" in action.target.to_lower():
		delivery_method = "hand"
	elif ("抽牌堆顶" in action.description or "draw" in action.description) or "draw_top" in action.target.to_lower():
		delivery_method = "draw_top"
	elif ("弃牌堆" in action.description or "discard" in action.description) or "discard" in action.target.to_lower():
		delivery_method = "discard"

	# 投递诅咒卡
	_deliver_curse(action.curse_id, delivery_method)


## 召唤类行动执行
func _execute_summon(action: EnemyAction, source_enemy_id: String) -> void:
	if action.summon_id.is_empty():
		return

	if battle_manager == null:
		push_warning("ActionExecutor: BattleManager 未初始化，无法召唤敌人")
		return

	# 检查战场是否已满（最多3名敌人）
	if battle_manager.enemy_entities.size() >= 3:
		return  # 满场跳过

	# 实例化新敌人
	var new_enemy_data: EnemyData = enemy_manager.get_enemy(action.summon_id)
	if new_enemy_data == null:
		push_warning("ActionExecutor: 召唤的敌人ID不存在 — %s" % action.summon_id)
		return

	# 创建战斗实体并加入战场
	var new_battle_entity := BattleEntity.new(new_enemy_data.id, false)
	new_battle_entity.max_hp = new_enemy_data.max_hp
	new_battle_entity.current_hp = new_enemy_data.current_hp
	new_battle_entity.shield = new_enemy_data.armor
	new_battle_entity.max_shield = new_enemy_data.max_hp
	new_battle_entity.max_action_points = 1
	new_battle_entity.action_points = 1

	battle_manager.enemy_entities.append(new_battle_entity)
	enemy_summoned.emit(action.summon_id)
	print("Enemy summoned: %s" % action.summon_id)


## 特殊类行动执行（偷取金币/手牌等）
func _execute_special(action: EnemyAction, source_enemy_id: String) -> void:
	# 获取敌人数据以访问参数覆盖
	var source_enemy: EnemyData = enemy_manager.get_enemy(source_enemy_id)
	if source_enemy == null:
		return

	# 偷取金币
	if ("偷" in action.description and "金" in action.description) or "steal_gold" in action.type:
		var steal_amount: int = 5  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("gold_steal"):
			steal_amount = source_enemy.action_params[action.id]["gold_steal"]
		else:
			steal_amount = _extract_number_from_text(action.value_reference)

		if steal_amount > 0 and battle_manager != null:
			# TODO: 从玩家 ResourceManager 扣除金币
			print("Enemy steals %d gold from player" % steal_amount)

	# 偷取手牌
	elif ("偷" in action.description and "牌" in action.description) or "steal_card" in action.type:
		var card_count: int = 1  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("card_steal"):
			card_count = source_enemy.action_params[action.id]["card_steal"]
		else:
			card_count = _extract_number_from_text(action.value_reference)

		if battle_manager != null and battle_manager.card_manager != null:
			# 随机偷取指定数量的手牌
			var hand: Array = battle_manager.card_manager.hand_cards
			if hand.size() > 0:
				for i in range(card_count):
					if hand.size() == 0:
						break
					var stolen_card: Card = hand[randi() % hand.size()]
					hand.erase(stolen_card)
					print("Enemy steals card: %s" % stolen_card.card_name)
					# TODO: 记录被偷卡牌ID，待敌人死后归还

	# 施加诅咒卡
	elif action.type == "curse" or "curse" in action.description or "诅咒" in action.description:
		var curse_count: int = 1  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("curse_count"):
			curse_count = source_enemy.action_params[action.id]["curse_count"]
		else:
			curse_count = _extract_number_from_text(action.value_reference)

		var curse_card_id: String = ""  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("curse_card_id"):
			curse_card_id = source_enemy.action_params[action.id]["curse_card_id"]
		else:
			curse_card_id = action.curse_id  # 使用默认诅咒ID

		if curse_count > 0 and curse_card_id != "" and battle_manager != null and battle_manager.card_manager != null:
			# 投递诅咒卡到随机位置
			for i in range(curse_count):
				_deliver_curse(curse_card_id, "draw_random")

	# 召唤敌人
	elif action.type == "summon" or "summon" in action.description or "召唤" in action.description:
		var summon_count: int = 1  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("summon_count"):
			summon_count = source_enemy.action_params[action.id]["summon_count"]
		else:
			summon_count = _extract_number_from_text(action.value_reference)

		var summon_enemy_id: String = ""  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("summon_enemy_id"):
			summon_enemy_id = source_enemy.action_params[action.id]["summon_enemy_id"]
		else:
			summon_enemy_id = action.summon_id  # 使用默认召唤敌人ID

		if summon_count > 0 and summon_enemy_id != "" and battle_manager != null:
			# 实例化新敌人并加入战场
			var new_enemy_data: EnemyData = enemy_manager.get_enemy(summon_enemy_id)
			if new_enemy_data == null:
				push_warning("ActionExecutor: 召唤的敌人ID不存在 — %s" % summon_enemy_id)
				return

			for i in range(summon_count):
				# 检查战场是否已满（最多3名敌人）
				if battle_manager.enemy_entities.size() >= 3:
					break  # 满场停止召唤

				# 创建战斗实体并加入战场
				var new_battle_entity := BattleEntity.new(new_enemy_data.id, false)
				new_battle_entity.max_hp = new_enemy_data.max_hp
				new_battle_entity.current_hp = new_enemy_data.current_hp
				new_battle_entity.shield = new_enemy_data.armor
				new_battle_entity.max_shield = new_enemy_data.max_hp
				new_battle_entity.max_action_points = 1
				new_battle_entity.action_points = 1

				battle_manager.enemy_entities.append(new_battle_entity)
				enemy_summoned.emit(summon_enemy_id)
				print("Enemy summoned: %s" % summon_enemy_id)

	# 移动方向
	elif action.type == "move" or "move" in action.description or "移动" in action.description:
		var move_direction: String = ""  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("move_direction"):
			move_direction = source_enemy.action_params[action.id]["move_direction"]

		if move_direction != "":
			# TODO: 实现移动逻辑，更新敌人位置
			print("Enemy %s moves %s" % [source_enemy_id, move_direction])

	# 改变天气
	elif action.type == "weather" or "weather" in action.description or "天气" in action.description:
		var weather: String = ""  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("weather"):
			weather = source_enemy.action_params[action.id]["weather"]

		if weather != "":
			# TODO: 实现天气改变逻辑，更新BattleManager的天气状态
			print("Weather changed to: %s" % weather)

	# 应用状态效果
	elif action.status_effect != "":
		var status_layers: int = action.status_layers  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("status_layers"):
			status_layers = source_enemy.action_params[action.id]["status_layers"]

		var status_id: String = action.status_effect  # 默认值
		if source_enemy.action_params.has(action.id) and source_enemy.action_params[action.id].has("status_id"):
			status_id = source_enemy.action_params[action.id]["status_id"]

		if status_manager != null and status_id != "":
			var status_type: StatusEffect.Type = _parse_status_type(status_id)
			if status_type != StatusEffect.Type.NONE:
				status_manager.apply(status_type, status_layers, "敌人行动: " + action.name)
				print("Applied status %s with %d layers" % [status_id, status_layers])


## ==================== 辅助方法 ====================

## 对玩家造成伤害
func _apply_damage_to_player(damage: int) -> void:
	if battle_manager == null or battle_manager.player_entity == null:
		return

	# TODO: 考虑玩家的伤害修正系数（坚守、破甲等）
	battle_manager.player_entity.current_hp -= damage
	if battle_manager.player_entity.current_hp < 0:
		battle_manager.player_entity.current_hp = 0

	print("Player takes %d damage, HP: %d/%d" % [
		damage,
		battle_manager.player_entity.current_hp,
		battle_manager.player_entity.max_hp
	])


## 对敌人造成伤害
func _apply_damage_to_enemy(target: EnemyData, damage: int) -> void:
	if target == null:
		return

	target.current_hp -= damage
	if target.current_hp <= 0:
		target.current_hp = 0
		target.is_alive = false

	print("Enemy %s takes %d damage, HP: %d/%d" % [
		target.id, damage, target.current_hp, target.max_hp
	])


## 治疗敌人
func _heal_enemy(target: EnemyData, heal_amount: int) -> void:
	if target == null or heal_amount <= 0:
		return

	target.current_hp += heal_amount
	if target.current_hp > target.max_hp:
		target.current_hp = target.max_hp

	print("Enemy %s healed for %d, HP: %d/%d" % [
		target.id, heal_amount, target.current_hp, target.max_hp
	])


## 检查敌人是否处于混乱状态
func _is_confused(enemy: EnemyData) -> bool:
	# TODO: 需要从 StatusManager 查询
	# 目前简化返回 false
	return false


## 获取随机友军（排除自己）
func _get_random_ally(exclude_id: String) -> EnemyData:
	var allies: Array[EnemyData] = []
	for enemy_id in enemy_manager._enemies.keys():
		if enemy_id != exclude_id:
			var ally: EnemyData = enemy_manager.get_enemy(enemy_id)
			if ally != null and ally.is_alive:
				allies.append(ally)

	if allies.is_empty():
		return null

	return allies[randi() % allies.size()]


## 投递诅咒卡到指定区域
func _deliver_curse(curse_id: String, delivery_method: String) -> void:
	if battle_manager == null or battle_manager.card_manager == null:
		return

	var card_manager: CardManager = battle_manager.card_manager

	match delivery_method:
		"hand":
			# 直接加入手牌
			card_manager.hand_cards.append(_create_curse_card(curse_id))
		"draw_top":
			# 加入抽牌堆顶部
			card_manager.draw_pile.push_front(_create_curse_card(curse_id))
		"draw_random":
			# 随机插入抽牌堆
			var idx: int = randi() % (card_manager.draw_pile.size() + 1)
			card_manager.draw_pile.insert(idx, _create_curse_card(curse_id))
		"discard":
			# 加入弃牌堆
			card_manager.discard_pile.append(_create_curse_card(curse_id))

	curse_delivered.emit(curse_id, delivery_method)
	print("Curse %s delivered to %s" % [curse_id, delivery_method])


## 创建诅咒卡牌实例（简化版）
func _create_curse_card(curse_id: String) -> Card:
	# TODO: 从 CardManager 或诅咒数据库加载诅咒卡数据
	# 目前返回一个简化的 Card 对象
	var curse_card := Card.new()
	# curse_card.load_data(curse_id)  # 待实现
	return curse_card


## 解析状态类型
func _parse_status_type(status_name: String) -> StatusEffect.Type:
	match status_name.to_lower():
		TranslationServer.translate("STATUS_POISON"), "poison":
			return StatusEffect.Type.POISON
		TranslationServer.translate("STATUS_TOXIC"), "toxic":
			return StatusEffect.Type.TOXIC
		TranslationServer.translate("STATUS_BURN"), "burn":
			return StatusEffect.Type.BURN
		TranslationServer.translate("STATUS_PLAGUE"), "plague":
			return StatusEffect.Type.PLAGUE
		TranslationServer.translate("STATUS_WOUND"), "wound":
			return StatusEffect.Type.WOUND
		TranslationServer.translate("STATUS_FEAR"), "fear":
			return StatusEffect.Type.FEAR
		TranslationServer.translate("STATUS_CONFUSION"), "confusion":
			return StatusEffect.Type.CONFUSION
		TranslationServer.translate("STATUS_STUN"), "stun":
			return StatusEffect.Type.STUN
		TranslationServer.translate("STATUS_BLIND"), "blind":
			return StatusEffect.Type.BLIND
		TranslationServer.translate("STATUS_WEAKEN"), "weaken":
			return StatusEffect.Type.WEAKEN
		TranslationServer.translate("STATUS_ARMOR_BREAK"), "armor_break":
			return StatusEffect.Type.ARMOR_BREAK
		TranslationServer.translate("STATUS_FROSTBITE"), "frostbite":
			return StatusEffect.Type.FROSTBITE
		TranslationServer.translate("STATUS_SLIP"), "slip":
			return StatusEffect.Type.SLIP
		_:
			return StatusEffect.Type.NONE


## 从文本中提取数字
func _extract_number_from_text(text: String) -> int:
	var regex := RegEx.new()
	regex.compile("\\d+")
	var match_result: RegExMatch = regex.search(text)
	if match_result:
		return match_result.get_string().to_int()
	return 0
