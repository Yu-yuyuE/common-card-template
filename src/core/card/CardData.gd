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

# 卡牌伤害配置（数据驱动，按等级索引：[等级1伤害, 等级2伤害]）
# 例：[6, 8] 表示等级 1 伤害为 6，等级 2 伤害为 8
@export var damage_by_level: Array[int] = []

# 卡牌行动参数系统（ADR-0020）
@export var card_action_str: String = ""   # 模板字符串形式的行动参数
@export var card_action_func: bool = false # 是否使用特殊处理函数（复杂效果用代码实现）

enum CardType {
	RANGED_ATTACK = 0, # 远程攻击
	MELEE_ATTACK = 1, # 近战攻击
	SKILL = 2, # 技能
	TROOP = 3, # 兵种
	CURSE = 4, # 诅咒
}

enum CardStateCategory {
	INITIAL_COMMON = 0, # 初始通用
	LOCKED_COMMON = 1, # 待解锁通用
	JINGZHOU_SP = 2, # 荆州专属
	XUZHOU_SP = 3, # 徐州专属
	BINGZHOU_SP = 4, # 并州专属
	SIZHOU_SP = 5, # 司州专属
	JIAOZHOU_SP = 6, # 交州专属
	YANGZHOU_SP = 7, # 扬州专属
	JIZHOU_SP = 8, # 冀州专属
	YANZHOU_SP = 9, # 兖州专属
	QINGZHOU_SP = 10, # 青州专属
	YIZHOU_SP = 11, # 益州专属
	LIANGZHOU_SP = 12, # 凉州专属
	YOUZHOU_SP = 13, # 幽州专属
	YUZHOU_SP = 14, # 豫州专属
}

func _init(p_id: String = "", p_cost: int = 1, p_remove: bool = false, p_exhaust: bool = false) -> void:
	id = p_id
	cost = p_cost
	remove_after_use = p_remove
	exhaust = p_exhaust
