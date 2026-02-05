class_name GeneratorComponent
extends BuildingComponent

var generation_timer: float = 0.0

func on_process(delta: float) -> void:
  if not is_road_connected():
    return

  var rate = definition.get("generation_rate", 0.0)
  if rate <= 0:
    return

  var resource_id = definition.get("generates", "")
  var effective_delta = delta * _get_effective_multiplier(resource_id)

  generation_timer += effective_delta
  var interval = 1.0 / rate

  if generation_timer >= interval:
    generation_timer -= interval
    var amount = definition.get("generation_amount", 1)
    if resource_id != "":
      output_resource(resource_id, amount)

func _get_effective_multiplier(resource_id: String) -> float:
  var is_positive := resource_id in config.resonance_positive_resources
  var mult := 1.0

  mult *= building._get_grief_speed_multiplier()
  mult *= 1.0 + (config.cascade_generator_boost_amount if building.cascade_boost_active else 0.0)
  mult *= game_state.get_weather_generation_modifier()
  mult *= game_state.get_belief_generation_modifier()
  mult *= game_state.get_flow_state_multiplier()
  mult *= game_state.get_wellbeing_generation_modifier(is_positive)
  for component in building.get_components():
    if component != self:
      mult *= component.get_generation_multiplier()
  mult *= building.get_adjacency_efficiency_multiplier()

  if resource_id == "anxiety":
    var suppression := building._get_calm_aura_suppression()
    mult *= (1.0 - suppression)

  return mult
