## EnemyAction.gd
## 敌人行动数据类（C3 - 敌人系统）
## 存储单个敌人行动的静态配置数据
## 依据 design/gdd/enemies-design.md
## 作者: Claude Code
## 创建日期: 2026-04-11

class_name EnemyAction extends RefCounted

## 行动类型枚举
enum ActionType {
	ATTACK,          ## 攻击
	DEFEND,          ## 防御
	BUFF_SELF,       ## 强化自身
	DEBUFF_PLAYER,   ## 减益玩家
	HEAL,            ## 治疗
	SPECIAL,         ## 特殊行动
	CURSE,           ## 诅咒投递
	SUMMON           ## 召唤
}

## 目标类型枚举
enum TargetType {
	PLAYER,          ## 玩家主将
	SELF,            ## 自身
	RANDOM_ALLY,     ## 随机友军
	ALL_ALLIES,      ## 所有友军
	PLAYER_CARD      ## 玩家卡牌
}

## 行动唯一标识（如 "A01", "B02", "C16"）
var id: String

## 行动名称
var name: String

## 行动级别（普通/精英/强力）
var tier: String

## 行动类型
var type: String  # "attack", "defend", "buff", "debuff", "heal", "special", "curse", "summon"

## 目标
var target: String  # "player", "self", "random_ally", "all_allies"

## 效果描述
var description: String

## 数值参考（如 "6~10", "护甲+6~10", "中毒×2层"）
var value_reference: String

## 冷却回合
var cooldown: int = 0

## 条件触发（如 "HP<50%", "回合数>3"）
var condition: String = ""

## 是否带蓄力
var is_charging: bool = false

## 施加的状态效果
var status_effect: String = ""

## 状态层数
var status_layers: int = 0

## 伤害值（解析后）
var damage: int = 0

## 护甲值（解析后）
var armor: int = 0

## 治疗值（解析后）
var heal: int = 0

## 诅咒ID（如果类型是 curse）
var curse_id: String = ""

## 召唤敌人ID（如果类型是 summon）
var summon_id: String = ""

## 执行该行动的敌人ID（运行时设置）
var source_enemy_id: String = ""

## 敌人管理器引用（用于访问action_params）
var enemy_manager: EnemyManager = null

## 敌人数据引用（用于访问action_params）
var enemy_data: EnemyData = null

## 动画名称（用于播放动画）
var animation: String = ""

## 初始化函数
func _init(
	p_id: String,
	p_name: String,
	p_tier: String,
	p_type: String,
	p_target: String,
	p_description: String,
	p_value_reference: String,
	p_cooldown: int = 0,
	p_condition: String = ""
) -> void:
	id = p_id
	name = p_name
	tier = p_tier
	type = p_type
	target = p_target
	description = p_description
	value_reference = p_value_reference
	cooldown = p_cooldown
	condition = p_condition

	# 解析数值参考字段
	_parse_value_reference()


