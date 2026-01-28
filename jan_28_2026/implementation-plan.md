# Psyche-Builder: Implementation Plan

## Overview

This document breaks down implementation into phases and granular tasks. Each task should take no more than a few minutes to a couple hours. Check off tasks as completed.

**Estimated total time: 3-4 weeks of focused work**

---

## Phase 0: Project Setup (Day 1)

### 0.1 Godot Project Initialization
- [x] Create new Godot 4.x project named "psyche_builder"
- [x] Set up project settings (window size: 1920x1080, stretch mode)
- [x] Create folder structure as defined in spec
- [x] Set up .gitignore for Godot project
- [x] Initialize git repository

### 0.2 Autoload Setup
- [x] Create `src/autoload/` folder
- [x] Create `game_state.gd` skeleton with basic properties
- [x] Create `event_bus.gd` with signal definitions
- [x] Create `config.gd` with developer knobs
- [x] Register all three as autoloads in project settings

### 0.3 Basic Scene Structure
- [x] Create `main.tscn` as entry point
- [x] Create `game_world.tscn` with Node2D root
- [x] Create `ui_layer.tscn` with CanvasLayer root
- [x] Set up main.tscn to instance game_world and ui_layer
- [x] Verify project runs with empty scenes

---

## Phase 1: Grid & Tile System (Days 1-2)

### 1.1 Grid Manager
- [x] Create `src/systems/grid_system.gd`
- [x] Define grid size constants (e.g., 50x50 tiles)
- [x] Define tile size constant (e.g., 64px)
- [x] Implement `world_to_grid(pos)` function
- [x] Implement `grid_to_world(coord)` function
- [x] Implement `is_valid_coord(coord)` function
- [x] Create tile occupancy tracking (Dictionary)
- [x] Implement `is_occupied(coord)` function
- [x] Implement `set_occupied(coord, entity)` function
- [x] Implement `clear_occupied(coord)` function

### 1.2 Visual Grid
- [x] Create TileMap node in game_world.tscn
- [x] Create or source simple grass/ground tile (placeholder)
- [x] Set up TileSet with ground tile
- [x] Fill grid with ground tiles
- [x] Add visual grid overlay (toggle-able) for placement guidance

### 1.3 Camera Setup
- [x] Add Camera2D to game_world.tscn
- [x] Implement camera pan (middle-mouse drag or WASD)
- [x] Implement camera zoom (scroll wheel)
- [x] Clamp camera to grid bounds
- [x] Set reasonable default position and zoom

### 1.4 Tile Selection/Hover
- [x] Implement mouse position to grid coord conversion
- [x] Create hover indicator sprite
- [x] Update hover indicator position each frame
- [x] Change hover indicator color based on validity (green/red)

---

## Phase 2: Resource System Foundation (Days 2-3)

### 2.1 Resource Type Definition
- [x] Create `resources/resource_types/` folder
- [x] Create base `ResourceType` custom Resource class
  - [x] Properties: name, display_name, icon, color, tags, decay_rate, stack_size, description
- [x] Create first resource .tres: `joy.tres`
- [x] Create second resource .tres: `grief.tres`
- [x] Create third resource .tres: `calm.tres`
- [x] Create fourth resource .tres: `energy_resource.tres` (if needed as item, or skip) - skipped, energy is global
- [x] Create fifth resource .tres: `wisdom.tres`

### 2.2 Resource Item Entity
- [x] Create `src/entities/resource_item.gd`
- [x] Create scene `resource_item.tscn` with Sprite2D + script
- [x] Implement initialization from ResourceType
- [x] Implement visual representation (colored circle placeholder)
- [x] Add `amount` property for stacking
- [x] Implement `decay()` function stub
- [ ] Add collision shape for pickup detection

### 2.3 Resource Spawning
- [x] Create `src/systems/resource_system.gd`
- [x] Implement `spawn_resource(type_id, position, amount)` function
- [x] Track all active resource items in array
- [x] Implement `get_resource_total(type_id)` for city-wide sum
- [x] Add signal emission on spawn

