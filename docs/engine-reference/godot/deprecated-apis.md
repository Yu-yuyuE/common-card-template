# Godot 4.4 → 4.6 Deprecated APIs

## 4.4 → 4.5

### Physics
- `Physics2DServer` methods using old physics types
- `PhysicsBody2D`/`PhysicsBody3D` properties deprecated in favor of new Jolt options

### Rendering
- `VisualServer` methods for old shader systems
- `ShaderMaterial` properties using deprecated syntax

### File System
- `FileAccess` methods returning old error codes

### Input
- `InputEvent` types replaced by new system

### GDScript
- `@export` without type hints
- `@tool` without proper context

## 4.5 → 4.6

### Physics
- **Godot Physics** (replaced by Jolt Physics)
- `Physics2DServer` methods for old physics engine
- `PhysicsBody2D`/`PhysicsBody3D` properties for Godot Physics

### Rendering
- **Vulkan renderer** (replaced by D3D12 on Windows)
- `VisualServer` methods for old glow system

### Core
- **Old IK system** (replaced by new restored IK)
- `Node` lifecycle methods deprecated

### GDScript
- `@onready` without proper context
- `@export` with deprecated types

### Accessibility
- Old accessibility API (replaced by AccessKit)

**Last verified**: 2026-04-10
