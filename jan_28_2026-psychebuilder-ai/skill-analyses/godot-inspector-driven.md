# Inspector-Driven Development Analysis: PsycheBuilder

## Summary

The PsycheBuilder project demonstrates **strong adherence** to inspector-driven principles in some areas (config.gd, resource types), but has **significant gaps** in others (building/event definitions, dynamic UI creation).

---

## Checklist Analysis

### 1. Hardcoded Numbers -> @export var

**GOOD:**
- `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/autoload/config.gd` - Excellent. 400+ lines of well-organized @export vars with 40+ @export_group() sections covering all game mechanics
- `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/jan_28_2026.gd` - Good. 50+ @export vars for UI, colors, thresholds

**ISSUES FOUND:**
| File | Line(s) | Hardcoded Value | Recommendation |
|------|---------|-----------------|----------------|
| `jan_28_2026.gd` | 497 | `Color(1, 0.3, 0.3)` | Add `@export var error_message_color: Color` |
| `jan_28_2026.gd` | 761-763 | `60, -200, 200` offsets | Add to Tutorial Hints export group |
| `jan_28_2026.gd` | 766-769 | `16, 16, 12, 12` margins | Add `@export var tutorial_popup_margins: int = 16` |
| `jan_28_2026.gd` | 778-780 | `13, 360` font/width | Add to Tutorial Hints export group |
| `adjacency_rules.gd` | 3 | `ADJACENCY_RADIUS = 2` | Move to config.gd as `@export var adjacency_radius: int = 2` |

### 2. Hardcoded Colors -> @export var color: Color

**GOOD:** Most colors are in @export vars (wellbeing colors, toast colors, tier colors)

**ISSUES:**
| File | Line | Color | Recommendation |
|------|------|-------|----------------|
| `jan_28_2026.gd` | 497 | `Color(1, 0.3, 0.3)` | `@export var placement_error_color: Color` |
| `jan_28_2026.gd` | 602 | `Color(0.7, 0.7, 0.7)` | `@export var tier_baseline_color: Color` |
| `jan_28_2026.gd` | 739 | `Color(0.6, 0.8, 0.9)` | Add to Tooltip export group |
| `jan_28_2026.gd` | 954-955 | `Color(0.6, 0.6, 0.6)` | `@export var empty_text_color: Color` |
| `jan_28_2026.gd` | 1118-1122 | `Color(0.5, 0.8, 0.5)`, `Color(0.9, 0.4, 0.4)` | `@export var connection_good/bad_color` |

### 3. @export_group() Organization

**EXCELLENT:** Both config.gd and jan_28_2026.gd use extensive @export_group() organization.

### 4. Const Dictionaries for Configurable Data

**MAJOR ISSUE:** Several large dictionaries are hardcoded in code that should be @export or .tres resources:

| File | Dictionary | Recommendation |
|------|-----------|----------------|
| `building_definitions.gd` | `definitions` (879 lines, 50+ buildings) | Create BuildingResource class + .tres files |
| `event_definitions.gd` | `definitions` (452 lines, 20+ events) | Create EventResource class + .tres files |
| `adjacency_rules.gd` | `rules` (220 lines) | Move to config.gd or AdjacencyRulesResource.tres |
| `adjacency_rules.gd` | `generator_stacking` (line 223) | Move to config.gd |

### 5. Spacer Control Nodes -> Container Properties

**ISSUE in jan_28_2026.tscn:**
```
Lines 91-93: [node name="LeftSpacer" type="Control"]
Line 150:    [node name="RightSpacer" type="Control"]
```

**Fix:** Remove spacers and use `size_flags_horizontal = SIZE_EXPAND` on TimeControlsPanel instead, or use a CenterContainer.

### 6. Shadowed Variable Warnings

No shadowing issues detected.

### 7. Ghost/Preview Drawing Consistency

Not applicable to this project.

### 8. Game Content -> Resource Classes + .tres Files

**GOOD:**
- `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/resources/resource_types/*.tres` - 32 resource type files
- `resource_type.gd` - Clean Resource class with @export fields

