## 武将属性数据
## 通过CSV加载 (design/detail/heroes.csv)
class_name HeroManager extends Node

# ===========================================================================
# 枚举
# ===========================================================================

## 阵营
enum Faction {
	WEI = 0,      ## 魏
	SHU = 1,      ## 蜀
	WU = 2,       ## 吴
	OTHERS = 3,   ## 群雄
}

## 兵种类型
enum TroopType {
	INFANTRY = 0,   ## 步兵
	CAVALRY = 1,    ## 骑兵
	ARCHER = 2,     ## 弓兵
	STRATEGIST = 3, ## 谋士
	SHIELD = 4,     ## 盾兵
}

# ===========================================================================
# 武将数据结构
# ===========================================================================

## 武将属性数据
## 通过CSV加载 (design/detail/heroes.csv)
class HeroData:
	var id: String                    ## 唯一标识（snake_case）
	var name_zh: String               ## 中文名
	var faction: int                  ## Faction 枚举值
	var max_hp: int                   ## 最大生命值
	var base_cost: int                ## 每回合基础行动点
	var leadership: int               ## 统帅（兵种卡携带上限）
	var affinity_primary: Array[int]  ## 主修兵种 [TroopType, TroopType]
	var affinity_secondary: int       ## 次修兵种 TroopType
	var exclusive_cards: int          ## 专属卡数量
	var passive_id: String            ## 被动技能 ID
	var hand_limit: int               ## 手牌上限（默认 5，袁绍 6）
	var no_armor: bool                ## 是否禁止获得护甲（仅典韦）
	var unlimited_armor: bool         ## 护盾上限无上限（仅张角）

	func _init() -> void:
		affinity_primary = []

# ===========================================================================
# 信号
# ===========================================================================

## 武将加载完成时发射（所有静态数据就绪）
signal heroes_loaded(hero_count: int)

## 当前武将变更时发射
signal hero_selected(hero_id: String)

## 被动技能触发时发射（Story 003）
signal passive_triggered(hero_id: String, skill_name: String, effect_result: Dictionary)

## 请求抽卡（Story 005 诸葛亮被动）
signal request_draw_card(count: int)

# ===========================================================================
# 常量
# ===========================================================================

## 数据文件路径
const DATA_PATH: String = "res://design/detail/heroes.csv"

## 兵种倾向权重（F3）
const WEIGHT_PRIMARY: float = 2.0    ## 主修
const WEIGHT_SECONDARY: float = 1.0  ## 次修
const WEIGHT_NON_AFFINITY: float = 0.5  ## 非倾向

# ===========================================================================
# 公共属性（由 ResourceManager._ready() 通过 get() 读取）
# ===========================================================================

## 当前武将最大 HP（供 ResourceManager 初始化用）
var max_hp: int = 50

## 当前武将基础行动点（供 ResourceManager 初始化用）
var base_ap: int = 3

# ===========================================================================
# 私有成员
# ===========================================================================

## 全量武将数据表：id -> HeroData
var _hero_table: Dictionary = {}

## 当前选中武将 ID
var _current_hero_id: String = ""

## 当前武将数据缓存
var _current_hero: HeroData = null

## 被动技能映射：skill_id -> Callable (Story 003)
var _passive_skills: Dictionary = {}

# ===========================================================================
# 生命周期
# ===========================================================================

func _ready() -> void:
	var count: int = _load_heroes_from_csv()
	if count == 0:
		push_error("HeroManager._ready: 武将数据加载失败，加载数量为 0")
	else:
		_register_passive_skills()  # Story 003

# ===========================================================================
# 数据加载
# ===========================================================================

