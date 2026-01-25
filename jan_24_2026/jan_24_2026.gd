extends Control

enum BuildingType { NONE, EXTRACTOR, GENERATOR, RADIATOR, HEAT_SINK }
enum ResourceType { FUEL, POWER, HEAT }

@export_group("Grid")
@export var grid_size: int = 7
@export var cell_size: float = 60.0
@export var grid_offset: Vector2 = Vector2(200, 50)

@export_group("Simulation")
@export var tick_interval: float = 0.5
@export var heat_shutdown_threshold: int = 3
@export var radiator_capacity: int = 2
@export var heat_sink_capacity: int = 4

@export_group("Game Feel")
@export var shake_amplitude: float = 8.0
@export var shake_duration: float = 0.3
@export var building_pop_scale: float = 1.4
@export var building_spring: float = 150.0
@export var building_damping: float = 12.0
@export var pipe_anim_speed: float = 5.0
@export var flow_dot_speed: float = 2.0
@export var smoke_spawn_interval: float = 0.1
@export var score_popup_speed: float = 40.0
@export var milestone_flash_duration: float = 0.5
@export var milestone_shake_amount: float = 0.2

class Building:
  var type: BuildingType
  var pos: Vector2i
  var heat_buildup: int = 0
  var heat_capacity: int = 0
  var shutdown: bool = false
  var scale: float = 1.0
  var scale_velocity: float = 0.0

  func _init(t: BuildingType, p: Vector2i):
    type = t
    pos = p
    scale_velocity = 0.0

class Pipe:
  var from: Vector2i
  var to: Vector2i
  var resource: ResourceType
  var anim_progress: float = 0.0

  func _init(f: Vector2i, t: Vector2i, r: ResourceType):
    from = f
    to = t
    resource = r
    anim_progress = 0.0

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
  var size: float

  func _init(p: Vector2):
    pos = p
    velocity = Vector2(randf_range(-15, 15), randf_range(-30, -15))
    life = randf_range(0.5, 1.0)
    max_life = life
    size = randf_range(4, 8)

class AbsorbParticle:
  var pos: Vector2
  var target: Vector2
  var life: float = 0.3
  var color: Color

  func _init(start: Vector2, end: Vector2, c: Color):
    pos = start
    target = end
    color = c

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
var total_score: int = 0

var pipes_from: Dictionary = {}
var pipes_to: Dictionary = {}

var feedback_message: String = ""
var feedback_timer: float = 0.0
var needs_redraw: bool = true

var screen_shake: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var score_popups: Array[ScorePopup] = []
var smoke_particles: Array[SmokeParticle] = []
var absorb_particles: Array[AbsorbParticle] = []
var sim_start_pulse: float = 0.0
var flow_anim_time: float = 0.0
var smoke_spawn_timer: float = 0.0
var active_power_pipes: Dictionary = {}
var milestone_flash: float = 0.0
var last_milestone: int = 0

@onready var extractor_label: Label = %Extractor
@onready var generator_label: Label = %Generator
@onready var radiator_label: Label = %Radiator
@onready var heat_sink_label: Label = %HeatSink
@onready var building_desc: VBoxContainer = %BuildingDesc
@onready var fuel_label: Label = %Fuel
@onready var power_label: Label = %Power
@onready var heat_label: Label = %Heat
@onready var start_stop_label: Label = %StartStop
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var prompt_label: Label = %PromptLabel
@onready var tooltip_label: Label = %TooltipLabel
@onready var resource_desc_label: Label = %ResourceDescLabel

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

const BUILDING_DESCRIPTIONS := {
  BuildingType.EXTRACTOR: ["Extractor", "Produces 1 Fuel per tick.", "Must be on edge cells."],
  BuildingType.GENERATOR: ["Generator", "Consumes 1 Fuel -> 2 Power + 1 Heat.", "Must be in interior. Shuts down if heat not routed."],
  BuildingType.RADIATOR: ["Radiator", "Absorbs 2 Heat total.", "Must be on edge cells."],
  BuildingType.HEAT_SINK: ["Heat Sink", "Absorbs 4 Heat total.", "Must be in interior."],
}

