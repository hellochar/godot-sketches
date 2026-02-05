class_name BuildingComponent
extends Node

var building: Node
var definition: Dictionary
var grid: Node

var game_state: Node:
  get:
    return GameState.instance

var event_bus: Node:
  get:
    return EventBus.instance

var config: Node:
  get:
    return Config.instance

func _init_component(p_building: Node) -> void:
  building = p_building
  definition = building.definition
  grid = building.grid

func on_initialize() -> void:
  pass

func on_process(_delta: float) -> void:
  pass

func on_processing_complete(_inputs: Dictionary, _outputs: Dictionary) -> void:
  pass

func on_output_produced(_resource_id: String, _amount: int) -> void:
  pass

func on_resource_added(_resource_id: String, _amount: int) -> void:
  pass

func get_speed_multiplier() -> float:
  return 1.0

func get_output_bonus() -> int:
  return 0

func get_storage_bonus() -> int:
  return 0

func get_generation_multiplier() -> float:
  return 1.0

func is_road_connected() -> bool:
  return building.road_connected

func get_storage_amount(resource_id: String) -> int:
  return building.get_storage_amount(resource_id)

func add_to_storage(resource_id: String, amount: int, purity: float = -1.0) -> int:
  return building.add_to_storage(resource_id, amount, purity)

func remove_from_storage(resource_id: String, amount: int) -> int:
  return building.remove_from_storage(resource_id, amount)

func output_resource(resource_id: String, amount: int, purity: float = -1.0) -> void:
  building._output_resource(resource_id, amount, purity)

func get_adjacent_buildings() -> Array[Node]:
  return building._get_adjacent_buildings()