### 2.4 Resource Decay
- [x] Implement decay tick in resource_system
- [x] Each resource item reduces based on decay_rate
- [x] Remove resource items when amount <= 0
- [x] Add signal emission on removal

### 2.5 Test Resource System
- [x] Add debug key to spawn resources at mouse position
- [ ] Verify resources appear visually
- [ ] Verify decay works over time
- [ ] Verify totals update correctly

---

## Phase 3: Building System Foundation (Days 3-5)

### 3.1 Building Data Structure
- [x] Create `src/data/building_definitions.gd`
- [x] Define building data dictionary structure
- [x] Add first building: "road" (infrastructure)
- [x] Add second building: "emotional_reservoir" (storage)
- [x] Add third building: "memory_well" (generator)
- [x] Add fourth building: "mourning_chapel" (processor)
- [x] Add fifth building: "morning_routine" (habit)

### 3.2 Building Entity Base
- [x] Create `src/entities/building.gd` base script
- [x] Create `building.tscn` base scene
- [x] Implement initialization from building definition
- [x] Add grid coordinate tracking
- [x] Add size support (1x1, 2x2, etc.)
- [x] Implement placeholder sprite based on building type

### 3.3 Building Placement
- [x] Create `src/systems/building_system.gd`
- [x] Implement `can_place(building_id, coord)` function
  - [x] Check grid bounds
  - [x] Check occupancy for all tiles building needs
- [x] Implement `place_building(building_id, coord)` function
  - [x] Instance building scene
  - [x] Initialize with definition
  - [x] Mark grid tiles as occupied
  - [x] Add to active buildings list
- [x] Implement `remove_building(building)` function

### 3.4 Building Placement UI
- [x] Create building selection state in game
- [x] When building selected, show preview at hover position
- [x] Left-click to place (if valid)
- [x] Right-click or Escape to cancel
- [x] Add temporary debug keys to select different buildings

### 3.5 Test Building Placement
- [ ] Place roads in various patterns
- [ ] Place multi-tile building (2x2)
- [ ] Verify occupancy prevents overlap
- [ ] Verify buildings persist

---

## Phase 4: Road & Pathfinding (Days 5-6)

### 4.1 Road Implementation
- [x] Create `src/entities/road.gd` (extends building or separate) - using building with INFRASTRUCTURE behavior
- [x] Roads are 1x1 tiles
- [ ] Roads visually connect to adjacent roads
- [ ] Implement road sprite with connection variants (or simple for now)

### 4.2 Pathfinding Setup
- [x] Implement A* pathfinding in grid_system or separate file
- [x] Pathfinding only considers road tiles as walkable
- [x] Implement `find_path(start_coord, end_coord)` function
- [x] Return array of coords or empty if no path

### 4.3 Building Connection
- [ ] Buildings need road adjacency to be "connected"
- [ ] Implement `is_building_connected(building)` function
- [ ] Visual indicator for unconnected buildings (red tint?)
- [ ] Unconnected buildings don't function

### 4.4 Test Pathfinding
- [ ] Draw path visually for debugging
- [ ] Verify paths go around obstacles
- [ ] Verify buildings report connected status correctly

---

## Phase 5: Worker System (Days 6-8)

### 5.1 Worker Entity
- [x] Create `src/entities/worker.gd`
- [x] Create `worker.tscn` with visual (glowing mote sprite)
- [x] Properties: current_job, job_target_a, job_target_b, current_path, habituation_level
- [x] Worker states: idle, moving_to_pickup, carrying, moving_to_dropoff

### 5.2 Worker Movement
- [x] Implement path following
- [x] Workers move along path coords
- [x] Set movement speed constant
- [ ] Visual: worker leaves faint trail (optional, can defer)
- [x] Smooth interpolation between tiles

