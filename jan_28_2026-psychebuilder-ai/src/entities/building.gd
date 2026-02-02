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

enum SaturationState {
  NONE,
  JOY_SATURATED,
  CALM_SATURATED,
  GRIEF_SATURATED,
  ANXIETY_SATURATED,
  WISDOM_SATURATED,
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

# Worry compounding state
var worry_compounding_timer: float = 0.0

# Doubt generation state
var doubt_generation_timer: float = 0.0

# Nostalgia crystallization state
var nostalgia_age_tracker: Dictionary = {}

# Resonance state
var resonance_timer: float = 0.0
var is_in_positive_resonance: bool = false
var is_in_negative_resonance: bool = false

# Saturation state
var saturation_state: SaturationState = SaturationState.NONE
var saturation_timer: float = 0.0
var saturation_resource: String = ""
var joy_numbness_level: float = 0.0

# Visual
@onready var sprite: ColorRect = %ColorRect
@onready var label: Label = %Label
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
  _process_worry_compounding(delta)
  _process_doubt_generation(delta)
  _process_doubt_insight_combination()
  _process_nostalgia_crystallization(delta)
  _process_resonance(delta)
  _process_saturation(delta)
  _process_saturation_effects(delta)
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
  var tension_multiplier = _get_tension_speed_multiplier()
  var wisdom_multiplier = _get_wisdom_efficiency_multiplier()
  var doubt_multiplier = _get_doubt_efficiency_multiplier()
  var resonance_multiplier = _get_resonance_speed_multiplier()
  process_timer -= delta * grief_multiplier * tension_multiplier * wisdom_multiplier * doubt_multiplier * resonance_multiplier
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

  var inputs = definition.get("input", {})
  var processed_negative = false
  for input_resource in inputs:
    if input_resource in ["anxiety", "grief"]:
      processed_negative = true
      break

  if processed_negative:
    _output_resource("tension", config.tension_from_processing)

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

  # Cathartic release for exercise_yard
  if building_id == "exercise_yard":
    var release_result = _perform_cathartic_release()
    if release_result.calm_generated > 0:
      _output_resource("calm", release_result.calm_generated)
    if release_result.insight_generated > 0:
      _output_resource("insight", release_result.insight_generated)

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
          var calm_amount = occupant.get_storage_amount("calm")
          var saturation_mult = 1.0
          if occupant.has_method("get_calm_saturation_multiplier"):
            saturation_mult = occupant.get_calm_saturation_multiplier()
          total_calm += int(calm_amount * saturation_mult)

  if total_calm < config.calm_aura_threshold:
    return 0.0

  var excess_calm = total_calm - config.calm_aura_threshold
  var suppression = excess_calm * config.calm_aura_suppression
  return minf(suppression, config.calm_aura_max_suppression)

func _get_nearby_tension() -> int:
  if not grid:
    return 0

  var total_tension = 0
  var radius = config.tension_aura_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_tension += occupant.get_storage_amount("tension")

  return total_tension

func _get_tension_speed_multiplier() -> float:
  var tension_amount = _get_nearby_tension() + storage.get("tension", 0)
  if tension_amount < config.tension_slowdown_threshold:
    return 1.0
  var excess_tension = tension_amount - config.tension_slowdown_threshold
  var slowdown = excess_tension * config.tension_slowdown_factor
  slowdown = minf(slowdown, config.tension_max_slowdown)
  return 1.0 - slowdown

func _get_nearby_wisdom() -> int:
  if not grid:
    return 0

  var total_wisdom = 0
  var radius = config.wisdom_aura_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_wisdom += occupant.get_storage_amount("wisdom")

  return total_wisdom

func _get_wisdom_efficiency_multiplier() -> float:
  var wisdom_amount = _get_nearby_wisdom() + storage.get("wisdom", 0)
  var saturation_bonus = get_wisdom_saturation_bonus()
  if wisdom_amount < config.wisdom_efficiency_threshold:
    return 1.0 + saturation_bonus
  var excess_wisdom = wisdom_amount - config.wisdom_efficiency_threshold
  var bonus = excess_wisdom * config.wisdom_efficiency_bonus_per_unit
  bonus = minf(bonus, config.wisdom_max_efficiency_bonus)
  return 1.0 + bonus + saturation_bonus

func _perform_cathartic_release() -> Dictionary:
  var tension_removed = remove_from_storage("tension", storage.get("tension", 0))
  var calm_generated = int(tension_removed * config.cathartic_release_calm_per_tension)
  var insight_generated = 0

  if tension_removed > 0 and randf() < config.cathartic_release_insight_chance:
    insight_generated = 1

  return {
    "tension_removed": tension_removed,
    "calm_generated": calm_generated,
    "insight_generated": insight_generated
  }

func _process_worry_compounding(delta: float) -> void:
  if storage_capacity <= 0:
    return

