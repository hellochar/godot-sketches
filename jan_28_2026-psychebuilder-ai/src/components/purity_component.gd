class_name PurityComponent
extends BuildingComponent

func on_process(delta: float) -> void:
  _process_purity_decay(delta)

func _process_purity_decay(delta: float) -> void:
  if building.storage_capacity <= 0:
    return

  var decay = config.purity_decay_rate * delta
  for resource_id in building.storage_purity.keys():
    if building.storage.get(resource_id, 0) <= 0:
      building.storage_purity.erase(resource_id)
      continue
    var old_purity = building.storage_purity[resource_id]
    building.storage_purity[resource_id] = maxf(old_purity - decay, config.purity_min_level)
    if old_purity >= config.purity_output_bonus_threshold and building.storage_purity[resource_id] < config.purity_output_bonus_threshold:
      event_bus.resource_purity_degraded.emit(building, resource_id, building.storage_purity[resource_id])

  if building.is_awakened and building.has_behavior(building.BuildingDefs.Behavior.PROCESSOR):
    _try_refine_resources(delta)

func _try_refine_resources(delta: float) -> void:
  for resource_id in building.storage:
    if building.storage[resource_id] <= 0:
      continue
    var purity = building.storage_purity.get(resource_id, config.purity_initial_level)
    if purity < config.purity_refine_threshold:
      var refine_gain = config.purity_refine_gain + config.purity_awakened_refine_bonus
      building.storage_purity[resource_id] = minf(purity + refine_gain * delta, config.purity_initial_level)
      if building.storage_purity[resource_id] >= config.purity_refine_threshold and purity < config.purity_refine_threshold:
        event_bus.resource_refined.emit(building, resource_id, building.storage_purity[resource_id])

func get_speed_multiplier() -> float:
  if not building.has_behavior(building.BuildingDefs.Behavior.PROCESSOR):
    return 1.0
  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 1.0
  var total_purity = 0.0
  var count = 0
  for resource_id in inputs:
    total_purity += building.storage_purity.get(resource_id, config.purity_min_level)
    count += 1
  if count == 0:
    return 1.0
  var avg_purity = total_purity / count
  if avg_purity >= config.purity_output_bonus_threshold:
    return 1.0 + config.purity_speed_bonus_at_pure * (avg_purity - config.purity_output_bonus_threshold) / (1.0 - config.purity_output_bonus_threshold)
  elif avg_purity <= config.purity_diluted_threshold:
    var dilution_ratio = (config.purity_diluted_threshold - avg_purity) / (config.purity_diluted_threshold - config.purity_min_level)
    return 1.0 - config.purity_diluted_penalty * dilution_ratio
  return 1.0

func get_output_bonus() -> int:
  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 0
  var all_pure = true
  for resource_id in inputs:
    if building.storage_purity.get(resource_id, config.purity_min_level) < config.purity_output_bonus_threshold:
      all_pure = false
      break
  if all_pure:
    event_bus.pure_resource_processed.emit(building, inputs.keys()[0], config.purity_output_bonus_amount)
    return config.purity_output_bonus_amount
  return 0