### 5.3 Worker Job Assignment
- [x] Create `src/systems/worker_system.gd`
- [x] Track all workers in array
- [x] Track attention pool (available, used)
- [x] Implement `assign_job(worker, job_type, target_a, target_b)` function
- [x] Job types: "transport" (carry from A to B), "operate" (stay at building)
- [x] Calculate attention cost based on habituation
- [x] Deduct attention from pool

### 5.4 Transport Job Logic
- [x] Worker assigned transport job: resource_type, source_building, dest_building
- [x] Worker pathfinds to source
- [x] Worker picks up resource (remove from source storage)
- [x] Worker pathfinds to destination
- [x] Worker drops off resource (add to dest storage)
- [x] Worker returns to idle (or repeats if job is persistent)
- [x] Increment job completion counter

### 5.5 Habituation System
- [x] Track completions per job (job identified by type + targets)
- [x] Implement habituation threshold checks
- [x] Reduce attention cost at each threshold
- [x] Refund attention to pool when cost decreases
- [ ] Visual/UI indicator of habituation level

### 5.6 Worker Assignment UI
- [x] Click building to select
- [x] If building can be source (has output), show "assign worker to transport from here"
- [x] Click destination building
- [x] Create transport job
- [ ] Show current worker assignments somehow

### 5.7 Test Worker System
- [ ] Assign worker to carry resource between two buildings
- [ ] Verify resource moves
- [ ] Verify attention is deducted
- [ ] Verify habituation progresses
- [ ] Verify attention is refunded at thresholds

---

## Phase 6: Building Behaviors (Days 8-10)

### 6.1 Storage Behavior
- [x] Buildings with storage behavior have inventory Dictionary
- [x] Inventory maps resource_type_id to amount
- [x] Capacity limits per type or total
- [x] Implement `add_to_storage(resource_type, amount)` - returns overflow
- [x] Implement `remove_from_storage(resource_type, amount)` - returns actual removed
- [x] Implement `get_storage_amount(resource_type)`
- [ ] Implement `has_space_for(resource_type, amount)`

### 6.2 Generator Behavior
- [x] Buildings with generator behavior produce resources
- [x] Track generation timer
- [x] On timer complete: spawn resource into building's storage
- [x] If storage full, resource spawns in world nearby
- [x] Define generation rate in building definition

### 6.3 Processor Behavior
- [x] Buildings with processor behavior transform resources
- [x] Check if input resources available in storage
- [x] If yes and worker assigned (if required): begin processing
- [x] Track processing timer
- [x] On complete: remove inputs, add outputs to storage
- [x] Define input/output/time in building definition

### 6.4 Habit Behavior
- [x] Buildings with habit behavior run automatically each day
- [ ] Trigger during day phase
- [x] Execute defined effect (spawn, process, etc.)
- [x] May consume energy

### 6.5 Coping Behavior
- [x] Buildings with coping behavior activate on condition
- [x] Define trigger condition in building definition
- [ ] Check condition each tick
- [ ] When triggered: activate special behavior (faster processing, spawn calming resource, etc.)
- [x] May have cooldown

### 6.6 Global Effect Behavior
- [ ] Buildings with global_effect provide city-wide modifiers
- [ ] Register effect with game_state on placement
- [ ] Unregister on removal
- [ ] Effects are checked by other systems (e.g., "all positive emotions +20%")

### 6.7 Test Building Behaviors
- [ ] Place generator, verify it produces resources
- [ ] Place processor, assign worker, verify transformation
- [ ] Place habit building, advance day, verify it triggers
- [ ] Place coping building, trigger condition, verify activation

---

## Phase 7: Time System (Days 10-11)

### 7.1 Day/Night Cycle Core
- [ ] Create `src/systems/time_system.gd`
- [ ] Track current day number
- [ ] Track current phase: "day" or "night"
- [ ] Track time within phase (0.0 to 1.0 or seconds)
- [ ] Define day phase duration (e.g., 45 seconds)

### 7.2 Phase Transitions
- [ ] Emit signal when day phase starts
- [ ] Emit signal when night phase starts
- [ ] During day: simulation runs
- [ ] During night: simulation paused, planning allowed