  var worry_amount = storage.get("worry", 0)
  if worry_amount < config.worry_compounding_threshold:
    worry_compounding_timer = 0.0
    return

  if worry_amount >= config.worry_compounding_max:
    return

  worry_compounding_timer += delta
  if worry_compounding_timer >= config.worry_compounding_interval:
    worry_compounding_timer = 0.0
    _output_resource("worry", config.worry_compounding_amount)

func _process_doubt_generation(delta: float) -> void:
  if storage_capacity <= 0:
    return

  var should_generate = false
  if not road_connected and not is_road():
    should_generate = true
  if current_status == Status.WAITING_INPUT or current_status == Status.WAITING_WORKER:
    should_generate = true

  if not should_generate:
    doubt_generation_timer = 0.0
    return

  doubt_generation_timer += delta
  if doubt_generation_timer >= config.doubt_generation_interval:
    doubt_generation_timer = 0.0
    var amount = 0
    if not road_connected and not is_road():
      amount += config.doubt_from_disconnected
    if current_status == Status.WAITING_INPUT or current_status == Status.WAITING_WORKER:
      amount += config.doubt_from_waiting
    if amount > 0:
      _output_resource("doubt", amount)

func _process_doubt_insight_combination() -> void:
  if storage_capacity <= 0:
    return

  var doubt_amount = storage.get("doubt", 0)
  var insight_amount = storage.get("insight", 0)

  if doubt_amount >= config.doubt_insight_combine_threshold and insight_amount >= config.doubt_insight_combine_threshold:
    remove_from_storage("doubt", config.doubt_insight_combine_threshold)
    remove_from_storage("insight", config.doubt_insight_combine_threshold)
    _output_resource("wisdom", config.wisdom_from_answered_doubt)

func _get_doubt_efficiency_multiplier() -> float:
  var doubt_amount = _get_nearby_doubt() + storage.get("doubt", 0)
  if doubt_amount <= 0:
    return 1.0
  var penalty = doubt_amount * config.doubt_efficiency_penalty
  penalty = minf(penalty, config.doubt_max_efficiency_penalty)
  return 1.0 - penalty

func _get_nearby_doubt() -> int:
  if not grid:
    return 0

  var total_doubt = 0
  var radius = config.doubt_spread_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_doubt += occupant.get_storage_amount("doubt")

  return total_doubt

func _process_nostalgia_crystallization(delta: float) -> void:
  if storage_capacity <= 0:
    return

  var nostalgia_amount = storage.get("nostalgia", 0)
  if nostalgia_amount <= 0:
    nostalgia_age_tracker.clear()
    return

  var tracked_count = nostalgia_age_tracker.size()
  while tracked_count < nostalgia_amount:
    var batch_id = "batch_%d_%d" % [Time.get_ticks_msec(), tracked_count]
    nostalgia_age_tracker[batch_id] = 0.0
    tracked_count += 1

  var crystallized_count = 0
  var to_remove: Array[String] = []
  for batch_id in nostalgia_age_tracker:
    nostalgia_age_tracker[batch_id] += delta
    if nostalgia_age_tracker[batch_id] >= config.nostalgia_crystallization_time:
      crystallized_count += 1
      to_remove.append(batch_id)

  if crystallized_count <= 0:
    return

  var amount_to_crystallize = mini(crystallized_count, nostalgia_amount)
  remove_from_storage("nostalgia", amount_to_crystallize)

  for batch_id in to_remove:
    nostalgia_age_tracker.erase(batch_id)
    if to_remove.find(batch_id) >= amount_to_crystallize:
      break

  var nearby_calm = _count_nearby_resource("calm")
  var nearby_negative = _count_nearby_resource("anxiety") + _count_nearby_resource("tension") + _count_nearby_resource("grief")

  var output_type: String
  var output_amount = amount_to_crystallize * config.nostalgia_crystallization_amount

  if nearby_calm >= config.nostalgia_crystallization_calm_threshold and nearby_calm > nearby_negative:
    output_type = "joy"
  elif nearby_negative >= config.nostalgia_crystallization_negative_threshold:
    output_type = "grief"
  else:
    output_type = "joy" if randf() < 0.5 else "grief"

  _output_resource(output_type, output_amount)
  event_bus.nostalgia_crystallized.emit(self, output_type, output_amount)

func _count_nearby_resource(resource_id: String) -> int:
  var total = storage.get(resource_id, 0)
  if not grid:
    return total

  var radius = config.nostalgia_crystallization_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total += occupant.get_storage_amount(resource_id)

  return total

func _process_resonance(delta: float) -> void:
  if storage_capacity <= 0:
    return

  is_in_positive_resonance = false
  is_in_negative_resonance = false

  for resource_id in storage:
    if storage[resource_id] < config.resonance_resource_threshold:
      continue

