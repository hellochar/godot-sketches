extends Control

const GRID_SIZE := 7
const CELL_SIZE := 60.0
const GRID_OFFSET := Vector2(200, 50)

enum BuildingType { NONE, EXTRACTOR, GENERATOR, RADIATOR, HEAT_SINK }
enum ResourceType { FUEL, POWER, HEAT }

class Building:
  var type: BuildingType
  var pos: Vector2i
  var heat_buildup: int = 0
  var heat_capacity: int = 0
  var shutdown: bool = false

  func _init(t: BuildingType, p: Vector2i):
    type = t
    pos = p
    if t == BuildingType.RADIATOR:
      heat_capacity = 2
    elif t == BuildingType.HEAT_SINK:
      heat_capacity = 4

class Pipe:
  var from: Vector2i
  var to: Vector2i
  var resource: ResourceType

  func _init(f: Vector2i, t: Vector2i, r: ResourceType):
    from = f
    to = t
    resource = r

var grid: Array = []
var pipes: Array[Pipe] = []
var outports: Array[Vector2i] = [
  Vector2i(3, 0),
  Vector2i(0, 3),
  Vector2i(6, 3),
]

var selected_building: BuildingType = BuildingType.NONE
var hovered_cell: Vector2i = Vector2i(-1, -1)
var drawing_pipe: bool = false
var pipe_start: Vector2i = Vector2i(-1, -1)
var pipe_resource: ResourceType = ResourceType.FUEL

var simulating: bool = false
var tick_timer: float = 0.0
const TICK_INTERVAL := 0.5
var total_score: int = 0

var pipes_from: Dictionary = {}
var pipes_to: Dictionary = {}

var feedback_message: String = ""
var feedback_timer: float = 0.0
var needs_redraw: bool = true

const BUILDING_COLORS := {
  BuildingType.EXTRACTOR: Color.YELLOW,
  BuildingType.GENERATOR: Color.ORANGE,
  BuildingType.RADIATOR: Color.DEEP_SKY_BLUE,
  BuildingType.HEAT_SINK: Color.SLATE_BLUE,
}

const RESOURCE_COLORS := {
  ResourceType.FUEL: Color.YELLOW,
  ResourceType.POWER: Color.LIME_GREEN,
  ResourceType.HEAT: Color.ORANGE_RED,
}

func _ready() -> void:
  for x in range(GRID_SIZE):
    var column := []
    for y in range(GRID_SIZE):
      column.append(null)
    grid.append(column)

func _process(delta: float) -> void:
  var mouse_pos := get_local_mouse_position()
  var grid_pos := pixel_to_grid(mouse_pos)
  var old_hovered := hovered_cell
  if is_valid_cell(grid_pos):
    hovered_cell = grid_pos
  else:
    hovered_cell = Vector2i(-1, -1)

  if old_hovered != hovered_cell:
    needs_redraw = true

  if simulating:
    tick_timer += delta
    if tick_timer >= TICK_INTERVAL:
      tick_timer = 0.0
      simulate_tick()
      needs_redraw = true

  if feedback_timer > 0:
    feedback_timer -= delta
    if feedback_timer <= 0:
      feedback_message = ""
      needs_redraw = true

  if needs_redraw or drawing_pipe:
    queue_redraw()
    needs_redraw = false

func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    var mb := event as InputEventMouseButton
    if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
      if hovered_cell != Vector2i(-1, -1):
        if selected_building != BuildingType.NONE:
          try_place_building(hovered_cell, selected_building)
        elif has_building_or_outport(hovered_cell):
          pipe_start = hovered_cell
          drawing_pipe = true
    elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
      if drawing_pipe and hovered_cell != Vector2i(-1, -1) and hovered_cell != pipe_start:
        try_place_pipe(pipe_start, hovered_cell)
      drawing_pipe = false
      pipe_start = Vector2i(-1, -1)
      needs_redraw = true
    elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
      if hovered_cell != Vector2i(-1, -1):
        remove_at(hovered_cell)

  if event is InputEventKey and event.pressed:
    var key := event as InputEventKey
    match key.keycode:
      KEY_1: selected_building = BuildingType.EXTRACTOR
      KEY_2: selected_building = BuildingType.GENERATOR
      KEY_3: selected_building = BuildingType.RADIATOR
      KEY_4: selected_building = BuildingType.HEAT_SINK
      KEY_ESCAPE: selected_building = BuildingType.NONE
      KEY_SPACE: simulating = not simulating
      KEY_F: pipe_resource = ResourceType.FUEL
      KEY_P: pipe_resource = ResourceType.POWER
      KEY_H: pipe_resource = ResourceType.HEAT
      KEY_R: reset_simulation()
    needs_redraw = true