### 7.3 Time Controls
- [ ] Speed control: 1x, 2x, 3x
- [ ] Pause button (during day - for events)
- [ ] Manual advance button (during night - "End Planning Phase")
- [ ] Show current day number in UI

### 7.4 Time-Based Triggers
- [ ] Hook habit buildings to day_started signal
- [ ] Hook energy regeneration to day_started signal
- [ ] Hook resource decay to tick (or day-based)

### 7.5 Test Time System
- [ ] Verify day/night cycle visually (maybe just a label for now)
- [ ] Verify simulation pauses at night
- [ ] Verify speed controls work
- [ ] Verify day-start hooks trigger

---

## Phase 8: Energy System (Days 11-12)

### 8.1 Energy State
- [ ] Add energy tracking to game_state
- [ ] Properties: current_energy, max_energy
- [ ] Initialize from config

### 8.2 Energy Regeneration
- [ ] On day start: add base regeneration amount
- [ ] Cap at max_energy
- [ ] Modifiable by buildings (Sleep Chamber bonus)

### 8.3 Energy Consumption
- [ ] Building placement costs energy
- [ ] Some building operations cost energy
- [ ] Starting new worker assignments costs energy (separate from attention?)
  - [ ] Note: Review if energy vs attention distinction is needed for workers
- [ ] Implement `spend_energy(amount)` function
- [ ] Returns false if insufficient

### 8.4 Energy UI
- [ ] Display current/max energy prominently
- [ ] Show regeneration amount
- [ ] Warn when low
- [ ] Show cost preview when placing buildings

### 8.5 Test Energy System
- [ ] Verify energy starts correctly
- [ ] Verify placing buildings costs energy
- [ ] Verify regeneration works
- [ ] Verify can't place when insufficient energy

---

## Phase 9: Metrics & Wellbeing (Days 12-13)

### 9.1 Metrics Tracking
- [ ] Create `src/systems/metrics_system.gd`
- [ ] Track all resource totals (delegate to resource_system)
- [ ] Track building counts by behavior type
- [ ] Track processing throughput (resources processed this day)
- [ ] Track attention used/available

### 9.2 Wellbeing Calculation
- [ ] Implement wellbeing formula from spec
- [ ] Recalculate on relevant changes (resource change, building change)
- [ ] Clamp to 0-100 range
- [ ] Store in game_state

### 9.3 Wellbeing UI
- [ ] Create prominent wellbeing meter
- [ ] Show numerical value
- [ ] Color gradient (red < yellow < green)
- [ ] Optional: particle effects at high wellbeing

### 9.4 Metrics Dashboard
- [ ] Create collapsible panel showing key metrics
- [ ] Resource totals (top 5-10 most relevant)
- [ ] Energy and attention
- [ ] Day counter
- [ ] Processing throughput

### 9.5 Test Metrics
- [ ] Verify wellbeing changes when resources change
- [ ] Verify UI updates in real-time
- [ ] Verify formula weights feel reasonable (tune as needed)

---

## Phase 10: Events System (Days 13-15)

### 10.1 Event Data Structure
- [ ] Create `src/data/event_definitions.gd`
- [ ] Define event data dictionary structure
- [ ] Add first event: "good_day" (simple positive)
- [ ] Add second event: "intrusive_thought" (simple negative)
- [ ] Add third event: "the_rejection" (inciting incident)

### 10.2 Event System Core
- [ ] Create `src/systems/event_system.gd`
- [ ] Track event pools by phase (early, mid, late)
- [ ] Track event history (which have occurred)
- [ ] Track current active event (if any)

### 10.3 Event Triggering
- [ ] Random event chance each day (configurable)
- [ ] Inciting incident triggers on specific day (e.g., day 5)
- [ ] Draw event from appropriate pool
- [ ] Execute event spawn effects

### 10.4 Event Spawning
- [ ] Parse event spawns array
- [ ] Spawn each resource at specified location
- [ ] Location types: "center", "random", "specific_building"
- [ ] Emit event_occurred signal

