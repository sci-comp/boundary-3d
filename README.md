# Boundary3D

Create collision boundaries by clicking points in Godot's 3D viewport.

https://github.com/user-attachments/assets/fbadf953-2705-4669-943a-e1f873440010

## Installation

1. Copy `boundary_3d` addon to `addons/`
2. Enable in Project Settings > Plugins
3. `Boundary3D` node available in scene dock

## Usage

1. Add `Boundary3D` node to scene
2. Enable `Tool Active` in inspector
3. Click collision shapes to place points
4. Press Enter or disable `Tool Active` to create boundaries
5. Click `Cleanup` when done to remove the unnecessary script

## Controls

- **Left Click**: Place point (on collision shapes)
- **Escape**: Remove last point
- **Enter**: Generate boundaries
- **Ctrl+C**: Clear all points

## Settings

**Boundary Settings**
- Height/Width: Dimensions of generated walls
- Collision Layer/Mask: Physics settings

**Tool Control**
- Tool Active: Enable/disable tool
- Cleanup: Remove script when finished

## Output

Creates `StaticBody3D` nodes with `BoxShape3D` collision between each pair of points.

**Requirements:** Godot 4.x, collision shapes in scene for point placement.

**License:** MIT
