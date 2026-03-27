# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6.1
- **Language**: C# (primary), GDScript (utilities)
- **Rendering**: 2D (Godot's dedicated 2D engine)
- **Physics**: Godot Physics (Jolt optional for 3D, not needed for 2D)

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
- **Draw Calls**: [TO BE CONFIGURED]
- **Memory Ceiling**: [TO BE CONFIGURED - typical 512MB for 2D game]

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
