## CardActionParser.gd
## 卡牌行动参数字符串解析器
## 实现 ADR-0020: 卡牌行动参数系统
## 作者: Claude Code
## 创建日期: 2026-04-13

class_name CardActionParser extends RefCounted

## 解析行动参数字符串
## 输入: "CA01:damage=6;CA06:status_id=POISON,layers=2"
## 输出: Array[CardAction]
func parse_action_string(action_str: String) -> Array[CardAction]:
	var actions: Array[CardAction] = []

	if action_str.is_empty():
		return actions

	# 按分号分割多个行动
	var action_parts = action_str.split(";")
	for part in action_parts:
		var trimmed = part.strip_edges()
		if trimmed.is_empty():
			continue

		var action = _parse_single_action(trimmed)
		if action != null:
			actions.append(action)

	return actions

## 解析单个行动
## 输入: "CA01:damage=6&target=ENEMY" 或 "CA01:IF(terrain=MOUNTAIN):damage=12;ELSE:damage=6"
func _parse_single_action(action_str: String) -> CardAction:
	var action = CardAction.new()

	# 标准格式: ACTION_ID:param1=value1&param2=value2
	var colon_pos = action_str.find(":")
	if colon_pos == -1:
		# 只有行动ID，无参数
		action.action_id = action_str.strip_edges()
		return action

	action.action_id = action_str.substr(0, colon_pos).strip_edges()
	var params_str = action_str.substr(colon_pos + 1).strip_edges()

	# 解析参数
	action.params = _parse_params(params_str)

	return action

## 解析参数
## 输入: "damage=6&target=ENEMY" 或 "status_id=POISON,layers=2"
func _parse_params(params_str: String) -> Dictionary:
	var params: Dictionary = {}

	if params_str.is_empty():
		return params

	# 支持 & 和 , 两种分隔符
	var param_parts: Array[String] = []
	if "&" in params_str:
		param_parts = params_str.split("&")
	else:
		param_parts = params_str.split(",")

	for part in param_parts:
		var trimmed = part.strip_edges()
		if trimmed.is_empty():
			continue

		var equal_pos = trimmed.find("=")
		if equal_pos == -1:
			continue

		var key = trimmed.substr(0, equal_pos).strip_edges()
		var value_str = trimmed.substr(equal_pos + 1).strip_edges()

		params[key] = _parse_value(value_str)

	return params

## 解析值（支持类型推断和动态变量）
## 输入: "6" -> int(6), "true" -> bool(true), "ENEMY" -> String("ENEMY"), "$target_hp" -> 动态变量
func _parse_value(value_str: String) -> Variant:
	var trimmed = value_str.strip_edges()

	# 检查是否为动态变量（以 $ 开头）
	if trimmed.begins_with("$"):
		return _create_dynamic_variable(trimmed)

	# 尝试解析为整数
	if trimmed.is_valid_int():
		return trimmed.to_int()

	# 尝试解析为浮点数
	if trimmed.is_valid_float():
		return trimmed.to_float()

	# 尝试解析为布尔值
	match trimmed.to_lower():
		"true":
			return true
		"false":
			return false

	# 检查是否包含运算符（表达式）
	if _is_expression(trimmed):
		return _create_expression(trimmed)

	# 默认解析为字符串
	return trimmed

## 创建动态变量对象
func _create_dynamic_variable(var_str: String) -> Dictionary:
	# 格式: $variable_name 或 $variable_name*0.3
	var variable = var_str.strip_edges()

	# 检查是否有后缀运算符
	var multiplier = 1.0
	var ops = ["*", "/", "+", "-"]

	for op in ops:
		var op_pos = variable.find(op)
		if op_pos != -1:
			var var_part = variable.substr(0, op_pos).strip_edges()
			var value_part = variable.substr(op_pos + 1).strip_edges()
			if value_part.is_valid_float():
				multiplier = value_part.to_float()
				if op == "/":
					multiplier = 1.0 / multiplier
				elif op == "-":
					multiplier = -multiplier
			variable = var_part
			break

	return {
		"type": "dynamic",
		"variable": variable.substr(1),  # 去掉 $ 前缀
		"multiplier": multiplier
	}

## 检查是否为表达式
func _is_expression(value_str: String) -> bool:
	var ops = ["*", "/", "+", "-", "%"]
	for op in ops:
		# 排除负数的情况
		if op == "-" and value_str.strip_edges().begins_with("-"):
			continue
		if op in value_str:
			return true
	return false

## 创建表达式对象
func _create_expression(expr_str: String) -> Dictionary:
	return {
		"type": "expression",
		"expression": expr_str
	}


# ============ 测试函数 ============

## 测试解析器
static func test_parser() -> void:
	var parser = CardActionParser.new()

	# 测试1: 简单参数
	var test1 = "CA01:damage=6&target=ENEMY"
	var actions1 = parser.parse_action_string(test1)
	print("Test 1: ", test1)
	print("  Actions: ", actions1.size())
	if actions1.size() > 0:
		print("  Action ID: ", actions1[0].action_id)
		print("  Params: ", actions1[0].params)

	# 测试2: 多行动
	var test2 = "CA01:damage=8;CA06:status_id=POISON,layers=2"
	var actions2 = parser.parse_action_string(test2)
	print("\nTest 2: ", test2)
	print("  Actions: ", actions2.size())
	for i in range(actions2.size()):
		print("  Action[", i, "] ID: ", actions2[i].action_id)
		print("  Action[", i, "] Params: ", actions2[i].params)

	# 测试3: 条件参数
	var test3 = "CA01:IF(terrain=MOUNTAIN):damage=12;ELSE:damage=6"
	var actions3 = parser.parse_action_string(test3)
	print("\nTest 3: ", test3)
	print("  Actions: ", actions3.size())
	if actions3.size() > 0:
		print("  Action ID: ", actions3[0].action_id)
		print("  Conditions: ", actions3[0].conditions.size())
		if actions3[0].conditions.size() > 0:
			var cond = actions3[0].conditions[0]
			print("    Field: ", cond.field)
			print("    Value: ", cond.value)
			print("    True branch: ", cond.true_branch)
			print("    False branch: ", cond.false_branch)


# ============ 数据结构类（与 CardActionExecutor 共享）===========

## 行动实例类
class CardAction:
	var action_id: String = ""
	var params: Dictionary = {}
	var conditions: Array[Condition] = []
	var trigger: String = "IMMEDIATE"

## 条件类
class Condition:
	var field: String = ""
	var operator: String = "="
	var value: Variant = null
	var true_branch: Dictionary = {}
	var false_branch: Dictionary = {}
