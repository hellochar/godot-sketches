class_name MomentumComponent
extends BuildingComponent

var momentum_level: float = 0.0
var momentum_last_recipe: String = ""
var momentum_starvation_timer: float = 0.0
var momentum_break_penalty_timer: float = 0.0

func on_process(delta: float) -> void:
  if momentum_break_penalty_timer > 0:
    momentum_break_penalty_timer -= delta

  var proc_comp = building.get_component("processor")
  if proc_comp and not proc_comp.processing_active:
    momentum_starvation_timer += delta
    if momentum_starvation_timer >= config.momentum_starvation_timeout and momentum_level > 0:
      _break_momentum()
    return

  momentum_starvation_timer = 0.0

func on_processing_complete(inputs: Dictionary, _outputs: Dictionary) -> void:
  var recipe_key = _get_recipe_key(inputs)
  _build_momentum(recipe_key)

func _get_recipe_key(inputs: Dictionary) -> String:
  var sorted_keys = inputs.keys()
  sorted_keys.sort()
  var parts: Array[String] = []
  for key in sorted_keys:
    parts.append("%s:%d" % [key, inputs[key]])
  return ":".join(parts)

func _build_momentum(recipe_key: String) -> void:
  if momentum_last_recipe != "" and momentum_last_recipe != recipe_key:
    _break_momentum()
    return

  momentum_last_recipe = recipe_key
  momentum_level = minf(momentum_level + config.momentum_gain_per_cycle, config.momentum_max_level)

func _break_momentum() -> void:
  momentum_level = maxf(0.0, momentum_level - config.momentum_decay_on_break)
  momentum_break_penalty_timer = config.momentum_break_penalty_duration
  if momentum_level <= 0:
    momentum_last_recipe = ""

func get_speed_multiplier() -> float:
  if momentum_break_penalty_timer > 0:
    return 1.0 - config.momentum_break_penalty_amount
  var momentum_ratio = momentum_level / config.momentum_max_level
  return 1.0 + (momentum_ratio * config.momentum_speed_bonus_at_max)
