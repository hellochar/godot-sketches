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

@export_group("Status Display")
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

# Road emotional memory state
var road_traffic_memory: Dictionary = {}
var road_dominant_emotion: String = ""
var road_imprinted: bool = false

# Cascade boost state
var cascade_boost_timer: float = 0.0
var cascade_boost_active: bool = false

# Emotional momentum state
var momentum_level: float = 0.0
var momentum_last_recipe: String = ""
var momentum_starvation_timer: float = 0.0
var momentum_break_penalty_timer: float = 0.0

# Support network state
var support_network: Array[Node] = []
var support_network_transfer_timer: float = 0.0

# Awakening state
var awakening_experience: int = 0
var is_awakened: bool = false

# Fatigue state
var fatigue_level: float = 0.0

# Emotional echo state
var emotional_echo: Dictionary = {}
var dominant_echo: String = ""

# Harmony state
var harmony_partners: Array[Node] = []
var is_in_harmony: bool = false

# Resource purity state (resource_id -> purity level 0.0-1.0)
var storage_purity: Dictionary = {}

# Attunement state
var attunement_levels: Dictionary = {}
var attuned_partners: Array[Node] = []
var attunement_timer: float = 0.0

# Fragility state
var fragility_level: float = 0.0
var is_cracked: bool = false
var fragility_leak_timer: float = 0.0

# Stagnation state (resource_id -> {age: float, stagnation: float})
var resource_age_data: Dictionary = {}
var stagnation_decay_timer: float = 0.0

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
  elif attuned_partners.size() > 0:
    sprite.color = base_color.lerp(Color(1.0, 0.9, 0.5), 0.4)
    disconnected_warning.visible = false
  elif is_in_harmony:
    sprite.color = base_color.lerp(Color(0.9, 0.95, 0.7), 0.3)
    disconnected_warning.visible = false
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
        var purity = storage_purity.get(res_id, config.purity_initial_level)
        var purity_indicator = ""
        if purity >= config.purity_output_bonus_threshold:
          purity_indicator = "*"
        elif purity <= config.purity_min_level + 0.1:
          purity_indicator = "~"
        storage_text += "\n%s: %d%s" % [res_id, storage[res_id], purity_indicator]
    if storage_text == "":
      storage_text = "\n(empty)"
    if attuned_partners.size() > 0:
      name_text += " [A]"
    label.text = name_text + storage_text
  else:
    if attuned_partners.size() > 0:
      name_text += " [A]"
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
  _process_road_memory_decay(delta)
  _process_cascade_boost(delta)
  _process_emotional_momentum(delta)
  _process_support_network()
  _process_network_load_sharing(delta)
  _process_fatigue(delta)
  _process_emotional_echo_decay(delta)
  _process_harmony()
  _process_purity_decay(delta)
  _process_attunement(delta)
  _process_fragility(delta)
  _process_stagnation(delta)
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
  var cascade_multiplier = 1.0 + (config.cascade_generator_boost_amount if cascade_boost_active else 0.0)
  var weather_modifier = game_state.get_weather_generation_modifier()
  var belief_modifier = game_state.get_belief_generation_modifier()
  var awakening_multiplier = get_awakening_generator_rate_multiplier()
  var harmony_multiplier = _get_harmony_speed_multiplier()
  var flow_multiplier = game_state.get_flow_state_multiplier()
  var effective_delta = delta * grief_multiplier * cascade_multiplier * weather_modifier * belief_modifier * awakening_multiplier * harmony_multiplier * flow_multiplier

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
  var momentum_multiplier = _get_momentum_speed_multiplier()
  var support_network_multiplier = _get_support_network_efficiency_multiplier()
  var weather_modifier = game_state.get_weather_processing_modifier()
  var belief_modifier = game_state.get_belief_processing_modifier()
  var awakening_multiplier = get_awakening_speed_multiplier()
  var breakthrough_modifier = game_state.get_breakthrough_speed_modifier()
  var fatigue_multiplier = _get_fatigue_speed_multiplier()
  var echo_multiplier = _get_emotional_echo_multiplier()
  var harmony_multiplier = _get_harmony_speed_multiplier()
  var flow_multiplier = game_state.get_flow_state_multiplier()
  var purity_multiplier = _get_purity_speed_multiplier()
  var attunement_multiplier = get_attunement_speed_multiplier()
  var fragility_multiplier = _get_fragility_speed_multiplier()
  var stagnation_multiplier = _get_stagnation_speed_multiplier()
  process_timer -= delta * grief_multiplier * tension_multiplier * wisdom_multiplier * doubt_multiplier * resonance_multiplier * momentum_multiplier * support_network_multiplier * weather_modifier * belief_modifier * awakening_multiplier * breakthrough_modifier * fatigue_multiplier * echo_multiplier * harmony_multiplier * flow_multiplier * purity_multiplier * attunement_multiplier * fragility_multiplier * stagnation_multiplier
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
  var processed_negative_types: Array[String] = []
  for input_resource in inputs:
    if input_resource == "grief":
      game_state.track_grief_processed(inputs[input_resource])
      processed_negative = true
      processed_negative_types.append("grief")
    elif input_resource == "anxiety":
      game_state.track_anxiety_processed(inputs[input_resource])
      processed_negative = true
      processed_negative_types.append("anxiety")
    elif input_resource in config.breakthrough_negative_types:
      processed_negative_types.append(input_resource)

  for neg_type in processed_negative_types:
    game_state.record_negative_processed(neg_type, inputs.get(neg_type, 1))

  if processed_negative:
    _output_resource("tension", config.tension_from_processing)

  _gain_fatigue()
  _gain_fragility(inputs)
  _build_emotional_echo(inputs)
  _gain_awakening_experience()

  var has_fresh = false
  for input_resource in inputs:
    if is_resource_fresh(input_resource):
      has_fresh = true
      event_bus.fresh_resource_bonus.emit(self, input_resource)
    reset_resource_age(input_resource)

  var recipe_key = _get_recipe_key(inputs)
  _build_momentum(recipe_key)

  var awakening_bonus = get_awakening_output_bonus()
  var harmony_bonus = get_harmony_output_bonus()
  var purity_bonus = get_purity_output_bonus()
  var attunement_bonus = get_attunement_output_bonus()
  var total_bonus = awakening_bonus + harmony_bonus + purity_bonus + attunement_bonus

  var synergy = try_attunement_synergy()
  if synergy.get("triggered", false):
    if synergy.has("output_type"):
      _output_resource(synergy["output_type"], synergy.get("amount", 1))
    if synergy.has("calm_bonus"):
      _output_resource("calm", synergy["calm_bonus"])
    if synergy.has("energy_bonus"):
      game_state.add_energy(synergy["energy_bonus"])

  var conditional_outputs = definition.get("conditional_outputs", {})
  if not conditional_outputs.is_empty():
    for condition_resource in conditional_outputs:
      if storage.get(condition_resource, 0) > 0:
        var output_data = conditional_outputs[condition_resource]
        var amount = output_data["amount"] + total_bonus
        _track_output_resource(output_data["output"], amount)
        _cascade_output_resource(output_data["output"], amount)
        return
  var outputs = definition.get("output", {})
  for resource_id in outputs:
    var amount = outputs[resource_id] + total_bonus
    _track_output_resource(resource_id, amount)
    _cascade_output_resource(resource_id, amount)

