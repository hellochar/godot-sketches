extends TileMapLayer

enum Visibility { HIDDEN, EXPLORED, VISIBLE }

@export var player: Node2D
@export var vision_range: int = 8
@export var occluder_layer: TileMapLayer

var cell_visibility: Dictionary = {}
var hidden_atlas_coords := Vector2i(8, 1)
var explored_modulate := Color(0.2, 0.2, 0.2, 1.0)

func _ready():
  z_index = 100

func _process(_delta):
  if not player or not occluder_layer:
    return
  update_visibility()

func update_visibility():
  var player_cell = local_to_map(player.global_position)

  for cell in cell_visibility:
    if cell_visibility[cell] == Visibility.VISIBLE:
      cell_visibility[cell] = Visibility.EXPLORED

  for x in range(-vision_range, vision_range + 1):
    for y in range(-vision_range, vision_range + 1):
      var offset = Vector2i(x, y)
      if offset.length() > vision_range:
        continue
      var cell = player_cell + offset
      if is_cell_visible_from_player(player_cell, cell):
        cell_visibility[cell] = Visibility.VISIBLE
      elif not cell_visibility.has(cell):
        cell_visibility[cell] = Visibility.HIDDEN

  update_fog_tiles()

func is_cell_visible_from_player(from_cell: Vector2i, to_cell: Vector2i) -> bool:
  var cells_on_line = get_cells_on_line(from_cell, to_cell)
  for i in range(cells_on_line.size() - 1):
    var cell = cells_on_line[i]
    if is_cell_occluder(cell):
      return false
  return true

func is_cell_occluder(cell: Vector2i) -> bool:
  var source_id = occluder_layer.get_cell_source_id(cell)
  if source_id == -1:
    return false
  var tile_set = occluder_layer.tile_set
  var atlas_coords = occluder_layer.get_cell_atlas_coords(cell)
  var tile_data = tile_set.get_source(source_id).get_tile_data(atlas_coords, 0)
  return tile_data.get_collision_polygons_count(0) > 0

func get_cells_on_line(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
  var cells: Array[Vector2i] = []
  var dx = abs(to_cell.x - from_cell.x)
  var dy = abs(to_cell.y - from_cell.y)
  var sx = 1 if from_cell.x < to_cell.x else -1
  var sy = 1 if from_cell.y < to_cell.y else -1
  var err = dx - dy
  var x = from_cell.x
  var y = from_cell.y

  while true:
    cells.append(Vector2i(x, y))
    if x == to_cell.x and y == to_cell.y:
      break
    var e2 = 2 * err
    if e2 > -dy:
      err -= dy
      x += sx
    if e2 < dx:
      err += dx
      y += sy

  return cells

func update_fog_tiles():
  clear()
  var source_id = 0

  for cell in cell_visibility:
    match cell_visibility[cell]:
      Visibility.HIDDEN:
        set_cell(cell, source_id, hidden_atlas_coords)
      Visibility.EXPLORED:
        set_cell(cell, source_id, hidden_atlas_coords)
        # Could use a different tile or modulate for explored
      Visibility.VISIBLE:
        pass
