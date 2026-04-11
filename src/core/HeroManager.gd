## HeroManager.gd
## 武将管理器（D3 — Hero System）
##
## 职责：
##   - 从 CSV 数据文件加载全部武将配置
##   - 持有当前选中武将的基础属性，供 ResourceManager / BattleManager 读取
##   - 提供兵种倾向权重查询接口（F3）
##   - 提供被动技能 ID 查询接口（供 PassiveSkillSystem 订阅注册）
##
## 系统边界（依据 design/gdd/heroes-design.md）：
##   本系统「不负责」状态施加、战斗流程、地图节点生成。
##   本系统仅初始化数值 + 提供查询接口。
##
## 数据来源：design/detail/heroes.csv
## 设计文档：design/gdd/heroes-design.md
## 依赖：ResourceManager（读取 max_hp / base_ap）

class_name HeroManager extends Node

# ---------------------------------------------------------------------------
# 枚举
# ---------------------------------------------------------------------------

## 兵种类型
enum TroopType {
	INFANTRY  = 0, ## 步兵
	CAVALRY   = 1, ## 骑兵
	ARCHER    = 2, ## 弓兵
	STRATEGIST = 3, ## 谋士
	SHIELD    = 4, ## 盾兵
}

## 阵营
enum Faction {
	WEI    = 0, ## 魏
	SHU    = 1, ## 蜀
	WU     = 2, ## 吴
	OTHERS = 3, ## 群雄
}

# ---------------------------------------------------------------------------
# 内部数据结构
# ---------------------------------------------------------------------------

## 武将静态数据（由 CSV 加载，全局只读）
class HeroData:
	var id: String                    ## 唯一标识（snake_case）
	var name_zh: String               ## 中文名
	var faction: int                  ## Faction 枚举值
	var max_hp: int                   ## 最大生命值
	var base_cost: int                ## 每回合基础行动点
	var leadership: int               ## 统帅（兵种卡携带上限，F2）
	var affinity_primary: Array[int]  ## 主修兵种 [TroopType, TroopType]
	var affinity_secondary: int       ## 次修兵种 TroopType
	var exclusive_cards: int          ## 专属卡数量
	var passive_id: String            ## 被动技能 ID
	var hand_limit: int               ## 手牌上限（默认 5，袁绍 6）
	var no_armor: bool                ## 是否禁止获得护甲（典韦）
	var unlimited_armor: bool         ## 护盾上限无上限（张角）

	func _init() -> void:
		affinity_primary = []

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## 武将加载完成时发射（所有静态数据就绪）
signal heroes_loaded(hero_count: int)

## 当前武将变更时发射
signal hero_selected(hero_id: String)

## 被动技能触发时发射（ADR-0010）
## 参数：
##   hero_id      — 触发被动的武将 ID
##   skill_name   — 被动技能名称 / ID
##   effect_result — 效果结果字典（Story 001 存根阶段为空字典）
signal passive_triggered(hero_id: String, skill_name: String, effect_result: Dictionary)

# ---------------------------------------------------------------------------
# 常量
# ---------------------------------------------------------------------------

## 数据文件路径
const DATA_PATH: String = "res://design/detail/heroes.csv"

## 兵种倾向权重（F3）
const WEIGHT_PRIMARY: float   = 2.0  ## 主修
const WEIGHT_SECONDARY: float = 1.0  ## 次修
const WEIGHT_BASE: float      = 1.0  ## 基准（非倾向使用 × 0.5）
const WEIGHT_NON_AFFINITY: float = 0.5 ## 非倾向

# ---------------------------------------------------------------------------
# 公共属性（由 ResourceManager._ready() 通过 get() 读取）
# ---------------------------------------------------------------------------

## 当前武将最大 HP（供 ResourceManager 初始化用）
var max_hp: int = 50

## 当前武将基础行动点（供 ResourceManager 初始化用）
var base_ap: int = 3

# ---------------------------------------------------------------------------
# 私有成员
# ---------------------------------------------------------------------------

## 全量武将数据表：id -> HeroData
var _hero_table: Dictionary = {}

## 当前选中武将 ID
var _current_hero_id: String = ""

## 当前武将数据缓存
var _current_hero: HeroData = null

# ---------------------------------------------------------------------------
# 生命周期
# ---------------------------------------------------------------------------

func _ready() -> void:
	var count: int = _load_heroes_from_csv()
	if count == 0:
		push_error("HeroManager._ready: 武将数据加载失败，加载数量为 0")