const RESOURCE_DESCRIPTIONS := {
  ResourceType.FUEL: "Fuel pipes carry fuel from Extractors to Generators.",
  ResourceType.POWER: "Power pipes carry power from Generators to Outports (green diamonds).",
  ResourceType.HEAT: "Heat pipes carry heat from Generators to Radiators/Heat Sinks.",
}

func _ready() -> void:
  for x in range(grid_size):
    var column := []
    for y in range(grid_size):
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
    flow_anim_time += delta
    if tick_timer >= tick_interval:
      tick_timer = 0.0
      simulate_tick()
    needs_redraw = true

  if feedback_timer > 0:
    feedback_timer -= delta
    if feedback_timer <= 0:
      feedback_message = ""
      needs_redraw = true

  if screen_shake > 0:
    screen_shake -= delta
    var trauma := screen_shake * screen_shake
    shake_offset = Vector2(
      randf_range(-shake_amplitude, shake_amplitude) * trauma,
      randf_range(-shake_amplitude, shake_amplitude) * trauma
    )
    needs_redraw = true
  else:
    shake_offset = Vector2.ZERO

  for popup in score_popups:
    popup.pos += popup.velocity * delta
    popup.life -= delta
  score_popups = score_popups.filter(func(p): return p.life > 0)
  if score_popups.size() > 0:
    needs_redraw = true

  if sim_start_pulse > 0:
    sim_start_pulse -= delta
    needs_redraw = true

  if milestone_flash > 0:
    milestone_flash -= delta
    needs_redraw = true

  for particle in smoke_particles:
    particle.pos += particle.velocity * delta
    particle.life -= delta
  smoke_particles = smoke_particles.filter(func(p): return p.life > 0)
  if smoke_particles.size() > 0:
    needs_redraw = true

  for particle in absorb_particles:
    var t := 1.0 - (particle.life / 0.3)
    particle.pos = particle.pos.lerp(particle.target, t * 0.15)
    particle.life -= delta
  absorb_particles = absorb_particles.filter(func(p): return p.life > 0)
  if absorb_particles.size() > 0:
    needs_redraw = true

  smoke_spawn_timer -= delta
  if smoke_spawn_timer <= 0 and simulating:
    smoke_spawn_timer = smoke_spawn_interval
    for x in range(grid_size):
      for y in range(grid_size):
        var b: Building = grid[x][y]
        if b != null and b.type == BuildingType.GENERATOR and b.heat_buildup > 0 and not b.shutdown:
          var center := grid_to_pixel(Vector2i(x, y), false)
          smoke_particles.append(SmokeParticle.new(center + Vector2(randf_range(-10, 10), -15)))

  for x in range(grid_size):
    for y in range(grid_size):
      var b: Building = grid[x][y]
      if b != null and b.scale != 1.0:
        var spring := building_spring
        var damping := building_damping
        var diff := 1.0 - b.scale
        b.scale_velocity += diff * spring * delta
        b.scale_velocity *= exp(-damping * delta)
        b.scale += b.scale_velocity * delta
        if absf(b.scale - 1.0) < 0.01 and absf(b.scale_velocity) < 0.1:
          b.scale = 1.0
          b.scale_velocity = 0.0
        needs_redraw = true

  for pipe in pipes:
    if pipe.anim_progress < 1.0:
      pipe.anim_progress = minf(1.0, pipe.anim_progress + delta * pipe_anim_speed)
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
      KEY_SPACE:
        simulating = not simulating
        if simulating:
          sim_start_pulse = 0.4
      KEY_F: pipe_resource = ResourceType.FUEL
      KEY_P: pipe_resource = ResourceType.POWER
      KEY_H: pipe_resource = ResourceType.HEAT
      KEY_R: reset_simulation()
    needs_redraw = true

func show_feedback(msg: String) -> void:
  feedback_message = msg
  feedback_timer = 2.0
  needs_redraw = true

func get_contextual_prompt() -> String:
  if selected_building != BuildingType.NONE:
    var building_name: String = BUILDING_DESCRIPTIONS[selected_building][0]
    return "Click a highlighted cell to place " + building_name + ". Press Esc to cancel."
  if drawing_pipe:
    return "Drag to an adjacent building to connect."
  if not simulating:
    var has_extractor := false
    var has_generator := false
    for x in range(grid_size):
      for y in range(grid_size):
        var b: Building = grid[x][y]
        if b != null:
          if b.type == BuildingType.EXTRACTOR:
            has_extractor = true
          if b.type == BuildingType.GENERATOR:
            has_generator = true
    if not has_extractor:
      return "Press 1 to select Extractor, then click an edge cell."
    if not has_generator:
      return "Press 2 to select Generator, then click an interior cell."
    if pipes.size() == 0:
      return "Click and drag from a building to connect with pipes."
    return "Press Space to start simulation."
  return ""

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

