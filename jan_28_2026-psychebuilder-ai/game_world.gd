extends Node2D

const GridSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/grid_system.gd")
const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")
const BackgroundShader = preload("res://jan_28_2026-psychebuilder-ai/src/shaders/mindspace_background.gdshader")
const AdjacencyRules = preload("res://jan_28_2026-psychebuilder-ai/src/data/adjacency_rules.gd")


var grid: Node  # GridSystem
var hover_coord: Vector2i = Vector2i(-1, -1)

@export_group("Camera")
@export var camera_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.25
@export var max_zoom: float = 2.0

@export_group("Grid Overlay")
@export var show_grid_lines: bool = true
@export var grid_line_color: Color = Color(0.3, 0.25, 0.4, 0.35)
@export var grid_line_width: float = 1.0

@export_group("Hover Indicator")
@export var hover_valid_color: Color = Color(0.4, 0.9, 0.5, 0.4)
@export var hover_invalid_color: Color = Color(0.9, 0.35, 0.35, 0.4)
@export var hover_selected_color: Color = Color(0.6, 0.5, 0.9, 0.4)

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
@export var aura_pulse_speed: float = 2.0
@export var aura_min_alpha: float = 0.15
@export var aura_max_alpha: float = 0.5

var aura_time: float = 0.0

@export_group("Day/Night Visuals")
@export var day_brightness: float = 1.0
@export var night_brightness: float = 0.6
@export var background_top_color: Color = Color(0.12, 0.1, 0.18, 1.0)
@export var background_bottom_color: Color = Color(0.18, 0.15, 0.25, 1.0)
@export var background_accent_color: Color = Color(0.25, 0.2, 0.35, 1.0)

var background_material: ShaderMaterial

func setup(p_grid_size: Vector2i, p_tile_size: int) -> void:
  grid = GridSystemScript.new()
  grid.setup(p_grid_size, p_tile_size)
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
  background_material = ShaderMaterial.new()
  background_material.shader = BackgroundShader
  background_material.set_shader_parameter("top_color", background_top_color)
  background_material.set_shader_parameter("bottom_color", background_bottom_color)
  background_material.set_shader_parameter("accent_color", background_accent_color)
  background_material.set_shader_parameter("day_brightness", day_brightness)
  background_material.set_shader_parameter("night_brightness", night_brightness)
  background_material.set_shader_parameter("time_of_day", 1.0)
  background.material = background_material

func set_time_of_day(progress: float) -> void:
  if background_material:
    background_material.set_shader_parameter("time_of_day", progress)

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

@export_group("Camera Focus")
@export var building_focus_padding: float = 0.2

func focus_on_buildings(buildings: Array) -> void:
  if buildings.is_empty():
    _center_camera()
    return

  var min_coord := Vector2(INF, INF)
  var max_coord := Vector2(-INF, -INF)

  for building in buildings:
    var coord = Vector2(building.grid_coord)
    var size = Vector2(building.size)
    min_coord.x = minf(min_coord.x, coord.x)
    min_coord.y = minf(min_coord.y, coord.y)
    max_coord.x = maxf(max_coord.x, coord.x + size.x)
    max_coord.y = maxf(max_coord.y, coord.y + size.y)

  var padding_tiles = (max_coord - min_coord) * building_focus_padding
  min_coord -= padding_tiles
  max_coord += padding_tiles

  var world_min = Vector2(min_coord) * grid.tile_size
  var world_max = Vector2(max_coord) * grid.tile_size
  var center = (world_min + world_max) * 0.5
  var bbox_size = world_max - world_min

  var viewport_size = get_viewport_rect().size
  var zoom_x = viewport_size.x / bbox_size.x if bbox_size.x > 0 else 1.0
  var zoom_y = viewport_size.y / bbox_size.y if bbox_size.y > 0 else 1.0
  var target_zoom = minf(zoom_x, zoom_y)
  target_zoom = clampf(target_zoom, min_zoom, max_zoom)

  camera.zoom = Vector2(target_zoom, target_zoom)
  camera.position = center
  _clamp_camera()

func _process(delta: float) -> void:
  _handle_camera_input(delta)
  _update_hover()
  aura_time += delta
  if aura_hovered_building:
    queue_redraw()

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
  if half_view.x * 2 >= world_size.x:
    camera.position.x = world_size.x / 2.0
  else:
    camera.position.x = clampf(camera.position.x, half_view.x, world_size.x - half_view.x)
  if half_view.y * 2 >= world_size.y:
    camera.position.y = world_size.y / 2.0
  else:
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
    if placement_mode:
      queue_redraw()

