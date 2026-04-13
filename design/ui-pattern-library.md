# Interaction Pattern Library: 三国称雄 (Three Kingdoms Ascendant)

> **Status**: Draft
> **Author**: UX Designer
> **Last Updated**: 2026-04-09
> **Version**: 1.0
> **Engine**: Godot 4.6.1
> **UI Framework**: Godot Control nodes
> **Related Documents**:
> - `design/art/art-bible.md` — visual standards (colors, typography, iconography)
> - `design/accessibility-requirements.md` — accessibility commitments per feature
> - `design/ux/battle-hud.md` — battle screen spec that references patterns

> **Why this document exists**: Every UI screen spec should be able to say
> "uses Button (Primary) pattern" rather than re-specifying hover states,
> press animations, focus behavior, keyboard handling, and screen reader
> announcements from scratch. This library is the single source of truth for
> reusable interaction behaviors.
>
> When a screen spec references a pattern name, the programmer looks it up here.
> When the behavior changes, it changes here and applies everywhere.
>
> **Status definitions**:
> - **Draft**: Interaction specified but not yet implemented or validated
> - **Stable**: Implemented, tested, and validated in at least one shipped screen
> - **Deprecated**: Being phased out — existing uses will be migrated

---

## How to Use This Library

**If you are designing a screen**: Browse the Pattern Catalog Index below before
inventing new interactions. When a standard pattern fits, reference it by name
in the screen spec (e.g., "The confirm button uses Button (Primary) pattern").
When no existing pattern fits, propose a new one — document it here before
the screen spec that introduces it.

**If you are implementing a screen**: When a screen spec says "use [PatternName]
pattern," find it in this document for the complete specification.

**If you are reviewing a screen spec**: Verify that all interactive elements
reference a pattern from this library or include their own full interaction
specification.

---

## Pattern Catalog Index

| Pattern Name | Category | Description | Used In (Screens) | Status |
|-------------|----------|-------------|------------------|--------|
| Button (Primary) | Input | Main action, highest visual weight | Main Menu, Shop, Confirm dialogs | Draft |
| Button (Secondary) | Input | Alternative or cancel action | All dialogs, Settings, Back buttons | Draft |
| Toggle Switch | Input | Binary on/off setting | Audio/Graphics settings | Draft |
| Slider | Input | Continuous value adjustment | Volume, Brightness, Text Size | Draft |
| Card Selection Grid | Game-Specific | Grid of selectable cards for upgrade/inspect | Shop Upgrade, Barracks | Draft |
| Status Icon | Game-Specific | Buff/debuff indicator with duration | Battle HUD | Draft |
| Resource Display | Game-Specific | Non-interactive resource counter (gold/cargo/HP) | HUD, Shop header | Draft |
| Node Map | Navigation | Campaign map node selection screen | Map Navigation | Draft |
| Modal Dialog | Layout | Blocking overlay with decision | All dialogs requiring player choice | Draft |
| Confirmation Dialog | Layout | Destructive action confirmation | Delete save, exit combat | Draft |
| Inventory Grid | Game-Specific | Grid of item/card slots | Card Collection, Equipment | Draft |
| Tooltip (Contextual) | Feedback | Information on hover/focus | Card descriptions, setting explanations | Draft |
| Intent Preview | Game-Specific | Enemy next action display | Battle HUD | Draft |

---

## Standard Control Patterns

---

#### Button (Primary)

**Category**: Input
**Status**: Draft
**When to Use**: The single most important action on a screen. "Start Game,"
"Confirm," "Accept," "Buy." There should be at most one Primary button visible
at a time.
**When NOT to Use**: Alternative or secondary actions; destructive actions
(use Confirmation Dialog first).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Full-opacity fill, primary color (ink-black with paper-white text). Label centered. | — | — | — | — |
| Hovered | Brightness +15%, subtle scale 1.03x, cursor → pointer | Mouse over | Smooth transition | 80ms ease-out | UI hover sound |
| Focused (keyboard) | Focus ring: 2px ink-black outline, 3px offset. Same brightness as Hovered. | Tab / D-pad navigation | Smooth transition | 80ms ease-out | Same as hover |
| Pressed | Scale 0.97x, brightness -10% | Click / Enter / A / Cross | Action fires on release (press-up) | 60ms ease-in press; 80ms release | UI confirm sound |
| Disabled | 40% opacity, no cursor change | — | No response | — | — |