func get_hover_tooltip() -> String:
  if hovered_cell == Vector2i(-1, -1):
    return ""
  if is_outport(hovered_cell):
    return "Outport: Deliver Power here to score points."
  var b: Building = grid[hovered_cell.x][hovered_cell.y]
  if b != null:
    var desc: Array = BUILDING_DESCRIPTIONS[b.type]
    var status := ""
    if b.shutdown:
      status = " [SHUTDOWN]"
    elif b.type == BuildingType.GENERATOR and b.heat_buildup > 0:
      status = " [Heat: %d/%d]" % [b.heat_buildup, heat_shutdown_threshold]
    elif b.type in [BuildingType.RADIATOR, BuildingType.HEAT_SINK]:
      status = " [Capacity: %d]" % b.heat_capacity
    return desc[0] + status + " - " + desc[1]
  return ""

func add_screen_shake(amount: float) -> void:
  screen_shake = maxf(screen_shake, amount)

func spawn_score_popup(grid_pos: Vector2i, amount: int) -> void:
  var pixel_pos := grid_to_pixel(grid_pos, false)
  var popup := ScorePopup.new(pixel_pos, "+" + str(amount))
  popup.velocity = Vector2(0, -score_popup_speed)
  score_popups.append(popup)

func spawn_absorb_particles(grid_pos: Vector2i, count: int) -> void:
  var center := grid_to_pixel(grid_pos, false)
  var b: Building = grid[grid_pos.x][grid_pos.y]
  var particle_color := Color.DEEP_SKY_BLUE if b.type == BuildingType.RADIATOR else Color.SLATE_BLUE
  for i in range(count * 3):
    var angle := randf() * TAU
    var dist := randf_range(25, 40)
    var start := center + Vector2(cos(angle), sin(angle)) * dist
    absorb_particles.append(AbsorbParticle.new(start, center, particle_color))

func pixel_to_grid(pixel: Vector2) -> Vector2i:
  var rel := pixel - grid_offset
  var gx := int(rel.x / cell_size)
  var gy := int(rel.y / cell_size)
  return Vector2i(gx, gy)

func grid_to_pixel(grid_pos: Vector2i, with_shake: bool = true) -> Vector2:
  var offset := grid_offset + (shake_offset if with_shake else Vector2.ZERO)
  return offset + Vector2(grid_pos) * cell_size + Vector2(cell_size / 2, cell_size / 2)

func is_valid_cell(pos: Vector2i) -> bool:
  return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size

func is_edge_cell(pos: Vector2i) -> bool:
  return pos.x == 0 or pos.x == grid_size - 1 or pos.y == 0 or pos.y == grid_size - 1

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
    var b := Building.new(type, pos)
    b.scale = building_pop_scale
    if type == BuildingType.RADIATOR:
      b.heat_capacity = radiator_capacity
    elif type == BuildingType.HEAT_SINK:
      b.heat_capacity = heat_sink_capacity
    grid[pos.x][pos.y] = b
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
  last_milestone = 0
  for x in range(grid_size):
    for y in range(grid_size):
      var b: Building = grid[x][y]
      if b != null:
        b.heat_buildup = 0
        b.shutdown = false
        if b.type == BuildingType.RADIATOR:
          b.heat_capacity = radiator_capacity
        elif b.type == BuildingType.HEAT_SINK:
          b.heat_capacity = heat_sink_capacity
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
  active_power_pipes.clear()

  for x in range(grid_size):
    for y in range(grid_size):
      var b: Building = grid[x][y]
      if b == null or b.shutdown:
        continue
      if b.type == BuildingType.EXTRACTOR:
        fuel_available[b.pos] = 1

  for x in range(grid_size):
    for y in range(grid_size):
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

  for x in range(grid_size):
    for y in range(grid_size):
      var b: Building = grid[x][y]
      if b == null or b.shutdown:
        continue

      if b.type == BuildingType.GENERATOR and heat_produced.has(b.pos):
        var heat_amount: int = heat_produced[b.pos]
        var heat_routed := route_heat(b.pos, heat_amount)

        if not heat_routed:
          b.heat_buildup += heat_amount
          if b.heat_buildup >= heat_shutdown_threshold:
            b.shutdown = true
            show_feedback("Generator overheated!")
            add_screen_shake(shake_duration)
        else:
          b.heat_buildup = max(0, b.heat_buildup - 1)

  for outport in outports:
    var incoming := find_power_sources(outport)
    var outport_power := 0
    for source in incoming:
      if power_produced.has(source):
        outport_power += power_produced[source]
        total_score += power_produced[source]
        power_produced[source] = 0
        mark_power_path(source, outport)
    if outport_power > 0:
      spawn_score_popup(outport, outport_power)

  check_milestones()

