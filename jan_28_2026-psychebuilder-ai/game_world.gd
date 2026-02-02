extends Node2D

const GridSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/grid_system.gd")
const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")

@onready var config: Node = get_node("/root/Config")

var grid: Node  # GridSystem
var hover_coord: Vector2i = Vector2i(-1, -1)

@export_group("Camera")
@export var camera_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.25
@export var max_zoom: float = 2.0

@export_group("Grid Overlay")
@export var show_grid_lines: bool = true
@export var grid_line_color: Color = Color(0.25, 0.22, 0.3, 0.5)
@export var grid_line_width: float = 1.0

@export_group("Hover Indicator")
@export var hover_valid_color: Color = Color(0.3, 1, 0.3, 0.4)
@export var hover_invalid_color: Color = Color(1, 0.3, 0.3, 0.4)
@export var hover_selected_color: Color = Color(0.5, 0.5, 1, 0.4)

@onready var camera: Camera2D = %Camera
@onready var grid_overlay: Node2D = %GridOverlay
@onready var hover_indicator: ColorRect = %HoverIndicator
@onready var background: ColorRect = $Background
@onready var buildings_layer: Node2D = %BuildingsLayer
@onready var resources_layer: Node2D = %ResourcesLayer
@onready var workers_layer: Node2D = %WorkersLayer

var is_dragging: bool = false
var drag_start_mouse: Vector2
var drag_start_camera: Vector2

# Placement mode
var placement_mode: bool = false
var placement_building_id: String = ""
var placement_size: Vector2i = Vector2i(1, 1)

func setup(p_grid_size: Vector2i, p_tile_size: int) -> void:
  grid = GridSystemScript.new(p_grid_size, p_tile_size)
  _setup_background()
  _draw_grid_lines()
  _center_camera()

func _setup_background() -> void:
  var world_size = Vector2(grid.grid_size) * grid.tile_size
  background.size = world_size

func _draw_grid_lines() -> void:
  if not show_grid_lines:
    return

  var world_size = Vector2(grid.grid_size) * grid.tile_size

  for x in range(grid.grid_size.x + 1):
    var line = Line2D.new()
    line.width = grid_line_width
    line.default_color = grid_line_color
    line.add_point(Vector2(x * grid.tile_size, 0))
    line.add_point(Vector2(x * grid.tile_size, world_size.y))
    grid_overlay.add_child(line)

  for y in range(grid.grid_size.y + 1):
    var line = Line2D.new()
    line.width = grid_line_width
    line.default_color = grid_line_color
    line.add_point(Vector2(0, y * grid.tile_size))
    line.add_point(Vector2(world_size.x, y * grid.tile_size))
    grid_overlay.add_child(line)

func _center_camera() -> void:
  var center = grid.grid_to_world(grid.grid_size / 2)
  camera.position = center

func _process(delta: float) -> void:
  _handle_camera_input(delta)
  _update_hover()

func _handle_camera_input(delta: float) -> void:
  var move_dir = Vector2.ZERO
  if Input.is_action_pressed("camera_left"):
    move_dir.x -= 1
  if Input.is_action_pressed("camera_right"):
    move_dir.x += 1
  if Input.is_action_pressed("camera_up"):
    move_dir.y -= 1
  if Input.is_action_pressed("camera_down"):
    move_dir.y += 1

  if move_dir != Vector2.ZERO:
    camera.position += move_dir.normalized() * camera_speed * delta / camera.zoom.x

  _clamp_camera()

func _clamp_camera() -> void:
  var world_size = Vector2(grid.grid_size) * grid.tile_size
  var half_view = get_viewport_rect().size / (2.0 * camera.zoom)
  camera.position.x = clampf(camera.position.x, half_view.x, world_size.x - half_view.x)
  camera.position.y = clampf(camera.position.y, half_view.y, world_size.y - half_view.y)

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    var mb = event as InputEventMouseButton
    if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
      _zoom_camera(zoom_speed)
    elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      _zoom_camera(-zoom_speed)
    elif mb.button_index == MOUSE_BUTTON_MIDDLE:
      if mb.pressed:
        is_dragging = true
        drag_start_mouse = mb.position
        drag_start_camera = camera.position
      else:
        is_dragging = false

  if event is InputEventMouseMotion and is_dragging:
    var mm = event as InputEventMouseMotion
    var delta = (drag_start_mouse - mm.position) / camera.zoom
    camera.position = drag_start_camera + delta
    _clamp_camera()

func _zoom_camera(amount: float) -> void:
  var new_zoom = clampf(camera.zoom.x + amount, min_zoom, max_zoom)
  camera.zoom = Vector2(new_zoom, new_zoom)
  _clamp_camera()

func _update_hover() -> void:
  var mouse_world = get_global_mouse_position()
  var new_coord = grid.world_to_grid(mouse_world)

  if new_coord != hover_coord:
    hover_coord = new_coord
    _update_hover_indicator()

func _update_hover_indicator() -> void:
  if not grid or not grid.is_valid_coord(hover_coord):
    hover_indicator.visible = false
    return

  hover_indicator.visible = true
  hover_indicator.position = grid.grid_to_world_top_left(hover_coord)

  var ts = grid.tile_size
  hover_indicator.size = Vector2(placement_size) * ts

  if placement_mode:
    var can_place = grid.is_area_free(hover_coord, placement_size)
    hover_indicator.color = hover_valid_color if can_place else hover_invalid_color
  else:
    hover_indicator.size = Vector2(ts, ts)
    hover_indicator.color = hover_selected_color if grid.is_occupied(hover_coord) else hover_valid_color

func set_placement_mode(enabled: bool, building_id: String = "") -> void:
  placement_mode = enabled
  placement_building_id = building_id

  if enabled and building_id != "":
    var def = BuildingDefs.get_definition(building_id)
    placement_size = def.get("size", Vector2i(1, 1))
  else:
    placement_size = Vector2i(1, 1)

  _update_hover_indicator()

func get_grid() -> Node:
  return grid

func get_buildings_layer() -> Node2D:
  return buildings_layer

func get_resources_layer() -> Node2D:
  return resources_layer

func get_workers_layer() -> Node2D:
  return workers_layer
