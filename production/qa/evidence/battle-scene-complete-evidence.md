# 验证证明 — BattleScene.tscn 完整 UI 结构

**Story**: sprint-8-ui-battle-scene-complete
**日期**: \_\_\_\_\_\_\_\_\_\_\_\_
**验证人**: \_\_\_\_\_\_\_\_\_\_\_\_
**Godot 版本**: 4.6.1（stable）

---

## AC-1 HeroZone 验证

| 检查项 | 预期 | 实际 | 通过？ |
|--------|------|------|:---:|
| HeroZone 节点存在（VBoxContainer，左侧中部） | ✅ 存在 | | \_\_\_ |
| HeroHpBar 存在（ProgressBar，max=60, value=60） | ✅ 存在 | | \_\_\_ |
| HeroArmorLabel 存在（初始 visible=false，text="🛡️0"） | ✅ 存在 | | \_\_\_ |
| HeroCounterLabel 存在（初始 text=""） | ✅ 存在 | | \_\_\_ |

---

## AC-2 APZone 验证

| 检查项 | 预期 | 实际 | 通过？ |
|--------|------|------|:---:|
| APZone 节点存在（HBoxContainer，左下角） | ✅ 存在 | | \_\_\_ |
| APLabel 存在（初始 text="AP: --"） | ✅ 存在 | | \_\_\_ |
| DrawPileLabel 存在（初始 text="🎴--"） | ✅ 存在 | | \_\_\_ |
| DiscardPileLabel 存在（初始 text="🗑️--"） | ✅ 存在 | | \_\_\_ |

---

## AC-3 EnvironmentZone 验证

| 检查项 | 预期 | 实际 | 通过？ |
|--------|------|------|:---:|
| EnvironmentZone 节点存在（HBoxContainer，顶部左上） | ✅ 存在 | | \_\_\_ |
| TerrainWeatherLabel 存在（初始 text="⛰️-- / ☀️--"） | ✅ 存在 | | \_\_\_ |
| RoundLabel 存在（初始 text="回合 1"） | ✅ 存在 | | \_\_\_ |

---

## AC-4 BattleUI.gd 新增方法验证

| 方法 | 预期行为 | 通过？ |
|------|---------|:---:|
| `update_hero_hp(45, 60)` | HeroHpBar.value=45, max_value=60 | \_\_\_ |
| `update_hero_armor(12)` | HeroArmorLabel.visible=true, text="🛡️12" | \_\_\_ |
| `update_hero_armor(0)` | HeroArmorLabel.visible=false | \_\_\_ |
| `update_ap(3, 4)` | APLabel.text="AP: 3/4"，手牌灰显同步更新 | \_\_\_ |
| `update_pile_counts(15, 4)` | DrawPileLabel="🎴15"，DiscardPileLabel="🗑️4" | \_\_\_ |
| `update_terrain_weather("山地", "晴天")` | TerrainWeatherLabel.text="山地 / 晴天" | \_\_\_ |
| `update_round(4)` | RoundLabel.text="回合 4" | \_\_\_ |

---

## AC-5 现有功能回归验证

| 检查项 | 预期 | 通过？ |
|--------|------|:---:|
| Background 节点存在，结构未变 | ✅ | \_\_\_ |
| PhaseLabel 节点存在，文本响应正常 | ✅ | \_\_\_ |
| EnemyArea + 3个子 Area 节点存在 | ✅ | \_\_\_ |
| HandContainer 节点存在 | ✅ | \_\_\_ |
| `bind(bm)` 方法正常连接信号 | ✅ | \_\_\_ |
| `refresh_hand(...)` 正常实例化 CardUI | ✅ | \_\_\_ |
| `register_enemy_hp_bar(...)` 正常注册 | ✅ | \_\_\_ |

---

## 最终结论

- 通过数量：\_\_\_ / 18
- 结论：⬜ PASS &nbsp; ⬜ FAIL &nbsp; ⬜ PARTIAL

---

> 此文件在 Godot 4.6.1 编辑器中完成验证后签字。
