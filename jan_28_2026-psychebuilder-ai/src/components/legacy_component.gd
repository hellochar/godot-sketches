class_name LegacyComponent
extends BuildingComponent

var is_legacy: bool = false
var legacy_timer: float = 0.0
var legacy_qualifying: bool = false

func on_process(delta: float) -> void:
  if is_legacy:
    return

  var meets_mastery = _check_mastery_requirement()
  var meets_awakening = _check_awakening_requirement()

  legacy_qualifying = meets_mastery and meets_awakening

  if legacy_qualifying:
    legacy_timer += delta
    if legacy_timer >= config.legacy_time_required:
      is_legacy = true
      event_bus.legacy_status_achieved.emit(building)
  else:
    legacy_timer = maxf(0.0, legacy_timer - delta * config.legacy_resilience_factor)

func _check_mastery_requirement() -> bool:
  var mastery_comp = building.get_component("mastery")
  if mastery_comp:
    for resource_type in mastery_comp.mastery_levels:
      if mastery_comp.mastery_levels[resource_type] >= config.legacy_mastery_threshold:
        return true
  else:
    for resource_type in building.mastery_levels:
      if building.mastery_levels[resource_type] >= config.legacy_mastery_threshold:
        return true
  return false

func _check_awakening_requirement() -> bool:
  if not config.legacy_awakening_required:
    return true
  var awakening_comp = building.get_component("awakening")
  if awakening_comp:
    return awakening_comp.is_awakened
  return building.is_awakened

func get_speed_multiplier() -> float:
  if not is_legacy:
    return 1.0
  return 1.0 + config.legacy_speed_bonus

func get_output_bonus() -> int:
  if not is_legacy:
    return 0
  return config.legacy_output_bonus

func is_legacy_building() -> bool:
  return is_legacy

func get_timer_progress() -> float:
  if is_legacy:
    return 1.0
  if not legacy_qualifying:
    return 0.0
  return legacy_timer / config.legacy_time_required
