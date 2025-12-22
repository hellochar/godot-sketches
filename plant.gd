extends Sprite2D
class_name Plant

signal multiplied(new_plant: Plant)

@export var multiply_interval: float = 3.0
@export var object_layer: TileMapLayer

var multiply_timer: float = 0.0

var grid_pos: Vector2i:
  get:
    return object_layer.local_to_map(object_layer.to_local(global_position))
  set(value):
    global_position = object_layer.to_global(object_layer.map_to_local(value))

func _process(delta: float) -> void:
  multiply_timer += delta
  if multiply_timer >= multiply_interval:
    multiply_timer = 0.0
    # try_multiply()

func try_multiply() -> void:
  var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
  directions.shuffle()
  directions.pop_back()
  directions.pop_back()
  for dir in directions:
    var new_pos := grid_pos + dir
    if is_cell_empty(new_pos):
      spawn_at(new_pos)
  queue_free()

func is_cell_empty(pos: Vector2i) -> bool:
  if object_layer:
    return object_layer.get_cell_source_id(pos) == -1
  return false

func spawn_at(pos: Vector2i) -> void:
  var new_plant := duplicate() as Plant
  new_plant.object_layer = object_layer
  new_plant.grid_pos = pos
  new_plant.multiply_timer = 0.0
  get_parent().add_child(new_plant)
  multiplied.emit(new_plant)

func harvest() -> void:
  queue_free()