**Accessibility**:
- Keyboard: Tab to focus, Enter or Space to activate
- Gamepad: D-pad/stick to navigate, A/Cross to activate
- Screen reader: Accessible name matches visible label. Role="button"
- Colorblind: Do not rely on color alone — Primary also uses fill vs outline
- Minimum touch target: 44×44px (if touch is considered for future mobile)

**Implementation Notes (Godot 4.6)**:
- Extend `Button` control with a custom theme
- Override `_draw()` for custom states rather than modifying theme mid-state
- Use `focus_mode = FOCUS_ALL` for keyboard/gamepad focus
- Set `mouse_default_cursor_shape = CURSOR_POINTING_HAND`
- For scale animation, use a Tween on a parent Container node to avoid clipping

---

#### Button (Secondary)

**Category**: Input
**Status**: Draft
**When to Use**: Alternative, cancel, or back actions. "Back," "Cancel,"
"Skip," "Maybe Later." Lower visual weight than Primary.
**When NOT to Use**: Primary action (use Button (Primary)); destructive actions
(use Button (Destructive) → Confirmation Dialog).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Outlined style (border only, transparent fill), secondary color. Slightly smaller/lower weight than Primary. | — | — | — | — |
| Hovered | Background fill appears at 15% opacity. Border brightens. Scale 1.02x. | Mouse over | Smooth transition | 80ms ease-out | UI hover sound (softer) |
| Focused | Focus ring same as Primary | Tab / D-pad | Smooth transition | 80ms ease-out | UI focus sound |
| Pressed | Scale 0.97x, fill opacity 30% | Click / Enter / B / Circle | Action fires on release | 60ms ease-in | UI cancel/back sound |
| Disabled | 40% opacity | — | No response | — | — |

**Accessibility**: Same as Primary. In dialogs with Primary button, Secondary
maps to platform cancel input (B / Circle / Escape) as well as direct activation.

**Implementation Notes**: Consistent positioning matters — Secondary should be
right/bottom of Primary in horizontal layouts, below Primary in vertical layouts.

---

#### Toggle Switch

**Category**: Input
**Status**: Draft
**When to Use**: Binary on/off settings with immediate effect. "Music On/Off,"
"Fullscreen," "Auto-run."
**When NOT to Use**: Mutually exclusive multiple choices (use Radio Button or
Dropdown); settings that require confirmation before applying.

**Interaction Specification**:

| State | Visual | Input | Response | Audio |
|-------|--------|-------|----------|-------|
| Off | Track: light gray (40%). Thumb: left position, dark fill | Click anywhere on track | Toggles to On | Click sound |
| On | Track: primary color (30% opacity). Thumb: right position, primary fill | Click anywhere on track | Toggles to Off | Click sound |
| Hovered/Focused | Slight brightness increase, focus ring around entire control | — | — | Hover sound (subtle) |
| Disabled | 40% opacity, cursor not-allowed | — | No response | — |
| Transition | Thumb slides smoothly between positions | — | 200ms ease-out | — |

**Accessibility**:
- Keyboard: Tab to focus, Space or Enter to toggle
- Screen reader: Role="switch", state "checked"/"not checked", accessible name
- Label must be adjacent and associated (use Label with matching `for` attribute)

---

#### Slider

**Category**: Input
**Status**: Draft
**When to Use**: Continuous or discrete value selection with a clear range.
"Volume," "Brightness," "Text Size."
**When NOT to Use**: Small discrete sets (use Dropdown or Toggle); settings where
exact value is less important than state.

**Interaction Specification**:

