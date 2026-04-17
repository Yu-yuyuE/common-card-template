## 战斗HUD主控UI
##
## 监听 BattleManager 信号，驱动：
## - 相位提示标签刷新
## - 手牌区 CardUI 节点的实例化与销毁
## - 敌人血条（ProgressBar）的数值更新
##
## 遵守 ADR-0007：禁止在 _process 中轮询战斗状态，
## 所有状态变更均由信号回调驱动。
class_name BattleUI extends Control

## 绑定的 BattleManager 实例（由外部在 _ready 后赋值，勿直接修改）
var battle_manager: BattleManager = null

## 手牌容器节点路径（场景中应为 HBoxContainer）
@export var hand_container_path: NodePath

## 相位提示标签路径
@export var phase_label_path: NodePath

## 当前行动点（用于 CardUI 灰显判定）
var _current_ap: int = 0

## 敌人血条字典，key = enemy_id (String)，value = ProgressBar
var _enemy_hp_bars: Dictionary = {}

## 当前手牌中的 CardUI 节点列表
var _card_uis: Array[Node] = []

# ---------------------------------------------------------------------------
# 绑定
# ---------------------------------------------------------------------------

## 初始化信号绑定——在外部将 BattleManager 实例赋值后调用此方法。
## 调用后 BattleUI 将响应该 BattleManager 的所有战斗事件。
func bind(bm: BattleManager) -> void:
	battle_manager = bm
	bm.battle_started.connect(_on_battle_started)
	bm.phase_changed.connect(_on_phase_changed)
	bm.turn_started.connect(_on_turn_started)
	bm.damage_dealt.connect(_on_damage_dealt)

# ---------------------------------------------------------------------------
# 信号回调（私有）
# ---------------------------------------------------------------------------

func _on_battle_started(total_stages: int, enemies: Array) -> void:
	_clear_hand()
	# total_stages 保留供后续阶段进度显示扩展
	var _stages: int = total_stages
	var _enemies: Array = enemies

func _on_phase_changed(phase: int) -> void:
	var label := _get_phase_label()
	if label == null:
		return

	match phase:
		BattleManager.BattlePhase.PLAYER_START:
			label.text = "玩家回合开始"
		BattleManager.BattlePhase.PLAYER_DRAW:
			label.text = "摸牌阶段"
		BattleManager.BattlePhase.PLAYER_PLAY:
			label.text = "玩家回合"
		BattleManager.BattlePhase.PLAYER_END:
			label.text = "结算中..."
		BattleManager.BattlePhase.ENEMY_TURN:
			label.text = "敌方回合"
		BattleManager.BattlePhase.PHASE_CHECK:
			label.text = "阶段检定"
		_:
			label.text = ""

func _on_turn_started(is_player: bool) -> void:
	# 根据行动方刷新所有手牌的灰显状态
	for node in _card_uis:
		if is_instance_valid(node) and node is CardUI:
			if is_player:
				(node as CardUI).setup(node.card_id, _current_ap)
			else:
				# 非玩家回合：全部灰显
				(node as CardUI).setup(node.card_id, 0)

func _on_damage_dealt(target_id: String, amount: int) -> void:
	if not _enemy_hp_bars.has(target_id):
		return
	var bar: ProgressBar = _enemy_hp_bars[target_id]
	if is_instance_valid(bar):
		bar.value = max(bar.value - amount, 0)

# ---------------------------------------------------------------------------
# 公开接口
# ---------------------------------------------------------------------------

## 刷新手牌显示。
## card_ids: 当前手牌的卡牌 ID 列表
## current_ap: 当前可用行动点（决定哪些牌可打出）
func refresh_hand(card_ids: Array[String], current_ap: int) -> void:
	_current_ap = current_ap
	_clear_hand()
	var container := get_node_or_null(hand_container_path)
	if container == null:
		return
	for card_id in card_ids:
		var card_ui := CardUI.new()
		card_ui.setup(card_id, _current_ap)
		container.add_child(card_ui)
		_card_uis.append(card_ui)

## 注册敌人血条，将 enemy_id 与对应 ProgressBar 关联。
## 应在战斗开始、敌人节点创建完毕后由外部调用。
func register_enemy_hp_bar(enemy_id: String, hp_bar: ProgressBar) -> void:
	_enemy_hp_bars[enemy_id] = hp_bar

# ---------------------------------------------------------------------------
# 内部工具（私有）
# ---------------------------------------------------------------------------

func _clear_hand() -> void:
	for node in _card_uis:
		if is_instance_valid(node):
			node.queue_free()
	_card_uis.clear()

## 取得相位标签节点，路径未设置或节点不存在时静默返回 null。
func _get_phase_label() -> Label:
	if phase_label_path.is_empty():
		return null
	var node := get_node_or_null(phase_label_path)
	if node is Label:
		return node as Label
	return null
