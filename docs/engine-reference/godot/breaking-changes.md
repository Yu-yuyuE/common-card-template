# Godot 4.4 → 4.6 Breaking Changes

## 4.4 → 4.5 Changes

### Physics
- `Physics2DServer` and `Physics3DServer` API changes
- Jolt Physics became an option (default in 4.6)
- `PhysicsBody2D` and `PhysicsBody3D` node changes

### File System
- `FileAccess` return types changed to `Error` enum
- File path handling updated for better cross-platform support

### Rendering
- Shader texture type changes
- New `ShaderMaterial` properties
- `VisualServer` API updates

### Input
- New `InputEvent` types
- `InputMap` improvements

### GDScript
- `@onready` attribute improvements
- `@export` attribute enhancements
- `@tool` improvements

## 4.5 → 4.6 Changes

### Physics
- **Jolt Physics became the default physics engine** (replacing Godot Physics)
- `PhysicsBody2D` and `PhysicsBody3D` defaults changed
- Physics material properties updated

### Rendering
- **Glow effect rework** (new shader-based system)
- **D3D12 became the default renderer on Windows** (replacing Vulkan)
- Shader compilation changes

### Core
- **Inverse Kinematics (IK) restored** in `Bone2D` and `Bone3D`
- `Node` lifecycle changes
- `Resource` loading improvements

### GDScript
- `@abstract` attribute added
- Variadic arguments support
- Better type inference

### Accessibility
- AccessKit integration for screen readers
- New accessibility API

### Miscellaneous
- `EditorPlugin` API changes
- `Theme` system improvements
- `Node` property changes

**Last verified**: 2026-04-10
