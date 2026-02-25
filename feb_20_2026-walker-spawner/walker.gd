extends Sprite2D
class_name Walker

@export var terrain: TileMapLayer
@export var forward: Vector2i = Vector2i(0, -1)
@export var lifetime: float = 30
@export var warning_duration: float = 5.0

var _is_dying: bool = false

func _ready() -> void:
  if !terrain:
    terrain = get_parent().get_node("roads") as TileMapLayer

  Utils.appear(self)
  async_loop()
  if lifetime >= 0:
    if warning_duration > 0 and lifetime > warning_duration:
      create_tween().tween_callback(_start_warning).set_delay(lifetime - warning_duration)
    create_tween().tween_callback(die).set_delay(lifetime)

func async_loop() -> void:
  # maze-walk the road tiles in terrain.
  while get_tree() and not _is_dying:
    var curr := terrain.local_to_map(terrain.to_local(global_position))

    # turn right
    # if forward is -y (0, -1)
    # right is +x (1, 0)
    
    var right := Vector2i(-forward.y, forward.x) # (0, -1) -> (1, 0) -> (0, 1), 
    var right_coord = curr + right
    var right_tile := terrain.get_cell_tile_data(right_coord)
    # print_debug("curr: ", curr, ", right_coord:", right_coord, ": ", right_tile, ". right is ", right)
    if right_tile:
      # var tween := create_tween()
      # tween.tween_property(self, "rotation_degrees", rotation_degrees + 90, 0.5)
      # await tween.finished
      await tween_move_to(right_coord)
      forward = right
      continue
    
    var forward_coord := curr + forward
    var forward_tile := terrain.get_cell_tile_data(forward_coord)
    if forward_tile:
      await tween_move_to(forward_coord)
      continue

    # turn left
    var left := Vector2i(forward.y, -forward.x)
    # var tween := create_tween()
    # tween.tween_property(self, "rotation_degrees", rotation_degrees - 90, 0.5)
    # await tween.finished
    forward = left

func tween_move_to(coord: Vector2i) -> void:
  var tween := create_tween()
  var pos := terrain.to_global(terrain.map_to_local(coord))
  tween.tween_property(self, "global_position", pos, 0.5)
  await tween.finished

func die() -> void:
  if _is_dying:
    return
  _is_dying = true
  await Utils.vanish(self).finished
  queue_free()

func _start_warning() -> void:
  Utils.pulse(self, warning_duration, 10.0, 0.3)