## 从 CSV 加载全部武将数据。
## 文件格式见 design/detail/heroes.csv 头部注释。
## 返回：加载成功的武将数量（用于验证）
func _load_heroes_from_csv() -> int:
	_hero_table.clear()

	if not FileAccess.file_exists(DATA_PATH):
		push_error("HeroManager: 数据文件未找到 — %s" % DATA_PATH)
		return 0

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("HeroManager: 无法打开文件 — %s" % DATA_PATH)
		return 0

	var loaded_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		# 跳过空行与注释行（以 ## 或 # 开头）
		if line.is_empty() or line.begins_with("#"):
			continue

		# 跳过 CSV 标题行（以 "id," 开头）
		if line.begins_with("id,"):
			continue

		var fields: PackedStringArray = line.split(",")
		if fields.size() < 14:
			push_warning("HeroManager: 行字段数不足，跳过 — [%s]" % line)
			continue

		var data := HeroData.new()
		data.id = fields[0].strip_edges()
		data.name_zh = fields[1].strip_edges()
		data.faction = _parse_faction(fields[2].strip_edges())
		data.max_hp = fields[3].strip_edges().to_int()
		data.base_cost = fields[4].strip_edges().to_int()
		data.leadership = fields[5].strip_edges().to_int()

		# affinity_primary 长度安全检查
		var primary_raw_0: String = fields[6].strip_edges()
		var primary_raw_1: String = fields[7].strip_edges()
		if not primary_raw_0.is_empty():
			data.affinity_primary.append(_parse_troop_type(primary_raw_0))
		if not primary_raw_1.is_empty():
			data.affinity_primary.append(_parse_troop_type(primary_raw_1))

		data.affinity_secondary = _parse_troop_type(fields[8].strip_edges())
		data.exclusive_cards = fields[9].strip_edges().to_int()
		data.passive_id = fields[10].strip_edges()

		# hand_limit 安全回退：若解析结果 <= 0 则强制使用默认值 5
		var parsed_hand_limit: int = fields[11].strip_edges().to_int()
		data.hand_limit = parsed_hand_limit if parsed_hand_limit > 0 else 5

		data.no_armor = fields[12].strip_edges().to_lower() == "true"
		data.unlimited_armor = fields[13].strip_edges().to_lower() == "true"

		if data.id.is_empty():
			push_warning("HeroManager: id 为空，跳过一行")
			continue

		_hero_table[data.id] = data
		loaded_count += 1

	file.close()
	heroes_loaded.emit(loaded_count)
	return loaded_count


# ===========================================================================
# 被动技能系统 (Story 003)
# ===========================================================================

## 注册所有被动技能效果
func _register_passive_skills() -> void:
	_passive_skills.clear()

	# 曹操：挟令诸侯 - 使用兵种卡时施加虚弱
	_passive_skills["xie_ling_zhu_hou"] = {"trigger": "on_troop_card_played", "func": Callable(self, "_effect_xie_ling_zhu_hou")}

	# 夏侯惇：刚烈 - 受伤时累计伤害
	_passive_skills["gang_lie"] = {"trigger": "on_damaged", "func": Callable(self, "_effect_gang_lie")}

	# 司马懿：隐忍
	_passive_skills["yin_ren"] = {"trigger": "on_curse_added", "func": Callable(self, "_effect_yin_ren")}

	# 典韦：恶来
	_passive_skills["e_lai"] = {"trigger": "on_damaged", "func": Callable(self, "_effect_e_lai")}

	# 刘备：仁德
	_passive_skills["ren_de"] = {"trigger": "on_troop_kill", "func": Callable(self, "_effect_ren_de")}

	# 关羽：武圣
	_passive_skills["wu_sheng"] = {"trigger": "on_attack", "func": Callable(self, "_effect_wu_sheng")}

	# 张飞：燕人咆哮
	_passive_skills["yan_ren_pao_xiao"] = {"trigger": "on_damaged", "func": Callable(self, "_effect_yan_ren_pao_xiao")}

	# 诸葛亮：卧龙
	_passive_skills["wo_long"] = {"trigger": "on_turn_start", "func": Callable(self, "_effect_wo_long")}
	_passive_skills["wo_long_skill"] = {"trigger": "on_skill_card_played", "func": Callable(self, "_effect_wo_long_skill")}

	# 赵云：龙胆
	_passive_skills["long_dan"] = {"trigger": "on_dodge", "func": Callable(self, "_effect_long_dan")}

	# 孙权：制衡
	_passive_skills["zhi_heng"] = {"trigger": "on_card_draw", "func": Callable(self, "_effect_zhi_heng")}

	# 周瑜：火谋
	_passive_skills["huo_mou"] = {"trigger": "on_attack", "func": Callable(self, "_effect_huo_mou")}

	# 吕布：人中吕布
	_passive_skills["ren_zhong_lv_bu"] = {"trigger": "on_attack", "func": Callable(self, "_effect_ren_zhong_lv_bu")}

	# 张角：黄天当立
	_passive_skills["huang_tian_dang_li"] = {"trigger": "on_death", "func": Callable(self, "_effect_huang_tian_dang_li")}

	# 贾诩：毒士
	_passive_skills["du_shi"] = {"trigger": "on_status_apply", "func": Callable(self, "_effect_du_shi")}

	print("HeroManager: 注册了 %d 个被动技能" % _passive_skills.size())


