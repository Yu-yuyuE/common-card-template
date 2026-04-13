## StatusEffect.gd
## 状态效果系统（C1）——状态枚举与数据结构定义
##
## 职责：定义游戏中所有状态的类型、元数据与实例数据结构。
## 本文件只做数据定义，不含任何运行时逻辑。
##
## 设计文档：design/gdd/status-design.md
## 依赖：无（纯数据层）
##
## 使用示例：
##   var effect := StatusEffect.make(StatusEffect.Type.POISON, 3, "毒蛇卡")
##   print(effect.layers)  # => 3

class_name StatusEffect extends RefCounted

# ---------------------------------------------------------------------------
# 状态类型枚举
# 编号对应设计文档 B1-B7（Buff）与 D1-D13（Debuff）
# ---------------------------------------------------------------------------

## 全部状态枚举值
enum Type {
	NONE         = -1,  ## 无效状态（用于错误处理）

	# ---- 正面状态（Buff） ----
	FURY         = 0,   ## B1 怒气：攻击伤害 +25%
	AGILITY      = 1,   ## B2 迅捷：50% 概率闪避
	BLOCK        = 2,   ## B3 格挡：抵挡一次攻击（消耗型）
	DEFEND       = 3,   ## B4 坚守：受到伤害 -25%
	COUNTER      = 4,   ## B5 反击：受到攻击时反击50%（消耗型）
	PIERCE       = 5,   ## B6 穿透：无视护甲攻击（消耗型）
	IMMUNE       = 6,   ## B7 免疫：免疫所有负面状态

	# ---- 负面状态（Debuff） ----
	POISON       = 10,  ## D1 中毒：每回合 4 穿透伤害
	TOXIC        = 11,  ## D2 剧毒：每回合 7 穿透伤害；覆盖中毒时合并层数
	FEAR         = 12,  ## D3 恐惧：受到额外攻击伤害 = 恐惧层数
	CONFUSION    = 13,  ## D4 混乱：下次攻击命中友军（消耗型）
	BLIND        = 14,  ## D5 盲目：攻击命中率 50%
	SLIP         = 15,  ## D6 滑倒：无法使用攻击卡
	ARMOR_BREAK  = 16,  ## D7 破甲：受到攻击伤害 +25%
	WEAKEN       = 17,  ## D8 虚弱：攻击伤害 -25%
	BURN         = 18,  ## D9 灼烧：每回合 5 走护盾伤害
	PLAGUE       = 19,  ## D10 瘟疫：每回合 2 穿透伤害；回合末传播1层至相邻单位
	STUN         = 20,  ## D11 眩晕：停止行动；受到攻击时消失
	WOUND        = 21,  ## D12 重伤：每回合 1×层 穿透伤害（叠加型）
	FROSTBITE    = 22,  ## D13 冻伤：每次出牌 HP -1
	BLEEDING     = 23,  ## D14 流血：受到治疗量 -50%
	RUSTY        = 24,  ## D15 腐蚀：受到护盾值 -50%
}

# ---------------------------------------------------------------------------
# 强度等级枚举
# 影响施加规则说明（不由 StatusEffect 自身强制，由调用方参考）
# ---------------------------------------------------------------------------

## 状态强度等级（参考设计文档 §1 状态强度说明）
enum Intensity {
	NORMAL  = 0,  ## 普通：建议施加 5–10 层
	MEDIUM  = 1,  ## 中等：建议施加 2–4 层
	STRONG  = 2,  ## 强力：建议施加 1–2 层
}

# ---------------------------------------------------------------------------
# 衰减机制枚举
# ---------------------------------------------------------------------------

## 状态持续/消耗机制
enum DecayMode {
	PER_ROUND = 0,  ## 每回合末层数 -1，归零后自动移除
	CONSUME   = 1,  ## 触发时消耗1层，归零后自动移除
}

# ---------------------------------------------------------------------------
# 状态元数据——每种 Type 对应一条只读记录
# 通过 StatusEffect.get_status_meta(type) 查询
# ---------------------------------------------------------------------------

## 单条状态元数据
class Meta:
	var type       : Type        ## 状态类型
	var label      : String      ## 显示名称（中文）
	var is_buff    : bool        ## true = 正面状态，false = 负面状态
	var decay_mode : DecayMode   ## 衰减机制
	var intensity  : Intensity   ## 强度等级
	## 每回合基础伤害值（无伤害型为 0）
	var dot_base_damage : int = 0
	## true = 伤害随层数增长（重伤）；false = 固定伤害（中毒等）
	var dot_layers_multiply : bool = false
	## true = 走护盾（灼烧）；false = 穿透护盾（中毒等）
	var dot_uses_armor : bool = false

	func _init(
		p_type: Type,
		p_label: String,
		p_is_buff: bool,
		p_decay: DecayMode,
		p_intensity: Intensity,
		p_dot: int = 0,
		p_multiply: bool = false,
		p_armor: bool = false
	) -> void:
		type                = p_type
		label               = p_label
		is_buff             = p_is_buff
		decay_mode          = p_decay
		intensity           = p_intensity
		dot_base_damage     = p_dot
		dot_layers_multiply = p_multiply
		dot_uses_armor      = p_armor


# 全局元数据表（静态只读，程序启动后不修改）
static var _META_TABLE: Dictionary = {}  # Type -> Meta

