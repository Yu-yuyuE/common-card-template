## HeroManager.gd
## 武将系统（D3）——武将数据与属性管理核心
##
## 职责：加载和管理武将数据，提供武将属性查询接口
## 位置：作为GameState的父节点
##
## 设计文档：design/gdd/heroes-design.md
## 依赖：
##   - ResourceManager（提供HP/行动点基础值）
##
## 使用示例：
##   var hero_mgr := HeroManager.new()
##   hero_mgr.load_hero_data()
##   var max_hp := hero_mgr.get_max_hp("曹操")
##   var base_ap := hero_mgr.get_base_ap("曹操")

class_name HeroManager extends Node

# ---------------------------------------------------------------------------
# 武将数据结构
# ---------------------------------------------------------------------------

## 武将属性数据
## 通过CSV加载
struct HeroData:
	var id: int
	var name: String
	var faction: String
	var max_hp: int
	var base_ap: int
	var armor_max: int
	var special_attribute: String

# ---------------------------------------------------------------------------
# 内部状态
# ---------------------------------------------------------------------------

## 武将数据字典
var _heroes: Dictionary = {}  # name -> HeroData

## 武将专属卡组数据字典
var _exclusive_decks: Dictionary = {}  # hero_name -> Array[CardData]

## 武将被动技能数据字典
var _passive_skills: Dictionary = {}  # hero_name -> Array[PassiveSkill]

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 初始化时加载武将数据
func _ready() -> void:
	_load_hero_attributes()
	_load_exclusive_decks()
	_load_passive_skills()


## 从CSV文件加载武将基础属性
func _load_hero_attributes() -> void:
	var file_path := "res://assets/csv_data/heroes_attributes.csv"

	if not FileAccess.file_exists(file_path):
		push_error("HeroManager: 武将属性文件未找到 — %s" % file_path)
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("HeroManager: 无法打开武将属性文件 — %s" % file_path)
		return

	# 跳过标题行
	var header_line := file.get_line()

	var loaded_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		# 跳过空行
		if line.is_empty():
			continue

		var fields: PackedStringArray = line.split(",")
		if fields.size() < 6:
			push_warning("HeroManager: 武将属性行字段数不足，跳过 — [%s]" % line)
			continue

		# 解析字段
		var id: int = fields[0].strip_edges().to_int()
		var name: String = fields[1].strip_edges()
		var faction: String = fields[2].strip_edges()
		var max_hp: int = fields[3].strip_edges().to_int()
		var base_ap: int = fields[4].strip_edges().to_int()
		var armor_max: int = fields[5].strip_edges().to_int()
		var special_attribute: String = fields[6].strip_edges()

		# 创建武将数据
		var hero_data := HeroData.new()
		hero_data.id = id
		hero_data.name = name
		hero_data.faction = faction
		hero_data.max_hp = max_hp
		hero_data.base_ap = base_ap
		hero_data.armor_max = armor_max
		hero_data.special_attribute = special_attribute

		# 存入字典
		_heroes[name] = hero_data
		loaded_count += 1

	file.close()
	print("HeroManager: 加载了 %d 个武将属性" % loaded_count)


## 从CSV文件加载武将专属卡组
func _load_exclusive_decks() -> void:
	var file_path := "res://assets/csv_data/heroes_exclusive_decks.csv"

	if not FileAccess.file_exists(file_path):
		push_error("HeroManager: 武将专属卡组文件未找到 — %s" % file_path)
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("HeroManager: 无法打开武将专属卡组文件 — %s" % file_path)
		return

	# 跳过标题行
	var header_line := file.get_line()

	var loaded_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		# 跳过空行
		if line.is_empty():
			continue

		var fields: PackedStringArray = line.split(",")
		if fields.size() < 8:
			push_warning("HeroManager: 武将专属卡组行字段数不足，跳过 — [%s]" % line)
			continue

		# 解析字段
		var id: int = fields[0].strip_edges().to_int()
		var hero_name: String = fields[1].strip_edges()
		var faction: String = fields[2].strip_edges()
		var type: String = fields[3].strip_edges()
		var card_name: String = fields[4].strip_edges()
		var cost_lv1: int = fields[5].strip_edges().to_int()
		var cost_lv2: int = fields[6].strip_edges().to_int()
		var lv1_effect: String = fields[7].strip_edges()
		var lv2_effect: String = ""
		var remove_lv1: bool = false
		var remove_lv2: bool = false

		# 读取LV2效果
		if fields.size() > 8:
			lv2_effect = fields[8].strip_edges()

		# 读取使用后是否移除
		if fields.size() > 9:
			var remove_str: String = fields[9].strip_edges()
			var remove_parts: PackedStringArray = remove_str.split("/")
			if remove_parts.size() >= 1:
				remove_lv1 = remove_parts[0].to_lower() == "是"
			if remove_parts.size() >= 2:
				remove_lv2 = remove_parts[1].to_lower() == "是"

		# 创建卡数据（这里简化，实际应创建CardData对象）
		# 为简化，我们只记录信息，由CardManager处理具体卡牌
		if not _exclusive_decks.has(hero_name):
			_exclusive_decks[hero_name] = []

		# 这里只是占位，实际实现需要创建CardData对象
		# _exclusive_decks[hero_name].append(CardData.new(...))

		loaded_count += 1

	file.close()
	print("HeroManager: 加载了 %d 张武将专属卡牌" % loaded_count)


