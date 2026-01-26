---
name: godot-inspector-driven
description: Move hardcoded values out of code and into the Godot inspector. Use when externalizing magic numbers to @export vars, converting const dictionaries to inspector-editable properties, replacing Spacer nodes with container settings, or making code more data-driven for designer iteration.
---

# Godot Inspector-Driven Development

## Principles

### 1. Expose Magic Numbers as @export vars
Replace hardcoded numeric values with `@export var` for inspector editing.

```gdscript
# Before
var speed := 200.0
draw_circle(center, 20, color)

# After
@export var speed: float = 200.0
@export var circle_radius: float = 20.0
draw_circle(center, circle_radius, color)
```

Use `@export_group()` to organize related exports:
```gdscript
@export_group("Movement")
@export var speed: float = 200.0
@export var acceleration: float = 50.0

@export_group("Visuals")
@export var circle_radius: float = 20.0
@export var line_width: float = 2.0
```

### 2. Build UI in .tscn, Not Code
Avoid `draw_string()` for static UI. Use Label nodes in the scene tree.

Exceptions where `draw_string()` is appropriate:
- Dynamic game rendering (values on game objects)
- Animated/positional text (score popups, tooltips following mouse)
- Debug overlays

### 3. Use Container Properties, Not Spacer Nodes
Replace empty Control nodes used for spacing with container properties.

```
# Before (in .tscn)
[node name="Spacer" type="Control"]
custom_minimum_size = Vector2(0, 10)

# After (on parent VBoxContainer)
theme_override_constants/separation = 10
```

### 4. Data-Driven Design
Convert const dictionaries to @export vars with helper functions.

```gdscript
# Before
const COLORS := {
  Type.A: Color.RED,
  Type.B: Color.BLUE,
}

# After
@export_group("Colors")
@export var type_a_color: Color = Color.RED
@export var type_b_color: Color = Color.BLUE

func get_color(type: Type) -> Color:
  match type:
    Type.A: return type_a_color
    Type.B: return type_b_color
  return Color.WHITE
```

### 5. Avoid Shadowed Variables
When @export vars conflict with local vars, rename the local var.

```gdscript
@export var outline_color: Color = Color.WHITE

func draw_thing() -> void:
  # Wrong: shadows @export var
  var outline_color := Color.RED

  # Right: use different name
  var draw_color := outline_color  # uses @export
```

## Checklist

When refactoring Godot code:

1. [ ] Find hardcoded numbers in drawing/physics code → make @export
2. [ ] Group related exports with @export_group()
3. [ ] Remove const dictionaries for configurable data → @export with helpers
4. [ ] Remove Spacer Control nodes → use container separation property
5. [ ] Check for shadowed variable warnings → rename locals
6. [ ] Ensure ghost/preview drawing uses same exports as actual drawing