| Element | Visual |
|---------|--------|
| Track | Horizontal bar, 8px height, light gray background (20% opacity) |
| Fill | Portion to left of thumb, primary color (40% opacity) |
| Thumb | Circular knob, 24px diameter, primary color fill, white 2px border |
| Value indicator (optional) | Small tooltip above thumb showing numeric value during drag |

| Interaction | Response |
|------------|----------|
| Click on track | Thumb jumps to click position, value updates |
| Drag thumb | Thumb follows mouse, value updates continuously |
| Mouse wheel over slider | Adjust by step increment |
| Arrow keys when focused | Adjust by step increment |
| Home/End keys | Jump to min/max |

**Accessibility**:
- Keyboard: Tab to focus, Arrow keys adjust by step, Home/End to min/max
- Screen reader: Role="slider", announces current value and min/max
- Minimum thumb size: 24×24px for touch friendliness

---

#### Card Selection Grid

**Category**: Game-Specific
**Status**: Draft
**When to Use**: Displaying a collection of cards for selection, upgrade choice,
or inspection. Used in Shop (select cards to buy), Barracks (troop selection),
Card Collection screen.
**When NOT to Use**: Single card display; non-interactive card presentation.

**Interaction Specification**:

| State | Visual | Response |
|-------|--------|----------|
| Default | Card art visible. Border: light gray (10% opacity). Overlay text: card name, cost, stats | — |
| Hovered | Border becomes primary color (2px solid). Subtle lift (scale 1.02x, shadow increases). Additional info tooltip may appear (cost/effect). | Smooth 80ms transition |
| Selected | Border: primary color (3px solid). Background overlay: primary color at 10% opacity. Checkmark icon in corner. | Immediate on click |
| Disabled (Affordability) | Card art desaturated (50% opacity). Cannot be selected. | Tooltip: "Insufficient Gold" |
| Disabled (Upgrade Slot Full) | Card art grayscale + lock icon overlay. Tooltip: "Upgrade limit reached" | — |
| Lv2 Card | Card border accent color (e.g., gold edge). "Lv2" badge in corner. | Distinctive but not competing with selection states |

**Card Content Layout** (fixed template across all cards):
- Top: Card type icon + rarity border color
- Middle: Card art (illustration)
- Bottom: Card name (bold), cost (gold icon), key stats
- For upgrade selection: Show "Lv1 → Lv2" comparison arrow between values

**Grid Configuration**:
- Responsive columns: 3–5 depending on screen width
- Fixed card size: 120×180px minimum
- Spacing: 12px between cards
- Scroll: Vertical scroll if grid exceeds viewport

**Accessibility**:
- Keyboard: Tab moves between cards (grid navigation via arrow keys), Space/Enter selects
- Screen reader: Each card announces "[Card Name], [Rarity], [Cost] gold, [Key Stats]. Selected/Not selected"
- Color-as-only-indicator: Rarity shown both by color AND icon shape; selection by border width AND checkmark
- Minimum card size: 80×120px for reduced resolution support

---

#### Status Icon

**Category**: Game-Specific
**Status**: Draft
**When to Use**: Displaying active buff/debuff status effects on a character
(HUD) or enemy health bar. Shows both positive and negative states.
**When NOT to Use**: Contextual icons that aren't persistent state; decorative
graphics without gameplay meaning.

**Visual Design** (based on Art Bible shape language):
- Shape: Diamond for negative states, Circle for positive states
- Size: 28×28px on HUD, 20×20px on enemy health bar
- Background: Diamond/circle filled with semi-transparent color (40% opacity)
- Icon: White silhouette on colored background
- Stack count: Small numeric badge at bottom-right corner (if applicable)
- Duration: Small horizontal bar at bottom showing remaining turns (stack count fills bar)

