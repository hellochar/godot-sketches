extends Node2D

const BuildingDefs = preload("res://jan_28_2026/src/data/building_definitions.gd")

var building_id: String
var definition: Dictionary
var grid_coord: Vector2i
var size: Vector2i = Vector2i(1, 1)

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

# Visual
@onready var sprite: ColorRect = $ColorRect
@onready var label: Label = $Label

func _ready() -> void:
  if definition:
    _update_visuals()

func initialize(p_building_id: String, p_grid_coord: Vector2i) -> void:
  building_id = p_building_id
  grid_coord = p_grid_coord
  definition = BuildingDefs.get_definition(building_id)

  if definition.is_empty():
    push_error("Unknown building: " + building_id)
    return

  size = definition.get("size", Vector2i(1, 1))
  storage_capacity = definition.get("storage_capacity", 0)

  if is_inside_tree():
    _update_visuals()

func _update_visuals() -> void:
  var tile_size = get_node("/root/Config").tile_size
  var pixel_size = Vector2(size) * tile_size

  sprite.size = pixel_size
  sprite.color = definition.get("color", Color.WHITE)

  label.size = pixel_size
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _update_storage_display()

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

func _process_generation(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.GENERATOR):
    return

  var rate = definition.get("generation_rate", 0.0)
  if rate <= 0:
    return

  generation_timer += delta
  var interval = 1.0 / rate

  if generation_timer >= interval:
    generation_timer -= interval
    var resource_id = definition.get("generates", "")
    var amount = definition.get("generation_amount", 1)
    if resource_id != "":
      _output_resource(resource_id, amount)

func _process_processing(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return

  if not processing_active:
    _try_start_processing()
    return

  process_timer -= delta
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

func _evaluate_trigger(_trigger: String) -> bool:
  # Simplified: always false for now
  # Full implementation would parse "anxiety > 10" etc.
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

  # Overflow spawns in world (handled by building_system)
  var overflow = amount - to_store
  if overflow > 0:
    # Signal to spawn resource nearby
    pass

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
    if not get_node("/root/GameState").spend_energy(energy_cost):
      return

  # Generate resources
  var generates = definition.get("habit_generates", {})
  for resource_id in generates:
    _output_resource(resource_id, generates[resource_id])

  # Energy bonus
  var energy_bonus = definition.get("habit_energy_bonus", 0)
  if energy_bonus > 0:
    get_node("/root/GameState").add_energy(energy_bonus)
