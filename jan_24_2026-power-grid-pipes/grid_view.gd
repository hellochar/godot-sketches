extends Control
class_name GridView

signal cell_clicked(pos: Vector2i)
signal cell_right_clicked(pos: Vector2i)

enum BuildingType { NONE, EXTRACTOR, GENERATOR, RADIATOR, HEAT_SINK, PIPE }
enum ResourceType { FUEL, POWER, HEAT }

class GridElement:
  var pos: Vector2i
  var scale: float = 1.0
  var scale_velocity: float = 0.0

  func _init(p: Vector2i):
    pos = p

class Building extends GridElement:
  var type: BuildingType
  var heat_buildup: int = 0
  var heat_capacity: int = 0
  var shutdown: bool = false

  func _init(t: BuildingType, p: Vector2i):
    super(p)
    type = t

class Pipe extends GridElement:
  var resource: ResourceType
  var connections: Array[Vector2i] = []
  var carrying: int = 0

  func _init(p: Vector2i, r: ResourceType):
    super(p)
    resource = r

class ScorePopup:
  var pos: Vector2
  var text: String
  var life: float = 1.0
  var velocity: Vector2 = Vector2.ZERO

  func _init(p: Vector2, t: String):
    pos = p
    text = t

class SmokeParticle:
  var pos: Vector2
  var velocity: Vector2
  var life: float
  var max_life: float
  var particle_size: float

  func _init(p: Vector2):
    pos = p
    velocity = Vector2(randf_range(-15, 15), randf_range(-30, -15))
    life = randf_range(0.5, 1.0)
    max_life = life
    particle_size = randf_range(4, 8)

class AbsorbParticle:
  var pos: Vector2
  var target: Vector2
  var life: float = 0.3
  var color: Color

  func _init(start: Vector2, end: Vector2, c: Color):
    pos = start
    target = end
    color = c

@export_group("Grid")
@export var grid_size: int = 7

@export_group("Buildings")
@export var extractor_radius: float = 20.0
@export var generator_half_size: float = 20.0
@export var radiator_size: float = 20.0
@export var heat_sink_outer: float = 15.0
@export var heat_sink_inner: float = 10.0
@export var outport_radius: float = 20.0

@export_group("Building Colors")
@export var extractor_color: Color = Color.YELLOW
@export var generator_color: Color = Color.ORANGE
@export var radiator_color: Color = Color.DEEP_SKY_BLUE
@export var heat_sink_color: Color = Color.SLATE_BLUE
@export var outport_color: Color = Color.LIME_GREEN

@export_group("Resource Colors")
@export var fuel_color: Color = Color.YELLOW
@export var power_color: Color = Color.LIME_GREEN
@export var heat_color: Color = Color.ORANGE_RED

@export_group("Pipes")
@export var pipe_width: float = 6.0
@export var pipe_reach: float = 0.8
@export var pipe_dot_size: float = 4.0
@export var pipe_dot_spacing: float = 0.33
@export var pipe_dot_count: int = 3

@export_group("Game Feel")
@export var flow_dot_speed: float = 2.0
@export var milestone_flash_duration: float = 0.5

var grid: Array = []
var outports: Array[Vector2i] = [
  Vector2i(3, 0),
  Vector2i(0, 3),
  Vector2i(6, 3),
]

var selected_building: BuildingType = BuildingType.NONE
var hovered_cell: Vector2i = Vector2i(-1, -1)
var pipe_resource: ResourceType = ResourceType.FUEL

var simulating: bool = false
var active_flows: Dictionary = {}  # key: "x,y", value: Vector2i (upstream cell position)
var shake_offset: Vector2 = Vector2.ZERO
var flow_anim_time: float = 0.0
var sim_start_pulse: float = 0.0
var milestone_flash: float = 0.0

var score_popups: Array[ScorePopup] = []
var smoke_particles: Array[SmokeParticle] = []
var absorb_particles: Array[AbsorbParticle] = []