## 触发被动技能（Story 003 AC-1）
func trigger_passive(trigger_type: String, context: Dictionary) -> void:
	if _current_hero == null or _current_hero.passive_id.is_empty():
		return

	# 尝试获取主被动技能
	var skill_data = _passive_skills.get(_current_hero.passive_id, null)
	var triggered: bool = false
	var result: Dictionary = {}

	if skill_data != null and skill_data.trigger == trigger_type:
		result = skill_data.func.call(context)
		triggered = true
	else:
		# 检查额外触发的被动（如诸葛亮）
		var extra_skill_id = _current_hero.passive_id + "_skill"
		var extra_skill_data = _passive_skills.get(extra_skill_id, null)
		if extra_skill_data != null and extra_skill_data.trigger == trigger_type:
			result = extra_skill_data.func.call(context)
			triggered = true

	if triggered:
		passive_triggered.emit(_current_hero_id, _current_hero.passive_id, result)


# ===========================================================================
# 被动技能效果实现（Story 005/006）
# ===========================================================================

func _effect_xie_ling_zhu_hou(context: Dictionary) -> Dictionary:
	return {"success": true, "effect": "apply_weak", "layers": 1}

func _effect_gang_lie(context: Dictionary) -> Dictionary:
	return {"success": true, "accumulated_damage": context.get("damage", 0)}

func _effect_yin_ren(context: Dictionary) -> Dictionary:
	return {"success": true, "curse_layers": 1}

func _effect_e_lai(context: Dictionary) -> Dictionary:
	return {"success": true, "crit_heal": 3}

func _effect_ren_de(context: Dictionary) -> Dictionary:
	return {"success": true, "heal": 8}

func _effect_wu_sheng(context: Dictionary) -> Dictionary:
	return {"success": true, "damage_boost": 0.5}

func _effect_yan_ren_pao_xiao(context: Dictionary) -> Dictionary:
	return {"success": true, "counter_damage": 3}

func _effect_wo_long(context: Dictionary) -> Dictionary:
	# 回合开始恢复1行动点
	request_draw_card.emit(0)  # 通知恢复AP
	return {"success": true, "restore_ap": 1}

func _effect_wo_long_skill(context: Dictionary) -> Dictionary:
	# 技能卡抽1张
	request_draw_card.emit(1)
	return {"success": true, "draw_cards": 1}

func _effect_long_dan(context: Dictionary) -> Dictionary:
	return {"success": true, "counter_attack": true}

func _effect_zhi_heng(context: Dictionary) -> Dictionary:
	return {"success": true, "discard_draw": 1}

func _effect_huo_mou(context: Dictionary) -> Dictionary:
	return {"success": true, "fire_damage": 2}

