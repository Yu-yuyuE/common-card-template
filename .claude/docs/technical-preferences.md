# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6.1
- **Language**: GDScript (primary), C# (utilities)
- **Rendering**: 2D (Godot's dedicated 2D engine)
- **Physics**: Godot Physics (Jolt optional for 3D, not needed for 2D)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows/macOS) and Mobile (iOS/Android)
- **Input Methods**: Keyboard/Mouse, Touch
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: UI must support both precise mouse clicks and larger touch targets. UI scaling must accommodate small mobile screens.

## Naming Conventions

- **Classes**: PascalCase (e.g., `CardController`, `BattleManager`)
- **Variables**: camelCase (e.g., `currentHealth`, `cardCost`)
- **Signals/Events**: camelCase past tense (e.g., `healthChanged`, `cardPlayed`)
- **Files**: snake_case matching class (e.g., `card_controller.cs`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `Card.tscn`)
- **Constants**: PascalCase or UPPER_SNAKE_CASE

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: 2000 maximum
- **Memory Ceiling**: 512MB RAM

## Testing

- **Framework**: GUT (Godot Unit Test) for GDScript, or NUnit for C#
- **Minimum Coverage**: Core game systems, balance formulas
- **Required Tests**: Balance formulas, gameplay systems

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: [TO BE CONFIGURED — run /setup-engine]
- **Language/Code Specialist**: [TO BE CONFIGURED]
- **Shader Specialist**: [TO BE CONFIGURED]
- **UI Specialist**: [TO BE CONFIGURED]
- **Additional Specialists**: [TO BE CONFIGURED]
- **Routing Notes**: [TO BE CONFIGURED]

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (primary language) | [TO BE CONFIGURED] |
| Shader / material files | [TO BE CONFIGURED] |
| UI / screen files | [TO BE CONFIGURED] |
| Scene / prefab / level files | [TO BE CONFIGURED] |
| Native extension / plugin files | [TO BE CONFIGURED] |
| General architecture review | Primary |
