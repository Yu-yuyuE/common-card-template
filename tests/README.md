# Test Framework

This directory contains the automated test suite and manual test records for the project.

## Directory Structure

- `unit/` — Isolated tests for individual classes, formulas, state machines, and core logic. Unit tests must not depend on external systems, file I/O, or the scene tree being fully initialized.
- `integration/` — Tests that verify multiple systems working together, such as save/load round-trips, combat sequence resolution, and complex entity interactions.
- `smoke/` — Critical path test lists designed for a 15-minute manual gate pass. Used before a release or milestone to ensure the build isn't fundamentally broken.
- `evidence/` — Screenshot and manual test sign-off records for stories whose requirements are visual, experiential, or UI-driven and cannot be effectively automated.

## Godot 4.6.1 Testing (GdUnit4)

This project uses GdUnit4 for automated testing in Godot.

### Running Tests Locally

You can run the tests from within the Godot Editor using the GdUnit4 plugin panel, or from the command line:

```bash
# Run all tests headlessly
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/

# Run a specific test suite
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/unit/card_battle_system/
```

### CI/CD

Tests are automatically run on every push to `main` and on pull requests via GitHub Actions. Merging is blocked if tests fail.
