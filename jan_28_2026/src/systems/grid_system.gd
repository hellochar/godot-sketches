extends RefCounted

var grid_size: Vector2i
var tile_size: int
var occupancy: Dictionary = {}  # Vector2i -> entity

func _init(p_grid_size: Vector2i = Vector2i(50, 50), p_tile_size: int = 64) -> void:
  grid_size = p_grid_size
  tile_size = p_tile_size

func world_to_grid(pos: Vector2) -> Vector2i:
  return Vector2i(floori(pos.x / tile_size), floori(pos.y / tile_size))

func grid_to_world(coord: Vector2i) -> Vector2:
  return Vector2(coord.x * tile_size + tile_size / 2.0, coord.y * tile_size + tile_size / 2.0)

func grid_to_world_top_left(coord: Vector2i) -> Vector2:
  return Vector2(coord.x * tile_size, coord.y * tile_size)

func is_valid_coord(coord: Vector2i) -> bool:
  return coord.x >= 0 and coord.x < grid_size.x and coord.y >= 0 and coord.y < grid_size.y

func is_occupied(coord: Vector2i) -> bool:
  return occupancy.has(coord)

func get_occupant(coord: Vector2i) -> Variant:
  return occupancy.get(coord, null)

func set_occupied(coord: Vector2i, entity: Node) -> void:
  occupancy[coord] = entity

func clear_occupied(coord: Vector2i) -> void:
  occupancy.erase(coord)

func is_area_free(coord: Vector2i, size: Vector2i) -> bool:
  for x in range(size.x):
    for y in range(size.y):
      var check_coord = coord + Vector2i(x, y)
      if not is_valid_coord(check_coord) or is_occupied(check_coord):
        return false
  return true

func occupy_area(coord: Vector2i, size: Vector2i, entity: Node) -> void:
  for x in range(size.x):
    for y in range(size.y):
      set_occupied(coord + Vector2i(x, y), entity)

func clear_area(coord: Vector2i, size: Vector2i) -> void:
  for x in range(size.x):
    for y in range(size.y):
      clear_occupied(coord + Vector2i(x, y))

func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
  var neighbors: Array[Vector2i] = []
  for offset in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
    var neighbor = coord + offset
    if is_valid_coord(neighbor):
      neighbors.append(neighbor)
  return neighbors

func get_adjacent_coords_in_radius(coord: Vector2i, radius: int) -> Array[Vector2i]:
  var result: Array[Vector2i] = []
  for x in range(-radius, radius + 1):
    for y in range(-radius, radius + 1):
      if x == 0 and y == 0:
        continue
      var check = coord + Vector2i(x, y)
      if is_valid_coord(check):
        result.append(check)
  return result