# ---------------------------------------------------------------------------
# 数据加载
# ---------------------------------------------------------------------------

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
		data.id               = fields[0].strip_edges().replace("﻿", "") # Clean BOM
		data.name_zh          = fields[1].strip_edges()
		data.faction          = _parse_faction(fields[2].strip_edges())
		data.max_hp           = fields[3].strip_edges().to_int()
		data.base_cost        = fields[4].strip_edges().to_int()
		data.leadership       = fields[5].strip_edges().to_int()

		# M-2：affinity_primary 长度安全检查
		# fields[6] 和 fields[7] 分别对应两个主修兵种槽位；
		# 若某槽为空字符串则跳过追加，避免解析为错误的 TroopType。
		var primary_raw_0: String = fields[6].strip_edges()
		var primary_raw_1: String = fields[7].strip_edges()
		if not primary_raw_0.is_empty():
			data.affinity_primary.append(_parse_troop_type(primary_raw_0))
		if not primary_raw_1.is_empty():
			data.affinity_primary.append(_parse_troop_type(primary_raw_1))

		data.affinity_secondary = _parse_troop_type(fields[8].strip_edges())
		data.exclusive_cards  = fields[9].strip_edges().to_int()
		data.passive_id       = fields[10].strip_edges()

		# m-4：hand_limit 安全回退：若解析结果 <= 0 则强制使用默认值 5
		var parsed_hand_limit: int = fields[11].strip_edges().to_int()
		data.hand_limit = parsed_hand_limit if parsed_hand_limit > 0 else 5

		data.no_armor         = fields[12].strip_edges().to_lower() == "true"
		data.unlimited_armor  = fields[13].strip_edges().to_lower() == "true"

		if data.id.is_empty():
			push_warning("HeroManager: id 为空，跳过一行")
			continue

		_hero_table[data.id] = data
		loaded_count += 1

	file.close()
	heroes_loaded.emit(loaded_count)
	return loaded_count


# ---------------------------------------------------------------------------
# 武将选择
# ---------------------------------------------------------------------------

## 选择当前战役使用的武将。
## 必须在战斗初始化之前调用，ResourceManager 依赖此方法填充的 max_hp / base_ap。
##
## 参数：
##   hero_id — 武将 ID（对应 heroes.csv 的 id 列）
## 返回：
##   true = 选择成功；false = hero_id 不存在
##
## 示例：
##   hero_manager.select_hero("cao_cao")
func select_hero(hero_id: String) -> bool:
	var clean_id: String = hero_id.replace("﻿", "").strip_edges()

	# 仅执行精确匹配（BOM 剥离后），不使用模糊 contains 匹配，
	# 避免 ID 前缀相同时（如 "lu_meng" / "lu_xun"）产生不确定的选择结果。
	var found_id: String = ""
	for key: String in _hero_table:
		if key.strip_edges() == clean_id:
			found_id = key
			break

	if found_id.is_empty():
		push_error("HeroManager: 武将 ID 不存在 — %s" % clean_id)
		return false

	_current_hero_id = found_id
	_current_hero = _hero_table[found_id]

	# 更新 ResourceManager 读取的公共属性
	max_hp  = _current_hero.max_hp
	base_ap = _current_hero.base_cost

	hero_selected.emit(found_id)
	return true


# ---------------------------------------------------------------------------
# 查询接口
# ---------------------------------------------------------------------------

## 获取当前武将数据（只读）。
## 返回：HeroData 或 null（未选武将时）
func get_current_hero() -> HeroData:
	return _current_hero


## 按 ID 获取武将数据（只读）。
## 用于选将界面遍历全量武将。
##
## 示例：
##   var data = hero_manager.get_hero_data("zhang_liao")
func get_hero_data(hero_id: String) -> HeroData:
	return _hero_table.get(hero_id, null)


## 获取全量武将 ID 列表。
##
## 示例：
##   for id in hero_manager.get_all_hero_ids():
##       print(id)
func get_all_hero_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_hero_table.keys())
	return result


## 获取指定阵营的武将 ID 列表。
##
## 参数：faction — Faction 枚举值
##
## 示例：
##   var wei_heroes = hero_manager.get_heroes_by_faction(HeroManager.Faction.WEI)
func get_heroes_by_faction(faction: int) -> Array[String]:
	var result: Array[String] = []
	for hero_id: String in _hero_table:
		if _hero_table[hero_id].faction == faction:
			result.append(hero_id)
	return result

## 获取兵种倾向权重（F3）。
## 供军营节点计算兵种卡出现概率使用。
##
## 参数：troop_type — TroopType 枚举值
## 返回：该兵种的权重倍数（float）
##
## 示例：
##   # 曹操：步兵/骑兵主修，谋士次修 → 步兵权重 2.0
##   var w = hero_manager.get_troop_weight(TroopType.INFANTRY)  # → 2.0
func get_troop_weight(troop_type: int) -> float:
	if _current_hero == null:
		push_warning("HeroManager.get_troop_weight: 尚未选择武将")
		return WEIGHT_BASE

	# C-2：用直接索引比较替换 `in` 运算符，避免热路径上的数组线性扫描分配
	var ap: Array[int] = _current_hero.affinity_primary
	if ap.size() > 0 and (troop_type == ap[0] or (ap.size() > 1 and troop_type == ap[1])):
		return WEIGHT_PRIMARY
	elif troop_type == _current_hero.affinity_secondary:
		return WEIGHT_SECONDARY
	else:
		return WEIGHT_NON_AFFINITY