func show_feedback(msg: String) -> void:
  feedback_message = msg
  feedback_timer = 2.0
  needs_redraw = true

func pixel_to_grid(pixel: Vector2) -> Vector2i:
  var rel := pixel - GRID_OFFSET
  var gx := int(rel.x / CELL_SIZE)
  var gy := int(rel.y / CELL_SIZE)
  return Vector2i(gx, gy)

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
  return GRID_OFFSET + Vector2(grid_pos) * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)

func is_valid_cell(pos: Vector2i) -> bool:
  return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func is_edge_cell(pos: Vector2i) -> bool:
  return pos.x == 0 or pos.x == GRID_SIZE - 1 or pos.y == 0 or pos.y == GRID_SIZE - 1

func is_outport(pos: Vector2i) -> bool:
  return pos in outports

func has_building_or_outport(pos: Vector2i) -> bool:
  if is_outport(pos):
    return true
  return grid[pos.x][pos.y] != null

func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
  var diff := (a - b).abs()
  return (diff.x == 1 and diff.y == 0) or (diff.x == 0 and diff.y == 1)

func can_place_building(pos: Vector2i, type: BuildingType) -> bool:
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
  return false

func try_place_building(pos: Vector2i, type: BuildingType) -> void:
  if can_place_building(pos, type):
    grid[pos.x][pos.y] = Building.new(type, pos)
    needs_redraw = true
  else:
    if is_outport(pos):
      show_feedback("Cannot build on outport")
    elif grid[pos.x][pos.y] != null:
      show_feedback("Cell occupied")
    elif is_edge_cell(pos) and type in [BuildingType.GENERATOR, BuildingType.HEAT_SINK]:
      show_feedback("Generator/Heat Sink: interior only")
    elif not is_edge_cell(pos) and type in [BuildingType.EXTRACTOR, BuildingType.RADIATOR]:
      show_feedback("Extractor/Radiator: edge only")

func can_place_pipe(from: Vector2i, to: Vector2i) -> bool:
  if not is_valid_cell(from) or not is_valid_cell(to):
    return false
  if from == to:
    return false
  if not is_adjacent(from, to):
    return false
  if not has_building_or_outport(from):
    return false
  if not has_building_or_outport(to):
    return false

  for existing in pipes:
    if existing.from == from and existing.to == to and existing.resource == pipe_resource:
      return false
  return true

func try_place_pipe(from: Vector2i, to: Vector2i) -> void:
  if can_place_pipe(from, to):
    var pipe := Pipe.new(from, to, pipe_resource)
    pipes.append(pipe)
    rebuild_pipe_indices()
    needs_redraw = true
  else:
    if not is_adjacent(from, to):
      show_feedback("Pipes must connect adjacent cells")
    elif not has_building_or_outport(from) or not has_building_or_outport(to):
      show_feedback("Pipes need buildings at both ends")
    else:
      show_feedback("Pipe already exists")

func rebuild_pipe_indices() -> void:
  pipes_from.clear()
  pipes_to.clear()
  for pipe in pipes:
    var key_from := "%d,%d" % [pipe.from.x, pipe.from.y]
    var key_to := "%d,%d" % [pipe.to.x, pipe.to.y]
    if not pipes_from.has(key_from):
      pipes_from[key_from] = []
    if not pipes_to.has(key_to):
      pipes_to[key_to] = []
    pipes_from[key_from].append(pipe)
    pipes_to[key_to].append(pipe)

