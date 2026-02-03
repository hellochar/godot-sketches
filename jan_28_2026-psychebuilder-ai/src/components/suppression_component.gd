class_name SuppressionComponent
extends BuildingComponent

var suppression_field_active: bool = false
var suppression_field_timer: float = 0.0

func on_process(delta: float) -> void:
  _process_suppression_field(delta)

func create_suppression_field() -> void:
  suppression_field_active = true
  suppression_field_timer = config.transmutation_suppression_duration
  var tile_size = config.tile_size
  var field_position = building.position + Vector2(building.size) * tile_size * 0.5
  event_bus.suppression_field_created.emit(building, field_position, config.transmutation_suppression_radius, config.transmutation_suppression_duration)

func _process_suppression_field(delta: float) -> void:
  if not suppression_field_active:
    return

  suppression_field_timer -= delta
  if suppression_field_timer <= 0:
    suppression_field_active = false
    return

  if not grid:
    return

  var radius = config.transmutation_suppression_radius
  for x in range(-radius, building.size.x + radius):
    for y in range(-radius, building.size.y + radius):
      if x >= 0 and x < building.size.x and y >= 0 and y < building.size.y:
        continue
      var check = building.grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != building and occupant.has_method("get_storage_amount"):
          var anxiety = occupant.get_storage_amount("anxiety")
          if anxiety > 0:
            var suppress_amount = int(anxiety * config.transmutation_suppression_strength * delta)
            if suppress_amount > 0:
              occupant.remove_from_storage("anxiety", suppress_amount)

func get_suppression_field_strength() -> float:
  if not suppression_field_active:
    return 0.0
  return config.transmutation_suppression_strength

func is_affected_by_suppression_field() -> bool:
  if not grid:
    return false

  var radius = config.transmutation_suppression_radius
  for x in range(-radius, building.size.x + radius):
    for y in range(-radius, building.size.y + radius):
      var check = building.grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != building and occupant.has_method("get_suppression_field_strength"):
          if occupant.get_suppression_field_strength() > 0:
            return true
  return false
