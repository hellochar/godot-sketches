class_name MasteryComponent
extends BuildingComponent

var mastery_processed: Dictionary = {}
var mastery_levels: Dictionary = {}
var dominant_mastery: String = ""
var is_specialized: bool = false

func on_process(delta: float) -> void:
  _decay_mastery(delta)

func on_processing_complete(inputs: Dictionary, _outputs: Dictionary) -> void:
  _gain_mastery(inputs)

func _decay_mastery(delta: float) -> void:
  if mastery_processed.is_empty():
    return

  var decay_modifier = 1.0
  if building.is_legacy:
    decay_modifier = 1.0 - config.legacy_decay_protection

  for resource_id in mastery_processed.keys():
    if resource_id != dominant_mastery:
      mastery_processed[resource_id] = maxf(0.0, mastery_processed[resource_id] - config.mastery_decay_rate * decay_modifier * delta)

  _update_dominant_mastery()

func _gain_mastery(inputs: Dictionary) -> void:
  for resource_id in inputs:
    var amount = inputs[resource_id]
    var current = mastery_processed.get(resource_id, 0.0)
    mastery_processed[resource_id] = current + amount

    var old_level = mastery_levels.get(resource_id, 0)
    var new_level = _calculate_mastery_level(resource_id)

    if new_level > old_level:
      mastery_levels[resource_id] = new_level
      event_bus.mastery_level_gained.emit(building, resource_id, new_level)

  _update_dominant_mastery()

func _calculate_mastery_level(resource_id: String) -> int:
  var processed = mastery_processed.get(resource_id, 0.0)
  var level = 0
  for threshold in config.mastery_thresholds:
    if processed >= threshold:
      level += 1
    else:
      break
  return mini(level, config.mastery_max_level)

func _update_dominant_mastery() -> void:
  var max_processed = 0.0
  var total_processed = 0.0
  var new_dominant = ""

  for resource_id in mastery_processed:
    total_processed += mastery_processed[resource_id]
    if mastery_processed[resource_id] > max_processed:
      max_processed = mastery_processed[resource_id]
      new_dominant = resource_id

  var old_specialized = is_specialized
  dominant_mastery = new_dominant

  if total_processed > 0:
    is_specialized = (max_processed / total_processed) >= config.mastery_specialization_threshold
  else:
    is_specialized = false

  if is_specialized and not old_specialized and dominant_mastery != "":
    event_bus.mastery_specialization_achieved.emit(building, dominant_mastery)

func get_level(resource_id: String) -> int:
  return mastery_levels.get(resource_id, 0)

func get_speed_multiplier() -> float:
  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 1.0

  var total_bonus = 0.0
  var total_penalty = 0.0
  var count = 0

  for resource_id in inputs:
    var level = get_level(resource_id)
    total_bonus += level * config.mastery_speed_bonus_per_level

    if is_specialized and resource_id != dominant_mastery:
      total_penalty += config.mastery_cross_penalty
    count += 1

  if count == 0:
    return 1.0

  return 1.0 + (total_bonus / count) - total_penalty

func get_output_bonus() -> int:
  var inputs = definition.get("input", {})
  for resource_id in inputs:
    if get_level(resource_id) >= config.mastery_max_level:
      return config.mastery_output_bonus_at_max
  return 0
