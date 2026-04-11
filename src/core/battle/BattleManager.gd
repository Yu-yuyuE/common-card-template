## 核心战斗管理器
## 负责1v3战场的初始化和整体数据持有。
class_name BattleManager extends Node

signal battle_started(total_stages: int, enemies: Array[BattleEntity])
signal phase_changed(phase: BattlePhase)
signal turn_started(is_player: bool)

# 为了测试 C3 未实现时的敌人行动
signal enemy_action_mock_triggered(enemy_id: String)
signal battle_victory() # 测试桩：全灭时触发
signal card_played(card_id: String, target_position: int) # 当卡牌被成功打出时发射

enum BattlePhase {
	NONE,
	PLAYER_START,
	PLAYER_DRAW,
	PLAYER_PLAY,
	PLAYER_END,
	ENEMY_TURN,
	PHASE_CHECK
}

var current_phase: BattlePhase = BattlePhase.NONE
var is_player_turn: bool = false

var player_entity: BattleEntity
var enemy_entities: Array[BattleEntity] = []

var current_stage: int = 1
var total_stages: int = 1
var terrain: String = "plain"
var weather: String = "clear"

var card_manager: CardManager

# 敌人系统组件
var enemy_turn_manager: EnemyTurnManager = null
var enemy_manager: EnemyManager = null
var status_manager: StatusManager = null

func _init() -> void:
	card_manager = CardManager.new(self)
	enemy_manager = EnemyManager.new()
	status_manager = StatusManager.new()
	enemy_turn_manager = EnemyTurnManager.new()
	add_child(enemy_turn_manager)
	enemy_turn_manager.set_enemy_manager(enemy_manager)
	enemy_turn_manager.set_battle_manager(self, status_manager)

## 初始化战场环境与实体
## 参数 stage_config 包含：
##   "stage_count": int (默认1)
##   "terrain": String (默认"plain")
##   "weather": String (默认"clear")
##   "enemies": Array[Dictionary] (最多读取前3个)
##   "deck": Array[CardData] (初始卡组配置，暂可选)
func setup_battle(stage_config: Dictionary, resource_manager: ResourceManager) -> void:
	# 1. 基础配置
	total_stages = stage_config.get("stage_count", 1)
	current_stage = 1
	terrain = stage_config.get("terrain", "plain")
	weather = stage_config.get("weather", "clear")

	# 2. 初始化玩家实体
	player_entity = BattleEntity.new("player", true)
	player_entity.max_hp = resource_manager.get_max_hp()
	player_entity.current_hp = resource_manager.get_hp()
	player_entity.max_action_points = resource_manager.get_max_ap()
	player_entity.action_points = player_entity.max_action_points # 初始行动点满
	player_entity.max_shield = resource_manager.get_armor_max()
	player_entity.shield = 0 # 初始护盾清零

	# 3. 初始化敌人实体（最多3个）
	enemy_entities.clear()
	var enemies_data: Array = stage_config.get("enemies", [])
	var count := mini(enemies_data.size(), 3)

	for i in range(count):
		var ed: Dictionary = enemies_data[i]
		var enemy := BattleEntity.new(ed.get("id", "enemy_%d" % i), false)
		enemy.max_hp = ed.get("hp", 10)
		enemy.current_hp = enemy.max_hp
		enemy.shield = ed.get("shield", 0)
		enemy.max_shield = ed.get("max_shield", enemy.max_hp)
		enemy.max_action_points = ed.get("ap", 1)
		enemy.action_points = enemy.max_action_points
		enemy_entities.append(enemy)

	# 4. 初始化卡组（如果提供了配置，否则留空待外部注入）
	var initial_deck: Array[CardData] = []
	if stage_config.has("deck"):
		initial_deck.append_array(stage_config["deck"])
	card_manager.initialize_deck(initial_deck)

	# 5. 发送战斗开始信号
	battle_started.emit(total_stages, enemy_entities)

	# 6. 初始化敌人管理器数据
	enemy_manager._load_enemy_data()  # 加载敌人配置
	enemy_manager._load_action_library()  # 加载行动库

	# 7. 进入第一回合
	_start_player_turn()

