extends Node2D

enum State { IDLE, MOVING_TO_PICKUP, PICKING_UP, CARRYING, MOVING_TO_DROPOFF, DROPPING_OFF }

var state: State = State.IDLE
var current_path: Array[Vector2i] = []
var path_index: int = 0
var grid: RefCounted  # GridSystem

# Job info
var job_type: String = ""  # "transport", "operate"
var source_building: Node = null
var dest_building: Node = null
var resource_type: String = ""
var carried_amount: int = 0

# Movement
@export var move_speed: float = 100.0
var target_position: Vector2

# Habituation tracking
var job_id: String = ""
var completions: int = 0

# Visual
@onready var sprite: Sprite2D = $Sprite2D

static var mote_texture: ImageTexture

func _ready() -> void:
  if not mote_texture:
    mote_texture = _create_mote_texture()
  sprite.texture = mote_texture
  modulate = Color(1, 0.95, 0.7, 1)

static func _create_mote_texture() -> ImageTexture:
  var size = 24
  var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
  var center = Vector2(size / 2.0, size / 2.0)
  var radius = size / 2.0 - 2

  for x in range(size):
    for y in range(size):
      var dist = Vector2(x, y).distance_to(center)
      if dist <= radius:
        var alpha = 1.0 - (dist / radius) * 0.5
        var brightness = 1.0 - (dist / radius) * 0.3
        image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
      else:
        image.set_pixel(x, y, Color(0, 0, 0, 0))

  return ImageTexture.create_from_image(image)

func setup(p_grid: RefCounted) -> void:
  grid = p_grid

func assign_transport_job(p_source: Node, p_dest: Node, p_resource_type: String) -> bool:
  if not grid:
    return false

  source_building = p_source
  dest_building = p_dest
  resource_type = p_resource_type
  job_type = "transport"
  job_id = "transport_%s_%s_%s" % [p_source.building_id, p_dest.building_id, p_resource_type]

  state = State.MOVING_TO_PICKUP
  _pathfind_to_building(source_building)

  return current_path.size() > 0

func assign_operate_job(building: Node) -> bool:
  if not grid:
    return false

  dest_building = building
  job_type = "operate"
  job_id = "operate_%s" % building.building_id

  state = State.MOVING_TO_DROPOFF
  _pathfind_to_building(building)

  if current_path.size() > 0:
    return true

  # Already adjacent to building
  _arrive_at_operate()
  return true

func _pathfind_to_building(building: Node) -> void:
  var building_coord = building.grid_coord
  var my_coord = grid.world_to_grid(position)

  # Find adjacent road tile to building
  var adjacent_roads: Array[Vector2i] = []
  var building_size = building.size

  for x in range(-1, building_size.x + 1):
    for y in range(-1, building_size.y + 1):
      if x >= 0 and x < building_size.x and y >= 0 and y < building_size.y:
        continue  # Skip building tiles themselves
      var check = building_coord + Vector2i(x, y)
      if grid.is_valid_coord(check) and grid.is_road_at(check):
        adjacent_roads.append(check)

  if adjacent_roads.is_empty():
    current_path = []
    return

  # Find path to nearest adjacent road
  var best_path: Array[Vector2i] = []
  var best_length = INF

  for target in adjacent_roads:
    var path = grid.find_path(my_coord, target, func(coord): return grid.is_road_at(coord))
    if path.size() > 0 and path.size() < best_length:
      best_length = path.size()
      best_path = path

  current_path = best_path
  path_index = 0

  if current_path.size() > 0:
    target_position = grid.grid_to_world(current_path[0])

func _process(delta: float) -> void:
  match state:
    State.IDLE:
      pass
    State.MOVING_TO_PICKUP, State.MOVING_TO_DROPOFF:
      _process_movement(delta)
    State.PICKING_UP:
      _process_pickup()
    State.DROPPING_OFF:
      _process_dropoff()
    State.CARRYING:
      _process_movement(delta)

func _process_movement(delta: float) -> void:
  if current_path.is_empty():
    _arrive_at_destination()
    return

  var move_dir = (target_position - position).normalized()
  var distance = position.distance_to(target_position)
  var move_amount = move_speed * delta

  if move_amount >= distance:
    position = target_position
    path_index += 1

    if path_index >= current_path.size():
      _arrive_at_destination()
    else:
      target_position = grid.grid_to_world(current_path[path_index])
  else:
    position += move_dir * move_amount

func _arrive_at_destination() -> void:
  current_path = []
  path_index = 0

  match state:
    State.MOVING_TO_PICKUP:
      state = State.PICKING_UP
    State.MOVING_TO_DROPOFF:
      if job_type == "transport":
        state = State.DROPPING_OFF
      else:
        _arrive_at_operate()
    State.CARRYING:
      state = State.DROPPING_OFF

func _process_pickup() -> void:
  if not source_building or resource_type == "":
    state = State.IDLE
    return

  var available = source_building.get_storage_amount(resource_type)
  if available > 0:
    carried_amount = source_building.remove_from_storage(resource_type, mini(available, 5))
    state = State.CARRYING
    _pathfind_to_building(dest_building)

    # Visual feedback
    modulate = Color(1.2, 1.1, 0.8, 1)
  else:
    # Wait for resources
    pass

func _process_dropoff() -> void:
  if not dest_building:
    state = State.IDLE
    return

  if carried_amount > 0:
    var overflow = dest_building.add_to_storage(resource_type, carried_amount)
    carried_amount = overflow

  if carried_amount == 0:
    modulate = Color(1, 0.95, 0.7, 1)
    completions += 1

    # Loop back to pickup
    state = State.MOVING_TO_PICKUP
    _pathfind_to_building(source_building)

func _arrive_at_operate() -> void:
  if dest_building:
    dest_building.assign_worker(self)
  state = State.IDLE

func unassign() -> void:
  if dest_building and job_type == "operate":
    dest_building.unassign_worker()
  job_type = ""
  source_building = null
  dest_building = null
  resource_type = ""
  carried_amount = 0
  state = State.IDLE
  current_path = []

func get_job_id() -> String:
  return job_id

func get_completions() -> int:
  return completions
