## 战斗HUD主控UI
##
## 监听 BattleManager 信号，驱动：
## - 相位提示标签刷新
## - 手牌区 CardUI 节点的实例化与销毁
## - 敌人血条（ProgressBar）的数值更新
## - 我方武将状态（HP、护盾、专属计数器）
## - 行动点与抽/弃牌堆数量显示
## - 全局环境（地形天气、回合数）
##
## 遵守 ADR-0007：禁止在 _process 中轮询战斗状态，
## 所有状态变更均由信号回调驱动（ADR-0016 Signal驱动绑定）。
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
# 公开接口（现有）
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
# 公开接口（新增 — 我方武将状态区）
# ---------------------------------------------------------------------------

## 更新我方武将 HP 血条。
## current: 当前 HP 值；max_val: HP 上限
func update_hero_hp(current: int, max_val: int) -> void:
	var bar := get_node_or_null("HeroZone/HeroHpBar") as ProgressBar
	if bar == null:
		return
	bar.max_value = float(max_val)
	bar.value = float(clamp(current, 0, max_val))

## 更新我方武将护盾数值。
## armor <= 0 时隐藏标签；armor > 0 时显示 "🛡️{armor}"。
func update_hero_armor(armor: int) -> void:
	var label := get_node_or_null("HeroZone/HeroArmorLabel") as Label
	if label == null:
		return
	if armor <= 0:
		label.visible = false
	else:
		label.text = "🛡️%d" % armor
		label.visible = true

## 更新我方武将专属计数器文本（如"隐忍x3"）。
## text 为空字符串时隐藏标签。
func update_hero_counter(text: String) -> void:
	var label := get_node_or_null("HeroZone/HeroCounterLabel") as Label
	if label == null:
		return
	label.text = text

# ---------------------------------------------------------------------------
# 公开接口（新增 — 费用与战局资源区）
# ---------------------------------------------------------------------------

## 更新行动点（AP）显示，并同步刷新手牌灰显状态。
## current: 当前 AP；max_val: AP 上限
func update_ap(current: int, max_val: int) -> void:
	_current_ap = current
	var label := get_node_or_null("APZone/APLabel") as Label
	if label != null:
		label.text = "AP: %d/%d" % [current, max_val]
	# 同步刷新所有手牌灰显
	for node in _card_uis:
		if is_instance_valid(node) and node is CardUI:
			(node as CardUI).setup(node.card_id, _current_ap)

## 更新抽牌堆与弃牌堆数量显示。
## draw: 抽牌堆剩余数量；discard: 弃牌堆数量
func update_pile_counts(draw: int, discard: int) -> void:
	var draw_label := get_node_or_null("APZone/DrawPileLabel") as Label
	if draw_label != null:
		draw_label.text = "🎴%d" % draw
	var discard_label := get_node_or_null("APZone/DiscardPileLabel") as Label
	if discard_label != null:
		discard_label.text = "🗑️%d" % discard

# ---------------------------------------------------------------------------
# 公开接口（新增 — 全局环境区）
# ---------------------------------------------------------------------------

## 更新地形天气显示标签。
## terrain: 地形名称（如"山地"）；weather: 天气名称（如"晴天"）
func update_terrain_weather(terrain: String, weather: String) -> void:
	var label := get_node_or_null("EnvironmentZone/TerrainWeatherLabel") as Label
	if label == null:
		return
	label.text = "%s / %s" % [terrain, weather]

## 更新回合计数器显示。
## round_num: 当前回合数（从 1 开始）
func update_round(round_num: int) -> void:
	var label := get_node_or_null("EnvironmentZone/RoundLabel") as Label
	if label == null:
		return
	label.text = "回合 %d" % round_num

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
