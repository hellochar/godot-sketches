class_name SaturationComponent
extends BuildingComponent

enum State {
  NONE,
  JOY_SATURATED,
  CALM_SATURATED,
  GRIEF_SATURATED,
  ANXIETY_SATURATED,
  WISDOM_SATURATED,
}

var saturation_state: State = State.NONE
var saturation_timer: float = 0.0
var saturation_resource: String = ""
var joy_numbness_level: float = 0.0

func on_process(delta: float) -> void:
  _update_saturation(delta)
  _process_effects(delta)

func _update_saturation(delta: float) -> void:
  var effective_capacity = building.get_effective_storage_capacity()
  if effective_capacity <= 0:
    saturation_state = State.NONE
    saturation_timer = 0.0
    return

  var saturated_resource_id = ""
  var highest_ratio = 0.0

  for resource_id in ["joy", "calm", "grief", "anxiety", "wisdom"]:
    var amount = building.storage.get(resource_id, 0)
    var ratio = float(amount) / float(effective_capacity)
    if ratio >= config.saturation_threshold and ratio > highest_ratio:
      highest_ratio = ratio
      saturated_resource_id = resource_id

  if saturated_resource_id == "":
    saturation_state = State.NONE
    saturation_timer = 0.0
    saturation_resource = ""
    return

  if saturated_resource_id != saturation_resource:
    saturation_timer = 0.0
    saturation_resource = saturated_resource_id

  saturation_timer += delta

  if saturation_timer >= config.saturation_time_required:
    match saturation_resource:
      "joy": saturation_state = State.JOY_SATURATED
      "calm": saturation_state = State.CALM_SATURATED
      "grief": saturation_state = State.GRIEF_SATURATED
      "anxiety": saturation_state = State.ANXIETY_SATURATED
      "wisdom": saturation_state = State.WISDOM_SATURATED
  else:
    saturation_state = State.NONE

func _process_effects(delta: float) -> void:
  match saturation_state:
    State.JOY_SATURATED:
      _process_joy_saturation(delta)
    State.GRIEF_SATURATED:
      _process_grief_saturation(delta)
    State.ANXIETY_SATURATED:
      _process_anxiety_saturation(delta)
    State.NONE:
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

  var neighbors = get_adjacent_buildings()
  if neighbors.is_empty():
    return

  var target = neighbors[randi() % neighbors.size()]
  var removed = building.remove_from_storage("joy", spread_amount)
  if removed > 0:
    target.add_to_storage("joy", removed)

func _process_grief_saturation(delta: float) -> void:
  if randf() < config.saturation_grief_wisdom_rate * delta:
    output_resource("wisdom", 1)

func _process_anxiety_saturation(delta: float) -> void:
  if randf() >= config.saturation_anxiety_panic_chance * delta:
    return

  if not grid:
    return

  var neighbors = get_adjacent_buildings()
  for neighbor in neighbors:
    neighbor.add_to_storage("anxiety", config.saturation_anxiety_panic_spread)

func get_joy_numbness_factor() -> float:
  return joy_numbness_level
