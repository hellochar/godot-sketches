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

### 6. Game Content → Resource Classes + .tres Files
For game content (cards, items, levels), create Resource classes with @export fields:

```gdscript
# card_resource.gd
class_name CardResource extends Resource

@export var title: String
@export var cost: int = 50
@export_range(0.0, 1.0) var success_chance: float = 0.8

@export_group("Tag Modifiers")
@export var health_modifier: int = 0
@export var social_modifier: int = 0
```

Then create individual `.tres` files editable in the inspector. Group related content in folders:
```
data/
├── cards/
│   ├── fire_spell.tres
│   └── heal.tres
├── items/
│   └── sword.tres
└── starter_deck.tres
```

### 7. Aggregate Resources → Collection Resource
Create a collection resource to reference multiple content pieces:

```gdscript
# deck_resource.gd
class_name DeckResource extends Resource

@export var cards: Array[Resource] = []
@export var items: Array[Resource] = []
```

**Important:** Use `Array[Resource]` not `Array[CardResource]` to avoid load-order issues with custom class names.

Wire the collection to your main scene via @export:
```gdscript
@export var starter_deck: Resource

func _ready() -> void:
  if starter_deck:
    game_state.load_from_deck(starter_deck)
```

### 8. Scene Templates for Dynamic UI
When creating UI elements dynamically, prefer PackedScene templates over pure code:

```gdscript
@export var card_scene: PackedScene

func _create_card(data: Resource) -> Control:
  var card := card_scene.instantiate()
  card.setup(data)
  return card
```

This allows designers to tweak card appearance in the editor without touching code.

## Checklist

When refactoring Godot code:

1. [ ] Find hardcoded numbers (sizes, margins, radii, durations) → `@export var`
2. [ ] Find hardcoded colors → `@export var color: Color`
3. [ ] Group related exports with `@export_group()`
4. [ ] Remove const dictionaries for configurable data → `@export` with match helpers
5. [ ] Remove Spacer Control nodes → use container separation property
6. [ ] Check for shadowed variable warnings → rename locals
7. [ ] Ensure ghost/preview drawing uses same exports as actual drawing
8. [ ] Game content (cards, items, enemies) → Resource classes + .tres files
9. [ ] Collections of content → aggregate resource with `Array[Resource]`
10. [ ] Dynamic UI elements → PackedScene templates via `@export var scene: PackedScene`
11. [ ] Load resources in `_ready()`, not `_init()` (for proper @export wiring)