func _update_hover_indicator() -> void:
  if not grid or not grid.is_valid_coord(hover_coord) or not placement_mode:
    hover_indicator.visible = false
    _hide_placement_reason()
    return

  hover_indicator.visible = true
  hover_indicator.position = grid.grid_to_world_top_left(hover_coord)

  var tile_size = grid.tile_size
  hover_indicator.size = Vector2(placement_size) * tile_size

  var failure_reason = _get_placement_failure_reason()
  if failure_reason == "":
    hover_indicator.color = hover_valid_color
    _hide_placement_reason()
  else:
    hover_indicator.color = hover_invalid_color
    _show_placement_reason(failure_reason)

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
  if placement_mode and placement_building_id != "" and grid.is_valid_coord(hover_coord):
    _draw_placement_adjacency_preview()

  if not aura_hovered_building or not is_instance_valid(aura_hovered_building):
    return

  var building = aura_hovered_building
  var building_center = _get_building_center(building)
  var tile_size = Config.instance.tile_size

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

  var calm_amount = building.storage.get("calm", 0)
  var tension_amount = building.storage.get("tension", 0)
  var wisdom_amount = building.storage.get("wisdom", 0)

  if has_calm:
    var calm_radius = (Config.instance.calm_aura_radius + 0.5) * tile_size
    _draw_aura_circle(building_center, calm_radius, aura_calm_color, maxi(calm_amount, 1))

  if has_tension:
    var tension_radius = (Config.instance.tension_aura_radius + 0.5) * tile_size
    _draw_aura_circle(building_center, tension_radius, aura_tension_color, maxi(tension_amount, 1))

  if has_wisdom:
    var wisdom_radius = (Config.instance.wisdom_aura_radius + 0.5) * tile_size
    _draw_aura_circle(building_center, wisdom_radius, aura_wisdom_color, maxi(wisdom_amount, 1))

  _draw_adjacency_lines(building, building_center)

func _draw_adjacency_lines(building: Node, building_center: Vector2) -> void:
  if not building.has_method("get_adjacency_descriptions"):
    return

  var adjacency_descriptions = building.get_adjacency_descriptions()
  if adjacency_descriptions.is_empty():
    return

  var adjacent_neighbors = building.adjacent_neighbors if "adjacent_neighbors" in building else []

  for neighbor in adjacent_neighbors:
    if not is_instance_valid(neighbor):
      continue

    var neighbor_id = neighbor.building_id if "building_id" in neighbor else ""
    if neighbor_id == "":
      continue

    var neighbor_center = _get_building_center(neighbor)
    var effect_type = -1
    var description = ""

    for desc in adjacency_descriptions:
      if desc["neighbor"] == neighbor_id:
        effect_type = desc["type"]
        description = desc["description"]
        break

    if effect_type == -1:
      continue

    var line_color: Color
    match effect_type:
      0:
        line_color = Config.instance.adjacency_synergy_color
      1:
        line_color = Config.instance.adjacency_conflict_color
      _:
        line_color = Config.instance.adjacency_neutral_color

    draw_line(building_center, neighbor_center, line_color, Config.instance.adjacency_line_width)

    var mid_point = (building_center + neighbor_center) * 0.5
    if effect_type == 0:
      _draw_synergy_icon(mid_point, line_color)
    elif effect_type == 1:
      _draw_conflict_icon(mid_point, line_color)

func _draw_synergy_icon(pos: Vector2, color: Color) -> void:
  var icon_size = 8.0
  draw_line(pos + Vector2(-icon_size, 0), pos + Vector2(icon_size, 0), color, 2.0)
  draw_line(pos + Vector2(0, -icon_size), pos + Vector2(0, icon_size), color, 2.0)

func _draw_conflict_icon(pos: Vector2, color: Color) -> void:
  var icon_size = 6.0
  draw_line(pos + Vector2(-icon_size, -icon_size), pos + Vector2(icon_size, icon_size), color, 2.0)
  draw_line(pos + Vector2(-icon_size, icon_size), pos + Vector2(icon_size, -icon_size), color, 2.0)

func _get_building_center(building: Node) -> Vector2:
  var tile_size = Config.instance.tile_size
  var size = building.size
  var top_left = grid.grid_to_world_top_left(building.grid_coord)
  return top_left + Vector2(size) * tile_size * 0.5