func _track_output_resource(resource_id: String, amount: int) -> void:
  if resource_id == "wisdom":
    game_state.track_wisdom_generated(amount)
  elif resource_id == "insight":
    game_state.track_insight_generated(amount)

func _get_recipe_key(inputs: Dictionary) -> String:
  var sorted_keys = inputs.keys()
  sorted_keys.sort()
  var parts: Array[String] = []
  for key in sorted_keys:
    parts.append("%s:%d" % [key, inputs[key]])
  return ":".join(parts)

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

func _output_resource(resource_id: String, amount: int, purity: float = -1.0) -> void:
  var effective_capacity = get_effective_storage_capacity()
  var space = effective_capacity - _get_total_stored()
  var to_store = mini(amount, space)
  var output_purity = purity if purity >= 0.0 else config.purity_initial_level

  if to_store > 0:
    var existing = storage.get(resource_id, 0)
    var existing_purity = storage_purity.get(resource_id, config.purity_initial_level)
    if existing > 0:
      var total = existing + to_store
      storage_purity[resource_id] = (existing_purity * existing + output_purity * to_store) / total
    else:
      storage_purity[resource_id] = output_purity
    storage[resource_id] = existing + to_store

  var overflow = amount - to_store
  if overflow > 0:
    var tile_size = config.tile_size
    var spawn_pos = position + Vector2(size) * tile_size * 0.5 + Vector2(randf_range(-16, 16), randf_range(-16, 16))
    event_bus.resource_overflow.emit(resource_id, overflow, self, spawn_pos)

func _cascade_output_resource(resource_id: String, amount: int) -> void:
  var remaining = _try_cascade_output(resource_id, amount)
  if remaining > 0:
    _output_resource(resource_id, remaining)

func _get_total_stored() -> int:
  var total = 0
  for resource_id in storage:
    total += storage[resource_id]
  return total

func get_effective_storage_capacity() -> int:
  return storage_capacity + get_attunement_storage_bonus()

