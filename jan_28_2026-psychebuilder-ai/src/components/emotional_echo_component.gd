class_name EmotionalEchoComponent
extends BuildingComponent

var emotional_echo: Dictionary = {}
var dominant_echo: String = ""

func on_process(delta: float) -> void:
  _decay_echo(delta)

func on_processing_complete(inputs: Dictionary, _outputs: Dictionary) -> void:
  _build_echo(inputs)

func _build_echo(inputs: Dictionary) -> void:
  for resource_id in inputs:
    var current = emotional_echo.get(resource_id, 0.0)
    emotional_echo[resource_id] = minf(current + config.echo_gain_per_process, config.echo_max_level)
  _update_dominant_echo()

func _decay_echo(delta: float) -> void:
  if emotional_echo.is_empty():
    return

  var decay = config.echo_decay_rate * delta
  for resource_id in emotional_echo.keys():
    emotional_echo[resource_id] = maxf(0.0, emotional_echo[resource_id] - decay)

  _update_dominant_echo()

func _update_dominant_echo() -> void:
  var max_value = 0.0
  dominant_echo = ""

  for resource_id in emotional_echo:
    if emotional_echo[resource_id] > max_value:
      max_value = emotional_echo[resource_id]
      dominant_echo = resource_id

func get_speed_multiplier() -> float:
  if dominant_echo == "" or emotional_echo.get(dominant_echo, 0.0) < config.echo_threshold:
    return 1.0

  var inputs = definition.get("input", {})
  if inputs.is_empty():
    return 1.0

  var primary_input = ""
  var max_amount = 0
  for resource_id in inputs:
    if inputs[resource_id] > max_amount:
      max_amount = inputs[resource_id]
      primary_input = resource_id

  if primary_input == "":
    return 1.0

  var echo_strength = emotional_echo.get(dominant_echo, 0.0) / config.echo_max_level

  if primary_input == dominant_echo:
    return 1.0 + (echo_strength * config.echo_same_type_bonus)
  else:
    return 1.0 - (echo_strength * config.echo_different_type_penalty)