var cell_size: float:
  get:
    return minf(size.x, size.y) / grid_size

func get_building_color(type: BuildingType) -> Color:
  match type:
    BuildingType.EXTRACTOR: return extractor_color
    BuildingType.GENERATOR: return generator_color
    BuildingType.RADIATOR: return radiator_color
    BuildingType.HEAT_SINK: return heat_sink_color
  return Color.WHITE

func get_resource_color(res: ResourceType) -> Color:
  match res:
    ResourceType.FUEL: return fuel_color
    ResourceType.POWER: return power_color
    ResourceType.HEAT: return heat_color
  return Color.WHITE

func _ready() -> void:
  for x in range(grid_size):
    var column := []
    for y in range(grid_size):
      column.append(null)
    grid.append(column)

func _draw() -> void:
  draw_background()
  draw_grid_lines()
  draw_valid_placement_highlights()
  draw_outports()
  draw_grid_elements()
  draw_smoke_particles()
  draw_absorb_particles()
  draw_hover_indicator()
  draw_score_popups()

func draw_background() -> void:
  draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.15))

func draw_grid_lines() -> void:
  var offset := shake_offset
  var cs := cell_size
  for x in range(grid_size + 1):
    var start_pt := offset + Vector2(x * cs, 0)
    var end_pt := offset + Vector2(x * cs, grid_size * cs)
    draw_line(start_pt, end_pt, Color(0.3, 0.3, 0.35), 1.0)
  for y in range(grid_size + 1):
    var start_pt := offset + Vector2(0, y * cs)
    var end_pt := offset + Vector2(grid_size * cs, y * cs)
    draw_line(start_pt, end_pt, Color(0.3, 0.3, 0.35), 1.0)

func draw_valid_placement_highlights() -> void:
  if selected_building == BuildingType.NONE:
    return
  var offset := shake_offset
  var cs := cell_size
  for x in range(grid_size):
    for y in range(grid_size):
      var pos := Vector2i(x, y)
      if can_place_at(pos, selected_building):
        var cell_pos := offset + Vector2(x, y) * cs
        draw_rect(Rect2(cell_pos, Vector2(cs, cs)), Color(0.2, 0.8, 0.2, 0.15))

func draw_outports() -> void:
  for outport in outports:
    draw_outport(outport)

func draw_outport(pos: Vector2i) -> void:
  var center := grid_to_pixel(pos)
  var outport_scale := 1.0
  if milestone_flash > 0:
    outport_scale = 1.0 + (milestone_flash / milestone_flash_duration) * 0.3
  var r := outport_radius * outport_scale
  var points := PackedVector2Array([
    center + Vector2(0, -r),
    center + Vector2(r, 0),
    center + Vector2(0, r),
    center + Vector2(-r, 0),
  ])
  var draw_color := outport_color
  if milestone_flash > 0:
    draw_color = draw_color.lerp(Color.WHITE, milestone_flash / milestone_flash_duration)
  draw_colored_polygon(points, draw_color)
  draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)

func draw_grid_elements() -> void:
  for x in range(grid_size):
    for y in range(grid_size):
      var element = grid[x][y]
      if element is Pipe:
        draw_pipe_element(element, Vector2i(x, y))
  for x in range(grid_size):
    for y in range(grid_size):
      var element = grid[x][y]
      if element is Building:
        draw_building(element, Vector2i(x, y))

func draw_building(b: Building, pos: Vector2i) -> void:
  var center := grid_to_pixel(pos)
  var color: Color = get_building_color(b.type)

  if b.shutdown:
    color = Color.DARK_GRAY
  elif b.heat_buildup > 0:
    var pulse := sin(Time.get_ticks_msec() / 200.0) * 0.3 + 0.7
    color = color.lerp(Color.RED, (b.heat_buildup / 3.0) * pulse)

  if sim_start_pulse > 0:
    var pulse_t := sim_start_pulse / 0.4
    color = color.lerp(Color.WHITE, pulse_t * 0.5)

  var s := b.scale
  match b.type:
    BuildingType.EXTRACTOR:
      draw_extractor(center, s, color, b.shutdown)
    BuildingType.GENERATOR:
      draw_generator(center, s, color, b.heat_buildup, b.shutdown)
    BuildingType.RADIATOR:
      draw_radiator(center, s, color, b.heat_capacity)
    BuildingType.HEAT_SINK:
      draw_heat_sink(center, s, color, b.heat_capacity)