### 10.5 Event Choices UI
- [ ] Create `src/ui/event_popup.gd` and scene
- [ ] Display event name and description
- [ ] Show choice buttons if event has choices
- [ ] Pause game while popup active
- [ ] Execute chosen effect
- [ ] Close popup and resume

### 10.6 Event Completion
- [ ] Track event completion conditions
- [ ] Check conditions each tick/day
- [ ] When complete: grant rewards
- [ ] Emit event_completed signal

### 10.7 Test Events
- [ ] Trigger simple event, verify resources spawn
- [ ] Trigger event with choices, verify choice works
- [ ] Verify inciting incident triggers at right time
- [ ] Verify completion rewards

---

## Phase 11: Adjacency System (Days 15-16)

### 11.1 Adjacency Data
- [ ] Create `src/data/adjacency_rules.gd`
- [ ] Define adjacency effects per building pair
- [ ] Structure: building_id -> neighbor_id -> effects dict

### 11.2 Adjacency Detection
- [ ] Implement `get_adjacent_buildings(building)` function
- [ ] Returns all buildings within 2 tiles
- [ ] Called on building placement
- [ ] Called on building removal (to update neighbors)

### 11.3 Adjacency Effects Application
- [ ] When building placed: calculate its adjacency bonuses
- [ ] Store active bonuses on building
- [ ] Apply bonuses to efficiency, output, etc.
- [ ] When neighbor added/removed: recalculate

### 11.4 Adjacency Visualization
- [ ] Show synergy/conflict indicators between buildings
- [ ] Colored lines or icons
- [ ] Visible when building selected

### 11.5 Test Adjacency
- [ ] Place two synergistic buildings near each other
- [ ] Verify bonus is applied
- [ ] Place conflicting buildings
- [ ] Verify penalty is applied
- [ ] Remove one, verify other updates

---

## Phase 12: UI Polish (Days 16-17)

### 12.1 HUD Layout
- [ ] Create `src/ui/hud.gd` and scene
- [ ] Top bar: Day counter, phase indicator, time controls
- [ ] Left side: Resource totals (scrollable if many)
- [ ] Right side: Wellbeing meter
- [ ] Bottom: Building selection toolbar

### 12.2 Building Selection UI
- [ ] Create building toolbar with available buildings
- [ ] Show building icon and name
- [ ] Show cost on hover
- [ ] Click to select for placement
- [ ] Gray out if can't afford or locked

### 12.3 Building Info Panel
- [ ] Create panel that shows when building clicked
- [ ] Display building name, description
- [ ] Show current storage contents
- [ ] Show current workers assigned
- [ ] Show adjacency bonuses active
- [ ] Buttons: assign worker, remove building

### 12.4 Tooltips
- [ ] Hover on resource in UI: show name, description, total
- [ ] Hover on building in toolbar: show full info
- [ ] Hover on placed building: show quick stats

### 12.5 Notifications
- [ ] Toast notification system
- [ ] Show when events occur
- [ ] Show when resources critically low
- [ ] Show when buildings complete processing

---

## Phase 13: Game Flow (Days 17-18)

### 13.1 Game Start
- [ ] Create starting condition loading from config
- [ ] Place starting buildings
- [ ] Spawn starting resources
- [ ] Set starting energy/attention
- [ ] Apply archetype modifiers

### 13.2 Tutorial Hints (Simple)
- [ ] Day 1: Hint about building roads
- [ ] Day 2: Hint about placing buildings
- [ ] Day 3: Hint about assigning workers
- [ ] Simple text popups, dismissible
- [ ] Track which hints shown

### 13.3 Win/End Detection
- [ ] Track game day count
- [ ] When max days reached: trigger ending
- [ ] Calculate final wellbeing
- [ ] Determine ending tier

### 13.4 End Screen
- [ ] Create `src/ui/end_screen.gd` and scene
- [ ] Display ending text based on tier
- [ ] Show final stats summary
- [ ] Show achievements earned
- [ ] Button: Play Again, Main Menu

