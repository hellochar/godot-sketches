extends Node

const BuildingScene = preload("res://jan_28_2026-psychebuilder-ai/src/entities/building.tscn")
const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")

@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")

var grid: Node  # GridSystem
var buildings_layer: Node2D
var unlocked_buildings: Array = []

func _ready() -> void:
  _update_day_based_unlocks(game_state.current_day)
  event_bus.event_completed.connect(_on_event_completed)
  event_bus.day_started.connect(_on_day_started)

func _on_day_started(day: int) -> void:
  _update_day_based_unlocks(day)

func _update_day_based_unlocks(day: int) -> void:
  var newly_unlocked: Array = []
  var day_buildings = BuildingDefs.get_unlocked_for_day(day)
  for building_id in day_buildings:
    if building_id not in unlocked_buildings:
      unlocked_buildings.append(building_id)
      newly_unlocked.append(building_id)
  for building_id in newly_unlocked:
    event_bus.building_unlocked.emit(building_id)

func _on_event_completed(event_id: String) -> void:
  game_state.grant_event_reward(event_id)
  _check_all_unlock_conditions()

func setup(p_grid: Node, p_buildings_layer: Node2D) -> void:
  grid = p_grid
  buildings_layer = p_buildings_layer

func can_place(building_id: String, coord: Vector2i) -> bool:
  return get_placement_failure_reason(building_id, coord) == ""

func get_placement_failure_reason(building_id: String, coord: Vector2i) -> String:
  var def = BuildingDefs.get_definition(building_id)
  if def.is_empty():
    return "Unknown building type"

  if def.get("unique", false):
    for building in game_state.active_buildings:
      if building.building_id == building_id:
        return "Only one %s allowed" % def.get("name", building_id)

  var size = def.get("size", Vector2i(1, 1))

  var area_result = _check_area_placement(coord, size)
  if area_result != "":
    return area_result

  var cost = def.get("build_cost", {})
  var energy_cost = cost.get("energy", 0)
  if energy_cost > game_state.current_energy:
    return "Not enough energy (%d needed)" % energy_cost

  return ""

func _check_area_placement(coord: Vector2i, size: Vector2i) -> String:
  for x in range(size.x):
    for y in range(size.y):
      var check_coord = coord + Vector2i(x, y)
      if not grid.is_valid_coord(check_coord):
        return "Out of bounds"
      if grid.is_occupied(check_coord):
        return "Space is occupied"
  return ""

func place_building(building_id: String, coord: Vector2i) -> Node:
  if not can_place(building_id, coord):
    return null

  var def = BuildingDefs.get_definition(building_id)
  var size = def.get("size", Vector2i(1, 1))

  # Spend energy
  var cost = def.get("build_cost", {})
  var energy_cost = cost.get("energy", 0)
  if energy_cost > 0:
    game_state.spend_energy(energy_cost)

  # Create building
  var building = BuildingScene.instantiate()
  building.initialize(building_id, coord, grid)
  building.position = grid.grid_to_world_top_left(coord)

  # Add to scene
  buildings_layer.add_child(building)
  game_state.active_buildings.append(building)

  # Mark grid as occupied
  grid.occupy_area(coord, size, building)

  # Update connections for nearby buildings
  _update_nearby_connections(coord, size)

  event_bus.building_placed.emit(building, coord)

  return building

func remove_building(building: Node) -> void:
  var gs = game_state
  if building not in gs.active_buildings:
    return

  for worker in gs.active_workers:
    if worker.source_building == building or worker.dest_building == building:
      worker.unassign()

  var coord = building.grid_coord
  var size = building.size

  # Clear grid
  grid.clear_area(coord, size)

  # Remove from tracking
  gs.active_buildings.erase(building)

  event_bus.building_removed.emit(building, coord)

  building.queue_free()

  # Update connections for nearby buildings
  _update_nearby_connections(coord, size)

func get_building_at(coord: Vector2i) -> Node:
  var occupant = grid.get_occupant(coord)
  if occupant and occupant in game_state.active_buildings:
    return occupant
  return null

func get_all_buildings() -> Array[Node]:
  return game_state.active_buildings

func get_buildings_by_type(building_id: String) -> Array[Node]:
  var result: Array[Node] = []
  for building in game_state.active_buildings:
    if building.building_id == building_id:
      result.append(building)
  return result

func get_roads() -> Array[Node]:
  var result: Array[Node] = []
  for building in game_state.active_buildings:
    if building.is_road():
      result.append(building)
  return result

func is_unlocked(building_id: String) -> bool:
  return building_id in unlocked_buildings

func unlock_building(building_id: String) -> void:
  if building_id not in unlocked_buildings:
    unlocked_buildings.append(building_id)
    event_bus.building_unlocked.emit(building_id)

func get_unlocked_buildings() -> Array:
  return unlocked_buildings

func check_unlock_condition(building_id: String) -> bool:
  var def = BuildingDefs.get_definition(building_id)
  if def.is_empty():
    return false
  if def.get("unlocked_by_default", false):
    return true
  if game_state.has_discovered_building(building_id):
    return true

  var condition = def.get("unlock_condition", {})
  if condition.is_empty():
    return false

  if condition.has("insight"):
    var required = condition["insight"]
    if game_state.get_resource_total("insight") >= required:
      return true

  if condition.has("event_reward"):
    var event_id = condition["event_reward"]
    if game_state.has_event_reward(event_id):
      return true

  return false

func _check_all_unlock_conditions() -> void:
  var all_ids = BuildingDefs.get_all_ids()
  for building_id in all_ids:
    if building_id not in unlocked_buildings:
      if check_unlock_condition(building_id):
        unlock_building(building_id)
        event_bus.building_activated.emit(null)

func get_lockable_buildings() -> Array:
  var result = []
  var all_ids = BuildingDefs.get_all_ids()
  for building_id in all_ids:
    var def = BuildingDefs.get_definition(building_id)
    if not def.get("unlocked_by_default", false):
      if building_id not in unlocked_buildings:
        result.append(building_id)
  return result

func get_discoverable_buildings() -> Array:
  var result = []
  var lockable = get_lockable_buildings()
  for building_id in lockable:
    var def = BuildingDefs.get_definition(building_id)
    var condition = def.get("unlock_condition", {})
    if not condition.has("event_reward"):
      result.append(building_id)
  return result

func trigger_all_habits() -> void:
  for building in game_state.active_buildings:
    building.trigger_habit()

func is_connected_to_road(coord: Vector2i) -> bool:
  var neighbors = grid.get_neighbors(coord)
  for neighbor in neighbors:
    var occupant = grid.get_occupant(neighbor)
    if occupant and occupant.is_road():
      return true
  return false

func _update_nearby_connections(coord: Vector2i, size: Vector2i) -> void:
  for x in range(-2, size.x + 2):
    for y in range(-2, size.y + 2):
      var check = coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant.has_method("_update_connection"):
          occupant._update_connection()
          if occupant.has_method("_update_connection_visual"):
            occupant._update_connection_visual()