func get_pipes_from(pos: Vector2i) -> Array:
  var key := "%d,%d" % [pos.x, pos.y]
  return pipes_from.get(key, [])

func get_pipes_to(pos: Vector2i) -> Array:
  var key := "%d,%d" % [pos.x, pos.y]
  return pipes_to.get(key, [])

func remove_at(pos: Vector2i) -> void:
  if not is_outport(pos) and grid[pos.x][pos.y] != null:
    grid[pos.x][pos.y] = null
    pipes = pipes.filter(func(p): return p.from != pos and p.to != pos)
    rebuild_pipe_indices()
    needs_redraw = true
  elif not is_outport(pos):
    var old_count := pipes.size()
    pipes = pipes.filter(func(p): return not (p.from == pos or p.to == pos))
    if pipes.size() != old_count:
      rebuild_pipe_indices()
      needs_redraw = true

func reset_simulation() -> void:
  simulating = false
  tick_timer = 0.0
  total_score = 0
  for x in range(GRID_SIZE):
    for y in range(GRID_SIZE):
      var b: Building = grid[x][y]
      if b != null:
        b.heat_buildup = 0
        b.shutdown = false
        if b.type == BuildingType.RADIATOR:
          b.heat_capacity = 2
        elif b.type == BuildingType.HEAT_SINK:
          b.heat_capacity = 4
  needs_redraw = true

func find_path(start: Vector2i, resource: ResourceType, target_types: Array) -> Array:
  var visited := {}
  var queue := [start]
  var paths := {start: [start]}

  while queue.size() > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]

    if visited.has(key):
      continue
    visited[key] = true

    if current != start:
      if is_outport(current) and target_types.has("OUTPORT"):
        return paths[current]
      var b: Building = grid[current.x][current.y]
      if b != null and target_types.has(b.type):
        return paths[current]

    for pipe in get_pipes_from(current):
      if pipe.resource == resource:
        var next: Vector2i = pipe.to
        var next_key := "%d,%d" % [next.x, next.y]
        if not visited.has(next_key):
          queue.append(next)
          paths[next] = paths[current] + [next]

  return []

func simulate_tick() -> void:
  var fuel_available := {}
  var power_produced := {}
  var heat_produced := {}

  for x in range(GRID_SIZE):
    for y in range(GRID_SIZE):
      var b: Building = grid[x][y]
      if b == null or b.shutdown:
        continue
      if b.type == BuildingType.EXTRACTOR:
        fuel_available[b.pos] = 1

  for x in range(GRID_SIZE):
    for y in range(GRID_SIZE):
      var b: Building = grid[x][y]
      if b == null or b.shutdown:
        continue

      if b.type == BuildingType.GENERATOR:
        var path := find_path_to_fuel(b.pos)
        if path.size() > 0:
          var source: Vector2i = path[0]
          if fuel_available.has(source) and fuel_available[source] > 0:
            fuel_available[source] -= 1
            power_produced[b.pos] = 2
            heat_produced[b.pos] = 1

  for x in range(GRID_SIZE):
    for y in range(GRID_SIZE):
      var b: Building = grid[x][y]
      if b == null or b.shutdown:
        continue

      if b.type == BuildingType.GENERATOR and heat_produced.has(b.pos):
        var heat_amount: int = heat_produced[b.pos]
        var heat_routed := route_heat(b.pos, heat_amount)

        if not heat_routed:
          b.heat_buildup += heat_amount
          if b.heat_buildup >= 3:
            b.shutdown = true
            show_feedback("Generator overheated!")
        else:
          b.heat_buildup = max(0, b.heat_buildup - 1)

  for outport in outports:
    var incoming := find_power_sources(outport)
    for source in incoming:
      if power_produced.has(source):
        total_score += power_produced[source]
        power_produced[source] = 0

func find_path_to_fuel(generator_pos: Vector2i) -> Array:
  var visited := {}
  var queue := [generator_pos]

  while queue.size() > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]

    if visited.has(key):
      continue
    visited[key] = true

    if current != generator_pos:
      var b: Building = grid[current.x][current.y]
      if b != null and b.type == BuildingType.EXTRACTOR and not b.shutdown:
        return [current]

    for pipe in get_pipes_to(current):
      if pipe.resource == ResourceType.FUEL:
        var prev: Vector2i = pipe.from
        var prev_key := "%d,%d" % [prev.x, prev.y]
        if not visited.has(prev_key):
          queue.append(prev)

  return []

