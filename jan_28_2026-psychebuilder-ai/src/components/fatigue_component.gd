class_name FatigueComponent
extends BuildingComponent

var fatigue_level: float = 0.0

func on_process(delta: float) -> void:
  _recover_fatigue(delta)

func on_processing_complete(_inputs: Dictionary, _outputs: Dictionary) -> void:
  _gain_fatigue()

func _gain_fatigue() -> void:
  var gain_modifier = 1.0
  if building.is_legacy:
    gain_modifier = 1.0 - config.legacy_resilience_factor
  fatigue_level = minf(fatigue_level + config.fatigue_gain_per_process * gain_modifier, config.fatigue_max_level)

func _recover_fatigue(delta: float) -> void:
  var proc_comp = building.get_component("processor")
  if proc_comp and proc_comp.processing_active:
    return

  var base_recovery = config.fatigue_recovery_rate * delta
  var calm_bonus = _get_nearby_calm() * config.fatigue_calm_recovery_bonus * delta
  var total_recovery = base_recovery + calm_bonus

  fatigue_level = maxf(0.0, fatigue_level - total_recovery)

func _get_nearby_calm() -> int:
  var total_calm = building.storage.get("calm", 0)
  if not grid:
    return total_calm

  var radius = config.fatigue_calm_radius
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
  if fatigue_level < config.fatigue_onset_threshold:
    return 1.0
  var effective_fatigue = (fatigue_level - config.fatigue_onset_threshold) / (config.fatigue_max_level - config.fatigue_onset_threshold)
  var penalty = effective_fatigue * config.fatigue_speed_penalty_at_max
  return 1.0 - penalty
