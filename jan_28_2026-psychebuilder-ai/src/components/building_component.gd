class_name BuildingComponent
extends Node

var building: Node
var definition: Dictionary
var grid: Node
var _game_state: Node
var _event_bus: Node
var _config: Node

var game_state: Node:
  get:
    if not _game_state:
      _game_state = building.game_state
    return _game_state

var event_bus: Node:
  get:
    if not _event_bus:
      _event_bus = building.event_bus
    return _event_bus

var config: Node:
  get:
    if not _config:
      _config = building.config
    return _config

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
