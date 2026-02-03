class_name StagnationComponent
extends BuildingComponent

var stagnation_decay_timer: float = 0.0

func on_process(delta: float) -> void:
  _process_stagnation(delta)

func _process_stagnation(delta: float) -> void:
  if building.storage_capacity <= 0:
    return

  for resource_id in building.storage:
    if building.storage[resource_id] <= 0:
      building.resource_age_data.erase(resource_id)
      continue

    if not building.resource_age_data.has(resource_id):
      building.resource_age_data[resource_id] = {"age": 0.0, "stagnation": 0.0}

    var data = building.resource_age_data[resource_id]
    data["age"] += delta

    if data["age"] >= config.stagnation_time_threshold:
      var old_stagnation = data["stagnation"]
      data["stagnation"] = minf(data["stagnation"] + config.stagnation_gain_rate * delta, config.stagnation_max_level)
      if old_stagnation < 0.5 and data["stagnation"] >= 0.5:
        event_bus.resource_stagnated.emit(building, resource_id, data["stagnation"])

  _process_stagnation_decay(delta)

func _process_stagnation_decay(delta: float) -> void:
  stagnation_decay_timer += delta
  if stagnation_decay_timer < config.stagnation_decay_interval:
    return

  stagnation_decay_timer = 0.0

  for resource_id in building.resource_age_data:
    var data = building.resource_age_data[resource_id]
    if data["stagnation"] < config.stagnation_max_level * 0.8:
      continue

    if randf() >= config.stagnation_decay_chance:
      continue

    var transform_to = config.stagnation_decay_transforms.get(resource_id, "")
    if transform_to == "":
      continue

    var amount = building.storage.get(resource_id, 0)
    if amount <= 0:
      continue

    var decay_amount = mini(amount, 2)
    building.remove_from_storage(resource_id, decay_amount)
    building._output_resource(transform_to, decay_amount)
    event_bus.resource_decayed_to_severe.emit(building, resource_id, transform_to)
    building.resource_age_data.erase(resource_id)

func get_speed_multiplier() -> float:
  if not building.has_behavior(building.BuildingDefs.Behavior.PROCESSOR):
    return 1.0

  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 1.0

  var total_stagnation = 0.0
  var total_freshness = 0.0
  var count = 0

  for resource_id in inputs:
    if not building.resource_age_data.has(resource_id):
      total_freshness += 1.0
      count += 1
      continue

    var data = building.resource_age_data[resource_id]
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
