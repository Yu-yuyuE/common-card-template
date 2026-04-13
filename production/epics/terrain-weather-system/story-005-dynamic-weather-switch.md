# Story 005: 动态天气切换机制

Epic: 地形天气系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/terrain-weather-system.md`
**Requirement**: TR-terrain-weather-system-004 (天气可变), TR-terrain-weather-system-006 (天气切换冷却)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: 地形天气系统架构
**ADR Decision Summary**: 提供 `change_weather` 接口供卡牌/事件调用，维护来源的冷却倒计时，防止频繁切换。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须实现天气切换时检查冷却机制change_weather(new_weather, source_id, cooldown)
- Forbidden: 禁止无冷却机制的频繁天气切换

---

## Acceptance Criteria

*From GDD `design/gdd/terrain-weather-system.md`, scoped to this story:*

- [ ] 实现 `change_weather(new_weather: String, source_id: String, cooldown: int = 2) -> bool`。
- [ ] 检查并拒绝重复天气：如果新天气与当前天气相同，返回 false。
- [ ] 检查并拒绝处于冷却的切换：如果在 `weather_cooldowns` 字典中 `source_id` 的剩余冷却回合 > 0，返回 false。
- [ ] 更新天气状态并触发 `weather_changed(new_weather)` 信号。
- [ ] 将新冷却计入字典，并提供 `tick_cooldowns()` 供每回合结束时调用以减1。
- [ ] 记录变更至 `weather_change_history`。

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

1. 每次 `change_weather` 成功后：
   ```gdscript
   weather_cooldowns[source_id] = cooldown
   weather_change_history.append({
       "from": old_weather,
       "to": new_weather_type,
       "source": source_id,
       "timestamp": Time.get_unix_time_from_system()
   })
   ```
2. `tick_cooldowns()` 方法应遍历字典所有键，将值减 1，如果小于等于 0，则可以删除该键。

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 具体改变天气的卡牌效果或事件效果调用代码。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 正常切换
  - Given: 当前天气是 CLEAR
  - When: 调用 `change_weather("rain", "card_123", 2)`
  - Then: 结果返回 true。当前天气变为 RAIN，发射改变信号。

- **AC-2**: 相同天气拦截
  - Given: 当前天气是 RAIN
  - When: 再次调用 `change_weather("rain", "skill_456", 2)`
  - Then: 结果返回 false。当前天气不变。

- **AC-3**: 冷却机制生效
  - Given: 调用过 `change_weather("rain", "card_123", 2)` (天气变为雨，card_123冷却=2)
  - When: 下回合立刻调用 `change_weather("fog", "card_123", 2)`
  - Then: 结果返回 false (因为 card_123 仍在冷却中)。

- **AC-4**: 不同源不共享冷却
  - Given: card_123 仍在冷却中
  - When: 调用 `change_weather("fog", "event_789", 2)`
  - Then: 结果返回 true (不同源独立冷却)。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/terrain_weather/dynamic_weather_switch_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