func _effect_ren_zhong_lv_bu(context: Dictionary) -> Dictionary:
	return {"success": true, "damage_boost": 0.5}

func _effect_huang_tian_dang_li(context: Dictionary) -> Dictionary:
	# 张角复活逻辑（Story 006）
	var max_resurrect: int = 3
	var current_resurrect: int = context.get("resurrect_count", 0)

	if current_resurrect < max_resurrect:
		return {"resurrected": true, "resurrect_count": current_resurrect + 1, "hp_ratio": 0.5}
	return {"resurrected": false}

func _effect_du_shi(context: Dictionary) -> Dictionary:
	# 贾诩毒士：状态层数合并
	var existing_layers: int = context.get("existing_layers", 0)
	var new_layers: int = context.get("new_layers", 1)
	return {"success": true, "merged_layers": existing_layers + new_layers}


# ===========================================================================
# 武将选择
# ===========================================================================

## 选择当前战役使用的武将。
## 必须在战斗初始化之前调用，ResourceManager 依赖此方法填充的 max_hp / base_ap。
##
## 参数：hero_id — 武将 ID（对应 heroes.csv 的 id 列）
## 返回：true = 选择成功；false = hero_id 不存在
func select_hero(hero_id: String) -> bool:
	var found_id: String = ""
	for key: String in _hero_table:
		if key.strip_edges() == hero_id.strip_edges():
			found_id = key
			break

	if found_id.is_empty():
		push_error("HeroManager: 武将 ID 不存在 — %s" % hero_id)
		return false

	_current_hero_id = found_id
	_current_hero = _hero_table[found_id]

	# 更新 ResourceManager 读取的公共属性
	max_hp = _current_hero.max_hp
	base_ap = _current_hero.base_cost

	hero_selected.emit(found_id)
	return true

# ===========================================================================
# 查询接口
# ===========================================================================

## 获取当前武将数据（只读）
func get_current_hero() -> HeroData:
	return _current_hero

## 按 ID 获取武将数据（只读）
func get_hero_data(hero_id: String) -> HeroData:
	return _hero_table.get(hero_id, null)

## 获取全量武将 ID 列表
func get_all_hero_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_hero_table.keys())
	return result

## 获取指定阵营的武将 ID 列表
func get_heroes_by_faction(faction: int) -> Array[String]:
	var result: Array[String] = []
	for hero_id: String in _hero_table:
		if _hero_table[hero_id].faction == faction:
			result.append(hero_id)
	return result

## 获取兵种倾向权重（F3）
func get_troop_weight(troop_type: int) -> float:
	if _current_hero == null:
		push_warning("HeroManager.get_troop_weight: 尚未选择武将")
		return WEIGHT_PRIMARY  # 返回基准权重

	var ap: Array[int] = _current_hero.affinity_primary
	if ap.size() > 0 and (troop_type == ap[0] or (ap.size() > 1 and troop_type == ap[1])):
		return WEIGHT_PRIMARY
	elif troop_type == _current_hero.affinity_secondary:
		return WEIGHT_SECONDARY
	else:
		return WEIGHT_NON_AFFINITY


## 获取指定武将的兵种权重（Story 002 AC-1）
func get_troop_weights(hero_id: String) -> Dictionary:
	var weights: Dictionary = {
		TroopType.INFANTRY: WEIGHT_NON_AFFINITY,
		TroopType.CAVALRY: WEIGHT_NON_AFFINITY,
		TroopType.ARCHER: WEIGHT_NON_AFFINITY,
		TroopType.STRATEGIST: WEIGHT_NON_AFFINITY,
		TroopType.SHIELD: WEIGHT_NON_AFFINITY
	}

	var hero: HeroData = _hero_table.get(hero_id, null)
	if hero == null:
		push_warning("HeroManager.get_troop_weights: 武将 ID 不存在 — %s" % hero_id)
		return {}  # 返回空字典表示错误

	# 次修权重为1.0
	if hero.affinity_secondary >= 0:
		weights[hero.affinity_secondary] = WEIGHT_SECONDARY

	# 主修权重为2.0
	for troop_type: int in hero.affinity_primary:
		weights[troop_type] = WEIGHT_PRIMARY

	return weights

