class_name FragilityComponent
extends BuildingComponent

var fragility_level: float = 0.0
var is_cracked: bool = false
var fragility_leak_timer: float = 0.0

func on_process(delta: float) -> void:
  var was_cracked = is_cracked
  is_cracked = fragility_level >= config.fragility_crack_threshold

  if is_cracked and not was_cracked:
    event_bus.building_cracked.emit(building, fragility_level)

  if is_cracked:
    _process_leak(delta)

  _heal_fragility(delta)

func on_processing_complete(inputs: Dictionary, _outputs: Dictionary) -> void:
  _gain_fragility(inputs)

func _gain_fragility(inputs: Dictionary) -> void:
  var negative_count = 0
  for resource_id in inputs:
    if resource_id in config.fragility_negative_emotions:
      negative_count += inputs[resource_id]

  if negative_count > 0:
    var gain_modifier = 1.0
    if building.is_legacy:
      gain_modifier = 1.0 - config.legacy_resilience_factor
    var old_level = fragility_level
    fragility_level = minf(fragility_level + negative_count * config.fragility_gain_per_negative * gain_modifier, config.fragility_max_level)
    if old_level < config.fragility_crack_threshold and fragility_level >= config.fragility_crack_threshold:
      is_cracked = true
      event_bus.building_cracked.emit(building, fragility_level)

func _process_leak(delta: float) -> void:
  if not grid:
    return

  fragility_leak_timer += delta
  if fragility_leak_timer < config.fragility_leak_interval:
    return

  fragility_leak_timer = 0.0

  var leak_candidates: Array[String] = []
  for resource_id in building.storage:
    if building.storage[resource_id] > 0:
      leak_candidates.append(resource_id)

  if leak_candidates.is_empty():
    return

  var leak_resource = leak_candidates[randi() % leak_candidates.size()]
  var neighbors = get_adjacent_buildings()

  if neighbors.is_empty():
    return

  var target = neighbors[randi() % neighbors.size()]
  var leaked = building.remove_from_storage(leak_resource, config.fragility_leak_amount)
  if leaked > 0:
    target.add_to_storage(leak_resource, leaked)
    event_bus.building_leaked.emit(building, leak_resource, target)

func _heal_fragility(delta: float) -> void:
  if fragility_level <= 0:
    return

  var base_heal = config.fragility_heal_rate * delta
  var calm_heal = _get_nearby_calm() * config.fragility_calm_heal_bonus * delta
  var total_heal = base_heal + calm_heal

  fragility_level = maxf(0.0, fragility_level - total_heal)

  if is_cracked and fragility_level < config.fragility_crack_threshold:
    is_cracked = false
    event_bus.building_healed.emit(building, fragility_level)

func _get_nearby_calm() -> int:
  var total_calm = building.storage.get("calm", 0)
  if not grid:
    return total_calm

  var radius = config.fragility_calm_heal_radius
  for x in range(-radius, building.size.x + radius):
    for y in range(-radius, building.size.y + radius):
      if x >= 0 and x < building.size.x and y >= 0 and y < building.size.y:
        continue
      var check = building.grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != building and occupant.has_method("get_storage_amount"):
          total_calm += occupant.get_storage_amount("calm")

  return total_calm

func get_speed_multiplier() -> float:
  if fragility_level <= 0:
    return 1.0
  var penalty = fragility_level * config.fragility_speed_penalty_at_max
  return 1.0 - penalty
