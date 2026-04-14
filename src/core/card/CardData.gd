## 卡牌数据类（Resource）
## 存储卡牌的静态配置数据，不随战斗状态变化。
class_name CardData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var cost: int = 1
@export var type: int = 0 # 0: 攻击, 1: 技能, 2: 状态, 3: 诅咒
@export var description: String = ""

# 卡牌流转规则控制
@export var remove_after_use: bool = false # 打出后移入移除区 (Removed)
@export var exhaust: bool = false          # 打出后移入消耗区 (Exhaust)

# 卡牌行动参数系统（ADR-0020）
@export var card_action_str: String = ""   # 模板字符串形式的行动参数
@export var card_action_func: bool = false # 是否使用特殊处理函数（复杂效果用代码实现）

enum CardStateCategory {
	INITIAL_COMMON,  # 初始通用
	LOCKED_COMMON, # 待开启通用
	JINGZHOU_SP,     # 荆州
	YANGZHOU_SP,  # 扬州
	XUZHOU_SP,      # 徐州
	SIZHOU_SP,      # 司州
	JIAOZHOU_SP,      # 交州
	JIZHOU_SP,      # 冀州
	BINGZHOU_SP,      # 并州
	YANZHOU_SP,      # 兖州
	QINGZHOU_SP,      # 青州
	LIANGZHOU_SP,      # 凉州
	YINAN_SP,      # 益州
	YUZHOU_SP,     # 豫州
	YOUZHOU_SP     # 幽州
}

enum CardType {
	RANGED_ATTACK,  # 远程攻击
	MELEE_ATTACK,		# 近战攻击
	SKILL,    			# 技能
	TROOP,		# 兵种
	CURSE				# 诅咒
}

func _init(p_id: String = "", p_cost: int = 1, p_remove: bool = false, p_exhaust: bool = false) -> void:
	id = p_id
	cost = p_cost
	remove_after_use = p_remove
	exhaust = p_exhaust
