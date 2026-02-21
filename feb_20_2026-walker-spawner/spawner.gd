extends Sprite2D

@export var terrain: TileMapLayer
@export var to_spawn: PackedScene
@export var time_between_spawns: float = 5

@onready var cooldown: float = time_between_spawns

func _ready():
  if !terrain:
    terrain = get_parent().get_node("roads") as TileMapLayer

func _process(delta: float) -> void:
  cooldown -= delta
  if cooldown <= 0:
    spawn()
    cooldown = time_between_spawns

func spawn() -> void:
  var instance = to_spawn.instantiate() as Walker
  var spawn_pos = get_spawn_pos()
  instance.global_position = terrain.to_global(terrain.map_to_local(spawn_pos))

  var curr := terrain.local_to_map(terrain.to_local(global_position))
  instance.forward = spawn_pos - curr
  get_parent().add_child(instance)

func get_spawn_pos() -> Vector2i:
  var curr := terrain.local_to_map(terrain.to_local(global_position))
  var neighbors := terrain.get_surrounding_cells(curr)
  for neighbor in neighbors:
    var tile := terrain.get_cell_tile_data(neighbor)
    if tile:
      return neighbor
  return curr
