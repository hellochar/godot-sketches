extends Node

const EventDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/event_definitions.gd")

signal event_popup_requested(event_data: Dictionary)

@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")
@onready var config: Node = get_node("/root/Config")

var event_history: Array[String] = []
var current_event: Dictionary = {}
var active_completion_events: Array[Dictionary] = []
var inciting_incident_triggered: bool = false
var energy_regen_modifier: int = 0

var resource_system: Node
var grid_system: Node

func setup(p_resource_system: Node, p_grid_system: Node) -> void:
  resource_system = p_resource_system
  grid_system = p_grid_system

func _ready() -> void:
  event_bus.day_started.connect(_on_day_started)

func _on_day_started(day_number: int) -> void:
  energy_regen_modifier = 0
  _check_inciting_incident(day_number)
  _check_random_event()
  _apply_energy_modifier()

func _check_inciting_incident(day_number: int) -> void:
  if inciting_incident_triggered:
    return

  if day_number >= config.inciting_incident_day:
    var incidents = EventDefs.get_inciting_incidents()
    if incidents.size() > 0:
      var incident_id = incidents[randi() % incidents.size()]
      _trigger_event(incident_id)
      inciting_incident_triggered = true

func _check_random_event() -> void:
  if randf() > config.random_event_chance:
    return

  if current_event.size() > 0:
    return

  var minor_events = EventDefs.get_minor_events()
  var available = minor_events.filter(func(id): return id not in event_history or config.allow_repeat_events)

  if available.size() == 0:
    available = minor_events

  if available.size() > 0:
    var event_id = available[randi() % available.size()]
    _trigger_event(event_id)

func _trigger_event(event_id: String) -> void:
  var event_data = EventDefs.get_definition(event_id)
  if event_data.is_empty():
    return

  current_event = event_data
  event_history.append(event_id)

  _spawn_event_resources(event_data.get("spawns", []))

  var effect = event_data.get("effect", {})
  if effect.has("energy_regen_modifier"):
    energy_regen_modifier += effect.get("energy_regen_modifier", 0)

  var conditional_spawns = event_data.get("conditional_spawns", {})
  for condition in conditional_spawns:
    if _evaluate_condition(condition):
      _spawn_event_resources(conditional_spawns[condition])

  var choices = event_data.get("choices", [])
  if choices.size() > 0:
    event_popup_requested.emit(event_data)
  else:
    event_bus.event_triggered.emit(event_id)
    _check_completion_tracking(event_data)
    current_event = {}

func _spawn_event_resources(spawns: Array) -> void:
  for spawn_data in spawns:
    var resource_type = spawn_data.get("resource", "")
    var amount = spawn_data.get("amount", 1)
    var location = spawn_data.get("location", "random")

    if resource_type == "" or amount <= 0:
      continue

    var world_pos = _get_spawn_position(location, spawn_data)
    if resource_system:
      resource_system.spawn_resource(resource_type, world_pos, amount)

func _get_spawn_position(location: String, spawn_data: Dictionary) -> Vector2:
  var grid_size = config.grid_size
  var tile_size = config.tile_size

  match location:
    "center":
      var center_coord = Vector2i(grid_size.x / 2, grid_size.y / 2)
      center_coord += Vector2i(randi_range(-2, 2), randi_range(-2, 2))
      return grid_system.grid_to_world(center_coord) if grid_system else Vector2(center_coord) * tile_size

    "random":
      var rand_coord = Vector2i(randi_range(5, grid_size.x - 5), randi_range(5, grid_size.y - 5))
      return grid_system.grid_to_world(rand_coord) if grid_system else Vector2(rand_coord) * tile_size

    "specific_building":
      var building_id = spawn_data.get("building_id", "")
      var building = _find_building_by_id(building_id)
      if building:
        return building.position
      return _get_spawn_position("center", {})

    _:
      return _get_spawn_position("random", {})

func _find_building_by_id(building_id: String) -> Node:
  for building in game_state.active_buildings:
    if building.building_id == building_id:
      return building
  return null

func execute_choice(choice_index: int) -> void:
  if current_event.is_empty():
    return

  var choices = current_event.get("choices", [])
  if choice_index < 0 or choice_index >= choices.size():
    return

  var choice = choices[choice_index]
  var effect = choice.get("effect", {})

  var energy_cost = effect.get("energy_cost", 0)
  if energy_cost > 0:
    game_state.spend_energy(energy_cost)

  var energy_gain = effect.get("energy_gain", 0)
  if energy_gain > 0:
    game_state.add_energy(energy_gain)

  _spawn_event_resources(effect.get("spawns", []))

  var event_id = current_event.get("id", "")
  event_bus.event_triggered.emit(event_id)
  event_bus.event_choice_made.emit(event_id, choice_index)

  _check_completion_tracking(current_event)
  current_event = {}

func _check_completion_tracking(event_data: Dictionary) -> void:
  var completion_condition = event_data.get("completion_condition", "")
  if completion_condition != "":
    active_completion_events.append({
      "id": event_data.get("id", ""),
      "condition": completion_condition,
      "reward": event_data.get("completion_reward", {})
    })

func check_completion_conditions() -> void:
  var completed: Array[Dictionary] = []

  for event in active_completion_events:
    if _evaluate_condition(event.get("condition", "")):
      completed.append(event)

  for event in completed:
    active_completion_events.erase(event)
    _grant_completion_reward(event)

func _evaluate_condition(condition: String) -> bool:
  if condition == "":
    return false

  var parts = condition.split(" and ")
  for part in parts:
    part = part.strip_edges()
    if not _evaluate_single_condition(part):
      return false
  return true

func _evaluate_single_condition(condition: String) -> bool:
  var pattern = RegEx.new()
  pattern.compile("(\\w+)\\s*([<>=!]+)\\s*(\\d+)")
  var result = pattern.search(condition)

  if not result:
    return false

  var resource_type = result.get_string(1)
  var op = result.get_string(2)
  var value = int(result.get_string(3))

  var current_total = game_state.get_resource_total(resource_type)

  match op:
    "<":
      return current_total < value
    "<=":
      return current_total <= value
    ">":
      return current_total > value
    ">=":
      return current_total >= value
    "==", "=":
      return current_total == value
    "!=":
      return current_total != value
    _:
      return false

func _grant_completion_reward(event: Dictionary) -> void:
  var reward = event.get("reward", {})
  var event_id = event.get("id", "")

  var unlock_building = reward.get("unlock_building", "")
  if unlock_building != "":
    pass

  var spawn = reward.get("spawn", {})
  if spawn.size() > 0:
    _spawn_event_resources([spawn])

  event_bus.event_completed.emit(event_id)

func _apply_energy_modifier() -> void:
  if energy_regen_modifier != 0 and game_state:
    game_state.add_energy(energy_regen_modifier)

func get_active_event() -> Dictionary:
  return current_event

func has_active_event() -> bool:
  return current_event.size() > 0

func get_event_history() -> Array[String]:
  return event_history

func has_event_occurred(event_id: String) -> bool:
  return event_id in event_history

func get_pending_completion_count() -> int:
  return active_completion_events.size()

func dismiss_event() -> void:
  if current_event.size() > 0:
    var event_id = current_event.get("id", "")
    event_bus.event_triggered.emit(event_id)
    _check_completion_tracking(current_event)
    current_event = {}