## 解析数值参考字段，提取伤害、护甲、治疗、状态等数值
func _parse_value_reference() -> void:
	# 如果数值参考为空或"—"，跳过解析
	if value_reference.is_empty() or value_reference == "—":
		return

	# 检查是否有敌人特定的参数覆盖
	if enemy_data != null and enemy_data.action_params.has(id):
		var override = enemy_data.action_params[id]

		# 应用目标覆盖
		if override.has("target"):
			target = override["target"]

		# 应用伤害覆盖
		if override.has("damage"):
			damage = _to_int(override["damage"])

		# 应用伤害次数覆盖
		if override.has("damage_count"):
			# 在 ActionExecutor 中处理
			pass

		# 应用护甲覆盖
		if override.has("armor"):
			armor = _to_int(override["armor"])

		# 应用治疗覆盖
		if override.has("heal"):
			heal = _to_int(override["heal"])

		# 应用状态层数覆盖
		if override.has("status_layers"):
			status_layers = _to_int(override["status_layers"])

		# 应用状态ID覆盖
		if override.has("status_id"):
			# 在 ActionExecutor 中处理
			pass

		# 应用冷却覆盖
		if override.has("cooldown"):
			cooldown = _to_int(override["cooldown"])

		# 应用偷取金币覆盖
		if override.has("gold_steal"):
			# 在 ActionExecutor 中处理
			pass

		# 应用偷取卡牌数量覆盖
		if override.has("card_steal"):
			# 在 ActionExecutor 中处理
			pass

		# 应用诅咒卡数量覆盖
		if override.has("curse_count"):
			# 在 ActionExecutor 中处理
			pass

		# 应用诅咒卡ID覆盖
		if override.has("curse_card_id"):
			# 在 ActionExecutor 中处理
			pass

		# 应用召唤数量覆盖
		if override.has("summon_count"):
			# 在 ActionExecutor 中处理
			pass

		# 应用召唤敌人ID覆盖
		if override.has("summon_enemy_id"):
			# 在 ActionExecutor 中处理
			pass

		# 应用移动方向覆盖
		if override.has("move_direction"):
			# 在 ActionExecutor 中处理
			pass

		# 应用天气改变覆盖
		if override.has("weather"):
			# 在 ActionExecutor 中处理
			pass

		# 如果有覆盖参数，跳过原始解析
		if not override.is_empty():
			return

	# 示例值参考格式：
	# - "6~10" → 伤害范围
	# - "护甲+6~10" → 护甲增加
	# - "中毒×2层" → 施加状态
	# - "伤害4~6+盲目×1" → 伤害+状态
	# - "回血4~8" → 治疗值
	# - "偷取3~8金" → 偷取金币

	# 解析伤害值
	if "伤害" in value_reference or type == "attack":
		# 提取数字范围
		var damage_match = _extract_number_range(value_reference)
		if damage_match > 0:
			damage = damage_match

	# 解析护甲值
	if "护甲" in value_reference or type == "defend":
		var armor_match = _extract_number_range(value_reference)
		if armor_match > 0:
			armor = armor_match

	# 解析治疗值
	if "回血" in value_reference or type == "heal":
		var heal_match = _extract_number_range(value_reference)
		if heal_match > 0:
			heal = heal_match

	# 解析状态效果
	if "×" in value_reference:
		# 格式：状态名×层数
		var status_parts = value_reference.split("×")
		if status_parts.size() >= 2:
			var status_name = status_parts[0].strip_edges()
			# 提取状态名称（移除可能的数字前缀）
			status_effect = status_name
			# 提取层数
			var layers_str = status_parts[1].strip_edges()
			if "层" in layers_str:
				layers_str = layers_str.replace("层", "")
			status_layers = layers_str.to_int()

	# 检查是否蓄力
	if "charge" in type.to_lower() or "蓄力" in description or "蓄力" in value_reference or "charge" in value_reference.to_lower():
		is_charging = true


## 从字符串中提取数字范围的中值
func _extract_number_range(text: String) -> int:
	# 查找所有数字
	var regex = RegEx.new()
	regex.compile("\\d+")
	var matches = regex.search_all(text)

	if matches.is_empty():
		return 0

	# 如果只有一个数字，返回它
	if matches.size() == 1:
		return matches[0].get_string().to_int()

	# 如果有两个数字（范围），返回中值
	if matches.size() >= 2:
		var min_val = matches[0].get_string().to_int()
		var max_val = matches[1].get_string().to_int()
		return (min_val + max_val) / 2

	return 0


## 获取行动类型枚举值
func get_action_type() -> int:
	match type.to_lower():
		"attack": return ActionType.ATTACK
		"defend": return ActionType.DEFEND
		"buff": return ActionType.BUFF_SELF
		"debuff": return ActionType.DEBUFF_PLAYER
		"heal": return ActionType.HEAL
		"special": return ActionType.SPECIAL
		"curse": return ActionType.CURSE
		"summon": return ActionType.SUMMON
		_: return ActionType.ATTACK


## 获取目标类型枚举值
func get_target_type() -> int:
	match target.to_lower():
		"player", "玩家主将", "tr_target_player": return TargetType.PLAYER
		"self", "自身", "tr_target_self": return TargetType.SELF
		"random_ally", "随机友军", "tr_target_random_ally": return TargetType.RANDOM_ALLY
		"all_allies", "所有友军", "tr_target_all_allies": return TargetType.ALL_ALLIES
		"player_card", "玩家卡牌", "tr_target_player_card": return TargetType.PLAYER_CARD
		_: return TargetType.PLAYER


## 将值转换为整数（支持int和float）
func _to_int(value) -> int:
	if value is int:
		return value
	elif value is float:
		return int(value)
	elif value is String:
		return value.to_int()
	else:
		return 0