func find_power_sources(outport: Vector2i) -> Array:
  var sources := []
  var visited := {}
  var queue := [outport]

  while queue.size() > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]

    if visited.has(key):
      continue
    visited[key] = true

    for pipe in get_pipes_to(current):
      if pipe.resource == ResourceType.POWER:
        var prev: Vector2i = pipe.from
        var b: Building = grid[prev.x][prev.y]
        if b != null and b.type == BuildingType.GENERATOR and not b.shutdown:
          sources.append(prev)
        else:
          var prev_key := "%d,%d" % [prev.x, prev.y]
          if not visited.has(prev_key):
            queue.append(prev)

  return sources

func route_heat(generator_pos: Vector2i, heat_amount: int) -> bool:
  var visited := {}
  var queue := [generator_pos]

  while queue.size() > 0 and heat_amount > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]

    if visited.has(key):
      continue
    visited[key] = true

    if current != generator_pos:
      var b: Building = grid[current.x][current.y]
      if b != null and b.type in [BuildingType.RADIATOR, BuildingType.HEAT_SINK]:
        if b.heat_capacity > 0:
          var absorbed := mini(heat_amount, b.heat_capacity)
          b.heat_capacity -= absorbed
          heat_amount -= absorbed
          if heat_amount <= 0:
            return true

    for pipe in get_pipes_from(current):
      if pipe.resource == ResourceType.HEAT:
        var next: Vector2i = pipe.to
        var next_key := "%d,%d" % [next.x, next.y]
        if not visited.has(next_key):
          queue.append(next)

  return heat_amount <= 0

func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.15))

  for x in range(GRID_SIZE + 1):
    var start := GRID_OFFSET + Vector2(x * CELL_SIZE, 0)
    var end := GRID_OFFSET + Vector2(x * CELL_SIZE, GRID_SIZE * CELL_SIZE)
    draw_line(start, end, Color(0.3, 0.3, 0.35), 1.0)

  for y in range(GRID_SIZE + 1):
    var start := GRID_OFFSET + Vector2(0, y * CELL_SIZE)
    var end := GRID_OFFSET + Vector2(GRID_SIZE * CELL_SIZE, y * CELL_SIZE)
    draw_line(start, end, Color(0.3, 0.3, 0.35), 1.0)

  for outport in outports:
    var center := grid_to_pixel(outport)
    var points := PackedVector2Array([
      center + Vector2(0, -20),
      center + Vector2(20, 0),
      center + Vector2(0, 20),
      center + Vector2(-20, 0),
    ])
    draw_colored_polygon(points, Color.LIME_GREEN)
    draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)

  for pipe in pipes:
    var from_pos := grid_to_pixel(pipe.from)
    var to_pos := grid_to_pixel(pipe.to)
    var color: Color = RESOURCE_COLORS[pipe.resource]
    draw_line(from_pos, to_pos, color, 3.0)

    var dir := (to_pos - from_pos).normalized()
    var arrow_pos := to_pos - dir * 15
    var perp := Vector2(-dir.y, dir.x) * 8
    draw_line(to_pos, arrow_pos + perp, color, 3.0)
    draw_line(to_pos, arrow_pos - perp, color, 3.0)

  for x in range(GRID_SIZE):
    for y in range(GRID_SIZE):
      var b: Building = grid[x][y]
      if b == null:
        continue

      var center := grid_to_pixel(Vector2i(x, y))
      var color: Color = BUILDING_COLORS[b.type]

      if b.shutdown:
        color = Color.DARK_GRAY
      elif b.heat_buildup > 0:
        var pulse := sin(Time.get_ticks_msec() / 200.0) * 0.3 + 0.7
        color = color.lerp(Color.RED, (b.heat_buildup / 3.0) * pulse)

      match b.type:
        BuildingType.EXTRACTOR:
          draw_circle(center, 20, color)
        BuildingType.GENERATOR:
          draw_rect(Rect2(center - Vector2(20, 20), Vector2(40, 40)), color)
          if b.heat_buildup > 0 and not b.shutdown:
            draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), str(b.heat_buildup), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
        BuildingType.RADIATOR:
          var points := PackedVector2Array([
            center + Vector2(0, -20),
            center + Vector2(20, 20),
            center + Vector2(-20, 20),
          ])
          draw_colored_polygon(points, color)
          draw_string(ThemeDB.fallback_font, center + Vector2(-5, 15), str(b.heat_capacity), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
        BuildingType.HEAT_SINK:
          draw_rect(Rect2(center - Vector2(15, 15), Vector2(30, 30)), color)
          draw_rect(Rect2(center - Vector2(10, 10), Vector2(20, 20)), color.darkened(0.3))
          draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), str(b.heat_capacity), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

  if hovered_cell != Vector2i(-1, -1) and not is_outport(hovered_cell):
    var rect_pos := GRID_OFFSET + Vector2(hovered_cell) * CELL_SIZE
    var can_place := can_place_building(hovered_cell, selected_building) if selected_building != BuildingType.NONE else false
    var hover_color := Color.GREEN if can_place else Color(0.5, 0.5, 0.5, 0.3)
    draw_rect(Rect2(rect_pos, Vector2(CELL_SIZE, CELL_SIZE)), hover_color, false, 2.0)

  if drawing_pipe and pipe_start != Vector2i(-1, -1):
    var start_pos := grid_to_pixel(pipe_start)
    var end_pos := get_local_mouse_position()
    var valid := hovered_cell != Vector2i(-1, -1) and can_place_pipe(pipe_start, hovered_cell)
    var pipe_color: Color = RESOURCE_COLORS[pipe_resource] if valid else Color.RED
    draw_line(start_pos, end_pos, pipe_color.lerp(Color.WHITE, 0.3), 2.0)

  draw_ui()