func add_to_storage(resource_id: String, amount: int, purity: float = -1.0) -> int:
  var effective_capacity = get_effective_storage_capacity()
  var space = effective_capacity - _get_total_stored()
  var to_add = mini(amount, space)
  var existing = storage.get(resource_id, 0)
  var existing_purity = storage_purity.get(resource_id, config.purity_initial_level)
  var incoming_purity = purity if purity >= 0.0 else config.purity_initial_level
  incoming_purity = maxf(incoming_purity - config.purity_transfer_loss, config.purity_min_level)
  if existing > 0 and to_add > 0:
    var total = existing + to_add
    storage_purity[resource_id] = (existing_purity * existing + incoming_purity * to_add) / total
  elif to_add > 0:
    storage_purity[resource_id] = incoming_purity
  storage[resource_id] = existing + to_add
  return amount - to_add

func remove_from_storage(resource_id: String, amount: int) -> int:
  var available = storage.get(resource_id, 0)
  var to_remove = mini(amount, available)
  storage[resource_id] = available - to_remove
  if storage[resource_id] <= 0:
    storage_purity.erase(resource_id)
  return to_remove

func get_storage_purity(resource_id: String) -> float:
  return storage_purity.get(resource_id, config.purity_initial_level)

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

  var consumes = definition.get("habit_consumes", {})
  var energy_cost = consumes.get("energy", 0)
  if energy_cost > 0:
    if not game_state.spend_energy(energy_cost):
      return

  var adjacency_multiplier = _get_habit_adjacency_multiplier()
  var weather_modifier = game_state.get_weather_habit_modifier()
  var belief_modifier = game_state.get_belief_habit_modifier()
  var total_multiplier = adjacency_multiplier * weather_modifier * belief_modifier

  if building_id == "exercise_yard":
    var release_result = _perform_cathartic_release()
    if release_result.calm_generated > 0:
      _output_resource("calm", release_result.calm_generated)
    if release_result.insight_generated > 0:
      _output_resource("insight", release_result.insight_generated)
      game_state.track_insight_generated(release_result.insight_generated)

  var generates = definition.get("habit_generates", {})
  for resource_id in generates:
    var amount = int(generates[resource_id] * total_multiplier)
    _output_resource(resource_id, amount)

  var reduces = definition.get("habit_reduces", {})
  for resource_id in reduces:
    var to_reduce = int(reduces[resource_id] * total_multiplier)
    var removed = remove_from_storage(resource_id, to_reduce)
    var remaining = to_reduce - removed
    if remaining > 0:
      game_state.update_resource_total(resource_id, -remaining)

  var energy_bonus = definition.get("habit_energy_bonus", 0)
  if energy_bonus > 0:
    var bonus_amount = int(energy_bonus * total_multiplier)
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
  var effective_capacity = get_effective_storage_capacity()
  if effective_capacity <= 0:
    return false
  return _get_total_stored() >= effective_capacity

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
  var effective_capacity = get_effective_storage_capacity()
  if effective_capacity <= 0:
    saturation_state = SaturationState.NONE
    saturation_timer = 0.0
    return

  var saturated_resource = ""
  var highest_ratio = 0.0

  for resource_id in ["joy", "calm", "grief", "anxiety", "wisdom"]:
    var amount = storage.get(resource_id, 0)
    var ratio = float(amount) / float(effective_capacity)
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

func record_road_traffic(emotion: String, amount: float) -> void:
  if not is_road():
    return

  var gain = config.road_memory_gain_per_pass * amount
  road_traffic_memory[emotion] = road_traffic_memory.get(emotion, 0.0) + gain
  _update_road_dominant_emotion()
  _update_road_visual()

func get_road_speed_modifier() -> float:
  if not road_imprinted:
    return 1.0

  if road_dominant_emotion in config.road_positive_emotions:
    return 1.0 + config.road_imprint_speed_bonus
  elif road_dominant_emotion in config.road_negative_emotions:
    return 1.0 - config.road_imprint_speed_penalty

  return 1.0

func _process_road_memory_decay(delta: float) -> void:
  if not is_road():
    return

  var decay = config.road_memory_decay_rate * delta
  var any_remaining = false
  for emotion in road_traffic_memory.keys():
    road_traffic_memory[emotion] = maxf(0.0, road_traffic_memory[emotion] - decay)
    if road_traffic_memory[emotion] > 0:
      any_remaining = true

  if any_remaining:
    _update_road_dominant_emotion()
    _update_road_visual()
  else:
    road_imprinted = false
    road_dominant_emotion = ""

