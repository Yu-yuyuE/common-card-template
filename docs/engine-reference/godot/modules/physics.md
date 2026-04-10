# Godot 4.6 Physics Module

## Jolt Physics

Jolt Physics is the default physics engine in Godot 4.6. It provides:
- Better performance
- More accurate physics
- Better stability
- Better collision detection

### Migration from Godot Physics

1. Replace `PhysicsBody2D` with `RigidBody2D`
2. Replace `PhysicsBody3D` with `RigidBody3D`
3. Update physics material properties
4. Update collision shape properties

### Recommended Settings

- **Contact Monitoring**: Enabled
- **Max Contacts Reported**: 64
- **Sleep Threshold**: 0.05
- **Sleep Velocity**: 0.01

### Best Practices

- Use `RigidBody2D`/`RigidBody3D` for dynamic objects
- Use `StaticBody2D`/`StaticBody3D` for static objects
- Use `CharacterBody2D`/`CharacterBody3D` for characters
- Avoid using `Area2D`/`Area3D` for collision detection

**Last verified**: 2026-04-10
