## TroopBranchRegistry.gd
## 兵种卡分支注册表
##
## 职责：管理兵种卡Lv3分支选项，提供分支查询接口
## 位置：作为独立工具类，由CardManager或军营节点UI调用
##
## 设计文档：design/gdd/troop-cards-design.md
## 依赖：
##   - TroopCard（兵种类型枚举）
##
## 使用示例：
##   var branches = TroopBranchRegistry.get_branch_options(TroopCard.TroopType.ARCHER)
##   # 返回：["连弩兵", "火矢兵", "投石兵", "弩车兵", "火兵", "猎人"]

class_name TroopBranchRegistry extends RefCounted

# ---------------------------------------------------------------------------
# 兵种分支映射表
# ---------------------------------------------------------------------------

## 兵种类型到Lv3分支的映射
## 每个分支包含：分支ID、分支名称、分支效果描述
const BRANCH_MAPPING: Dictionary = {
	TroopCard.TroopType.INFANTRY: [
		{"id": "heavy_infantry", "name": "重装步兵", "effect": "高额护盾+坚守"},
		{"id": "spear_infantry", "name": "长枪步兵", "effect": "对骑兵伤害翻倍"},
		{"id": "dual_blade_infantry", "name": "双刀步兵", "effect": "连击伤害+25%"},
		{"id": "shield_breaker", "name": "破盾步兵", "effect": "无视护盾直接扣HP"},
		{"id": "veteran_infantry", "name": "老兵步兵", "effect": "伤害+50%，费用+1"},
	],
	TroopCard.TroopType.CAVALRY: [
		{"id": "heavy_cavalry", "name": "铁甲重骑", "effect": "关隘地形无惩罚"},
		{"id": "light_cavalry", "name": "轻骑兵", "effect": "沙漠费用-1，额外灼烧"},
		{"id": "shock_cavalry", "name": "冲击骑兵", "effect": "击退+眩晕"},
		{"id": "scout_cavalry", "name": "斥候骑兵", "effect": "抽牌+伤害"},
		{"id": "desert_cavalry", "name": "沙漠游骑", "effect": "沙漠费用0，灼烧联动"},
	],
	TroopCard.TroopType.ARCHER: [
		{"id": "crossbow_archer", "name": "连弩兵", "effect": "多目标伤害"},
		{"id": "fire_archer", "name": "火矢兵", "effect": "灼烧效果"},
		{"id": "siege_archer", "name": "投石兵", "effect": "无视护甲AOE"},
		{"id": "ballista_archer", "name": "弩车兵", "effect": "高额单体伤害"},
		{"id": "fire_master", "name": "火兵", "effect": "灼烧扩散"},
		{"id": "hunter", "name": "猎人", "effect": "Debuff触发直击"},
	],
	TroopCard.TroopType.STRATEGIST: [
		{"id": "tactician", "name": "军师", "effect": "随机Debuff增强"},
		{"id": "fire_strategist", "name": "火攻军师", "effect": "灼烧效果+伤害"},
		{"id": "ice_strategist", "name": "冰策军师", "effect": "减速效果"},
		{"id": "wind_strategist", "name": "风谋军师", "effect": "击退+伤害"},
		{"id": "curse_strategist", "name": "咒术军师", "effect": "诅咒卡联动"},
	],
	TroopCard.TroopType.SHIELD: [
		{"id": "iron_shield", "name": "铁甲盾兵", "effect": "护盾+强制攻击"},
		{"id": "holy_shield", "name": "圣盾兵", "effect": "护盾+坚守"},
		{"id": "desert_shield", "name": "沙漠盾卫", "effect": "清除灼烧+护盾"},
		{"id": "pass_shield", "name": "关隘铁盾", "effect": "关隘地形护盾翻倍"},
		{"id": "guard_shield", "name": "护卫盾兵", "effect": "保护队友"},
	],
}

# ---------------------------------------------------------------------------
# 查询接口
# ---------------------------------------------------------------------------

## 获取指定兵种类型的所有Lv3分支选项
## 参数：troop_type - 兵种类型枚举值
## 返回：分支列表（每个分支包含id、name、effect字段）
static func get_branch_options(troop_type: int) -> Array[Dictionary]:
	var branches: Array[Dictionary] = []

	if BRANCH_MAPPING.has(troop_type):
		for branch in BRANCH_MAPPING[troop_type]:
			branches.append(branch)

	return branches


## 根据分支ID获取分支信息
## 参数：branch_id - 分支ID（如"heavy_infantry"）
## 返回：分支信息字典，若不存在返回空字典
static func get_branch_by_id(branch_id: String) -> Dictionary:
	for troop_type in BRANCH_MAPPING.keys():
		for branch in BRANCH_MAPPING[troop_type]:
			if branch["id"] == branch_id:
				return branch

	return {}


## 检查兵种卡是否已升级到Lv3（无法再升级）
## 参数：card - 兵种卡实例
## 返回：true=已是Lv3，false=还可以升级
static func is_max_level(card: TroopCard) -> bool:
	return card.current_level >= 3