func _update_road_dominant_emotion() -> void:
  var max_value = 0.0
  var dominant = ""

  for emotion in road_traffic_memory:
    if road_traffic_memory[emotion] > max_value:
      max_value = road_traffic_memory[emotion]
      dominant = emotion

  road_dominant_emotion = dominant
  road_imprinted = max_value >= config.road_memory_threshold

func _update_road_visual() -> void:
  if not is_road():
    return

  var base_color = definition.get("color", Color.WHITE)

  if not road_imprinted:
    sprite.color = base_color
    return

  var emotion_color = base_color
  if road_dominant_emotion in config.road_positive_emotions:
    emotion_color = Color(0.6, 0.8, 0.6)
  elif road_dominant_emotion in config.road_negative_emotions:
    emotion_color = Color(0.7, 0.5, 0.6)

  sprite.color = base_color.lerp(emotion_color, 0.4)

func _process_cascade_boost(delta: float) -> void:
  if not cascade_boost_active:
    return

  cascade_boost_timer -= delta
  if cascade_boost_timer <= 0:
    cascade_boost_active = false
    cascade_boost_timer = 0.0

func trigger_cascade_boost(resource_id: String) -> void:
  if not has_behavior(BuildingDefs.Behavior.GENERATOR):
    return

  var generates = definition.get("generates", "")
  if generates == resource_id:
    cascade_boost_active = true
    cascade_boost_timer = config.cascade_generator_boost_duration

func _try_cascade_output(resource_id: String, amount: int) -> int:
  if not grid:
    return amount

  var remaining = amount
  var neighbors = _get_adjacent_buildings()

  for neighbor in neighbors:
    if remaining <= 0:
      break

    if config.cascade_direct_storage and neighbor.has_behavior(BuildingDefs.Behavior.STORAGE):
      var overflow = neighbor.add_to_storage(resource_id, remaining)
      remaining = overflow

    if remaining > 0 and neighbor.has_behavior(BuildingDefs.Behavior.PROCESSOR):
      var inputs = neighbor.definition.get("input", {})
      if resource_id in inputs:
        var transfer = mini(remaining, config.cascade_processor_transfer)
        var overflow = neighbor.add_to_storage(resource_id, transfer)
        remaining -= (transfer - overflow)

    if neighbor.has_behavior(BuildingDefs.Behavior.GENERATOR):
      neighbor.trigger_cascade_boost(resource_id)

  return remaining

func _process_emotional_momentum(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return

  if momentum_break_penalty_timer > 0:
    momentum_break_penalty_timer -= delta

  if not processing_active:
    momentum_starvation_timer += delta
    if momentum_starvation_timer >= config.momentum_starvation_timeout and momentum_level > 0:
      _break_momentum()
    return

  momentum_starvation_timer = 0.0

func _build_momentum(recipe_key: String) -> void:
  if momentum_last_recipe != "" and momentum_last_recipe != recipe_key:
    _break_momentum()
    return

  momentum_last_recipe = recipe_key
  momentum_level = minf(momentum_level + config.momentum_gain_per_cycle, config.momentum_max_level)

func _break_momentum() -> void:
  momentum_level = maxf(0.0, momentum_level - config.momentum_decay_on_break)
  momentum_break_penalty_timer = config.momentum_break_penalty_duration
  if momentum_level <= 0:
    momentum_last_recipe = ""

func _get_momentum_speed_multiplier() -> float:
  if momentum_break_penalty_timer > 0:
    return 1.0 - config.momentum_break_penalty_amount
  var momentum_ratio = momentum_level / config.momentum_max_level
  return 1.0 + (momentum_ratio * config.momentum_speed_bonus_at_max)

func _process_support_network() -> void:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    support_network.clear()
    return

  if not grid:
    support_network.clear()
    return

  support_network = _find_connected_buildings_of_same_type()

func _find_connected_buildings_of_same_type() -> Array[Node]:
  var result: Array[Node] = []
  var visited: Dictionary = {}
  var to_visit: Array[Vector2i] = []

  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check) and grid.is_road_at(check):
        to_visit.append(check)
        visited[check] = true

  while to_visit.size() > 0:
    var current = to_visit.pop_front()
    var occupant = grid.get_occupant(current)

    if occupant and occupant != self and occupant.building_id == building_id:
      if occupant not in result:
        result.append(occupant)

    if grid.is_road_at(current):
      for neighbor in grid.get_neighbors(current):
        if not visited.has(neighbor):
          visited[neighbor] = true
          to_visit.append(neighbor)

  return result