# ---------------------------------------------------------------------------
# 阶段流转控制 (状态机)
# ---------------------------------------------------------------------------

func _set_phase(phase: BattlePhase) -> void:
	current_phase = phase
	phase_changed.emit(current_phase)

func _start_player_turn() -> void:
	is_player_turn = true
	_set_phase(BattlePhase.PLAYER_START)
	turn_started.emit(true)

	# TODO: 结算回合开始的状态效果（毒、灼烧跳字等）

	_set_phase(BattlePhase.PLAYER_DRAW)
	card_manager.fill_hand_to_limit()

	_set_phase(BattlePhase.PLAYER_PLAY)
	# 等待玩家操作。玩家操作完后必须调用 end_player_turn()

## 外部输入：玩家点击“结束回合”按钮
func end_player_turn() -> void:
	if current_phase != BattlePhase.PLAYER_PLAY:
		return

	_set_phase(BattlePhase.PLAYER_END)
	# TODO: StatusManager.tick_status(player_entity)

	is_player_turn = false
	_start_enemy_turn()

# ---------------------------------------------------------------------------
# 出牌逻辑 (Story 004)
# ---------------------------------------------------------------------------

## 玩家尝试打出卡牌
## 参数：
##   card_id: 要打出的卡牌实例的 ID
##   target_position: 目标槽位 (-1 为自身/全场，0-2 为敌人)
## 返回：
##   true = 打出成功，false = 费用不足或不在手牌等原因
func play_card(card_id: String, target_position: int) -> bool:
	if current_phase != BattlePhase.PLAYER_PLAY:
		return false

	# 1. 查找手牌
	var card_to_play: Card = null
	for c in card_manager.hand_cards:
		if c.get_id() == card_id:
			card_to_play = c
			break

	if card_to_play == null:
		return false # 没这张牌

	# 2. 费用检查
	var cost = card_to_play.current_cost
	if player_entity.action_points < cost:
		return false # 费用不足

	# 3. 扣除费用
	player_entity.action_points -= cost
	# (如果接入 ResourceManager，需要在这里同步 ResourceManager，当前使用 player_entity 同步状态)

	# 4. 结算效果 (Story 005)
	_resolve_card_effect(card_to_play, target_position)

	# 5. 卡牌流转入弃牌/消耗/移除区
	card_manager.exhaust_or_discard_played_card(card_to_play)

	# 6. 通知 UI 等监听者
	card_played.emit(card_id, target_position)

	return true

func _resolve_card_effect(card: Card, target_position: int) -> void:
	# TODO: Story 005 具体路由和伤害结算
	pass

func _start_enemy_turn() -> void:
	_set_phase(BattlePhase.ENEMY_TURN)
	turn_started.emit(false)

	# 遍历存活敌人执行回合
	var alive_enemies: Array[EnemyData] = []
	for enemy in enemy_entities:
		if enemy.current_hp > 0:
			# 从 EnemyManager 获取原始数据
			var enemy_data: EnemyData = enemy_manager.get_enemy(enemy.id)
			if enemy_data != null:
				alive_enemies.append(enemy_data)

	# 交给 EnemyTurnManager 执行
	enemy_turn_manager.execute_enemy_turn(alive_enemies)

	_check_phase()

func _check_phase() -> void:
	_set_phase(BattlePhase.PHASE_CHECK)

	var any_enemy_alive := false
	for enemy in enemy_entities:
		if enemy.current_hp > 0:
			any_enemy_alive = true
			break

	if any_enemy_alive:
		# 下一轮
		_start_player_turn()
	else:
		# TODO: Story 006 (多阶段处理)，暂用 Mock 解决
		battle_victory.emit()