## 从CSV文件加载武将被动技能
func _load_passive_skills() -> void:
	var file_path := "res://assets/csv_data/heroes_passive_skills.csv"

	if not FileAccess.file_exists(file_path):
		push_error("HeroManager: 武将被动技能文件未找到 — %s" % file_path)
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("HeroManager: 无法打开武将被动技能文件 — %s" % file_path)
		return

	# 跳过标题行
	var header_line := file.get_line()

	var loaded_count: int = 0

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		# 跳过空行
		if line.is_empty():
			continue

		var fields: PackedStringArray = line.split(",")
		if fields.size() < 4:
			push_warning("HeroManager: 武将被动技能行字段数不足，跳过 — [%s]" % line)
			continue

		# 解析字段
		var id: int = fields[0].strip_edges().to_int()
		var hero_name: String = fields[1].strip_edges()
		var faction: String = fields[2].strip_edges()
		var skill_name: String = fields[3].strip_edges()
		var skill_effect: String = ""

		if fields.size() > 4:
			skill_effect = fields[4].strip_edges()

		# 创建被动技能数据
		if not _passive_skills.has(hero_name):
			_passive_skills[hero_name] = []

		# 这里只是占位，实际实现需要创建PassiveSkill对象
		# _passive_skills[hero_name].append(PassiveSkill.new(skill_name, skill_effect))

		loaded_count += 1

	file.close()
	print("HeroManager: 加载了 %d 个武将被动技能" % loaded_count)


# ---------------------------------------------------------------------------
# 查询接口
# ---------------------------------------------------------------------------

## 获取武将的最大HP
func get_max_hp(hero_name: String) -> int:
	if _heroes.has(hero_name):
		return _heroes[hero_name].max_hp
	else:
		push_warning("HeroManager: 未找到武将 %s 的数据，返回默认值50" % hero_name)
		return 50


## 获取武将的基础行动点
func get_base_ap(hero_name: String) -> int:
	if _heroes.has(hero_name):
		return _heroes[hero_name].base_ap
	else:
		push_warning("HeroManager: 未找到武将 %s 的数据，返回默认值4" % hero_name)
		return 4


## 获取武将的护盾上限
func get_armor_max(hero_name: String) -> int:
	if _heroes.has(hero_name):
		return _heroes[hero_name].armor_max
	else:
		push_warning("HeroManager: 未找到武将 %s 的数据，返回默认值0" % hero_name)
		return 0


## 获取武将的阵营
func get_faction(hero_name: String) -> String:
	if _heroes.has(hero_name):
		return _heroes[hero_name].faction
	else:
		push_warning("HeroManager: 未找到武将 %s 的数据，返回默认值" % hero_name)
		return ""


## 获取武将的特殊属性
func get_special_attribute(hero_name: String) -> String:
	if _heroes.has(hero_name):
		return _heroes[hero_name].special_attribute
	else:
		push_warning("HeroManager: 未找到武将 %s 的数据，返回空字符串" % hero_name)
		return ""


## 获取武将是否是袁绍（特殊处理）
func is_yuan_shao(hero_name: String) -> bool:
	return hero_name == "袁绍"


## 获取所有武将名称
func get_all_hero_names() -> Array:
	return _heroes.keys()


## 获取指定阵营的所有武将
func get_heroes_by_faction(faction: String) -> Array:
	var result: Array = []
	for name in _heroes.keys():
		if _heroes[name].faction == faction:
			result.append(name)
	return result


## 检查武将是否存在
func has_hero(hero_name: String) -> bool:
	return _heroes.has(hero_name)


## 获取武将的专属卡组
func get_exclusive_deck(hero_name: String) -> Array:
	if _exclusive_decks.has(hero_name):
		return _exclusive_decks[hero_name]
	return []


## 获取武将的被动技能
func get_passive_skills(hero_name: String) -> Array:
	if _passive_skills.has(hero_name):
		return _passive_skills[hero_name]
	return []