func _process_network_load_sharing(delta: float) -> void:
  if support_network.size() < config.support_network_min_size:
    return

  var effective_capacity = get_effective_storage_capacity()
  if effective_capacity <= 0:
    return

  var fill_ratio = float(_get_total_stored()) / float(effective_capacity)
  if fill_ratio < config.support_network_load_share_threshold:
    support_network_transfer_timer = 0.0
    return

  support_network_transfer_timer += delta
  if support_network_transfer_timer < config.support_network_transfer_interval:
    return

  support_network_transfer_timer = 0.0

  var best_target: Node = null
  var lowest_fill: float = 1.0

  for member in support_network:
    var member_capacity = member.get_effective_storage_capacity()
    if member_capacity <= 0:
      continue
    var member_fill = float(member._get_total_stored()) / float(member_capacity)
    if member_fill < lowest_fill:
      lowest_fill = member_fill
      best_target = member

  if best_target and lowest_fill < fill_ratio - 0.1:
    for resource_id in storage:
      if storage[resource_id] > 0:
        var to_transfer = mini(storage[resource_id], config.support_network_transfer_amount)
        var removed = remove_from_storage(resource_id, to_transfer)
        if removed > 0:
          best_target.add_to_storage(resource_id, removed)
          break

func _get_support_network_efficiency_multiplier() -> float:
  if support_network.size() < config.support_network_min_size:
    return 1.0
  var bonus = support_network.size() * config.support_network_efficiency_per_member
  bonus = minf(bonus, config.support_network_max_efficiency_bonus)
  return 1.0 + bonus

func _gain_awakening_experience() -> void:
  if is_awakened:
    return
  awakening_experience += config.awakening_experience_per_process
  if awakening_experience >= config.awakening_threshold:
    _awaken()

func _awaken() -> void:
  is_awakened = true
  storage_capacity += config.awakening_storage_bonus
  event_bus.building_awakened.emit(self)

func get_awakening_speed_multiplier() -> float:
  if is_awakened:
    return 1.0 + config.awakening_speed_bonus
  return 1.0

func get_awakening_output_bonus() -> int:
  if is_awakened:
    return config.awakening_output_bonus
  return 0

func get_awakening_generator_rate_multiplier() -> float:
  if is_awakened:
    return 1.0 + config.awakening_generator_rate_bonus
  return 1.0

func _gain_fatigue() -> void:
  fatigue_level = minf(fatigue_level + config.fatigue_gain_per_process, config.fatigue_max_level)