func draw_pipe_element(p: Pipe, pos: Vector2i) -> void:
  var center := grid_to_pixel(pos)
  var color: Color = get_resource_color(p.resource)
  var cs := cell_size
  var flow_key := "%d,%d" % [pos.x, pos.y]
  var is_active := active_flows.has(flow_key)

  if is_active:
    color = color.lightened(0.3)

  if p.connections.size() == 0:
    draw_circle(center, pipe_width, color)
  else:
    for conn in p.connections:
      var dir := Vector2(conn - pos).normalized()
      var endpoint := center + dir * (cs * pipe_reach)
      if is_active:
        draw_line(center, endpoint, color.lightened(0.3), pipe_width + 4)
      draw_line(center, endpoint, color, pipe_width)

    if simulating and is_active:
      var upstream: Vector2i = active_flows[flow_key]
      for conn in p.connections:
        if conn == upstream:
          var upstream_edge := center + Vector2(upstream - pos).normalized() * (cs * pipe_reach)
          draw_flow_dots(upstream_edge, center, color)
        else:
          var downstream_edge := center + Vector2(conn - pos).normalized() * (cs * pipe_reach)
          draw_flow_dots(center, downstream_edge, color)

  draw_circle(center, pipe_width / 2, color.lightened(0.2))

func draw_extractor(center: Vector2, s: float, color: Color, shutdown: bool) -> void:
  draw_circle(center, extractor_radius * s, color)
  if simulating and not shutdown:
    var pump := sin(flow_anim_time * 6.0) * 0.3 + 0.7
    var inner_radius := (extractor_radius * 0.5) * s * pump
    draw_circle(center, inner_radius, color.darkened(0.3))

func draw_generator(center: Vector2, s: float, color: Color, heat_buildup: int, shutdown: bool) -> void:
  var half := generator_half_size * s
  draw_rect(Rect2(center - Vector2(half, half), Vector2(half * 2, half * 2)), color)
  if heat_buildup > 0 and not shutdown:
    draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), str(heat_buildup), HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)

func draw_radiator(center: Vector2, s: float, color: Color, heat_capacity: int) -> void:
  var rs := radiator_size * s
  var points := PackedVector2Array([
    center + Vector2(0, -rs),
    center + Vector2(rs, rs),
    center + Vector2(-rs, rs),
  ])
  draw_colored_polygon(points, color)
  draw_string(ThemeDB.fallback_font, center + Vector2(-5, 15), str(heat_capacity), HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)

func draw_heat_sink(center: Vector2, s: float, color: Color, heat_capacity: int) -> void:
  var outer := heat_sink_outer * s
  var inner := heat_sink_inner * s
  draw_rect(Rect2(center - Vector2(outer, outer), Vector2(outer * 2, outer * 2)), color)
  draw_rect(Rect2(center - Vector2(inner, inner), Vector2(inner * 2, inner * 2)), color.darkened(0.3))
  draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), str(heat_capacity), HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)

func draw_flow_dots(from_pos: Vector2, to_pos: Vector2, color: Color) -> void:
  for i in range(pipe_dot_count):
    var dot_t := fmod(flow_anim_time * flow_dot_speed + i * pipe_dot_spacing, 1.0)
    var dot_pos := from_pos.lerp(to_pos, dot_t)
    draw_circle(dot_pos, pipe_dot_size, color.lightened(0.3))