func check_milestones() -> void:
  var milestones := [10, 25, 50, 100, 200, 500]
  for m in milestones:
    if total_score >= m and last_milestone < m:
      last_milestone = m
      milestone_flash = milestone_flash_duration
      add_screen_shake(milestone_shake_amount)
      show_feedback("Milestone: " + str(m) + " power!")
      break

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

func mark_power_path(from_pos: Vector2i, to_pos: Vector2i) -> void:
  var visited := {}
  var queue := [to_pos]
  var parent := {}

  while queue.size() > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]

    if visited.has(key):
      continue
    visited[key] = true

    if current == from_pos:
      var path_node := current
      while parent.has(path_node):
        var next_node: Vector2i = parent[path_node]
        var pipe_key := "%d,%d-%d,%d" % [path_node.x, path_node.y, next_node.x, next_node.y]
        active_power_pipes[pipe_key] = true
        path_node = next_node
      return

    for pipe in get_pipes_to(current):
      if pipe.resource == ResourceType.POWER:
        var prev: Vector2i = pipe.from
        var prev_key := "%d,%d" % [prev.x, prev.y]
        if not visited.has(prev_key):
          queue.append(prev)
          parent[prev] = current

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
          spawn_absorb_particles(current, absorbed)
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

  var offset := grid_offset + shake_offset

  for x in range(grid_size + 1):
    var start := offset + Vector2(x * cell_size, 0)
    var end := offset + Vector2(x * cell_size, grid_size * cell_size)
    draw_line(start, end, Color(0.3, 0.3, 0.35), 1.0)

  for y in range(grid_size + 1):
    var start := offset + Vector2(0, y * cell_size)
    var end := offset + Vector2(grid_size * cell_size, y * cell_size)
    draw_line(start, end, Color(0.3, 0.3, 0.35), 1.0)

  if selected_building != BuildingType.NONE:
    for x in range(grid_size):
      for y in range(grid_size):
        var pos := Vector2i(x, y)
        if can_place_building(pos, selected_building):
          var cell_pos := offset + Vector2(x, y) * cell_size
          var highlight_color := Color(0.2, 0.8, 0.2, 0.15)
          draw_rect(Rect2(cell_pos, Vector2(cell_size, cell_size)), highlight_color)

  for outport in outports:
    var center := grid_to_pixel(outport)
    var outport_scale := 1.0
    if milestone_flash > 0:
      outport_scale = 1.0 + (milestone_flash / milestone_flash_duration) * 0.3
    var points := PackedVector2Array([
      center + Vector2(0, -20 * outport_scale),
      center + Vector2(20 * outport_scale, 0),
      center + Vector2(0, 20 * outport_scale),
      center + Vector2(-20 * outport_scale, 0),
    ])
    var outport_color := Color.LIME_GREEN
    if milestone_flash > 0:
      outport_color = outport_color.lerp(Color.WHITE, milestone_flash / milestone_flash_duration)
    draw_colored_polygon(points, outport_color)
    draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)

  for pipe in pipes:
    var from_pos := grid_to_pixel(pipe.from)
    var to_pos := grid_to_pixel(pipe.to)
    var color: Color = RESOURCE_COLORS[pipe.resource]
    var pipe_key := "%d,%d-%d,%d" % [pipe.from.x, pipe.from.y, pipe.to.x, pipe.to.y]
    var is_active := active_power_pipes.has(pipe_key)
    if is_active:
      draw_line(from_pos, to_pos, color.lightened(0.5), 8.0)
      color = color.lightened(0.3)
    var t := pipe.anim_progress
    var eased := 1.0 - (1.0 - t) * (1.0 - t)
    var current_end := from_pos.lerp(to_pos, eased)
    draw_line(from_pos, current_end, color, 3.0)

    if t >= 1.0:
      var dir := (to_pos - from_pos).normalized()
      var arrow_pos := to_pos - dir * 15
      var perp := Vector2(-dir.y, dir.x) * 8
      draw_line(to_pos, arrow_pos + perp, color, 3.0)
      draw_line(to_pos, arrow_pos - perp, color, 3.0)

      if simulating:
        var flow_speed := flow_dot_speed
        var dot_spacing := 0.33
        for i in range(3):
          var dot_t := fmod(flow_anim_time * flow_speed + i * dot_spacing, 1.0)
          var dot_pos := from_pos.lerp(to_pos, dot_t)
          draw_circle(dot_pos, 4, color.lightened(0.3))

  for x in range(grid_size):
    for y in range(grid_size):
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

      if sim_start_pulse > 0:
        var pulse_t := sim_start_pulse / 0.4
        color = color.lerp(Color.WHITE, pulse_t * 0.5)

      var s := b.scale
      match b.type:
        BuildingType.EXTRACTOR:
          draw_circle(center, 20 * s, color)
          if simulating and not b.shutdown:
            var pump := sin(flow_anim_time * 6.0) * 0.3 + 0.7
            var inner_radius := 10 * s * pump
            draw_circle(center, inner_radius, color.darkened(0.3))
        BuildingType.GENERATOR:
          var half := 20 * s
          draw_rect(Rect2(center - Vector2(half, half), Vector2(half * 2, half * 2)), color)
          if b.heat_buildup > 0 and not b.shutdown:
            draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), str(b.heat_buildup), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
        BuildingType.RADIATOR:
          var points := PackedVector2Array([
            center + Vector2(0, -20 * s),
            center + Vector2(20 * s, 20 * s),
            center + Vector2(-20 * s, 20 * s),
          ])
          draw_colored_polygon(points, color)
          draw_string(ThemeDB.fallback_font, center + Vector2(-5, 15), str(b.heat_capacity), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
        BuildingType.HEAT_SINK:
          var outer := 15 * s
          var inner := 10 * s
          draw_rect(Rect2(center - Vector2(outer, outer), Vector2(outer * 2, outer * 2)), color)
          draw_rect(Rect2(center - Vector2(inner, inner), Vector2(inner * 2, inner * 2)), color.darkened(0.3))
          draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), str(b.heat_capacity), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

  for particle in smoke_particles:
    var alpha := particle.life / particle.max_life
    var smoke_color := Color(0.5, 0.5, 0.5, alpha * 0.6)
    draw_circle(particle.pos + shake_offset, particle.size * (1.0 + (1.0 - alpha) * 0.5), smoke_color)

  for particle in absorb_particles:
    var alpha := particle.life / 0.3
    var absorb_color := Color(particle.color.r, particle.color.g, particle.color.b, alpha)
    draw_circle(particle.pos + shake_offset, 4, absorb_color)

  if hovered_cell != Vector2i(-1, -1) and not is_outport(hovered_cell):
    var can_place := can_place_building(hovered_cell, selected_building) if selected_building != BuildingType.NONE else false
    var hover_color := Color.GREEN if can_place else Color(0.5, 0.5, 0.5, 0.3)
    if selected_building != BuildingType.NONE and not can_place:
      hover_color = Color(1.0, 0.3, 0.3, 0.5)
    var pulse := sin(Time.get_ticks_msec() / 150.0) * 0.03 + 1.0
    var hover_size := cell_size * pulse
    var hover_offset := (cell_size - hover_size) / 2.0
    var rect_pos := offset + Vector2(hovered_cell) * cell_size + Vector2(hover_offset, hover_offset)
    draw_rect(Rect2(rect_pos, Vector2(hover_size, hover_size)), hover_color, false, 2.0)

    if selected_building != BuildingType.NONE:
      if can_place:
        var ghost_center := grid_to_pixel(hovered_cell)
        var ghost_color: Color = BUILDING_COLORS[selected_building]
        ghost_color.a = 0.4
        match selected_building:
          BuildingType.EXTRACTOR:
            draw_circle(ghost_center, 20, ghost_color)
          BuildingType.GENERATOR:
            draw_rect(Rect2(ghost_center - Vector2(20, 20), Vector2(40, 40)), ghost_color)
          BuildingType.RADIATOR:
            var ghost_points := PackedVector2Array([
              ghost_center + Vector2(0, -20),
              ghost_center + Vector2(20, 20),
              ghost_center + Vector2(-20, 20),
            ])
            draw_colored_polygon(ghost_points, ghost_color)
          BuildingType.HEAT_SINK:
            draw_rect(Rect2(ghost_center - Vector2(15, 15), Vector2(30, 30)), ghost_color)
      else:
        var reason := get_placement_reason(hovered_cell, selected_building)
        if reason != "":
          var reason_pos := grid_to_pixel(hovered_cell) + Vector2(0, 35)
          draw_string(ThemeDB.fallback_font, reason_pos, reason, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 0.5, 0.5))

  if drawing_pipe and pipe_start != Vector2i(-1, -1):
    var start_pos := grid_to_pixel(pipe_start)
    var end_pos := get_local_mouse_position()
    var valid := hovered_cell != Vector2i(-1, -1) and can_place_pipe(pipe_start, hovered_cell)
    var pipe_color: Color = RESOURCE_COLORS[pipe_resource] if valid else Color.RED
    draw_line(start_pos, end_pos, pipe_color.lerp(Color.WHITE, 0.3), 2.0)

  for popup in score_popups:
    var alpha := popup.life
    var popup_color := Color(0.3, 1.0, 0.3, alpha)
    draw_string(ThemeDB.fallback_font, popup.pos + shake_offset, popup.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, popup_color)

  update_ui()