## 验证兵种卡是否超出统帅上限
func can_add_troop_card(current_troop_count: int) -> bool:
	if _current_hero == null:
		return false
	return current_troop_count < _current_hero.leadership

## 获取当前武将手牌上限
func get_hand_limit() -> int:
	if _current_hero == null:
		return 5
	return _current_hero.hand_limit

## 查询当前武将是否禁止获得护甲（典韦被动）
func is_armor_disabled() -> bool:
	if _current_hero == null:
		return false
	return _current_hero.no_armor

## 查询当前武将是否护盾无上限（张角被动）
func has_unlimited_armor() -> bool:
	if _current_hero == null:
		return false
	return _current_hero.unlimited_armor

## 获取当前武将的护盾上限（Story 003 AC3-AC5）
func get_armor_max() -> int:
	if _current_hero == null:
		return 50  # 默认值

	# 曹仁：护盾上限 = MaxHP + 30
	if _current_hero_id == "cao_ren":
		return _current_hero.max_hp + 30

	# 典韦：禁止护甲
	if _current_hero.no_armor:
		return 0

	# 张角：无上限（返回 -1 表示无上限）
	if _current_hero.unlimited_armor:
		return -1

	# 默认：护盾上限 = MaxHP
	return _current_hero.max_hp

## 获取当前武将被动技能 ID
func get_passive_id() -> String:
	if _current_hero == null:
		return ""
	return _current_hero.passive_id

## 获取当前武将中文名
func get_hero_name_zh() -> String:
	if _current_hero == null:
		return ""
	return _current_hero.name_zh


# ===========================================================================
# 专属卡组与生涯地图接口 (Story 004)
# ===========================================================================

## 获取武将的专属卡组（Story 004 AC-1）
func get_exclusive_deck(hero_id: String) -> Array[String]:
	var hero: HeroData = _hero_table.get(hero_id, null)
	if hero == null:
		push_warning("HeroManager.get_exclusive_deck: 武将 ID 不存在 — %s" % hero_id)
		return []
	return hero.exclusive_deck


## 获取当前武将的专属卡组
func get_current_exclusive_deck() -> Array[String]:
	if _current_hero == null:
		return []
	return _current_hero.exclusive_deck


## 获取武将的生涯地图（Story 004 AC-2）
func get_career_maps(hero_id: String) -> Array[String]:
	var hero: HeroData = _hero_table.get(hero_id, null)
	if hero == null:
		push_warning("HeroManager.get_career_maps: 武将 ID 不存在 — %s" % hero_id)
		return []
	return hero.career_maps


# ===========================================================================
# 私有工具方法
# ===========================================================================

## 将 CSV 字符串解析为 Faction 枚举值
func _parse_faction(raw: String) -> int:
	match raw.to_lower():
		"wei":    return Faction.WEI
		"shu":    return Faction.SHU
		"wu":     return Faction.WU
		"others": return Faction.OTHERS
		_:
			push_warning("HeroManager: 未知阵营 '%s'，默认 OTHERS" % raw)
			return Faction.OTHERS

## 将 CSV 字符串解析为 TroopType 枚举值
func _parse_troop_type(raw: String) -> int:
	match raw.to_lower():
		"infantry":   return TroopType.INFANTRY
		"cavalry":    return TroopType.CAVALRY
		"archer":     return TroopType.ARCHER
		"strategist": return TroopType.STRATEGIST
		"shield":     return TroopType.SHIELD
		_:
			push_warning("HeroManager: 未知兵种 '%s'，默认 INFANTRY" % raw)
			return TroopType.INFANTRY