## CurseCardData.gd
## 诅咒卡数据结构
##
## 职责：定义诅咒卡的数据结构，包括三种诅咒类型及其属性
## 位置：作为CardData的子类，由CurseManager管理
##
## 设计文档：design/gdd/curse-system-design.md
## 依赖：
##   - CardData（卡牌基础数据）
##
## 使用示例：
##   var curse_data = CurseCardData.new("CC0001", 0, "毒药", 0)
##   curse_data.curse_type = CurseCardData.CurseType.DRAW_TRIGGER
##   curse_data.effect_text = "抽入手牌时立即受到2点伤害"

class_name CurseCardData extends CardData

# ---------------------------------------------------------------------------
# 诅咒类型枚举
# ---------------------------------------------------------------------------

## 诅咒卡类型
enum CurseType {
	DRAW_TRIGGER = 0,       ## 抽到触发型：抽到时立即触发效果，然后进入弃牌堆
	PERSISTENT_LIBRARY = 1, ## 常驻牌库型：留在抽牌堆，持续影响游戏直到被移除
	PERSISTENT_HAND = 2     ## 常驻手牌型：留在手牌，需支付费用才能弃置
}

# ---------------------------------------------------------------------------
# 诅咒卡数据字段
# ---------------------------------------------------------------------------

## 诅咒类型
var curse_type: CurseType = CurseType.DRAW_TRIGGER

## 诅咒效果文本（所有类型共用）
var effect_text: String = ""

## 弃置费用（仅常驻手牌型使用）
var discard_cost: int = 0

## 特殊属性（如"不可使用"等）
var special_attribute: String = ""

## 图鉴归属
var catalog: String = ""

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

## 创建诅咒卡数据实例
func _init(card_id: String, card_cost: int, card_name: String, card_rarity: int) -> void:
	super._init(card_id, card_cost, card_name, card_rarity)
	# 诅咒卡默认为诅咒类型
	card_type = CardData.CardType.CURSE

# ---------------------------------------------------------------------------
# 查询方法
# ---------------------------------------------------------------------------

## 检查是否是抽到触发型诅咒
func is_draw_trigger() -> bool:
	return curse_type == CurseType.DRAW_TRIGGER


## 检查是否是常驻牌库型诅咒
func is_persistent_library() -> bool:
	return curse_type == CurseType.PERSISTENT_LIBRARY


## 检查是否是常驻手牌型诅咒
func is_persistent_hand() -> bool:
	return curse_type == CurseType.PERSISTENT_HAND


## 获取诅咒类型名称
static func get_curse_type_name(type: CurseType) -> String:
	match type:
		CurseType.DRAW_TRIGGER:
			return "抽到触发型"
		CurseType.PERSISTENT_LIBRARY:
			return "常驻牌库型"
		CurseType.PERSISTENT_HAND:
			return "常驻手牌型"
		_:
			return TranslationServer.translate("CURSE_UNKNOWN")


## 获取效果描述
func get_effect_description() -> String:
	return effect_text


## 检查是否是不可使用诅咒（用于确定类型）
func is_unusable() -> bool:
	return special_attribute == "不可使用"