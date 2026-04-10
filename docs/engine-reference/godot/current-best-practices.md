# Godot 4.6 Best Practices

## Physics
- **Always use Jolt Physics** - It's the default and recommended engine
- Use `PhysicsBody2D`/`PhysicsBody3D` with Jolt properties
- Avoid Godot Physics unless you have legacy code

## Rendering
- **Use D3D12 on Windows** - It's the default and offers better performance
- Use the new shader-based glow system
- Prefer `ShaderMaterial` with modern syntax

## Core
- **Use the restored IK system** in `Bone2D`/`Bone3D`
- Use `@onready` for automatic property initialization
- Use `@export` with explicit types
- Use `@tool` for editor scripts

## GDScript
- Use `@abstract` for abstract classes
- Use variadic arguments for flexible function parameters
- Use type hints for all exported variables
- Use `@onready` for lazy initialization

## Accessibility
- **Use AccessKit** for screen reader support
- Implement accessibility properties on UI elements
- Test with screen readers

## Performance
- Use `Resource` caching for frequently loaded assets
- Use `SceneTree` signals efficiently
- Profile with Godot's built-in profiler

## Localization
- Use Godot's built-in localization system with CSV files
- Use `Localization` class for text retrieval
- Support full Unicode for CJK characters

## Project Structure
- Use `res://` for all resource references
- Organize assets in clear directories
- Use `@tool` scripts for editor utilities

**Last verified**: 2026-04-10
