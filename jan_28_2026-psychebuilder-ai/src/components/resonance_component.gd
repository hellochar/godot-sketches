class_name ResonanceComponent
extends BuildingComponent

var resonance_timer: float = 0.0
var is_in_positive_resonance: bool = false
var is_in_negative_resonance: bool = false

func on_process(delta: float) -> void:
  if building.storage_capacity <= 0:
    return

  is_in_positive_resonance = false
  is_in_negative_resonance = false

  for resource_id in building.storage:
    if building.storage[resource_id] < config.resonance_resource_threshold:
      continue

    var resonating_buildings = _find_resonating_buildings(resource_id)
    if resonating_buildings.size() >= config.resonance_min_buildings:
      if resource_id in config.resonance_positive_resources:
        is_in_positive_resonance = true
      elif resource_id in config.resonance_negative_resources:
        is_in_negative_resonance = true
        _process_negative_amplification(delta, resource_id)

func _find_resonating_buildings(resource_id: String) -> Array[Node]:
  var result: Array[Node] = [building]
  if not grid:
    return result

  var radius = config.resonance_radius
  for x in range(-radius, building.size.x + radius):
    for y in range(-radius, building.size.y + radius):
      if x >= 0 and x < building.size.x and y >= 0 and y < building.size.y:
        continue
      var check = building.grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != building and occupant.has_method("get_storage_amount"):
          if occupant.get_storage_amount(resource_id) >= config.resonance_resource_threshold:
            result.append(occupant)

  return result

func _process_negative_amplification(delta: float, resource_id: String) -> void:
  resonance_timer += delta
  if resonance_timer < config.resonance_negative_amplification_interval:
    return

  resonance_timer = 0.0
  var amount = config.resonance_negative_amplification_amount
  output_resource(resource_id, amount)
  event_bus.resonance_amplification.emit(building, resource_id, amount)

func get_speed_multiplier() -> float:
  if is_in_positive_resonance:
    return 1.0 + config.resonance_positive_speed_bonus
  return 1.0
