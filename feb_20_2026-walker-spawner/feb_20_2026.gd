extends Node

@onready var roads: TileMapLayer = %roads

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    var mouse_pos := roads.get_local_mouse_position()
    var cell := roads.local_to_map(mouse_pos)
    if event.keycode == KEY_R:
      roads.set_cells_terrain_connect([cell], 1, 0)
    elif event.keycode == KEY_Z:
      roads.set_cells_terrain_connect([cell], 1, -1)