func update_ui() -> void:
  extractor_label.add_theme_color_override("font_color", Color.WHITE if selected_building == BuildingType.EXTRACTOR else BUILDING_COLORS[BuildingType.EXTRACTOR])
  generator_label.add_theme_color_override("font_color", Color.WHITE if selected_building == BuildingType.GENERATOR else BUILDING_COLORS[BuildingType.GENERATOR])
  radiator_label.add_theme_color_override("font_color", Color.WHITE if selected_building == BuildingType.RADIATOR else BUILDING_COLORS[BuildingType.RADIATOR])
  heat_sink_label.add_theme_color_override("font_color", Color.WHITE if selected_building == BuildingType.HEAT_SINK else BUILDING_COLORS[BuildingType.HEAT_SINK])

  var desc_line1: Label = building_desc.get_node("Line1")
  var desc_line2: Label = building_desc.get_node("Line2")
  if selected_building != BuildingType.NONE:
    var desc: Array = BUILDING_DESCRIPTIONS[selected_building]
    desc_line1.text = desc[1]
    desc_line2.text = desc[2]
    building_desc.visible = true
  else:
    building_desc.visible = false

  fuel_label.add_theme_color_override("font_color", Color.WHITE if pipe_resource == ResourceType.FUEL else RESOURCE_COLORS[ResourceType.FUEL])
  power_label.add_theme_color_override("font_color", Color.WHITE if pipe_resource == ResourceType.POWER else RESOURCE_COLORS[ResourceType.POWER])
  heat_label.add_theme_color_override("font_color", Color.WHITE if pipe_resource == ResourceType.HEAT else RESOURCE_COLORS[ResourceType.HEAT])

  start_stop_label.text = "Space: " + ("Stop" if simulating else "Start")

  score_label.text = "SCORE: " + str(total_score)

  status_label.text = "RUNNING" if simulating else ""

  if feedback_message != "":
    var alpha: float = minf(1.0, feedback_timer)
    feedback_label.text = feedback_message
    feedback_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, alpha))
  else:
    feedback_label.text = ""

  prompt_label.text = get_contextual_prompt()
  tooltip_label.text = get_hover_tooltip()

  if selected_building == BuildingType.NONE and not drawing_pipe:
    resource_desc_label.text = RESOURCE_DESCRIPTIONS[pipe_resource]
  else:
    resource_desc_label.text = ""
