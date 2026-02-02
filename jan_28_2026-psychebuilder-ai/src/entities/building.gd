extends Node2D

const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")

@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")
@onready var config: Node = get_node("/root/Config")

enum Status {
  IDLE,
  PROCESSING,
  WAITING_INPUT,
  WAITING_WORKER,
  STORAGE_FULL,
  GENERATING,
  COPING_READY,
  COPING_COOLDOWN,
}

@export var status_colors: Dictionary = {
  Status.IDLE: Color(0.5, 0.5, 0.5),
  Status.PROCESSING: Color(0.2, 0.8, 0.2),
  Status.WAITING_INPUT: Color(0.9, 0.6, 0.2),
  Status.WAITING_WORKER: Color(0.8, 0.4, 0.8),
  Status.STORAGE_FULL: Color(0.8, 0.2, 0.2),
  Status.GENERATING: Color(0.2, 0.6, 0.9),
  Status.COPING_READY: Color(0.9, 0.9, 0.2),
  Status.COPING_COOLDOWN: Color(0.4, 0.4, 0.6),
}

var current_status: Status = Status.IDLE

var building_id: String
var definition: Dictionary
var grid_coord: Vector2i
var size: Vector2i = Vector2i(1, 1)
var grid: RefCounted

# Connection
var road_connected: bool = false

# Storage
var storage: Dictionary = {}  # resource_id -> amount
var storage_capacity: int = 0

# Processing state
var processing_active: bool = false
var process_timer: float = 0.0
var assigned_worker: Node = null

# Generation state
var generation_timer: float = 0.0

# Coping state
var coping_cooldown_timer: float = 0.0

# Anxiety spreading state
var anxiety_spread_timer: float = 0.0

# Visual
@onready var sprite: ColorRect = $ColorRect
@onready var label: Label = $Label
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var status_indicator: ColorRect = %StatusIndicator
@onready var disconnected_warning: Label = %DisconnectedWarning

func _ready() -> void:
  if definition:
    _update_visuals()

func initialize(p_building_id: String, p_grid_coord: Vector2i, p_grid: RefCounted = null) -> void:
  building_id = p_building_id
  grid_coord = p_grid_coord
  grid = p_grid
  definition = BuildingDefs.get_definition(building_id)

  if definition.is_empty():
    push_error("Unknown building: " + building_id)
    return

  size = definition.get("size", Vector2i(1, 1))
  storage_capacity = definition.get("storage_capacity", 0)
  _update_connection()

  if is_inside_tree():
    _update_visuals()

func _update_visuals() -> void:
  var tile_size = config.tile_size
  var pixel_size = Vector2(size) * tile_size

  sprite.size = pixel_size
  _update_connection_visual()

  label.size = pixel_size
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _update_storage_display()

  progress_bar.size.x = pixel_size.x
  progress_bar.visible = false

  _update_status_visual()

func _update_connection() -> void:
  if not grid:
    road_connected = true
    return

  if is_road():
    road_connected = true
    return

  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check) and grid.is_road_at(check):
        road_connected = true
        return

  road_connected = false

func _update_connection_visual() -> void:
  var base_color = definition.get("color", Color.WHITE)
  var is_disconnected = not road_connected and not is_road()
  if is_disconnected:
    sprite.color = base_color.lerp(Color(0.8, 0.2, 0.2), 0.5)
    disconnected_warning.visible = true
  else:
    sprite.color = base_color
    disconnected_warning.visible = false

func _update_storage_display() -> void:
  var name_text = definition.get("name", building_id)
  if storage_capacity > 0:
    var _total = _get_total_stored()
    var storage_text = ""
    for res_id in storage:
      if storage[res_id] > 0:
        storage_text += "\n%s: %d" % [res_id, storage[res_id]]
    if storage_text == "":
      storage_text = "\n(empty)"
    label.text = name_text + storage_text
  else:
    label.text = name_text

func _process(delta: float) -> void:
  if not definition:
    return

  _process_generation(delta)
  _update_storage_display()
  _process_processing(delta)
  _process_coping(delta)
  _process_anxiety_spreading(delta)
  _update_status()
  _update_status_visual()

func _process_generation(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.GENERATOR):
    return

  if not road_connected:
    return

  var rate = definition.get("generation_rate", 0.0)
  if rate <= 0:
    return

  var resource_id = definition.get("generates", "")
  var grief_multiplier = _get_grief_speed_multiplier()
  var effective_delta = delta * grief_multiplier

  if resource_id == "anxiety":
    var suppression = _get_calm_aura_suppression()
    effective_delta *= (1.0 - suppression)

  generation_timer += effective_delta
  var interval = 1.0 / rate

  if generation_timer >= interval:
    generation_timer -= interval
    var amount = definition.get("generation_amount", 1)
    if resource_id != "":
      _output_resource(resource_id, amount)

