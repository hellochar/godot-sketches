class_name HabitComponent
extends BuildingComponent

func trigger() -> void:
  var consumes = definition.get("habit_consumes", {})
  var energy_cost = consumes.get("energy", 0)
  if energy_cost > 0:
    if not game_state.spend_energy(energy_cost):
      return

  var adjacency_multiplier = building._get_habit_adjacency_multiplier()
  var weather_modifier = game_state.get_weather_habit_modifier()
  var belief_modifier = game_state.get_belief_habit_modifier()
  var total_multiplier = adjacency_multiplier * weather_modifier * belief_modifier

  var habit_special = definition.get("habit_special", "")
  if habit_special == "cathartic_release":
    var release_result = building._perform_cathartic_release()
    if release_result.calm_generated > 0:
      output_resource("calm", release_result.calm_generated)
    if release_result.insight_generated > 0:
      output_resource("insight", release_result.insight_generated)
      game_state.track_insight_generated(release_result.insight_generated)

  var generates = definition.get("habit_generates", {})
  for resource_id in generates:
    var amount = int(generates[resource_id] * total_multiplier)
    output_resource(resource_id, amount)

  var reduces = definition.get("habit_reduces", {})
  for resource_id in reduces:
    var to_reduce = int(reduces[resource_id] * total_multiplier)
    var removed = building.remove_from_storage(resource_id, to_reduce)
    var remaining = to_reduce - removed
    if remaining > 0:
      game_state.update_resource_total(resource_id, -remaining)

  var energy_bonus = definition.get("habit_energy_bonus", 0)
  if energy_bonus > 0:
    var bonus_amount = int(energy_bonus * total_multiplier)
    game_state.add_energy(bonus_amount)
