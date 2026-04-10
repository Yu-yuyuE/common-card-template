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
godot --headless --script tests/gdunit4_runner.gd

# Run a specific test suite
godot --headless --script tests/gdunit4_runner.gd
```

### CI/CD

Tests are automatically run on every push to `main` and on pull requests via GitHub Actions. Merging is blocked if tests fail.

## Test Naming

- **Files**: `[system]_[feature]_test.gd`
- **Functions**: `test_[scenario]_[expected]`
- **Example**: `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `tests/evidence/` |
| UI | Manual walkthrough OR interaction test | `tests/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## Installing GdUnit4

1. Open Godot → AssetLib → search "GdUnit4" → Download & Install
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: `res://addons/gdunit4/` exists