## 返回指定状态类型的元数据。
## 示例：
##   var meta := StatusEffect.get_status_meta(StatusEffect.Type.POISON)
##   print(meta.label)  # => "中毒"
static func get_status_meta(p_type: Type) -> Meta:
	_ensure_meta_table()
	return _META_TABLE[p_type] as Meta


## 返回该类型是否为正面状态（Buff）。
static func is_buff(p_type: Type) -> bool:
	return get_status_meta(p_type).is_buff


static func is_debuff(p_type: Type) -> bool:
	return not get_status_meta(p_type).is_buff


# ---------------------------------------------------------------------------
# 实例字段——运行时单个状态实例
# 通过 StatusEffect.make() 工厂方法创建
# ---------------------------------------------------------------------------

## 状态类型
var type   : Type   = Type.POISON
## 当前层数（≥ 1；降为 0 时由 StatusManager 自动移除）
var layers : int    = 0
## 施加来源描述（卡牌名 / 武将名 / 地形名），用于战斗日志
var source : String = ""

# ---------------------------------------------------------------------------
# 工厂方法
# ---------------------------------------------------------------------------

## 创建一个新的状态实例。
##
## 参数：
##   p_type   — 状态类型（StatusEffect.Type 枚举值）
##   p_layers — 初始层数（必须 ≥ 1）
##   p_source — 来源描述，用于日志追溯（如 "毒箭卡"）
##
## 示例：
##   var s := StatusEffect.make(StatusEffect.Type.BURN, 2, "火攻卡")
static func make(p_type: Type, p_layers: int, p_source: String = "") -> StatusEffect:
	assert(p_layers >= 1, "状态层数必须 >= 1")
	var s     := StatusEffect.new()
	s.type    = p_type
	s.layers  = p_layers
	s.source  = p_source
	return s


# ---------------------------------------------------------------------------
# 元数据表初始化（仅执行一次）
# ---------------------------------------------------------------------------

static func _ensure_meta_table() -> void:
	if not _META_TABLE.is_empty():
		return
	_build_meta_table()


static func _build_meta_table() -> void:
	# 格式：Meta.new(Type, 名称, is_buff, decay, intensity, dot_base_damage, dot_layers_multiply, dot_uses_armor)
	var entries: Array[Meta] = [
		# ---- Buff ----
		Meta.new(Type.FURY,        "怒气", true,  DecayMode.PER_ROUND, Intensity.MEDIUM),
		Meta.new(Type.AGILITY,     "迅捷", true,  DecayMode.PER_ROUND, Intensity.MEDIUM),
		Meta.new(Type.BLOCK,       "格挡", true,  DecayMode.CONSUME,   Intensity.MEDIUM),
		Meta.new(Type.DEFEND,      "坚守", true,  DecayMode.PER_ROUND, Intensity.STRONG),
		Meta.new(Type.COUNTER,     "反击", true,  DecayMode.CONSUME,   Intensity.MEDIUM),
		Meta.new(Type.PIERCE,      "穿透", true,  DecayMode.CONSUME,   Intensity.MEDIUM),
		Meta.new(Type.IMMUNE,      "免疫", true,  DecayMode.PER_ROUND, Intensity.STRONG),
		# ---- Debuff ----
		Meta.new(Type.POISON,      "中毒", false, DecayMode.PER_ROUND, Intensity.MEDIUM, 4, false, false),
		Meta.new(Type.TOXIC,       "剧毒", false, DecayMode.PER_ROUND, Intensity.STRONG, 7, false, false),
		Meta.new(Type.FEAR,        "恐惧", false, DecayMode.PER_ROUND, Intensity.NORMAL, 0, false, false),
		Meta.new(Type.CONFUSION,   "混乱", false, DecayMode.CONSUME,   Intensity.STRONG, 0, false, false),
		Meta.new(Type.BLIND,       "盲目", false, DecayMode.PER_ROUND, Intensity.MEDIUM, 0, false, false),
		Meta.new(Type.SLIP,        "滑倒", false, DecayMode.PER_ROUND, Intensity.STRONG, 0, false, false),
		Meta.new(Type.ARMOR_BREAK, "破甲", false, DecayMode.PER_ROUND, Intensity.MEDIUM, 0, false, false),
		Meta.new(Type.WEAKEN,      "虚弱", false, DecayMode.PER_ROUND, Intensity.MEDIUM, 0, false, false),
		Meta.new(Type.BURN,        "灼烧", false, DecayMode.PER_ROUND, Intensity.MEDIUM, 5, false, true),
		Meta.new(Type.PLAGUE,      "瘟疫", false, DecayMode.PER_ROUND, Intensity.STRONG, 2, false, false),
		Meta.new(Type.STUN,        "眩晕", false, DecayMode.PER_ROUND, Intensity.STRONG, 0, false, false),
		Meta.new(Type.WOUND,       "重伤", false, DecayMode.PER_ROUND, Intensity.NORMAL, 1, true, false),
		Meta.new(Type.FROSTBITE,   "冻伤", false, DecayMode.PER_ROUND, Intensity.NORMAL, 0, false, false),
		Meta.new(Type.BLEEDING,    "流血", false, DecayMode.PER_ROUND, Intensity.MEDIUM, 0, false, false),
		Meta.new(Type.RUSTY,       "生锈", false, DecayMode.PER_ROUND, Intensity.MEDIUM, 0, false, false),
	]
	for m: Meta in entries:
		_META_TABLE[m.type] = m
