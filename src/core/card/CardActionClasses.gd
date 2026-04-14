## CardActionClasses.gd
## 卡牌行动系统的数据结构类
## 由 CardActionExecutor 和 CardActionParser 共享使用
## 作者: Claude Code
## 创建日期: 2026-04-13

# ============ 行动模板类 ============
class CardActionTemplate:
	var action_id: String = ""
	var action_type: String = ""
	var required_params: Array[String] = []
	var optional_params: Array[String] = []
	var description: String = ""

# ============ 行动实例类 ============
class CardAction:
	var action_id: String = ""
	var params: Dictionary = {}
	var conditions: Array[Condition] = []
	var trigger: String = "IMMEDIATE"  # IMMEDIATE, AFTER_DRAW, ON_CARD_PLAYED

# ============ 条件类 ============
class Condition:
	var field: String = ""  # terrain, weather, target_has_status, target_status
	var operator: String = "="  # =, !=, >, <, >=, <=
	var value: Variant = null
	var true_branch: Dictionary = {}  # 条件为真时的参数覆盖
	var false_branch: Dictionary = {}  # 条件为假时的参数覆盖

# ============ 效果事件类 ============
class EffectEvent:
	var action_id: String = ""
	var action_type: String = ""
	var caster: Object = null
	var target: Object = null
	var value: int = 0  # 效果数值（伤害值、治疗量等）
	var success: bool = false
	var message: String = ""  # 用于UI显示的消息