**NEEDS WORK:**
- **Buildings:** 50+ building definitions in `building_definitions.gd` should be individual .tres files
- **Events:** 20+ event definitions in `event_definitions.gd` should be individual .tres files

### 9. Collections -> Aggregate Resource with Array[Resource]

**NOT IMPLEMENTED:**
- No aggregate resource for building collections
- No aggregate resource for event collections
- `starting_buildings` in config.gd (line 445-455) is Array[Dictionary] - should reference BuildingResource files

### 10. Dynamic UI -> PackedScene Templates

**ISSUES:** UI elements created in code instead of .tscn templates:

| File | Function | Lines | Recommendation |
|------|----------|-------|----------------|
| `jan_28_2026.gd` | `_create_building_tooltip()` | 690-742 | Create `building_tooltip.tscn` |
| `jan_28_2026.gd` | `_create_tutorial_hint_popup()` | 756-789 | Create `tutorial_hint_popup.tscn` |
| `jan_28_2026.gd` | `_create_toast()` | 876-913 | Create `toast.tscn`, add `@export var toast_scene: PackedScene` |
| `jan_28_2026.gd` | `_populate_resource_list()` | 791-820 | Create `resource_list_item.tscn` |

### 11. Load Resources in _ready(), Not _init()

**GOOD:** Resources are loaded appropriately.

---

## Recommendations / TODOs

### High Priority (Designer Iteration Blockers)

1. **Convert building_definitions.gd to .tres files**
   - Create `class_name BuildingResource extends Resource`
   - Create `resources/buildings/*.tres` for each building
   - Create `resources/building_catalog.tres` as collection resource
   - Allows designers to edit buildings in inspector

2. **Convert event_definitions.gd to .tres files**
   - Create `class_name EventResource extends Resource`
   - Create `resources/events/*.tres` for each event
   - Create `resources/event_catalog.tres` as collection resource

3. **Move adjacency_rules.gd to config.gd or .tres**
   - Add `@export var adjacency_radius: int = 2` to config.gd
   - Move `generator_stacking` Dictionary to config.gd as @export

### Medium Priority (Code Quality)

4. **Create PackedScene templates for dynamic UI:**
   - `src/ui/building_tooltip.tscn`
   - `src/ui/tutorial_hint_popup.tscn`
   - `src/ui/toast.tscn`
   - `src/ui/resource_list_item.tscn`

5. **Remove Spacer nodes in jan_28_2026.tscn:**
   - Remove LeftSpacer, RightSpacer nodes
   - Use container size_flags or CenterContainer instead

6. **Export remaining hardcoded colors:**
   - `error_message_color`
   - `tier_baseline_color`
   - `empty_text_color`
   - `connection_good_color`, `connection_bad_color`
   - `indicator_label_color`

### Low Priority (Polish)

7. **Export hardcoded numbers in tutorial popup:**
   - Tutorial popup offsets
   - Tutorial popup margins
   - Font sizes

8. **Add @export for loop constants:**
   - Magic numbers in `_find_road_near_building` range loop

---

## What's Working Well

1. **config.gd is exemplary** - 400+ lines of well-organized @export vars with descriptive groups
2. **Resource types use .tres files** - 32 emotion/resource types as inspector-editable files
3. **Main scene uses .tscn nodes** - UI hierarchy defined in scene, not code
4. **Uses %UniqueNames** - Good practice for node access
5. **jan_28_2026.gd has extensive @export groups** - UI colors, sizes, thresholds all configurable

---

## Designer Iteration Score

| Area | Can Iterate Without Code? |
|------|---------------------------|
| Time/Energy/Attention settings | Yes |
| Wellbeing mechanics | Yes |
| Visual effects thresholds | Yes |
| UI colors and sizes | Yes |
| Resource types | Yes |
| **Building definitions** | **No** |
| **Event definitions** | **No** |
| **Adjacency rules** | **No** |
| Toast/tooltip appearance | No |
| Tutorial popup structure | No |

**Overall:** 60% data-driven. Main gap is building/event definitions locked in code.