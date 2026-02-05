class_name HarmonyComponent
extends BuildingComponent

var harmony_partners: Array[Node] = []
var is_in_harmony: bool = false

func on_process(_delta: float) -> void:
  var was_in_harmony = is_in_harmony
  harmony_partners.clear()
  is_in_harmony = false

  if not grid:
    return

  var my_pairs = config.harmony_pairs.get(building.building_id, [])
  var neighbors = get_adjacent_buildings()

  for neighbor in neighbors:
    if neighbor.building_id in my_pairs:
      harmony_partners.append(neighbor)

    var neighbor_pairs = config.harmony_pairs.get(neighbor.building_id, [])
    if building.building_id in neighbor_pairs and neighbor not in harmony_partners:
      harmony_partners.append(neighbor)

  is_in_harmony = harmony_partners.size() > 0

  if is_in_harmony != was_in_harmony:
    building._update_connection_visual()
    if is_in_harmony and not was_in_harmony:
      event_bus.harmony_formed.emit(building, harmony_partners)

func get_speed_multiplier() -> float:
  if not is_in_harmony:
    return 1.0
  var bonus = config.harmony_speed_bonus
  if harmony_partners.size() > 1:
    bonus += (harmony_partners.size() - 1) * config.harmony_mutual_bonus
  return 1.0 + bonus

func get_generation_multiplier() -> float:
  return get_speed_multiplier()

func get_output_bonus() -> int:
  if is_in_harmony:
    return config.harmony_output_bonus
  return 0