func _process_fatigue(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return

  if processing_active:
    return

  var base_recovery = config.fatigue_recovery_rate * delta
  var calm_bonus = _get_nearby_calm_for_fatigue() * config.fatigue_calm_recovery_bonus * delta
  var total_recovery = base_recovery + calm_bonus

  fatigue_level = maxf(0.0, fatigue_level - total_recovery)

func _get_nearby_calm_for_fatigue() -> int:
  var total_calm = storage.get("calm", 0)
  if not grid:
    return total_calm

  var radius = config.fatigue_calm_radius
  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_calm += occupant.get_storage_amount("calm")

  return total_calm

func _get_fatigue_speed_multiplier() -> float:
  if fatigue_level < config.fatigue_onset_threshold:
    return 1.0
  var effective_fatigue = (fatigue_level - config.fatigue_onset_threshold) / (config.fatigue_max_level - config.fatigue_onset_threshold)
  var penalty = effective_fatigue * config.fatigue_speed_penalty_at_max
  return 1.0 - penalty

func _build_emotional_echo(inputs: Dictionary) -> void:
  for resource_id in inputs:
    var current = emotional_echo.get(resource_id, 0.0)
    emotional_echo[resource_id] = minf(current + config.echo_gain_per_process, config.echo_max_level)

  _update_dominant_echo()

func _process_emotional_echo_decay(delta: float) -> void:
  if emotional_echo.is_empty():
    return

  var decay = config.echo_decay_rate * delta
  for resource_id in emotional_echo.keys():
    emotional_echo[resource_id] = maxf(0.0, emotional_echo[resource_id] - decay)

  _update_dominant_echo()

func _update_dominant_echo() -> void:
  var max_value = 0.0
  dominant_echo = ""

  for resource_id in emotional_echo:
    if emotional_echo[resource_id] > max_value:
      max_value = emotional_echo[resource_id]
      dominant_echo = resource_id

func _get_emotional_echo_multiplier() -> float:
  if dominant_echo == "" or emotional_echo.get(dominant_echo, 0.0) < config.echo_threshold:
    return 1.0

  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 1.0

  var primary_input = ""
  var max_amount = 0
  for resource_id in inputs:
    if inputs[resource_id] > max_amount:
      max_amount = inputs[resource_id]
      primary_input = resource_id

  if primary_input == "":
    return 1.0

  var echo_strength = emotional_echo.get(dominant_echo, 0.0) / config.echo_max_level

  if primary_input == dominant_echo:
    return 1.0 + (echo_strength * config.echo_same_type_bonus)
  else:
    return 1.0 - (echo_strength * config.echo_different_type_penalty)

func _process_harmony() -> void:
  var was_in_harmony = is_in_harmony
  var was_attuned_count = attuned_partners.size()
  harmony_partners.clear()
  is_in_harmony = false

  if not grid:
    return

  var my_pairs = config.harmony_pairs.get(building_id, [])
  var neighbors = _get_adjacent_buildings()

  for neighbor in neighbors:
    if neighbor.building_id in my_pairs:
      harmony_partners.append(neighbor)

    var neighbor_pairs = config.harmony_pairs.get(neighbor.building_id, [])
    if building_id in neighbor_pairs and neighbor not in harmony_partners:
      harmony_partners.append(neighbor)

  is_in_harmony = harmony_partners.size() > 0

  var visual_changed = is_in_harmony != was_in_harmony or attuned_partners.size() != was_attuned_count
  if visual_changed:
    _update_connection_visual()
    if is_in_harmony and not was_in_harmony:
      event_bus.harmony_formed.emit(self, harmony_partners)

func _get_harmony_speed_multiplier() -> float:
  if not is_in_harmony:
    return 1.0
  var bonus = config.harmony_speed_bonus
  if harmony_partners.size() > 1:
    bonus += (harmony_partners.size() - 1) * config.harmony_mutual_bonus
  return 1.0 + bonus

func get_harmony_output_bonus() -> int:
  if is_in_harmony:
    return config.harmony_output_bonus
  return 0

func _process_purity_decay(delta: float) -> void:
  if storage_capacity <= 0:
    return

  var decay = config.purity_decay_rate * delta
  for resource_id in storage_purity.keys():
    if storage.get(resource_id, 0) <= 0:
      storage_purity.erase(resource_id)
      continue
    var old_purity = storage_purity[resource_id]
    storage_purity[resource_id] = maxf(old_purity - decay, config.purity_min_level)
    if old_purity >= config.purity_output_bonus_threshold and storage_purity[resource_id] < config.purity_output_bonus_threshold:
      event_bus.resource_purity_degraded.emit(self, resource_id, storage_purity[resource_id])

  if is_awakened and has_behavior(BuildingDefs.Behavior.PROCESSOR):
    _try_refine_resources(delta)

func _try_refine_resources(delta: float) -> void:
  for resource_id in storage:
    if storage[resource_id] <= 0:
      continue
    var purity = storage_purity.get(resource_id, config.purity_initial_level)
    if purity < config.purity_refine_threshold:
      var refine_gain = config.purity_refine_gain + config.purity_awakened_refine_bonus
      storage_purity[resource_id] = minf(purity + refine_gain * delta, config.purity_initial_level)
      if storage_purity[resource_id] >= config.purity_refine_threshold and purity < config.purity_refine_threshold:
        event_bus.resource_refined.emit(self, resource_id, storage_purity[resource_id])

func _get_purity_speed_multiplier() -> float:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return 1.0
  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 1.0
  var total_purity = 0.0
  var count = 0
  for resource_id in inputs:
    total_purity += storage_purity.get(resource_id, config.purity_min_level)
    count += 1
  if count == 0:
    return 1.0
  var avg_purity = total_purity / count
  if avg_purity >= config.purity_output_bonus_threshold:
    return 1.0 + config.purity_speed_bonus_at_pure * (avg_purity - config.purity_output_bonus_threshold) / (1.0 - config.purity_output_bonus_threshold)
  elif avg_purity <= config.purity_diluted_threshold:
    var dilution_ratio = (config.purity_diluted_threshold - avg_purity) / (config.purity_diluted_threshold - config.purity_min_level)
    return 1.0 - config.purity_diluted_penalty * dilution_ratio
  return 1.0

func get_purity_output_bonus() -> int:
  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 0
  var all_pure = true
  for resource_id in inputs:
    if storage_purity.get(resource_id, config.purity_min_level) < config.purity_output_bonus_threshold:
      all_pure = false
      break
  if all_pure:
    event_bus.pure_resource_processed.emit(self, inputs.keys()[0], config.purity_output_bonus_amount)
    return config.purity_output_bonus_amount
  return 0

func _process_attunement(delta: float) -> void:
  var old_attuned = attuned_partners.duplicate()

  if not is_in_harmony:
    for partner_id in attunement_levels.keys():
      var was_above_threshold = attunement_levels[partner_id] >= config.attunement_threshold
      attunement_levels[partner_id] = maxf(0.0, attunement_levels[partner_id] - config.attunement_decay_on_break * delta)
      var is_above_threshold = attunement_levels[partner_id] >= config.attunement_threshold
      if was_above_threshold and not is_above_threshold:
        for old_partner in old_attuned:
          if old_partner.get_instance_id() == partner_id:
            event_bus.attunement_broken.emit(self, old_partner)
            break
      if attunement_levels[partner_id] <= 0:
        attunement_levels.erase(partner_id)
    _update_attuned_partners()
    return

  for partner in harmony_partners:
    var partner_id = partner.get_instance_id()
    var current = attunement_levels.get(partner_id, 0.0)
    var new_level = minf(current + config.attunement_gain_rate * delta, config.attunement_max_level)
    var was_attuned = current >= config.attunement_threshold
    var is_attuned = new_level >= config.attunement_threshold
    attunement_levels[partner_id] = new_level
    if not was_attuned and is_attuned:
      event_bus.attunement_achieved.emit(self, partner)
    if new_level > current and int(new_level * 10) > int(current * 10):
      event_bus.attunement_progress.emit(self, partner, new_level)

  _update_attuned_partners()

func _update_attuned_partners() -> void:
  attuned_partners.clear()
  for partner in harmony_partners:
    var partner_id = partner.get_instance_id()
    if attunement_levels.get(partner_id, 0.0) >= config.attunement_threshold:
      attuned_partners.append(partner)

func is_attuned_with(partner: Node) -> bool:
  return partner in attuned_partners

func get_attunement_speed_multiplier() -> float:
  if attuned_partners.is_empty():
    return 1.0
  return 1.0 + config.attunement_speed_bonus * attuned_partners.size()

func get_attunement_output_bonus() -> int:
  if attuned_partners.is_empty():
    return 0
  return config.attunement_output_bonus * attuned_partners.size()

func get_attunement_storage_bonus() -> int:
  if attuned_partners.is_empty():
    return 0
  return config.attunement_storage_bonus * attuned_partners.size()

func try_attunement_synergy() -> Dictionary:
  var result = {"triggered": false}
  if attuned_partners.is_empty():
    return result
  for partner in attuned_partners:
    var pair_key = "%s+%s" % [building_id, partner.building_id]
    var reverse_key = "%s+%s" % [partner.building_id, building_id]
    var synergy = config.attunement_synergy_bonuses.get(pair_key, config.attunement_synergy_bonuses.get(reverse_key, {}))
    if synergy.is_empty():
      continue
    if synergy.has("output_type") and synergy.has("chance"):
      if randf() < synergy["chance"]:
        result["triggered"] = true
        result["output_type"] = synergy["output_type"]
        result["amount"] = 1
        event_bus.attunement_synergy_triggered.emit(self, partner, synergy["output_type"])
    if synergy.has("tension_reduction"):
      var reduced = remove_from_storage("tension", synergy["tension_reduction"])
      if reduced > 0:
        result["triggered"] = true
        event_bus.attunement_synergy_triggered.emit(self, partner, "tension_reduction")
    if synergy.has("calm_bonus"):
      result["triggered"] = true
      result["calm_bonus"] = synergy["calm_bonus"]
      event_bus.attunement_synergy_triggered.emit(self, partner, "calm_bonus")
    if synergy.has("energy_bonus"):
      result["triggered"] = true
      result["energy_bonus"] = synergy["energy_bonus"]
      event_bus.attunement_synergy_triggered.emit(self, partner, "energy_bonus")
  return result

func _process_fragility(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return

  var was_cracked = is_cracked
  is_cracked = fragility_level >= config.fragility_crack_threshold

  if is_cracked and not was_cracked:
    event_bus.building_cracked.emit(self, fragility_level)

  if is_cracked:
    _process_fragility_leak(delta)

  _heal_fragility(delta)

func _gain_fragility(inputs: Dictionary) -> void:
  var negative_count = 0
  for resource_id in inputs:
    if resource_id in config.fragility_negative_emotions:
      negative_count += inputs[resource_id]

  if negative_count > 0:
    var old_level = fragility_level
    fragility_level = minf(fragility_level + negative_count * config.fragility_gain_per_negative, config.fragility_max_level)
    if old_level < config.fragility_crack_threshold and fragility_level >= config.fragility_crack_threshold:
      is_cracked = true
      event_bus.building_cracked.emit(self, fragility_level)

func _process_fragility_leak(delta: float) -> void:
  if not grid:
    return

  fragility_leak_timer += delta
  if fragility_leak_timer < config.fragility_leak_interval:
    return

  fragility_leak_timer = 0.0

  var leak_candidates: Array[String] = []
  for resource_id in storage:
    if storage[resource_id] > 0:
      leak_candidates.append(resource_id)

  if leak_candidates.is_empty():
    return

  var leak_resource = leak_candidates[randi() % leak_candidates.size()]
  var neighbors = _get_adjacent_buildings()

  if neighbors.is_empty():
    return

  var target = neighbors[randi() % neighbors.size()]
  var leaked = remove_from_storage(leak_resource, config.fragility_leak_amount)
  if leaked > 0:
    target.add_to_storage(leak_resource, leaked)
    event_bus.building_leaked.emit(self, leak_resource, target)

func _heal_fragility(delta: float) -> void:
  if fragility_level <= 0:
    return

  var base_heal = config.fragility_heal_rate * delta
  var calm_heal = _get_nearby_calm_for_fragility() * config.fragility_calm_heal_bonus * delta
  var total_heal = base_heal + calm_heal

  var old_level = fragility_level
  fragility_level = maxf(0.0, fragility_level - total_heal)

  if is_cracked and fragility_level < config.fragility_crack_threshold:
    is_cracked = false
    event_bus.building_healed.emit(self, fragility_level)

func _get_nearby_calm_for_fragility() -> int:
  var total_calm = storage.get("calm", 0)
  if not grid:
    return total_calm

  var radius = config.fragility_calm_heal_radius
  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_calm += occupant.get_storage_amount("calm")

  return total_calm

func _get_fragility_speed_multiplier() -> float:
  if fragility_level <= 0:
    return 1.0
  var penalty = fragility_level * config.fragility_speed_penalty_at_max
  return 1.0 - penalty

func _process_stagnation(delta: float) -> void:
  if storage_capacity <= 0:
    return

  for resource_id in storage:
    if storage[resource_id] <= 0:
      resource_age_data.erase(resource_id)
      continue

    if not resource_age_data.has(resource_id):
      resource_age_data[resource_id] = {"age": 0.0, "stagnation": 0.0}

    var data = resource_age_data[resource_id]
    data["age"] += delta

    if data["age"] >= config.stagnation_time_threshold:
      var old_stagnation = data["stagnation"]
      data["stagnation"] = minf(data["stagnation"] + config.stagnation_gain_rate * delta, config.stagnation_max_level)
      if old_stagnation < 0.5 and data["stagnation"] >= 0.5:
        event_bus.resource_stagnated.emit(self, resource_id, data["stagnation"])

  _process_stagnation_decay(delta)

func _process_stagnation_decay(delta: float) -> void:
  stagnation_decay_timer += delta
  if stagnation_decay_timer < config.stagnation_decay_interval:
    return

  stagnation_decay_timer = 0.0

  for resource_id in resource_age_data:
    var data = resource_age_data[resource_id]
    if data["stagnation"] < config.stagnation_max_level * 0.8:
      continue

    if randf() >= config.stagnation_decay_chance:
      continue

    var transform_to = config.stagnation_decay_transforms.get(resource_id, "")
    if transform_to == "":
      continue

    var amount = storage.get(resource_id, 0)
    if amount <= 0:
      continue

    var decay_amount = mini(amount, 2)
    remove_from_storage(resource_id, decay_amount)
    _output_resource(transform_to, decay_amount)
    event_bus.resource_decayed_to_severe.emit(self, resource_id, transform_to)
    resource_age_data.erase(resource_id)

func _get_stagnation_speed_multiplier() -> float:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return 1.0

  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 1.0

  var total_stagnation = 0.0
  var total_freshness = 0.0
  var count = 0

  for resource_id in inputs:
    if not resource_age_data.has(resource_id):
      total_freshness += 1.0
      count += 1
      continue

    var data = resource_age_data[resource_id]
    if data["age"] < config.stagnation_fresh_threshold:
      total_freshness += 1.0
    else:
      total_stagnation += data["stagnation"]
    count += 1

  if count == 0:
    return 1.0

  var avg_stagnation = total_stagnation / count
  var avg_freshness = total_freshness / count

  if avg_freshness > 0.5:
    return 1.0 + config.stagnation_fresh_bonus * avg_freshness
  elif avg_stagnation > 0:
    return 1.0 - config.stagnation_process_penalty * avg_stagnation

  return 1.0

func reset_resource_age(resource_id: String) -> void:
  if resource_age_data.has(resource_id):
    resource_age_data[resource_id] = {"age": 0.0, "stagnation": 0.0}

func get_resource_stagnation(resource_id: String) -> float:
  if not resource_age_data.has(resource_id):
    return 0.0
  return resource_age_data[resource_id].get("stagnation", 0.0)

func is_resource_fresh(resource_id: String) -> bool:
  if not resource_age_data.has(resource_id):
    return true
  return resource_age_data[resource_id].get("age", 0.0) < config.stagnation_fresh_threshold
