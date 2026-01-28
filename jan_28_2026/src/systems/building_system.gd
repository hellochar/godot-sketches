extends Node

const BuildingScene = preload("res://jan_28_2026/src/entities/building.tscn")
const BuildingDefs = preload("res://jan_28_2026/src/data/building_definitions.gd")
const GridSystemScript = preload("res://jan_28_2026/src/systems/grid_system.gd")

var grid: RefCounted  # GridSystem
var buildings_layer: Node2D
var active_buildings: Array[Node] = []
var unlocked_buildings: Array = []

func _ready() -> void:
  unlocked_buildings = BuildingDefs.get_all_unlocked()

func setup(p_grid: RefCounted, p_buildings_layer: Node2D) -> void:
  grid = p_grid
  buildings_layer = p_buildings_layer

func can_place(building_id: String, coord: Vector2i) -> bool:
  var def = BuildingDefs.get_definition(building_id)
  if def.is_empty():
    return false

  var size = def.get("size", Vector2i(1, 1))

  # Check if area is free
  if not grid.is_area_free(coord, size):
    return false

  # Check energy cost
  var cost = def.get("build_cost", {})
  var energy_cost = cost.get("energy", 0)
  if energy_cost > get_node("/root/GameState").current_energy:
    return false

  return true

func place_building(building_id: String, coord: Vector2i) -> Node:
  if not can_place(building_id, coord):
    return null

  var def = BuildingDefs.get_definition(building_id)
  var size = def.get("size", Vector2i(1, 1))

  # Spend energy
  var cost = def.get("build_cost", {})
  var energy_cost = cost.get("energy", 0)
  if energy_cost > 0:
    get_node("/root/GameState").spend_energy(energy_cost)

  # Create building
  var building = BuildingScene.instantiate()
  building.initialize(building_id, coord)
  building.position = grid.grid_to_world_top_left(coord)

  # Add to scene
  buildings_layer.add_child(building)
  active_buildings.append(building)

  # Mark grid as occupied
  grid.occupy_area(coord, size, building)

  get_node("/root/EventBus").building_placed.emit(building, coord)

  return building

func remove_building(building: Node) -> void:
  if building not in active_buildings:
    return

  var coord = building.grid_coord
  var size = building.size

  # Clear grid
  grid.clear_area(coord, size)

  # Remove from tracking
  active_buildings.erase(building)

  get_node("/root/EventBus").building_removed.emit(building, coord)

  building.queue_free()

func get_building_at(coord: Vector2i) -> Node:
  var occupant = grid.get_occupant(coord)
  if occupant and occupant in active_buildings:
    return occupant
  return null

func get_all_buildings() -> Array[Node]:
  return active_buildings

func get_buildings_by_type(building_id: String) -> Array[Node]:
  var result: Array[Node] = []
  for building in active_buildings:
    if building.building_id == building_id:
      result.append(building)
  return result

func get_roads() -> Array[Node]:
  var result: Array[Node] = []
  for building in active_buildings:
    if building.is_road():
      result.append(building)
  return result

func is_unlocked(building_id: String) -> bool:
  return building_id in unlocked_buildings

func unlock_building(building_id: String) -> void:
  if building_id not in unlocked_buildings:
    unlocked_buildings.append(building_id)

func get_unlocked_buildings() -> Array:
  return unlocked_buildings

func trigger_all_habits() -> void:
  for building in active_buildings:
    building.trigger_habit()

func is_connected_to_road(coord: Vector2i) -> bool:
  var neighbors = grid.get_neighbors(coord)
  for neighbor in neighbors:
    var occupant = grid.get_occupant(neighbor)
    if occupant and occupant.is_road():
      return true
  return false
