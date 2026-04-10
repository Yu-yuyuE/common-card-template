# Epics Index

Last Updated: 2026-04-10
Engine: Godot 4.6.1

## Foundation Layer

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| 存档持久化系统 | Foundation | save-persistence-system | save-persistence-system.md | Not yet created | Ready |
| 资源管理系统 | Foundation | resource-management-system | resource-management-system.md | Not yet created | Ready |
| 本地化系统 | Foundation | localization-system | localization-system.md | Not yet created | Ready |

## Core Layer

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| 状态效果系统 | Core | status-effects-system | status-design.md | Not yet created | Ready |
| 卡牌战斗系统 | Core | card-battle-system | card-battle-system.md | Not yet created | Ready |
| 敌人系统 | Core | enemy-system | enemies-design.md | Not yet created | Ready |

## Feature Layer

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| 地形天气系统 | Feature | terrain-weather-system | terrain-weather-system.md | Not yet created | Ready |
| 兵种卡系统 | Feature | troop-card-system | troop-cards-design.md | Not yet created | Ready |
| 武将系统 | Feature | hero-system | heroes-design.md | Not yet created | Ready |
| 诅咒系统 | Feature | curse-system | curse-system.md | Not yet created | Ready |
| 卡牌解锁系统 | Meta | card-unlock-system | cards-design.md | Not yet created | Ready |
| 军营系统 | Feature | barracks-system | barracks-system.md | Not yet created | Ready |
| 酒馆系统 | Feature | inn-system | inn-system.md | Not yet created | Ready |

## Meta Layer

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| 地图节点系统 | Meta | map-node-system | map-design.md | Not yet created | Ready |
| 商店系统 | Meta | shop-system | shop-system.md | Not yet created | Ready |
| 装备系统 | Meta | equipment-system | equipment-design.md | Not yet created | Ready |
| 事件系统 | Meta | event-system | event-system.md | Not yet created | Ready |
| 卡牌升级系统 | Meta | card-upgrade-system | card-upgrade-system.md | Not yet created | Ready |

---

## Summary

- **Total Epics**: 18
- **Foundation**: 3
- **Core**: 3
- **Feature**: 7
- **Meta**: 5
- **Status**: All Ready for Story Creation

## Next Steps

For each epic, run `/create-stories [system-name]` to break down into implementable stories.

### Recommended Order (Dependency-Safe)

1. **Foundation**: save-persistence-system → resource-management-system → localization-system
2. **Core**: status-effects-system → card-battle-system → enemy-system
3. **Feature**: terrain-weather-system → hero-system → troop-card-system → curse-system → barracks-system → inn-system
4. **Meta**: map-node-system → shop-system → equipment-system → card-upgrade-system → event-system
