## CurseInjectionSystem.gd
## 诅咒注入系统（简化版 - 复用卡牌管理）
##
## 职责：配置诅咒卡的获得规则，复用 CardManager 的标准流程
## 位置：作为 CardManager 的辅助配置模块
##
## 设计理念：
##   诅咒卡本质是卡牌，注入/净化应复用卡牌管理流程，
##   通过卡牌类型参数区分特殊逻辑，避免重复系统。
##
## 设计文档：design/gdd/curse-system.md
## 依赖：
##   - CardManager（卡牌管理）
##   - CurseCardData（诅咒卡数据结构）
##
## 使用示例：
##   var injection_system = CurseInjectionSystem.new(card_manager)
##   injection_system.add_curse_card("curse_plague", InjectionSource.ENEMY_ACTION)

class_name CurseInjectionSystem extends Node

# ---------------------------------------------------------------------------
# 枚举定义
# ---------------------------------------------------------------------------

## 注入来源（与卡牌获得来源一致）
enum InjectionSource {
    ENEMY_ACTION,        ## 敌人行动触发（B/C类行动）
    MAP_EVENT,           ## 地图事件触发
    CARD_EFFECT,         ## 卡牌效果触发
    HERO_INITIAL_DECK,   ## 武将初始卡组预置（司马懿）
}

# ---------------------------------------------------------------------------
# 默认规则
# ---------------------------------------------------------------------------

## 注入来源映射到位置的默认规则
## 基于GDD定义，可被外部配置覆盖
const DEFAULT_INJECTION_RULES: Dictionary = {
    InjectionSource.ENEMY_ACTION: "discard_pile",     ## 弃牌堆（下次洗牌进入牌库）
    InjectionSource.MAP_EVENT: "library",             ## 抽牌堆（立即生效）
    InjectionSource.CARD_EFFECT: "hand",              ## 手牌（直接进入手牌）
    InjectionSource.HERO_INITIAL_DECK: "library",     ## 抽牌堆（预置）
}

# ---------------------------------------------------------------------------
# 成员变量
# ---------------------------------------------------------------------------

## 依赖组件
var card_manager: CardManager
var curse_manager: CurseManager

# ---------------------------------------------------------------------------
# 初始化
# ---------------------------------------------------------------------------

func _init(p_card_manager: CardManager, p_curse_manager: CurseManager = null) -> void:
    card_manager = p_card_manager
    curse_manager = p_curse_manager

# ---------------------------------------------------------------------------
# 注入接口（简化为统一的卡牌获得）
# ---------------------------------------------------------------------------

## 统一的诅咒卡获得接口
##
## 设计理念：诅咒卡获得 = 普通卡牌获得 + 卡牌类型标识
## 复用 CardManager 的标准流程，通过参数区分诅咒卡
##
## 参数：
##   - card_id: 诅咒卡ID
##   - source: 获得来源
##   - target_location_override: 可选，覆盖默认注入位置
##
## 返回：true=获得成功，false=获得失败
func add_curse_card(card_id: String, source: InjectionSource, target_location_override: String = "") -> bool:
    # 1. 验证诅咒卡是否存在
    if curse_manager == null:
        push_error("CurseInjectionSystem: CurseManager未初始化")
        return false

    var curse_data = curse_manager.get_curse(card_id)
    if curse_data == null:
        push_error("CurseInjectionSystem: 诅咒卡不存在 - %s" % card_id)
        return false

    # 2. 创建诅咒卡实例
    var curse_card = Card.new(curse_data)

    # 3. 标记诅咒卡类型（用于事件参数）
    curse_card.is_curse = true
    curse_card.curse_source = source

    # 4. 确定目标位置
    var target_location = target_location_override
    if target_location.is_empty():
        target_location = DEFAULT_INJECTION_RULES.get(source, "library")

    # 5. 通过 CardManager 标准流程添加卡牌
    # 这里复用 CardManager 的现有逻辑，确保一致的行为
    var success = _add_card_to_location(curse_card, target_location)

    if success:
        # 6. 触发标准卡牌获得事件（CardManager.card_drawn）
        # 事件参数中包含卡牌类型，便于监听者区分
        card_manager.card_drawn.emit(curse_card)
        print("CurseInjectionSystem: 诅咒卡 %s 获得成功，来源: %s, 位置: %s" % [card_id, InjectionSource.keys()[source], target_location])

    return success


# ---------------------------------------------------------------------------
# 内部辅助方法
# ---------------------------------------------------------------------------

## 将卡牌添加到指定位置（复用 CardManager 逻辑）
func _add_card_to_location(card: Card, location: String) -> bool:
    match location:
        "discard_pile":
            card_manager.discard_pile.append(card)
            return true
        "library":
            card_manager.draw_pile.append(card)
            return true
        "hand":
            # 检查手牌是否已满
            var hand_limit = card_manager.get_hand_limit()
            if card_manager.hand_cards.size() >= hand_limit:
                # 手牌已满，先弃置一张
                if card_manager.hand_cards.size() > 0:
                    var discarded_card = card_manager.hand_cards.pop_back()
                    card_manager.discard_pile.append(discarded_card)
                    card_manager.hand_full_discarded.emit(discarded_card)
                    print("CurseInjectionSystem: 手牌已满，弃置一张卡以腾出位置")
                else:
                    push_warning("CurseInjectionSystem: 手牌已满但为空，无法添加")
                    return false

            card_manager.hand_cards.append(card)
            return true
        _:
            push_error("CurseInjectionSystem: 未知位置 - %s" % location)
            return false


# ---------------------------------------------------------------------------
# 封装接口（简化调用）
# ---------------------------------------------------------------------------

## 为敌人行动注入诅咒卡
func inject_curse_by_enemy_action(card_id: String) -> bool:
    return add_curse_card(card_id, InjectionSource.ENEMY_ACTION)

## 为地图事件注入诅咒卡
func inject_curse_by_map_event(card_id: String) -> bool:
    return add_curse_card(card_id, InjectionSource.MAP_EVENT)

## 为卡牌效果注入诅咒卡
func inject_curse_by_card_effect(card_id: String) -> bool:
    return add_curse_card(card_id, InjectionSource.CARD_EFFECT)

## 为武将初始卡组注入诅咒卡
func inject_curse_by_hero_initial_deck(card_id: String) -> bool:
    return add_curse_card(card_id, InjectionSource.HERO_INITIAL_DECK)

## 为卡牌效果注入诅咒卡到指定位置
func inject_curse_card_to_location(card_id: String, location: String) -> bool:
    return add_curse_card(card_id, InjectionSource.CARD_EFFECT, location)


# ---------------------------------------------------------------------------
# 查询接口
# ---------------------------------------------------------------------------

## 根据来源获取默认注入位置
func get_default_injection_location(source: InjectionSource) -> String:
    return DEFAULT_INJECTION_RULES.get(source, "library")