func _draw_aura_circle(center: Vector2, radius: float, color: Color, resource_amount: int = 1) -> void:
  var pulse = 0.8 + 0.2 * sin(aura_time * aura_pulse_speed)
  var amount_alpha = lerpf(aura_min_alpha, aura_max_alpha, clampf(float(resource_amount) / 10.0, 0.0, 1.0))
  var final_alpha = color.a * pulse * amount_alpha / aura_max_alpha

  var fill_color = Color(color.r, color.g, color.b, final_alpha * 0.5)
  draw_circle(center, radius, fill_color)

  var outline_color = Color(color.r, color.g, color.b, final_alpha * 2.0)
  outline_color.a = minf(outline_color.a, 0.8)

  var points = PackedVector2Array()
  for i in range(aura_arc_points + 1):
    var angle = float(i) / float(aura_arc_points) * TAU
    points.append(center + Vector2(cos(angle), sin(angle)) * radius)
  for i in range(aura_arc_points):
    draw_line(points[i], points[i + 1], outline_color, aura_line_width)

func spawn_floating_text(world_pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
  var label = Label.new()
  label.text = text
  label.position = world_pos - Vector2(50, 10)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", 12)
  label.add_theme_color_override("font_color", color)
  label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
  label.add_theme_constant_override("outline_size", 2)
  add_child(label)

  var tween = create_tween()
  tween.set_parallel(true)
  tween.tween_property(label, "position:y", world_pos.y - 60, 2.0)
  tween.tween_property(label, "modulate:a", 0.0, 2.0).set_delay(0.5)
  tween.chain().tween_callback(label.queue_free)

func _draw_placement_adjacency_preview() -> void:
  var tile_size = Config.instance.tile_size
  var placement_def = BuildingDefs.get_definition(placement_building_id)
  var placement_center = grid.grid_to_world_top_left(hover_coord) + Vector2(placement_size) * tile_size * 0.5

  var game_state = GameState.instance
  var adjacency_radius = AdjacencyRules.ADJACENCY_RADIUS

  var net_efficiency = 1.0
  var has_effects = false

  for building in game_state.active_buildings:
    if building.building_id == "road":
      continue

    var building_coord = building.grid_coord
    var distance = max(
      absi(hover_coord.x - building_coord.x),
      absi(hover_coord.y - building_coord.y)
    )

    if distance > adjacency_radius + max(placement_size.x, placement_size.y):
      continue

    var neighbor_id = building.building_id
    var effect = AdjacencyRules.get_adjacency_effect(placement_building_id, neighbor_id)
    var reverse_effect = AdjacencyRules.get_adjacency_effect(neighbor_id, placement_building_id)

    if effect.is_empty() and reverse_effect.is_empty():
      continue

    has_effects = true
    var building_center = _get_building_center(building)

    var combined_type = AdjacencyRules.EffectType.NEUTRAL
    var combined_efficiency = 1.0

    if not effect.is_empty():
      combined_type = effect.get("type", AdjacencyRules.EffectType.NEUTRAL)
      combined_efficiency *= effect.get("efficiency", 1.0)
    if not reverse_effect.is_empty():
      var rev_type = reverse_effect.get("type", AdjacencyRules.EffectType.NEUTRAL)
      if rev_type == AdjacencyRules.EffectType.SYNERGY or combined_type == AdjacencyRules.EffectType.SYNERGY:
        combined_type = AdjacencyRules.EffectType.SYNERGY
      elif rev_type == AdjacencyRules.EffectType.CONFLICT:
        combined_type = AdjacencyRules.EffectType.CONFLICT
      combined_efficiency *= reverse_effect.get("efficiency", 1.0)

    net_efficiency *= combined_efficiency

    var line_color: Color
    match combined_type:
      AdjacencyRules.EffectType.SYNERGY:
        line_color = Config.instance.adjacency_synergy_color
      AdjacencyRules.EffectType.CONFLICT:
        line_color = Config.instance.adjacency_conflict_color
      _:
        line_color = Config.instance.adjacency_neutral_color

    draw_line(placement_center, building_center, line_color, Config.instance.adjacency_line_width)

    var mid_point = (placement_center + building_center) * 0.5
    if combined_type == AdjacencyRules.EffectType.SYNERGY:
      _draw_synergy_icon(mid_point, line_color)
    elif combined_type == AdjacencyRules.EffectType.CONFLICT:
      _draw_conflict_icon(mid_point, line_color)

  if has_effects and net_efficiency != 1.0:
    var efficiency_text = "x%.2f" % net_efficiency
    var text_pos = placement_center + Vector2(0, -tile_size - 10)
    var text_color = Color(0.3, 0.9, 0.3) if net_efficiency > 1.0 else Color(0.9, 0.5, 0.3)
    draw_string(ThemeDB.fallback_font, text_pos, efficiency_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, text_color)