func draw_smoke_particles() -> void:
  for particle in smoke_particles:
    var alpha := particle.life / particle.max_life
    var smoke_color := Color(0.5, 0.5, 0.5, alpha * 0.6)
    draw_circle(particle.pos + shake_offset, particle.particle_size * (1.0 + (1.0 - alpha) * 0.5), smoke_color)

func draw_absorb_particles() -> void:
  for particle in absorb_particles:
    var alpha := particle.life / 0.3
    var absorb_color := Color(particle.color.r, particle.color.g, particle.color.b, alpha)
    draw_circle(particle.pos + shake_offset, 4, absorb_color)

func draw_hover_indicator() -> void:
  if hovered_cell == Vector2i(-1, -1) or is_outport(hovered_cell):
    return
  var offset := shake_offset
  var cs := cell_size
  var can_place := can_place_at(hovered_cell, selected_building) if selected_building != BuildingType.NONE else false
  var hover_color := Color.GREEN if can_place else Color(0.5, 0.5, 0.5, 0.3)
  if selected_building != BuildingType.NONE and not can_place:
    hover_color = Color(1.0, 0.3, 0.3, 0.5)
  var pulse := sin(Time.get_ticks_msec() / 150.0) * 0.03 + 1.0
  var hover_size := cs * pulse
  var hover_offset := (cs - hover_size) / 2.0
  var rect_pos := offset + Vector2(hovered_cell) * cs + Vector2(hover_offset, hover_offset)
  draw_rect(Rect2(rect_pos, Vector2(hover_size, hover_size)), hover_color, false, 2.0)

  if selected_building != BuildingType.NONE:
    if can_place:
      draw_element_ghost(hovered_cell)
    else:
      draw_placement_reason(hovered_cell)

func draw_element_ghost(pos: Vector2i) -> void:
  var ghost_center := grid_to_pixel(pos)
  if selected_building == BuildingType.PIPE:
    var ghost_color: Color = get_resource_color(pipe_resource)
    ghost_color.a = 0.4
    draw_circle(ghost_center, pipe_width, ghost_color)
    for neighbor in get_adjacent_cells(pos):
      if should_connect_pipe(pos, neighbor, pipe_resource):
        var dir := Vector2(neighbor - pos).normalized()
        var endpoint := ghost_center + dir * (cell_size * pipe_reach)
        draw_line(ghost_center, endpoint, ghost_color, pipe_width)
  else:
    var ghost_color: Color = get_building_color(selected_building)
    ghost_color.a = 0.4
    match selected_building:
      BuildingType.EXTRACTOR:
        draw_circle(ghost_center, extractor_radius, ghost_color)
      BuildingType.GENERATOR:
        var half := generator_half_size
        draw_rect(Rect2(ghost_center - Vector2(half, half), Vector2(half * 2, half * 2)), ghost_color)
      BuildingType.RADIATOR:
        var ghost_points := PackedVector2Array([
          ghost_center + Vector2(0, -radiator_size),
          ghost_center + Vector2(radiator_size, radiator_size),
          ghost_center + Vector2(-radiator_size, radiator_size),
        ])
        draw_colored_polygon(ghost_points, ghost_color)
      BuildingType.HEAT_SINK:
        draw_rect(Rect2(ghost_center - Vector2(heat_sink_outer, heat_sink_outer), Vector2(heat_sink_outer * 2, heat_sink_outer * 2)), ghost_color)

func draw_placement_reason(pos: Vector2i) -> void:
  var reason := get_placement_reason(pos, selected_building)
  if reason != "":
    var reason_pos := grid_to_pixel(pos) + Vector2(0, 35)
    draw_string(ThemeDB.fallback_font, reason_pos, reason, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 0.5, 0.5))

func draw_score_popups() -> void:
  for popup in score_popups:
    var alpha := popup.life
    var popup_color := Color(0.3, 1.0, 0.3, alpha)
    draw_string(ThemeDB.fallback_font, popup.pos + shake_offset, popup.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, popup_color)

