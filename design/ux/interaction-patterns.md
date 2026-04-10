# Interaction Pattern Library

> **Status**: Draft
> **Author**: UX Designer
> **Last Updated**: 2026-04-09
> **Accessibility Tier**: Standard (WCAG 2.1 AA contrast, focus order documented, colorblind support via shape coding)
> **Linked Documents**: `design/ux/battle-hud.md`, `design/gdd/systems-index.md`

---

## Overview

This document defines the core interaction patterns for the 三国称雄 (Three Kingdoms Ascendant) game interface. It serves as a reference for UI implementation, ensuring consistency across all screens and interactions.

The patterns defined here are based on the game's core pillars:
- Tactical depth through card-based combat
- Strategic resource management
- Three Kingdoms historical theme

---

## Core Patterns

### 1. Card Interaction

#### 1.1 Card Selection
- **Trigger**: Click/tap on a card in hand or deck
- **Visual Feedback**: 
  - Card lifts slightly (5px) with subtle shadow
  - Glow effect around card border
  - Targeting reticle appears if card requires target selection
- **States**:
  - Enabled: Card is playable (sufficient resources)
  - Disabled: Card cannot be played (insufficient resources or other constraints)
  - Selected: Card is chosen and awaiting target confirmation

#### 1.2 Card Drag and Drop
- **Trigger**: Mouse down on card, drag to target area
- **Visual Feedback**:
  - Card follows cursor with 50% opacity
  - Valid drop zones highlighted with green border
  - Invalid drop zones dimmed with red overlay
- **Constraints**:
  - Cards can only be dragged from hand to battlefield
  - Dragging a card to an invalid zone returns it to original position

#### 1.3 Card Hover Details
- **Trigger**: Mouse hover over any card for >0.5 seconds
- **Visual Feedback**:
  - Tooltip appears above card with full details
  - Card slightly enlarges (105% scale)
  - Background darkens to highlight card
- **Content**:
  - Full card name and description
  - Resource cost
  - Special effects and modifiers
  - Historical context (for hero and troop cards)

### 2. Resource Management

#### 2.1 Resource Display
- **Location**: Top of screen, persistent
- **Elements**:
  - Cargo (粮草): Current/Maximum (e.g., 85/150)
  - Gold (金币): Current amount (e.g., 120)
  - Action Points (行动点): Current/Maximum (e.g., 3/3)
- **Visual States**:
  - Normal: White text on dark background
  - Low: Orange text when below 25%
  - Critical: Red text and pulsing animation when below 10%

#### 2.2 Resource Gain Animation
- **Trigger**: Resource increases through any means
- **Visual Feedback**:
  - Number animates upward with "+X" indicator
  - Brief color flash (green for positive, red for negative)
  - Progress bar fills smoothly
- **Sound**: Subtle chime for positive changes

#### 2.3 Resource Spend Confirmation
- **Trigger**: Attempting to spend resources
- **Visual Feedback**:
  - Resource counter flashes
  - Temporary display of new total
  - Insufficient resources highlighted in red
- **Interaction**:
  - If sufficient: Action proceeds normally
  - If insufficient: Action blocked with tooltip explanation

### 3. Battle System

#### 3.1 Unit Selection
- **Trigger**: Click/tap on any unit (player or enemy)
- **Visual Feedback**:
  - Unit border glows with team color (blue for player, red for enemy)
  - Health bar becomes prominent
  - Status effects displayed with icons
- **States**:
  - Idle: Normal border
  - Hover: Slightly brighter border
  - Selected: Thick glowing border
  - Targeted: Pulsing border with targeting reticle

#### 3.2 Action Targeting
- **Trigger**: Selecting a card that requires a target
- **Visual Feedback**:
  - Valid targets highlighted with green pulsing border
  - Invalid targets dimmed
  - Targeting reticle follows cursor
- **Interaction**:
  - Clicking valid target confirms action
  - Clicking invalid target shows tooltip explaining why
  - Pressing Escape cancels targeting mode

#### 3.3 Turn Progression
- **Trigger**: End of turn initiated by player or AI
- **Visual Feedback**:
  - Turn counter animation
  - "Thinking" indicator for AI turns
  - Resource regeneration animations
  - Status effect updates
- **Sound**: Distinct chime for turn start/end

### 4. Map Navigation

#### 4.1 Node Selection
- **Trigger**: Click/tap on any map node
- **Visual Feedback**:
  - Node border glows
  - Tooltip appears with node details
  - Path to node highlighted if accessible
- **States**:
  - Unvisited: Normal appearance
  - Visited: Slightly brighter
  - Current: Pulsing border
  - Locked: Dimmed with lock icon

#### 4.2 Path Drawing
- **Trigger**: Moving between nodes
- **Visual Feedback**:
  - Path drawn with team color
  - Resource cost displayed along path
  - Obstacles and hazards marked
- **Constraints**:
  - Path must have sufficient resources
  - Cannot move to inaccessible nodes

### 5. Menu Navigation

#### 5.1 Main Menu
- **Layout**: Vertical list of options centered on screen
- **Visual Style**: Bamboo texture background with ink-brush text
- **Interaction**:
  - Up/Down arrows or mouse hover to select
  - Enter/Click to confirm
  - Escape to return to previous screen