func draw_ui() -> void:
  var ui_x := 20.0
  var ui_y := 50.0
  var line_height := 25.0

  draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), "BUILDINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
  ui_y += line_height

  var building_names := {
    BuildingType.EXTRACTOR: "1: Extractor (edge)",
    BuildingType.GENERATOR: "2: Generator (interior)",
    BuildingType.RADIATOR: "3: Radiator (edge, cap:2)",
    BuildingType.HEAT_SINK: "4: Heat Sink (int, cap:4)",
  }

  for type in building_names:
    var color: Color = BUILDING_COLORS[type]
    if selected_building == type:
      color = Color.WHITE
    draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), building_names[type], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
    ui_y += line_height

  ui_y += 10
  draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), "PIPE RESOURCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
  ui_y += line_height

  var resource_names := {
    ResourceType.FUEL: "F: Fuel",
    ResourceType.POWER: "P: Power",
    ResourceType.HEAT: "H: Heat",
  }

  for res in resource_names:
    var color: Color = RESOURCE_COLORS[res]
    if pipe_resource == res:
      color = Color.WHITE
    draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), resource_names[res], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
    ui_y += line_height

  ui_y += 10
  draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), "CONTROLS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
  ui_y += line_height
  draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), "Space: " + ("Stop" if simulating else "Start"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
  ui_y += line_height
  draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), "R: Reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
  ui_y += line_height
  draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), "Esc: Deselect", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
  ui_y += line_height
  draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y), "RClick: Remove", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)

  var score_x := GRID_OFFSET.x + GRID_SIZE * CELL_SIZE + 30
  draw_string(ThemeDB.fallback_font, Vector2(score_x, 80), "SCORE: " + str(total_score), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.LIME_GREEN)

  if simulating:
    draw_string(ThemeDB.fallback_font, Vector2(score_x, 110), "RUNNING", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)

  if feedback_message != "":
    var alpha: float = minf(1.0, feedback_timer)
    draw_string(ThemeDB.fallback_font, Vector2(score_x, 150), feedback_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.3, 0.3, alpha))