func pixel_to_grid(pixel: Vector2) -> Vector2i:
  var rel := pixel - shake_offset
  var cs := cell_size
  var gx := int(rel.x / cs)
  var gy := int(rel.y / cs)
  return Vector2i(gx, gy)

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
  var cs := cell_size
  return shake_offset + Vector2(grid_pos) * cs + Vector2(cs / 2, cs / 2)

func is_valid_cell(pos: Vector2i) -> bool:
  return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size

func is_edge_cell(pos: Vector2i) -> bool:
  return pos.x == 0 or pos.x == grid_size - 1 or pos.y == 0 or pos.y == grid_size - 1

func is_outport(pos: Vector2i) -> bool:
  return pos in outports

func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
  var diff := (a - b).abs()
  return (diff.x == 1 and diff.y == 0) or (diff.x == 0 and diff.y == 1)

func get_adjacent_cells(pos: Vector2i) -> Array[Vector2i]:
  var neighbors: Array[Vector2i] = []
  var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
  for off in offsets:
    var neighbor := pos + off
    if is_valid_cell(neighbor):
      neighbors.append(neighbor)
  return neighbors

func can_place_at(pos: Vector2i, type: BuildingType) -> bool:
  if not is_valid_cell(pos):
    return false
  if grid[pos.x][pos.y] != null:
    return false
  if is_outport(pos):
    return false
  match type:
    BuildingType.EXTRACTOR, BuildingType.RADIATOR:
      return is_edge_cell(pos)
    BuildingType.GENERATOR, BuildingType.HEAT_SINK:
      return not is_edge_cell(pos)
    BuildingType.PIPE:
      return true
  return false

func should_connect_pipe(_pipe_pos: Vector2i, neighbor_pos: Vector2i, res: ResourceType) -> bool:
  if is_outport(neighbor_pos):
    return res == ResourceType.POWER
  var neighbor = grid[neighbor_pos.x][neighbor_pos.y]
  if neighbor == null:
    return false
  if neighbor is Pipe:
    return neighbor.resource == res
  if neighbor is Building:
    match neighbor.type:
      BuildingType.EXTRACTOR:
        return res == ResourceType.FUEL
      BuildingType.GENERATOR:
        return true
      BuildingType.RADIATOR, BuildingType.HEAT_SINK:
        return res == ResourceType.HEAT
  return false

func place_pipe(pos: Vector2i) -> Pipe:
  var p := Pipe.new(pos, pipe_resource)
  grid[pos.x][pos.y] = p
  update_pipe_connections(pos)
  for neighbor in get_adjacent_cells(pos):
    var n = grid[neighbor.x][neighbor.y]
    if n is Pipe:
      update_pipe_connections(neighbor)
  return p

func update_pipe_connections(pos: Vector2i) -> void:
  var element = grid[pos.x][pos.y]
  if not element is Pipe:
    return
  var p: Pipe = element
  p.connections.clear()
  for neighbor in get_adjacent_cells(pos):
    if should_connect_pipe(pos, neighbor, p.resource):
      p.connections.append(neighbor)

func get_element_at(pos: Vector2i):
  if not is_valid_cell(pos):
    return null
  return grid[pos.x][pos.y]

func get_building_at(pos: Vector2i) -> Building:
  var element = get_element_at(pos)
  if element is Building:
    return element
  return null

func get_pipe_at(pos: Vector2i) -> Pipe:
  var element = get_element_at(pos)
  if element is Pipe:
    return element
  return null

func get_placement_reason(pos: Vector2i, type: BuildingType) -> String:
  if not is_valid_cell(pos):
    return ""
  if is_outport(pos):
    return "Cannot build on Outport"
  if grid[pos.x][pos.y] != null:
    return "Cell occupied"
  match type:
    BuildingType.EXTRACTOR, BuildingType.RADIATOR:
      if not is_edge_cell(pos):
        return "Must be on edge"
    BuildingType.GENERATOR, BuildingType.HEAT_SINK:
      if is_edge_cell(pos):
        return "Must be in interior"
  return ""