    var resonating_buildings = _find_resonating_buildings(resource_id)
    if resonating_buildings.size() >= config.resonance_min_buildings:
      if resource_id in config.resonance_positive_resources:
        is_in_positive_resonance = true
      elif resource_id in config.resonance_negative_resources:
        is_in_negative_resonance = true
        _process_negative_resonance_amplification(delta, resource_id)

func _find_resonating_buildings(resource_id: String) -> Array[Node]:
  var result: Array[Node] = [self]
  if not grid:
    return result

  var radius = config.resonance_radius
  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          if occupant.get_storage_amount(resource_id) >= config.resonance_resource_threshold:
            result.append(occupant)

  return result

func _process_negative_resonance_amplification(delta: float, resource_id: String) -> void:
  resonance_timer += delta
  if resonance_timer < config.resonance_negative_amplification_interval:
    return

  resonance_timer = 0.0
  var amount = config.resonance_negative_amplification_amount
  _output_resource(resource_id, amount)
  event_bus.resonance_amplification.emit(self, resource_id, amount)

func _get_resonance_speed_multiplier() -> float:
  if is_in_positive_resonance:
    return 1.0 + config.resonance_positive_speed_bonus
  return 1.0

func _process_saturation(delta: float) -> void:
  if storage_capacity <= 0:
    saturation_state = SaturationState.NONE
    saturation_timer = 0.0
    return

  var saturated_resource = ""
  var highest_ratio = 0.0

  for resource_id in ["joy", "calm", "grief", "anxiety", "wisdom"]:
    var amount = storage.get(resource_id, 0)
    var ratio = float(amount) / float(storage_capacity)
    if ratio >= config.saturation_threshold and ratio > highest_ratio:
      highest_ratio = ratio
      saturated_resource = resource_id

  if saturated_resource == "":
    saturation_state = SaturationState.NONE
    saturation_timer = 0.0
    saturation_resource = ""
    return

  if saturated_resource != saturation_resource:
    saturation_timer = 0.0
    saturation_resource = saturated_resource

  saturation_timer += delta

  if saturation_timer >= config.saturation_time_required:
    match saturation_resource:
      "joy":
        saturation_state = SaturationState.JOY_SATURATED
      "calm":
        saturation_state = SaturationState.CALM_SATURATED
      "grief":
        saturation_state = SaturationState.GRIEF_SATURATED
      "anxiety":
        saturation_state = SaturationState.ANXIETY_SATURATED
      "wisdom":
        saturation_state = SaturationState.WISDOM_SATURATED
  else:
    saturation_state = SaturationState.NONE

func _process_saturation_effects(delta: float) -> void:
  match saturation_state:
    SaturationState.JOY_SATURATED:
      _process_joy_saturation(delta)
    SaturationState.CALM_SATURATED:
      pass
    SaturationState.GRIEF_SATURATED:
      _process_grief_saturation(delta)
    SaturationState.ANXIETY_SATURATED:
      _process_anxiety_saturation(delta)
    SaturationState.WISDOM_SATURATED:
      pass
    SaturationState.NONE:
      joy_numbness_level = maxf(0.0, joy_numbness_level - delta * 0.1)

func _process_joy_saturation(delta: float) -> void:
  joy_numbness_level = minf(1.0, joy_numbness_level + delta * config.saturation_joy_numbness_factor * 0.1)

  if not grid:
    return

  var spread_amount = int(config.saturation_joy_spread_rate * delta)
  if spread_amount <= 0 and randf() < config.saturation_joy_spread_rate * delta:
    spread_amount = 1

  if spread_amount <= 0:
    return

  var neighbors = _get_adjacent_buildings()
  if neighbors.is_empty():
    return

  var target = neighbors[randi() % neighbors.size()]
  var removed = remove_from_storage("joy", spread_amount)
  if removed > 0:
    target.add_to_storage("joy", removed)

func _process_grief_saturation(delta: float) -> void:
  if randf() < config.saturation_grief_wisdom_rate * delta:
    _output_resource("wisdom", 1)

func _process_anxiety_saturation(delta: float) -> void:
  if randf() >= config.saturation_anxiety_panic_chance * delta:
    return

  if not grid:
    return

  var neighbors = _get_adjacent_buildings()
  for neighbor in neighbors:
    neighbor.add_to_storage("anxiety", config.saturation_anxiety_panic_spread)

func _get_adjacent_buildings() -> Array[Node]:
  var result: Array[Node] = []
  if not grid:
    return result

  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("add_to_storage"):
          if occupant not in result:
            result.append(occupant)

  return result

func get_calm_saturation_multiplier() -> float:
  if saturation_state == SaturationState.CALM_SATURATED:
    return config.saturation_calm_aura_multiplier
  return 1.0

func get_wisdom_saturation_bonus() -> float:
  if saturation_state == SaturationState.WISDOM_SATURATED:
    return config.saturation_wisdom_efficiency_bonus
  return 0.0

func get_joy_numbness_factor() -> float:
  return 1.0 - joy_numbness_level