#### 5.2 Settings Menu
- **Layout**: Tabbed interface with categorized options
- **Visual Style**: Consistent with main menu but with more detailed controls
- **Interaction**:
  - Click tabs to switch categories
  - Sliders for continuous values (volume, difficulty)
  - Checkboxes for boolean options
  - Dropdowns for multiple choice options

#### 5.3 Inventory Management
- **Layout**: Grid-based display of cards and items
- **Visual Style**: Scrollable card view with filtering options
- **Interaction**:
  - Click to select/view details
  - Drag to rearrange
  - Right-click/context menu for actions
  - Filter by type, rarity, or other attributes

---

## Visual Design Principles

### Color Coding
- **Player Units**: Blue accents
- **Enemy Units**: Red accents
- **Resources**: Gold/yellow for positive, gray for neutral
- **Status Effects**: Color-coded by type (green for buffs, red for debuffs)

### Typography
- **Headers**: Bold, larger font size
- **Body Text**: Clean, readable font
- **Numbers**: Monospace for easy comparison
- **Emphasis**: Italic or bold for important information

### Animations
- **Subtle**: All animations should be smooth but not distracting
- **Purposeful**: Every animation should convey information or provide feedback
- **Consistent**: Similar actions should have similar animations
- **Performance**: All animations must maintain 60fps on target hardware

---

## Localization Considerations (本地化考虑)

为支持中文、英文和日文三种语言，所有用户界面文本元素必须遵守以下最大字符限制：

| 文本元素 | 中文最大字符 | 英文最大字符 | 日文最大字符 | 应用场景 |
|----------|--------------|--------------|--------------|----------|
| 卡牌名称 | 6 | 10 | 6 | 手牌和战场显示，需紧凑 |
| 卡牌描述 | 50 | 80 | 50 | 悬停提示中显示，可换行 |
| 资源数值 (粮草、金币、行动点) | 8 | 12 | 8 | "85/150" vs "85/150" vs "85/150" |
| 状态图标文本 (如 灼烧) | 4 | 6 | 4 | 战场中固定位置显示 |
| 动作指令 (如 "使用"、"取消") | 4 | 6 | 4 | 按钮文字，需统一大小 |
| 提示文本 (如 "资源不足") | 8 | 12 | 8 | 短暂提示，快速阅读 |
| 按钮文本 (如 "攻击"、"防御") | 4 | 6 | 4 | 高频使用，保持一致性 |
| 界面标签 (如 "手牌"、"装备") | 4 | 6 | 4 | 菜单和分组标题 |
| 信息标题 (如 "战斗信息") | 6 | 10 | 6 | 主要区域标题 |
| 模态框标题 (如 "确认弃牌") | 8 | 12 | 8 | 对话框标题 |
| 状态详情 (悬停弹出) | 30 | 45 | 30 | 详细说明，可多行显示 |

> **重要**: 所有 UI 文本布局应基于英文版本的长度进行设计，因为英文通常比中文和日文占用更多空间。所有动态文本区域（如悬停提示）必须支持自动换行。

---

## Platform Considerations

### PC (Primary)
- **Input**: Mouse and keyboard optimized
- **Resolution**: Supports 1080p to 4K with scalable UI
- **Features**: Right-click context menus, keyboard shortcuts

### Mobile (Future)
- **Input**: Touch-optimized with larger targets
- **Resolution**: Responsive design for various screen sizes
- **Features**: Gesture support, simplified menus

---

## Accessibility Patterns

### Visual
- **Contrast**: All UI elements must meet WCAG 2.1 AA contrast standards
- **Text Size**: Minimum 16px for body text, scalable
- **Color Blind**: No information conveyed by color alone

### Motor
- **Keyboard Navigation**: Full navigation possible with keyboard
- **Focus Indicators**: Clear visual indication of focused elements
- **Timing**: No time-limited interactions without extensions

### Cognitive
- **Consistency**: Similar elements behave similarly
- **Feedback**: All actions provide clear feedback
- **Simplicity**: Complex information broken into digestible chunks

---

## Implementation Notes

### Godot Specifics
- **Control Nodes**: Use appropriate Control node types (Button, Label, etc.)
- **Themes**: Implement using Godot's theme system for consistency
- **Signals**: Use signals for inter-component communication
- **Containers**: Utilize container nodes for automatic layout

### Performance
- **Batching**: Minimize draw calls through proper batching
- **Textures**: Use atlases for small UI elements
- **Animations**: Optimize animations to avoid frame drops

### Testing
- **Cross-Platform**: Test on all target platforms
- **Edge Cases**: Verify behavior with extreme values
- **User Testing**: Regular playtesting sessions to validate patterns

---

## Pattern Evolution

This library will evolve throughout development:

1. **Pre-Production**: Core patterns defined and prototyped
2. **Production**: Patterns refined based on implementation
3. **Polish**: Final adjustments based on playtesting feedback

Any changes to patterns must be documented with:
- Reason for change
- Impact on existing implementations
- Update plan for affected screens

---

## Open Issues

| Issue | Description | Owner | Status |
|-------|-------------|-------|--------|
| Card tooltip positioning | Tooltips sometimes overlap with other UI elements | UX Designer | In Progress |
| Resource animation timing | Current timing feels too fast | Game Designer | To Do |
| Mobile touch targets | Need to verify all touch targets meet minimum size requirements | UX Designer | To Do |

---

## Revision History

| Date | Author | Changes | Version |
|------|--------|---------|---------|
| 2026-04-09 | UX Designer | Initial creation of pattern library | 1.0.0 |