## 获取指定武将所有兵种的倾向权重字典（ADR-0010 接口要求）。
## 供外部系统（如军营节点）一次性获取完整权重表使用。
##
## 参数：hero_id — 武将 ID
## 返回：Dictionary{ TroopType(int) -> float }；若 hero_id 不存在则返回空字典
##
## 示例：
##   var weights = hero_manager.get_troop_weights("cao_cao")
##   # → { 0: 2.0, 1: 2.0, 2: 0.5, 3: 1.0, 4: 0.5 }
func get_troop_weights(hero_id: String) -> Dictionary:
	var data: HeroData = _hero_table.get(hero_id, null)
	if data == null:
		push_warning("HeroManager.get_troop_weights: 武将 ID 不存在 — %s" % hero_id)
		return {}

	var weights: Dictionary = {}
	var ap: Array[int] = data.affinity_primary

	for troop: int in TroopType.values():
		if ap.size() > 0 and (troop == ap[0] or (ap.size() > 1 and troop == ap[1])):
			weights[troop] = WEIGHT_PRIMARY
		elif troop == data.affinity_secondary:
			weights[troop] = WEIGHT_SECONDARY
		else:
			weights[troop] = WEIGHT_NON_AFFINITY

	return weights


## 验证兵种卡是否超出统帅上限（AC7）。
## 供军营节点"加入卡组"按钮使用。
##
## 参数：current_troop_count — 当前卡组中兵种卡数量
## 返回：true = 可以再加；false = 已达上限
##
## 示例：
##   if not hero_manager.can_add_troop_card(deck.troop_card_count):
##       button.disabled = true
func can_add_troop_card(current_troop_count: int) -> bool:
	if _current_hero == null:
		return false
	return current_troop_count < _current_hero.leadership


## 获取当前武将手牌上限。
## 袁绍为 6，其余为 5（AC 对应 heroes-design.md 群雄 → 袁绍被动）。
##
## 示例：
##   var limit = hero_manager.get_hand_limit()
func get_hand_limit() -> int:
	if _current_hero == null:
		return 5
	return _current_hero.hand_limit


## 查询当前武将是否禁止获得护甲（典韦被动 AC8）。
##
## 示例：
##   if hero_manager.is_armor_disabled():
##       resource_manager.set_armor_max(0)
func is_armor_disabled() -> bool:
	if _current_hero == null:
		return false
	return _current_hero.no_armor


## 查询当前武将是否护盾无上限（张角被动）。
##
## 示例：
##   if hero_manager.has_unlimited_armor():
##       resource_manager.set_armor_max(-1)
func has_unlimited_armor() -> bool:
	if _current_hero == null:
		return false
	return _current_hero.unlimited_armor


## 获取当前武将的护盾上限（Story 003 AC3-AC5）。
##
## 规则：
##   - 曹仁 (cao_ren): max_hp + 30
##   - 张角 (zhang_jiao): -1 (无上限)
##   - 典韦 (dian_wei): 0 (禁止护甲)
##   - 默认: max_hp
##
## 示例：
##   var armor_max = hero_manager.get_armor_max()  # → 50, 80, -1, 或 0
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


## 获取当前武将被动技能 ID，供被动系统注册触发器使用。
##
## 示例：
##   var passive = hero_manager.get_passive_id()  # → "yin_ren"
func get_passive_id() -> String:
	if _current_hero == null:
		return ""
	return _current_hero.passive_id


## 获取当前武将中文名。
##
## 示例：
##   label.text = hero_manager.get_hero_name_zh()  # → "司马懿"
func get_hero_name_zh() -> String:
	if _current_hero == null:
		return ""
	return _current_hero.name_zh


## 触发当前武将的被动技能（ADR-0010 接口要求）。
## Story 001 阶段为存根实现：仅发射 passive_triggered 信号，不执行效果逻辑。
## 完整效果逻辑将在被动技能系统（PassiveSkillSystem）实现后接入。
##
## 参数：
##   trigger_type — 触发类型字符串（如 "on_turn_start"、"on_card_played"）
##   context      — 触发上下文数据（如 { "card_id": "...", "damage": 5 }）
##                  存根阶段暂不消费 context，保留参数供 PassiveSkillSystem 接入时使用。
##
## 示例：
##   hero_manager.trigger_passive("on_turn_start", {})
func trigger_passive(trigger_type: String, _context: Dictionary) -> void:
	if _current_hero == null:
		push_warning("HeroManager.trigger_passive: 尚未选择武将，触发类型 — %s" % trigger_type)
		return

	# 存根：直接发射信号，effect_result 留空待 PassiveSkillSystem 实现后填充
	passive_triggered.emit(_current_hero_id, _current_hero.passive_id, {})


# ---------------------------------------------------------------------------
# 私有工具方法
# ---------------------------------------------------------------------------

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
