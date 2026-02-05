class_name AwakeningComponent
extends BuildingComponent

var awakening_experience: int = 0
var is_awakened: bool = false

func on_processing_complete(_inputs: Dictionary, _outputs: Dictionary) -> void:
  _gain_experience()

func _gain_experience() -> void:
  if is_awakened:
    return
  awakening_experience += config.awakening_experience_per_process
  if awakening_experience >= config.awakening_threshold:
    _awaken()

func _awaken() -> void:
  is_awakened = true
  building.storage_capacity += config.awakening_storage_bonus
  event_bus.building_awakened.emit(building)

func get_speed_multiplier() -> float:
  if is_awakened:
    return 1.0 + config.awakening_speed_bonus
  return 1.0

func get_output_bonus() -> int:
  if is_awakened:
    return config.awakening_output_bonus
  return 0

func get_generator_rate_multiplier() -> float:
  if is_awakened:
    return 1.0 + config.awakening_generator_rate_bonus
  return 1.0

func get_generation_multiplier() -> float:
  return get_generator_rate_multiplier()