### 13.5 Main Menu
- [ ] Create simple main menu
- [ ] Start Game button
- [ ] (Optional) Settings button
- [ ] (Optional) Credits

### 13.6 Test Full Flow
- [ ] Start new game
- [ ] Play through to ending
- [ ] Verify correct ending based on wellbeing
- [ ] Verify restart works

---

## Phase 14: Content Population (Days 18-20)

### 14.1 Remaining Resources
- [ ] Create .tres files for all ~25 resources from spec
- [ ] Ensure all have icons (placeholder colored circles fine)
- [ ] Verify tags are correct
- [ ] Tune decay rates

### 14.2 Remaining Buildings
- [ ] Add all buildings from spec (aim for ~30-40 in prototype)
- [ ] Implement any unique behaviors needed
- [ ] Set up unlock conditions
- [ ] Balance costs and effects
- [ ] Create placeholder sprites

### 14.3 More Events
- [ ] Add all inciting incidents from spec (5-6)
- [ ] Add minor events (8-10)
- [ ] Set up event pools correctly
- [ ] Tune spawn amounts

### 14.4 Building Unlocks
- [ ] Implement unlock checking
- [ ] Starting palette based on archetype
- [ ] Insight-based unlocks
- [ ] Event reward unlocks

### 14.5 Discovery System
- [ ] Each evening: chance to discover new building
- [ ] Present 3 options, player picks 1
- [ ] Add to available palette
- [ ] Simple UI popup for discovery

---

## Phase 15: Visual Polish (Days 20-22)

### 15.1 Color Scheme
- [ ] Define color palette for each resource type
- [ ] Apply to resource sprites
- [ ] Apply to UI elements

### 15.2 Building Sprites
- [ ] Create distinct sprites for each building (even if simple)
- [ ] Neural/organic aesthetic
- [ ] Size variations for different building sizes

### 15.3 Worker Visuals
- [ ] Glowing mote sprite with soft edges
- [ ] Different glow intensity based on habituation?
- [ ] Carrying animation/indication when transporting

### 15.4 World Visuals
- [ ] Background gradient or texture (mindspace feel)
- [ ] Grid overlay styling
- [ ] Day/night visual difference (lighting shift)

### 15.5 Wellbeing Visual Effects
- [ ] Screen-wide saturation based on wellbeing
- [ ] Particle effects at high wellbeing
- [ ] Subtle vignette at low wellbeing

### 15.6 UI Styling
- [ ] Consistent button style
- [ ] Panel backgrounds
- [ ] Font selection
- [ ] Icon set

---

## Phase 16: Audio (Days 22-23)

### 16.1 Basic Sound Effects
- [ ] Building placement sound
- [ ] Resource pickup/dropoff sound
- [ ] Button click sounds
- [ ] Event notification sound

### 16.2 Ambient Audio
- [ ] Background ambient loop
- [ ] Different ambience for day vs night
- [ ] Mood shift with wellbeing (optional)

### 16.3 Audio System
- [ ] Create audio manager singleton
- [ ] Volume controls in settings
- [ ] Play sounds through manager

---

## Phase 17: Balance & Tuning (Days 23-25)

### 17.1 Economy Tuning
- [ ] Playtest: Is energy scarce enough?
- [ ] Playtest: Is attention constraining early game?
- [ ] Playtest: Does habituation feel rewarding?
- [ ] Adjust values in config

### 17.2 Building Tuning
- [ ] Are processors balanced? (time, input/output ratios)
- [ ] Are generators too fast/slow?
- [ ] Are global effects impactful?
- [ ] Adjust building definitions

### 17.3 Event Tuning
- [ ] Are inciting incidents overwhelming or too easy?
- [ ] Is event timing good?
- [ ] Are rewards satisfying?
- [ ] Adjust event definitions

### 17.4 Wellbeing Tuning
- [ ] Does wellbeing respond to actions appropriately?
- [ ] Are ending thresholds reasonable?
- [ ] Adjust formula weights

