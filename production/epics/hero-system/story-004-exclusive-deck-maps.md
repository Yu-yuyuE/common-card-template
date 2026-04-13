# Story 004: 专属卡组与生涯地图接口

Epic: 武将系统
Estimate: 1 day
Status: Ready
Layer: Feature
Type: Logic
Manifest Version: 2026-04-09

## Context

**GDD**: `design/gdd/heroes-design.md`
**Requirement**: TR-heroes-design-006 (专属卡组), TR-heroes-design-007 (生涯地图)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: 武将系统架构
**ADR Decision Summary**: 提供数据访问器，用于向其他系统输出武将附属的专属卡与地图标识。

**Engine**: Godot 4.6.1 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: 必须为每名武将存储：专属卡组(≤12张)、生涯地图(5张)。

---

## Acceptance Criteria

*From GDD `design/gdd/heroes-design.md`, scoped to this story:*

- [ ] 实现 `get_exclusive_deck(hero_id) -> Array[String]` 和 `get_current_exclusive_deck() -> Array[String]` 接口。
- [ ] 返回该武将的所有专属卡ID。在CSV解析阶段需要确保使用英文逗号正确分割了字符串。
- [ ] 实现 `get_career_maps(hero_id) -> Array[String]` 接口。生涯地图以字符串数组的形式维护(如 `["M1_start", "M2_mid", ...]`)。
- [ ] 数据长度验证：大多数武将的专属卡在12-16张（最高司马懿15/18张），生涯地图一定是 5 张。如果解析后尺寸不对，建议在读取时打印警告，以方便配置校验。

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

1. 在 `HeroManager._load_hero_data()` 内，若遇到 `exclusive_deck`：
   `hero.exclusive_deck = row.get("exclusive_deck", "").split(",")`
2. 生涯地图：
   `hero.career_maps = row.get("career_maps", "").split(",")`
3. 加入简单的合规日志：
   `if hero.career_maps.size() != 5: push_warning("Hero %s does not have exactly 5 maps!" % hero.id)`

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- `DeckManager` 将这些专属卡放入玩家初始套牌的逻辑（由游戏流程启动模块负责）。
- 生成具体这5张地图内各节点内容的逻辑（由地图节点系统M1负责）。

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 专属卡组获取
  - Given: `cao_cao` 配置了 `exclusive_deck="Z01,Z02,Z03"`。
  - When: 调用 `get_exclusive_deck("cao_cao")`
  - Then: 获得 `["Z01", "Z02", "Z03"]` 的数组。

- **AC-2**: 生涯地图数量告警
  - Given: 某非法武将配置的地图数量只有 4。
  - When: 执行 CSV 加载。
  - Then: 控制台抛出相应 Warning。但不阻止运行。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/hero_system/exclusive_deck_maps_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: 无