| Status Type | Background Color | Icon Examples |
|-------------|------------------|---------------|
| Buff (Positive) | Blue (#4A90D9, 40% opacity) | Shield (格挡), Attack Up (怒气), Dodge (闪避) |
| Debuff (Negative) | Red (#D94A4A, 40% opacity) | Poison (中毒), Burn (灼烧), Weakness (虚弱) |
| Neutral / Special | Purple (#9B4AD9, 40%) | Immune,reflect effects that don't fit above |

**Duration Display**:
- For duration-based status (layer count = turns remaining): horizontal progress bar at bottom of icon
- For consumption-based status (格挡, 穿透): remove icon immediately on consumption

**Interaction**:
- Hover over icon: Tooltip appears with full status name, description, remaining duration, and any numeric values
- No click action — purely informational

**Accessibility**:
- Color is secondary to shape (diamond vs circle)
- Tooltip must be accessible via keyboard focus (Tab navigation to status area)
- Screen reader: When status changes, announce "[Status Name] applied, [duration] turns remaining"
- Color contrast: Icon must have 4.5:1 minimum contrast against colored background

---

#### Resource Display

**Category**: Game-Specific
**Status**: Draft
**When to Use**: Non-interactive display of player resources (gold, cargo, HP).
**When NOT to Use**: Interactive resource spending (use Button patterns).

**Display Format**:
- Icon + numeric value on single line
- High contrast text (white or near-white) on semi-transparent dark background
- Standard spacing: icon 16px, value font size 18px

| Resource | Icon | Normal Color | Low Warning | Format |
|----------|------|--------------|-------------|--------|
| Gold (金币) | Coin bag 🎒 | Yellow (#FFD700) | < 50: Red pulse | 🎒 120 |
| Cargo (粮草) | Wheat bundle 🌾 | Orange (#FFA500) | < 20: Red pulse | 🌾 45/150 |
| HP (生命) | Heart ❤️ | Red (#FF4A4A) | < 20: Red flash + pulse | ❤️ 32/58 |

**Low Resource Warning**:
- When value drops below threshold (configurable per resource), animate:
  - Icon color shifts to brighter warning red
  - Subtle pulse animation (scale 1.05x, 0.5s cycle)
  - For HP only: health bar also shows distinct pattern (diagonal stripes)

**Accessibility**:
- Always show numeric value (do not rely on color alone for low warning)
- Colorblind-safe warning: icon shape changes (e.g., outline becomes dashed)
- Screen reader: "Gold: 120" (value spoken clearly, no icon name)

---

#### Modal Dialog

**Category**: Layout
**Status**: Draft
**When to Use**: Blocking overlay requiring explicit player decision before
returning to underlying screen. Used for confirmations, alerts, error messages.
**When NOT to Use**: Non-blocking notifications (use Toast); settings screens
(use full-screen replacement).

**Visual Design**:
- Dark overlay: 60% opacity black covering entire screen
- Dialog panel: Centered, 80% minimum width (capped at 600px), rounded corners (8px), white/paper background
- Standard spacing: 24px padding inside panel
- Typography: Title (bold, 20px), body (16px), buttons in footer

**Layout Structure**:
```
┌─────────────────────────────────┐
│            │ Overlay             │
│            └─────────────────────┘
│    ┌─────────────────────────┐   │
│    │     Title (optional)    │   │
│    │    ──────────────────   │   │
│    │                         │   │
│    │   Message body text     │   │
│    │   (wrap to multiple)    │   │
│    │                         │   │
│    │   [Primary] [Secondary] │   │
│    └─────────────────────────┘   │
```

**Behavior**:
- Opens centered with fade-in (150ms)
- Background interaction blocked (click on overlay closes if allowed; by default, requires explicit button)
- ESC key closes dialog with Secondary/Cancel action
- Focus: Primary button receives focus by default

**Accessibility**:
- Focus trap: Tab cycles within dialog only
- Screen reader: Dialog role, label from title; focus moves to first interactive element
- ESC key bound to Secondary/Cancel; announce "Press Escape to cancel"
- Dialog content must be concise; long text requires "scroll within panel" behavior

---

#### Confirmation Dialog

**Category