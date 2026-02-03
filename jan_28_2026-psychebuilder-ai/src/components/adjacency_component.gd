class_name AdjacencyComponent
extends BuildingComponent

const AdjacencyRules = preload("res://jan_28_2026-psychebuilder-ai/src/data/adjacency_rules.gd")

var _signals_connected: bool = false

func on_initialize() -> void:
  call_deferred("_connect_signals")
  call_deferred("recalculate_adjacency")

func _connect_signals() -> void:
  if _signals_connected:
    return
  _signals_connected = true
  event_bus.building_placed.connect(_on_building_placed)
  event_bus.building_removed.connect(_on_building_removed)

func _on_building_placed(placed_building: Node, _coord: Vector2i) -> void:
  if placed_building == building:
    recalculate_adjacency()
  elif _is_within_adjacency_radius(placed_building):
    recalculate_adjacency()

func _on_building_removed(removed_building: Node, _coord: Vector2i) -> void:
  if removed_building == building:
    return
  if removed_building in building.adjacent_neighbors:
    recalculate_adjacency()

func _is_within_adjacency_radius(other: Node) -> bool:
  if not other or not is_instance_valid(other):
    return false
  if not other.has_method("get_storage_amount"):
    return false
  var other_coord = other.grid_coord if other.has_method("get_storage_amount") else Vector2i(-999, -999)
  var other_size = other.size if "size" in other else Vector2i(1, 1)
  for x in range(building.size.x):
    for y in range(building.size.y):
      var my_cell = building.grid_coord + Vector2i(x, y)
      for ox in range(other_size.x):
        for oy in range(other_size.y):
          var other_cell = other_coord + Vector2i(ox, oy)
          var dist = absi(my_cell.x - other_cell.x) + absi(my_cell.y - other_cell.y)
          if dist <= AdjacencyRules.ADJACENCY_RADIUS:
            return true
  return false

func get_buildings_in_adjacency_radius() -> Array[Node]:
  var result: Array[Node] = []
  if not grid:
    return result
  var checked_buildings: Dictionary = {}
  for x in range(-AdjacencyRules.ADJACENCY_RADIUS, building.size.x + AdjacencyRules.ADJACENCY_RADIUS):
    for y in range(-AdjacencyRules.ADJACENCY_RADIUS, building.size.y + AdjacencyRules.ADJACENCY_RADIUS):
      if x >= 0 and x < building.size.x and y >= 0 and y < building.size.y:
        continue
      var check = building.grid_coord + Vector2i(x, y)
      if not grid.is_valid_coord(check):
        continue
      var occupant = grid.get_occupant(check)
      if not occupant or occupant == building:
        continue
      if not occupant.has_method("get_storage_amount"):
        continue
      var occupant_id = occupant.get_instance_id()
      if checked_buildings.has(occupant_id):
        continue
      if _is_within_adjacency_radius(occupant):
        checked_buildings[occupant_id] = true
        result.append(occupant)
  return result

func recalculate_adjacency() -> void:
  building.adjacency_effects.clear()
  building.adjacency_efficiency_multiplier = 1.0
  building.adjacency_output_bonus = 0
  building.adjacency_transport_bonus = 0.0
  building.adjacent_neighbors = get_buildings_in_adjacency_radius()

  var same_type_count = 0

  for neighbor in building.adjacent_neighbors:
    var neighbor_id = neighbor.building_id if "building_id" in neighbor else ""
    if neighbor_id == "":
      continue

    if neighbor_id == building.building_id and building.has_behavior(building.BuildingDefs.Behavior.GENERATOR):
      same_type_count += 1

    var effect = AdjacencyRules.get_adjacency_effect(building.building_id, neighbor_id)
    if effect.is_empty():
      continue

    building.adjacency_effects[neighbor_id] = effect

    if effect.has("efficiency"):
      building.adjacency_efficiency_multiplier *= effect["efficiency"]

    if effect.has("output_bonus"):
      building.adjacency_output_bonus += effect["output_bonus"]

    if effect.has("output_penalty"):
      building.adjacency_output_bonus += effect["output_penalty"]

    if effect.has("transport_bonus"):
      building.adjacency_transport_bonus += effect["transport_bonus"]

    var effect_type = effect.get("type", -1)
    if effect_type == AdjacencyRules.EffectType.SYNERGY:
      event_bus.adjacency_synergy_formed.emit(building, neighbor, effect)
    elif effect_type == AdjacencyRules.EffectType.CONFLICT:
      event_bus.adjacency_conflict_formed.emit(building, neighbor, effect)

  if same_type_count > 0 and building.has_behavior(building.BuildingDefs.Behavior.GENERATOR):
    var stacking_mult = AdjacencyRules.get_stacking_multiplier(building.building_id, same_type_count + 1)
    building.adjacency_efficiency_multiplier *= stacking_mult

  event_bus.adjacency_changed.emit(building)

func get_adjacency_efficiency_multiplier() -> float:
  return building.adjacency_efficiency_multiplier

func get_adjacency_output_bonus() -> int:
  return building.adjacency_output_bonus

func get_adjacency_transport_bonus() -> float:
  return building.adjacency_transport_bonus

func get_adjacency_spillover() -> Dictionary:
  var spillover: Dictionary = {}
  for neighbor_id in building.adjacency_effects:
    var effect = building.adjacency_effects[neighbor_id]
    if effect.has("spillover"):
      for resource_id in effect["spillover"]:
        spillover[resource_id] = spillover.get(resource_id, 0) + effect["spillover"][resource_id]
  return spillover

func has_adjacency_synergy() -> bool:
  for neighbor_id in building.adjacency_effects:
    var effect = building.adjacency_effects[neighbor_id]
    if effect.get("type", -1) == AdjacencyRules.EffectType.SYNERGY:
      return true
  return false

func has_adjacency_conflict() -> bool:
  for neighbor_id in building.adjacency_effects:
    var effect = building.adjacency_effects[neighbor_id]
    if effect.get("type", -1) == AdjacencyRules.EffectType.CONFLICT:
      return true
  return false

func get_adjacency_descriptions() -> Array[Dictionary]:
  var result: Array[Dictionary] = []
  for neighbor_id in building.adjacency_effects:
    var effect = building.adjacency_effects[neighbor_id]
    result.append({
      "neighbor": neighbor_id,
      "type": effect.get("type", AdjacencyRules.EffectType.NEUTRAL),
      "description": effect.get("description", ""),
      "efficiency": effect.get("efficiency", 1.0),
      "output_bonus": effect.get("output_bonus", 0)
    })
  return result
