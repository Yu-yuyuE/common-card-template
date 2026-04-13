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
	var exclusive_deck: Array[String] ## 专属卡组 ID 列表
	var career_maps: Array[String]    ## 生涯地图 ID 列表

	func _init() -> void:
		affinity_primary = []
		exclusive_deck = []
		career_maps = []

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
	# This method has been DEPRECATED. All passive skills are now handled by PassiveSkillManager.
	# DO NOT use this. It is here only for backward compatibility during migration.
	pass


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

