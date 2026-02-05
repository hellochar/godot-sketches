class_name ProcessorComponent
extends BuildingComponent

var processing_active: bool = false
var process_timer: float = 0.0

func on_process(delta: float) -> void:
  if not is_road_connected():
    return

  if not processing_active:
    _try_start_processing()
    return

  var effective_delta = delta * _get_combined_speed_multiplier()
  process_timer -= effective_delta

  if process_timer <= 0:
    _complete_processing()

func _try_start_processing() -> void:
  if definition.get("requires_worker", false) and not building.assigned_worker:
    return

  var inputs = definition.get("input", {})
  if not building._has_inputs(inputs):
    return

  building._consume_inputs(inputs)
  processing_active = true
  process_timer = definition.get("process_time", 1.0)

func _complete_processing() -> void:
  processing_active = false
  building._complete_processing_effects()

func _get_combined_speed_multiplier() -> float:
  var mult := 1.0
  mult *= building._get_grief_speed_multiplier()
  mult *= building._get_tension_speed_multiplier()
  mult *= building._get_wisdom_efficiency_multiplier()
  mult *= building._get_doubt_efficiency_multiplier()
  mult *= building._get_sync_chain_speed_multiplier()
  mult *= game_state.get_weather_processing_modifier()
  mult *= game_state.get_belief_processing_modifier()
  mult *= game_state.get_breakthrough_speed_modifier()
  mult *= game_state.get_flow_state_multiplier()
  mult *= game_state.get_wellbeing_processing_modifier()
  for component in building.get_components():
    if component != self:
      mult *= component.get_speed_multiplier()
  return mult