### 17.5 Pacing
- [ ] Is day length comfortable?
- [ ] Is night phase useful or just waiting?
- [ ] Total run length feel right?

---

## Phase 18: Testing & Bug Fixing (Days 25-27)

### 18.1 Playtest Sessions
- [ ] Full playthrough #1 - note all issues
- [ ] Full playthrough #2 - verify fixes
- [ ] Full playthrough #3 - different choices
- [ ] Full playthrough #4 - edge cases (no buildings, ignore events, etc.)

### 18.2 Bug Fixes
- [ ] Address critical bugs
- [ ] Address gameplay blockers
- [ ] Address major UI issues
- [ ] Document known issues

### 18.3 Edge Cases
- [ ] What happens if player builds no roads?
- [ ] What happens if all workers unassigned?
- [ ] What happens if storage fills completely?
- [ ] What happens if energy hits 0?

---

## Phase 19: Documentation & Polish (Days 27-28)

### 19.1 Code Cleanup
- [ ] Remove debug code
- [ ] Comment complex sections
- [ ] Consistent naming conventions
- [ ] Remove unused assets

### 19.2 Developer Documentation
- [ ] How to add new resources
- [ ] How to add new buildings
- [ ] How to add new events
- [ ] Config values explained

### 19.3 Build
- [ ] Test export to target platforms
- [ ] Create itch.io or similar page (if sharing)
- [ ] Write short description/intro

---

## Appendix: Developer Knobs Reference

All tunable values centralized in `config.gd`:

```gdscript
# Time
var day_duration_seconds: float = 45.0
var total_days: int = 20

# Energy
var starting_energy: int = 10
var max_energy: int = 20
var energy_regen_per_day: int = 3

# Attention
var base_attention_pool: int = 10
var habituation_thresholds: Array = [5, 15, 30, 50]
var habituation_costs: Array = [1.0, 0.5, 0.25, 0.1, 0.0]

# Events
var inciting_incident_day: int = 5
var random_event_chance: float = 0.3  # per day

# Wellbeing
var positive_emotion_weight: float = 2.0
var derived_resource_weight: float = 3.0
var negative_emotion_weight: float = 1.5
var unprocessed_negative_weight: float = 2.0
var habit_building_weight: float = 1.0
var adjacency_synergy_weight: float = 0.5
var wellbeing_normalizer: float = 50.0

# Endings
var flourishing_threshold: int = 80
var growing_threshold: int = 50
var surviving_threshold: int = 20
```

---

## Appendix: Quick Reference - File Locations

| Content Type | Location |
|--------------|----------|
| Resource definitions | `resources/resource_types/*.tres` |
| Building definitions | `src/data/building_definitions.gd` |
| Event definitions | `src/data/event_definitions.gd` |
| Adjacency rules | `src/data/adjacency_rules.gd` |
| Starting configs | `resources/starting_configs/*.tres` |
| Developer knobs | `src/autoload/config.gd` |

---

## Progress Tracking

**Phase Completion:**
- [ ] Phase 0: Project Setup
- [ ] Phase 1: Grid & Tile System
- [ ] Phase 2: Resource System Foundation
- [ ] Phase 3: Building System Foundation
- [ ] Phase 4: Road & Pathfinding
- [ ] Phase 5: Worker System
- [ ] Phase 6: Building Behaviors
- [ ] Phase 7: Time System
- [ ] Phase 8: Energy System
- [ ] Phase 9: Metrics & Wellbeing
- [ ] Phase 10: Events System
- [ ] Phase 11: Adjacency System
- [ ] Phase 12: UI Polish
- [ ] Phase 13: Game Flow
- [ ] Phase 14: Content Population
- [ ] Phase 15: Visual Polish
- [ ] Phase 16: Audio
- [ ] Phase 17: Balance & Tuning
- [ ] Phase 18: Testing & Bug Fixing
- [ ] Phase 19: Documentation & Polish

**Current Phase:** 0
**Current Task:** [Not started]
**Blockers:** None
