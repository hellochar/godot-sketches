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
var building_system: Node = null
var placement_reason_label: Label = null

var aura_hovered_building: Node = null
var aura_overlay: Node2D = null

@export_group("Aura Visualization")
@export var aura_calm_color: Color = Color(0.3, 0.6, 1.0, 0.3)
@export var aura_tension_color: Color = Color(1.0, 0.3, 0.3, 0.3)
@export var aura_wisdom_color: Color = Color(0.7, 0.3, 1.0, 0.3)
@export var aura_line_width: float = 2.0
@export var aura_arc_points: int = 32

func setup(p_grid_size: Vector2i, p_tile_size: int) -> void:
  grid = GridSystemScript.new(p_grid_size, p_tile_size)
  _setup_background()
  _draw_grid_lines()
  _center_camera()
  _create_placement_reason_label()
  _create_aura_overlay()

func _create_placement_reason_label() -> void:
  placement_reason_label = Label.new()
  placement_reason_label.name = "PlacementReasonLabel"
  placement_reason_label.visible = false
  placement_reason_label.add_theme_font_size_override("font_size", 12)
  placement_reason_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
  placement_reason_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
  placement_reason_label.add_theme_constant_override("shadow_offset_x", 1)
  placement_reason_label.add_theme_constant_override("shadow_offset_y", 1)
  add_child(placement_reason_label)

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
    _hide_placement_reason()
    return

  hover_indicator.visible = true
  hover_indicator.position = grid.grid_to_world_top_left(hover_coord)

  var tile_size = grid.tile_size
  hover_indicator.size = Vector2(placement_size) * tile_size

  if placement_mode:
    var failure_reason = _get_placement_failure_reason()
    if failure_reason == "":
      hover_indicator.color = hover_valid_color
      _hide_placement_reason()
    else:
      hover_indicator.color = hover_invalid_color
      _show_placement_reason(failure_reason)
  else:
    _hide_placement_reason()
    hover_indicator.size = Vector2(tile_size, tile_size)
    if grid.is_occupied(hover_coord):
      hover_indicator.color = hover_selected_color
    else:
      hover_indicator.color = hover_valid_color

func _get_placement_failure_reason() -> String:
  if building_system and placement_building_id != "":
    return building_system.get_placement_failure_reason(placement_building_id, hover_coord)
  if not grid.is_area_free(hover_coord, placement_size):
    return "Space is occupied"
  return ""

func _show_placement_reason(reason: String) -> void:
  placement_reason_label.text = reason
  placement_reason_label.visible = true
  var indicator_pos = hover_indicator.position
  var offset = Vector2(0, -20)
  placement_reason_label.position = indicator_pos + offset

func _hide_placement_reason() -> void:
  placement_reason_label.visible = false

func set_placement_mode(enabled: bool, building_id: String = "", p_building_system: Node = null) -> void:
  placement_mode = enabled
  placement_building_id = building_id
  if p_building_system:
    building_system = p_building_system

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

func _create_aura_overlay() -> void:
  aura_overlay = Node2D.new()
  aura_overlay.name = "AuraOverlay"
  aura_overlay.z_index = 10
  add_child(aura_overlay)

func set_aura_building(building: Node) -> void:
  if aura_hovered_building != building:
    aura_hovered_building = building
    queue_redraw()

func _draw() -> void:
  if not aura_hovered_building or not is_instance_valid(aura_hovered_building):
    return

  var building = aura_hovered_building
  var building_center = _get_building_center(building)
  var tile_size = config.tile_size

  var has_calm = building.storage.get("calm", 0) > 0
  var has_tension = building.storage.get("tension", 0) > 0
  var has_wisdom = building.storage.get("wisdom", 0) > 0

  var generates = building.definition.get("generates", "")
  if generates == "calm":
    has_calm = true
  elif generates == "tension":
    has_tension = true
  elif generates == "wisdom":
    has_wisdom = true

  var output = building.definition.get("output", {})
  if output.has("calm"):
    has_calm = true
  if output.has("tension"):
    has_tension = true
  if output.has("wisdom"):
    has_wisdom = true

  if has_calm:
    var calm_radius = (config.calm_aura_radius + 0.5) * tile_size
    _draw_aura_circle(building_center, calm_radius, aura_calm_color)

  if has_tension:
    var tension_radius = (config.tension_aura_radius + 0.5) * tile_size
    _draw_aura_circle(building_center, tension_radius, aura_tension_color)

  if has_wisdom:
    var wisdom_radius = (config.wisdom_aura_radius + 0.5) * tile_size
    _draw_aura_circle(building_center, wisdom_radius, aura_wisdom_color)

func _get_building_center(building: Node) -> Vector2:
  var tile_size = config.tile_size
  var size = building.size
  var top_left = grid.grid_to_world_top_left(building.grid_coord)
  return top_left + Vector2(size) * tile_size * 0.5

func _draw_aura_circle(center: Vector2, radius: float, color: Color) -> void:
  var fill_color = Color(color.r, color.g, color.b, color.a * 0.3)
  draw_circle(center, radius, fill_color)
  var outline_color = Color(color.r, color.g, color.b, color.a * 2.0)
  outline_color.a = minf(outline_color.a, 0.8)
  var points = PackedVector2Array()
  for i in range(aura_arc_points + 1):
    var angle = float(i) / float(aura_arc_points) * TAU
    points.append(center + Vector2(cos(angle), sin(angle)) * radius)
  for i in range(aura_arc_points):
    draw_line(points[i], points[i + 1], outline_color, aura_line_width)
