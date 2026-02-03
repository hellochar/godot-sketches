# Building.gd Component Refactoring

## Goal
Refactor building.gd (2613 lines) into a component-based architecture with ~24 focused components.

## Architecture
- Each system becomes a child Node with its own script
- Building.gd becomes a thin coordinator (~300 lines)
- Components communicate via signals and building methods
- Components are conditionally added based on building definition behaviors

## File Structure
```
src/components/
  building_component.gd          # Base class
  multiplier_aggregator.gd       # Multiplier collection
  storage_component.gd           # Storage management
  generator_component.gd         # Resource generation
  processor_component.gd         # Processing logic
  coping_component.gd            # Reactive behaviors
  habit_component.gd             # Daily behaviors
  infrastructure_component.gd    # Road behavior
  resonance_component.gd         # Resonance detection
  saturation_component.gd        # Saturation effects
  harmony_component.gd           # Building harmony
  attunement_component.gd        # Long-term harmony
  emotional_echo_component.gd    # Echo buildup
  fatigue_component.gd           # Processor fatigue
  fragility_component.gd         # Crack/leak
  mastery_component.gd           # Skill building
  velocity_component.gd          # Processing speed
  momentum_component.gd          # Recipe momentum
  legacy_component.gd            # Legacy status
  awakening_component.gd         # Awakening experience
  purity_component.gd            # Purity tracking
  stagnation_component.gd        # Resource aging
  adjacency_component.gd         # Adjacency effects
  suppression_component.gd       # Suppression field
  network_component.gd           # Support networks
```

---

## Phase 1: Infrastructure [COMPLETED]
- [x] Create building_component.gd base class
- [x] Create multiplier_aggregator.gd
- [x] Create storage_component.gd
- [x] Add component registration to Building.gd
- [x] Delegate storage methods to StorageComponent
- [x] Extract generator_component.gd
- [x] Run game to verify Phase 1 works

---

## Phase 2: Core Behaviors [COMPLETED]
- [x] Extract processor_component.gd
- [x] Extract coping_component.gd
- [x] Extract habit_component.gd
- [x] Extract infrastructure_component.gd
- [x] Replace is_road() with has_component("infrastructure")
- [x] Run game to verify Phase 2 works

---

## Phase 3: Emotional Systems [COMPLETED]
- [x] Extract resonance_component.gd
- [x] Extract saturation_component.gd
- [x] Extract harmony_component.gd
- [x] Extract attunement_component.gd
- [x] Extract emotional_echo_component.gd
- [x] Run game to verify Phase 3 works

---

## Phase 4: Building State [COMPLETED]
- [x] Extract fatigue_component.gd
- [x] Extract fragility_component.gd
- [x] Extract mastery_component.gd
- [x] Extract velocity_component.gd
- [x] Extract momentum_component.gd
- [x] Extract legacy_component.gd
- [x] Extract awakening_component.gd
- [x] Run game to verify Phase 4 works

---

## Phase 5: Resource & Utility
- [ ] Extract purity_component.gd
- [ ] Extract stagnation_component.gd
- [ ] Extract adjacency_component.gd
- [ ] Extract suppression_component.gd
- [ ] Extract network_component.gd
- [ ] Remove all hard-coded ID checks
- [ ] Final cleanup of Building.gd coordinator
- [ ] Run game to verify Phase 5 works

---

## Phase 6: Validation
- [ ] Write gdUnit4 tests for critical components
- [ ] Run full test suite
- [ ] Verify building.gd is under 500 lines
- [ ] Final verification - run game end to end

---

## Progress Log

### 2026-02-02
- Phase 1 completed. Created base infrastructure, storage component, generator component.
- Game runs without errors.

---

## Key Patterns

### Component Base Class
```gdscript
class_name BuildingComponent
extends Node

var building: Node
var definition: Dictionary
var grid: Node
# Lazy-loaded autoloads via getters

func _init_component(p_building: Node) -> void
func on_initialize() -> void
func on_process(delta: float) -> void
func get_speed_multiplier() -> float
func get_output_bonus() -> int
```

### Adding Components in Building._setup_components()
```gdscript
if BuildingDefs.Behavior.X in behaviors:
  var comp = preload("res://.../x_component.gd").new()
  _add_component("x", comp)
```

### Skipping Old Code When Component Exists
```gdscript
func _process_x(delta: float) -> void:
  if has_component("x"):
    return
  # old code...
```

---

## IMPORTANT FOR CONTEXT COMPACTION
When compacting context, reference this file first:
`c:\Users\hello\godot\sketches\jan_28_2026-psychebuilder-ai\REFACTOR_BUILDING_COMPONENTS.md`

This file contains the full plan, progress, and patterns needed to continue the refactoring.
