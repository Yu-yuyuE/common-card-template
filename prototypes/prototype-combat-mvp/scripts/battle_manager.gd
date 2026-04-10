# PROTOTYPE - NOT FOR PRODUCTION
# Question: 1v3 战场模型 + 兵种卡 + 地形系统的战斗循环是否有趣且可操作？
# Date: 2026-04-10

extends Node2D

# 战场配置
const PLAYER_HP: int = 50
const ENEMY_HP_ARRAY: Array[int] = [30, 35, 40]
const TERRAIN_TYPES: Array[String] = ["平原", "山地", "森林", "水域"]

# 当前状态
var player_hp: int = PLAYER_HP
var enemy_units: Array[Dictionary] = []
var current_terrain: String = "平原"
var hand_cards: Array[Dictionary] = []

# UI 引用
@onready var player_label: Label = $UI/PlayerHP
@onready var enemies_container: HBoxContainer = $UI/EnemiesContainer
@onready var terrain_label: Label = $UI/TerrainLabel
@onready var hand_container: HBoxContainer = $UI/HandContainer

func _ready():
	_init_battle()
	_update_ui()

func _init_battle():
	# 初始化敌人单位
	enemy_units.clear()
	for i in range(3):
		enemy_units.append({
			"hp": ENEMY_HP_ARRAY[i],
			"max_hp": ENEMY_HP_ARRAY[i],
			"name": "敌人" + str(i + 1),
			"alive": true
		})

	# 随机地形
	current_terrain = TERRAIN_TYPES[randi() % TERRAIN_TYPES.size()]

	# 初始化手牌（每种种卡一张）
	hand_cards = CardData.get_starting_hand()

func _update_ui():
	player_label.text = "玩家 HP: %d/%d" % [player_hp, PLAYER_HP]
	terrain_label.text = "当前地形: %s" % current_terrain

	# 更新敌人显示
	for child in enemies_container.get_children():
		child.queue_free()

	for enemy in enemy_units:
		var label = Label.new()
		label.text = "%s\nHP: %d/%d" % [enemy.name, enemy.hp, enemy.max_hp]
		if not enemy.alive:
			label.text += "\n[已阵亡]"
			label.modulate = Color(0.5, 0.5, 0.5)
		enemies_container.add_child(label)

	# 更新手牌显示
	for child in hand_container.get_children():
		child.queue_free()

	for card in hand_cards:
		var button = Button.new()
		button.text = "%s\n伤害: %d\n效果: %s" % [card.name, card.base_damage, card.description]
		button.custom_minimum_size = Vector2(120, 80)
		button.pressed.connect(_on_card_played.bind(card))
		hand_container.add_child(button)

func _on_card_played(card: Dictionary):
	# 计算地形修正
	var terrain_modifier: float = Terrain.get_damage_modifier(card.type, current_terrain)
	var final_damage: int = int(card.base_damage * terrain_modifier)

	# 选择目标（简化：随机选择存活的敌人）
	var alive_enemies: Array[int] = []
	for i in range(enemy_units.size()):
		if enemy_units[i].alive:
			alive_enemies.append(i)

	if alive_enemies.is_empty():
		print("所有敌人已阵亡！战斗胜利！")
		return

	var target_index: int = alive_enemies[randi() % alive_enemies.size()]

	# 应用伤害
	enemy_units[target_index].hp -= final_damage
	print("玩家使用 %s 对 %s 造成 %d 点伤害（地形修正: %.1fx）" % [card.name, enemy_units[target_index].name, final_damage, terrain_modifier])

	# 检查敌人是否阵亡
	if enemy_units[target_index].hp <= 0:
		enemy_units[target_index].hp = 0
		enemy_units[target_index].alive = false
		print("%s 已阵亡！" % enemy_units[target_index].name)

	# 从手牌移除该卡
	hand_cards.erase(card)

	# 敌人回合
	_enemy_turn()

	# 更新UI
	_update_ui()

func _enemy_turn():
	for enemy in enemy_units:
		if enemy.alive and player_hp > 0:
			var damage: int = randi_range(5, 10)
			player_hp -= damage
			print("%s 攻击玩家，造成 %d 点伤害" % [enemy.name, damage])

	if player_hp <= 0:
		player_hp = 0
		print("玩家阵亡！战斗失败！")

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			# 重置战斗
			player_hp = PLAYER_HP
			_init_battle()
			_update_ui()
			print("战斗已重置")
		elif event.keycode == KEY_F1:
			# 显示调试信息
			print("=== 调试信息 ===")
			print("玩家HP: %d" % player_hp)
			print("地形: %s" % current_terrain)
			print("手牌数量: %d" % hand_cards.size())
			print("存活敌人: %d" % enemy_units.filter(func(e): return e.alive).size())
