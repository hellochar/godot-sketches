class_name VelocityComponent
extends BuildingComponent

var velocity_history: Array[Dictionary] = []
var velocity_current: float = 0.0
var velocity_momentum: float = 0.0
var velocity_sustained_timer: float = 0.0
var velocity_last_process_time: float = 0.0

func on_process(delta: float) -> void:
  var current_time = Time.get_ticks_msec() / 1000.0
  _cleanup_history(current_time)
  _calculate_velocity()

  if velocity_current >= config.velocity_high_threshold:
    velocity_sustained_timer += delta
    velocity_momentum = minf(velocity_momentum + config.velocity_momentum_gain * delta, config.velocity_momentum_max)

    if velocity_sustained_timer >= config.velocity_sustained_threshold:
      if velocity_momentum >= 0.5:
        event_bus.velocity_burst_triggered.emit(building, velocity_current)
  else:
    velocity_sustained_timer = maxf(0.0, velocity_sustained_timer - delta * 2.0)
    velocity_momentum = maxf(0.0, velocity_momentum - config.velocity_momentum_decay * delta)

func on_processing_complete(inputs: Dictionary, _outputs: Dictionary) -> void:
  _record_event(inputs)

func _record_event(inputs: Dictionary) -> void:
  var current_time = Time.get_ticks_msec() / 1000.0
  var total_amount = 0
  for resource_id in inputs:
    total_amount += inputs[resource_id]

  velocity_history.append({
    "time": current_time,
    "amount": total_amount
  })
  velocity_last_process_time = current_time

func _cleanup_history(current_time: float) -> void:
  var cutoff_time = current_time - config.velocity_sample_window
  while velocity_history.size() > 0 and velocity_history[0]["time"] < cutoff_time:
    velocity_history.pop_front()

func _calculate_velocity() -> void:
  if velocity_history.size() < 2:
    velocity_current = 0.0
    return

  var total_amount = 0.0
  for entry in velocity_history:
    total_amount += entry["amount"]

  velocity_current = total_amount / config.velocity_sample_window

func get_speed_multiplier() -> float:
  var base_multiplier = 1.0

  if velocity_current >= config.velocity_high_threshold:
    var excess = velocity_current - config.velocity_high_threshold
    var normalized = minf(excess / config.velocity_high_threshold, 1.0)
    base_multiplier += config.velocity_high_speed_bonus * normalized
  elif velocity_current < config.velocity_low_threshold and velocity_history.size() > 0:
    var deficit = config.velocity_low_threshold - velocity_current
    var normalized = minf(deficit / config.velocity_low_threshold, 1.0)
    base_multiplier -= config.velocity_low_speed_penalty * normalized

  var momentum_bonus = velocity_momentum * config.velocity_burst_bonus
  return base_multiplier + momentum_bonus

func get_velocity() -> float:
  return velocity_current

func get_momentum() -> float:
  return velocity_momentum