func _process_processing(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return

  if not road_connected:
    return

  if not processing_active:
    _try_start_processing()
    return

  var grief_multiplier = _get_grief_speed_multiplier()
  process_timer -= delta * grief_multiplier
  if process_timer <= 0:
    _complete_processing()

func _try_start_processing() -> void:
  if definition.get("requires_worker", false) and not assigned_worker:
    return

  var inputs = definition.get("input", {})
  if not _has_inputs(inputs):
    return

  _consume_inputs(inputs)
  processing_active = true
  process_timer = definition.get("process_time", 1.0)

func _complete_processing() -> void:
  processing_active = false
  var conditional_outputs = definition.get("conditional_outputs", {})
  if not conditional_outputs.is_empty():
    for condition_resource in conditional_outputs:
      if storage.get(condition_resource, 0) > 0:
        var output_data = conditional_outputs[condition_resource]
        _output_resource(output_data["output"], output_data["amount"])
        return
  var outputs = definition.get("output", {})
  for resource_id in outputs:
    _output_resource(resource_id, outputs[resource_id])

func _process_coping(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.COPING):
    return

  if coping_cooldown_timer > 0:
    coping_cooldown_timer -= delta
    return

  # Check trigger condition (simplified - just checks total amounts)
  # Full implementation would parse the condition string
  var trigger = definition.get("coping_trigger", "")
  if not _evaluate_trigger(trigger):
    return

  # Activate coping
  var inputs = definition.get("coping_input", {})
  if _has_inputs(inputs):
    _consume_inputs(inputs)
    var outputs = definition.get("coping_output", {})
    for resource_id in outputs:
      _output_resource(resource_id, outputs[resource_id])
    coping_cooldown_timer = definition.get("coping_cooldown", 30.0)

func _process_anxiety_spreading(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.STORAGE):
    return

  var anxiety_amount = storage.get("anxiety", 0)
  if anxiety_amount < config.anxiety_overflow_threshold:
    return

  anxiety_spread_timer += delta
  if anxiety_spread_timer < config.anxiety_spread_interval:
    return

  anxiety_spread_timer = 0.0
  _spread_anxiety_to_neighbors()

func _spread_anxiety_to_neighbors() -> void:
  if not grid:
    return

  var spread_amount = config.anxiety_spread_amount
  var all_adjacent_coords: Array[Vector2i] = []

  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        all_adjacent_coords.append(check)

  var spread_targets: Array[Node] = []
  for coord in all_adjacent_coords:
    var occupant = grid.get_occupant(coord)
    if occupant and occupant != self and occupant.has_method("add_to_storage"):
      if occupant not in spread_targets:
        spread_targets.append(occupant)

  for target in spread_targets:
    if target.storage_capacity > 0:
      var removed = remove_from_storage("anxiety", spread_amount)
      if removed > 0:
        target.add_to_storage("anxiety", removed)
        break

func _evaluate_trigger(trigger: String) -> bool:
  if trigger.is_empty():
    return false

  var parts = trigger.split(" ", false)
  if parts.size() != 3:
    return false

  var resource_id = parts[0]
  var operator = parts[1]
  var threshold = parts[2].to_int()

  var current_value = game_state.get_resource_total(resource_id)

  match operator:
    ">":
      return current_value > threshold
    ">=":
      return current_value >= threshold
    "<":
      return current_value < threshold
    "<=":
      return current_value <= threshold
    "==":
      return current_value == threshold
    _:
      return false

func has_behavior(behavior: int) -> bool:
  var behaviors = definition.get("behaviors", [])
  return behavior in behaviors

func _has_inputs(inputs: Dictionary) -> bool:
  for resource_id in inputs:
    if storage.get(resource_id, 0) < inputs[resource_id]:
      return false
  return true

func _consume_inputs(inputs: Dictionary) -> void:
  for resource_id in inputs:
    storage[resource_id] = storage.get(resource_id, 0) - inputs[resource_id]

func _output_resource(resource_id: String, amount: int) -> void:
  # Try to add to storage first
  var current = storage.get(resource_id, 0)
  var space = storage_capacity - _get_total_stored()
  var to_store = mini(amount, space)

  if to_store > 0:
    storage[resource_id] = current + to_store

  # Overflow spawns in world
  var overflow = amount - to_store
  if overflow > 0:
    var tile_size = config.tile_size
    var spawn_pos = position + Vector2(size) * tile_size * 0.5 + Vector2(randf_range(-16, 16), randf_range(-16, 16))
    event_bus.resource_overflow.emit(resource_id, overflow, self, spawn_pos)

func _get_total_stored() -> int:
  var total = 0
  for resource_id in storage:
    total += storage[resource_id]
  return total

func add_to_storage(resource_id: String, amount: int) -> int:
  var space = storage_capacity - _get_total_stored()
  var to_add = mini(amount, space)
  storage[resource_id] = storage.get(resource_id, 0) + to_add
  return amount - to_add  # return overflow

func remove_from_storage(resource_id: String, amount: int) -> int:
  var available = storage.get(resource_id, 0)
  var to_remove = mini(amount, available)
  storage[resource_id] = available - to_remove
  return to_remove

func get_storage_amount(resource_id: String) -> int:
  return storage.get(resource_id, 0)

func assign_worker(worker: Node) -> void:
  assigned_worker = worker

func unassign_worker() -> void:
  assigned_worker = null

func is_road() -> bool:
  return has_behavior(BuildingDefs.Behavior.INFRASTRUCTURE)

func trigger_habit() -> void:
  if not has_behavior(BuildingDefs.Behavior.HABIT):
    return

  # Consume resources if needed
  var consumes = definition.get("habit_consumes", {})
  # For energy consumption, check global state
  var energy_cost = consumes.get("energy", 0)
  if energy_cost > 0:
    if not game_state.spend_energy(energy_cost):
      return

  var adjacency_multiplier = _get_habit_adjacency_multiplier()

  # Generate resources
  var generates = definition.get("habit_generates", {})
  for resource_id in generates:
    var amount = int(generates[resource_id] * adjacency_multiplier)
    _output_resource(resource_id, amount)

  # Reduce resources (from storage first, then GameState totals)
  var reduces = definition.get("habit_reduces", {})
  for resource_id in reduces:
    var to_reduce = int(reduces[resource_id] * adjacency_multiplier)
    var removed = remove_from_storage(resource_id, to_reduce)
    var remaining = to_reduce - removed
    if remaining > 0:
      game_state.update_resource_total(resource_id, -remaining)

  # Energy bonus
  var energy_bonus = definition.get("habit_energy_bonus", 0)
  if energy_bonus > 0:
    var bonus_amount = int(energy_bonus * adjacency_multiplier)
    game_state.add_energy(bonus_amount)

func _update_status() -> void:
  if is_road():
    current_status = Status.IDLE
    return

  if _is_storage_full():
    current_status = Status.STORAGE_FULL
    return

  if has_behavior(BuildingDefs.Behavior.PROCESSOR):
    if processing_active:
      current_status = Status.PROCESSING
      return
    if definition.get("requires_worker", false) and not assigned_worker:
      current_status = Status.WAITING_WORKER
      return
    var inputs = definition.get("input", {})
    if not inputs.is_empty() and not _has_inputs(inputs):
      current_status = Status.WAITING_INPUT
      return

  if has_behavior(BuildingDefs.Behavior.COPING):
    if coping_cooldown_timer > 0:
      current_status = Status.COPING_COOLDOWN
      return
    var trigger = definition.get("coping_trigger", "")
    if _evaluate_trigger(trigger):
      current_status = Status.COPING_READY
      return

  if has_behavior(BuildingDefs.Behavior.GENERATOR):
    current_status = Status.GENERATING
    return

  current_status = Status.IDLE

func _update_status_visual() -> void:
  status_indicator.color = status_colors.get(current_status, Color.GRAY)

  var is_processor = has_behavior(BuildingDefs.Behavior.PROCESSOR)
  var is_coping = has_behavior(BuildingDefs.Behavior.COPING)

  if is_processor and processing_active:
    progress_bar.visible = true
    var total_time = definition.get("process_time", 1.0)
    var progress = 1.0 - (process_timer / total_time)
    progress_bar.value = progress * 100.0
  elif is_coping and coping_cooldown_timer > 0:
    progress_bar.visible = true
    var total_cooldown = definition.get("coping_cooldown", 30.0)
    var progress = 1.0 - (coping_cooldown_timer / total_cooldown)
    progress_bar.value = progress * 100.0
  else:
    progress_bar.visible = false

func _is_storage_full() -> bool:
  if storage_capacity <= 0:
    return false
  return _get_total_stored() >= storage_capacity

func _get_grief_speed_multiplier() -> float:
  var grief_amount = storage.get("grief", 0)
  if grief_amount < config.grief_slowdown_threshold:
    return 1.0
  var excess_grief = grief_amount - config.grief_slowdown_threshold
  var slowdown = excess_grief * config.grief_slowdown_factor
  slowdown = minf(slowdown, config.grief_max_slowdown)
  return 1.0 - slowdown

func _count_adjacent_habits() -> int:
  if not grid:
    return 0
  var count = 0
  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("has_behavior"):
          if occupant.has_behavior(BuildingDefs.Behavior.HABIT):
            count += 1
  return count

func _get_habit_adjacency_multiplier() -> float:
  var adjacent_count = _count_adjacent_habits()
  if adjacent_count == 0:
    return 1.0
  var bonus = adjacent_count * config.habit_adjacency_bonus
  return minf(1.0 + bonus, config.habit_max_adjacency_multiplier)

func _get_calm_aura_suppression() -> float:
  if not grid:
    return 0.0

  var total_calm = 0
  var radius = config.calm_aura_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_calm += occupant.get_storage_amount("calm")

  if total_calm < config.calm_aura_threshold:
    return 0.0

  var excess_calm = total_calm - config.calm_aura_threshold
  var suppression = excess_calm * config.calm_aura_suppression
  return minf(suppression, config.calm_aura_max_suppression)
