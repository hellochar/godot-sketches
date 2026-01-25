extends Control

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
@export var smoke_spawn_interval: float = 0.1
@export var score_popup_speed: float = 40.0
@export var milestone_shake_amount: float = 0.2

@onready var grid_view: GridView = %GridView
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
  GridView.BuildingType.EXTRACTOR: Color.YELLOW,
  GridView.BuildingType.GENERATOR: Color.ORANGE,
  GridView.BuildingType.RADIATOR: Color.DEEP_SKY_BLUE,
  GridView.BuildingType.HEAT_SINK: Color.SLATE_BLUE,
}

const RESOURCE_COLORS := {
  GridView.ResourceType.FUEL: Color.YELLOW,
  GridView.ResourceType.POWER: Color.LIME_GREEN,
  GridView.ResourceType.HEAT: Color.ORANGE_RED,
}

const BUILDING_DESCRIPTIONS := {
  GridView.BuildingType.EXTRACTOR: ["Extractor", "Produces 1 Fuel per tick.", "Must be on edge cells."],
  GridView.BuildingType.GENERATOR: ["Generator", "Consumes 1 Fuel -> 2 Power + 1 Heat.", "Must be in interior. Shuts down if heat not routed."],
  GridView.BuildingType.RADIATOR: ["Radiator", "Absorbs 2 Heat total.", "Must be on edge cells."],
  GridView.BuildingType.HEAT_SINK: ["Heat Sink", "Absorbs 4 Heat total.", "Must be in interior."],
}

const RESOURCE_DESCRIPTIONS := {
  GridView.ResourceType.FUEL: "Fuel pipes carry fuel from Extractors to Generators.",
  GridView.ResourceType.POWER: "Power pipes carry power from Generators to Outports (green diamonds).",
  GridView.ResourceType.HEAT: "Heat pipes carry heat from Generators to Radiators/Heat Sinks.",
}

var simulating: bool = false
var tick_timer: float = 0.0
var total_score: int = 0

var pipes_from: Dictionary = {}
var pipes_to: Dictionary = {}

var feedback_message: String = ""
var feedback_timer: float = 0.0
var needs_redraw: bool = true

var screen_shake: float = 0.0
var smoke_spawn_timer: float = 0.0
var last_milestone: int = 0

func _process(delta: float) -> void:
  var mouse_pos := grid_view.get_local_mouse_position()
  var grid_pos := grid_view.pixel_to_grid(mouse_pos)
  var old_hovered := grid_view.hovered_cell
  if grid_view.is_valid_cell(grid_pos):
    grid_view.hovered_cell = grid_pos
  else:
    grid_view.hovered_cell = Vector2i(-1, -1)

  if old_hovered != grid_view.hovered_cell:
    needs_redraw = true

  if simulating:
    tick_timer += delta
    grid_view.flow_anim_time += delta
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
    grid_view.shake_offset = Vector2(
      randf_range(-shake_amplitude, shake_amplitude) * trauma,
      randf_range(-shake_amplitude, shake_amplitude) * trauma
    )
    needs_redraw = true
  else:
    grid_view.shake_offset = Vector2.ZERO

  for popup in grid_view.score_popups:
    popup.pos += popup.velocity * delta
    popup.life -= delta
  grid_view.score_popups = grid_view.score_popups.filter(func(p): return p.life > 0)
  if grid_view.score_popups.size() > 0:
    needs_redraw = true

  if grid_view.sim_start_pulse > 0:
    grid_view.sim_start_pulse -= delta
    needs_redraw = true

  if grid_view.milestone_flash > 0:
    grid_view.milestone_flash -= delta
    needs_redraw = true

  for particle in grid_view.smoke_particles:
    particle.pos += particle.velocity * delta
    particle.life -= delta
  grid_view.smoke_particles = grid_view.smoke_particles.filter(func(p): return p.life > 0)
  if grid_view.smoke_particles.size() > 0:
    needs_redraw = true

  for particle in grid_view.absorb_particles:
    var t := 1.0 - (particle.life / 0.3)
    particle.pos = particle.pos.lerp(particle.target, t * 0.15)
    particle.life -= delta
  grid_view.absorb_particles = grid_view.absorb_particles.filter(func(p): return p.life > 0)
  if grid_view.absorb_particles.size() > 0:
    needs_redraw = true

  smoke_spawn_timer -= delta
  if smoke_spawn_timer <= 0 and simulating:
    smoke_spawn_timer = smoke_spawn_interval
    for x in range(grid_view.grid_size):
      for y in range(grid_view.grid_size):
        var b: GridView.Building = grid_view.grid[x][y]
        if b != null and b.type == GridView.BuildingType.GENERATOR and b.heat_buildup > 0 and not b.shutdown:
          var center := grid_view.grid_to_pixel(Vector2i(x, y))
          grid_view.smoke_particles.append(GridView.SmokeParticle.new(center + Vector2(randf_range(-10, 10), -15)))

  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b: GridView.Building = grid_view.grid[x][y]
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

  for pipe in grid_view.pipes:
    if pipe.anim_progress < 1.0:
      pipe.anim_progress = minf(1.0, pipe.anim_progress + delta * pipe_anim_speed)
      needs_redraw = true

  if needs_redraw or grid_view.drawing_pipe:
    grid_view.queue_redraw()
    needs_redraw = false

  update_ui()

func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    var mb := event as InputEventMouseButton
    if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
      if grid_view.hovered_cell != Vector2i(-1, -1):
        if grid_view.selected_building != GridView.BuildingType.NONE:
          try_place_building(grid_view.hovered_cell, grid_view.selected_building)
        elif grid_view.has_building_or_outport(grid_view.hovered_cell):
          grid_view.pipe_start = grid_view.hovered_cell
          grid_view.drawing_pipe = true
    elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
      if grid_view.drawing_pipe and grid_view.hovered_cell != Vector2i(-1, -1) and grid_view.hovered_cell != grid_view.pipe_start:
        try_place_pipe(grid_view.pipe_start, grid_view.hovered_cell)
      grid_view.drawing_pipe = false
      grid_view.pipe_start = Vector2i(-1, -1)
      needs_redraw = true
    elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
      if grid_view.hovered_cell != Vector2i(-1, -1):
        remove_at(grid_view.hovered_cell)

  if event is InputEventKey and event.pressed:
    var key := event as InputEventKey
    match key.keycode:
      KEY_1: grid_view.selected_building = GridView.BuildingType.EXTRACTOR
      KEY_2: grid_view.selected_building = GridView.BuildingType.GENERATOR
      KEY_3: grid_view.selected_building = GridView.BuildingType.RADIATOR
      KEY_4: grid_view.selected_building = GridView.BuildingType.HEAT_SINK
      KEY_ESCAPE: grid_view.selected_building = GridView.BuildingType.NONE
      KEY_SPACE:
        simulating = not simulating
        grid_view.simulating = simulating
        if simulating:
          grid_view.sim_start_pulse = 0.4
      KEY_F: grid_view.pipe_resource = GridView.ResourceType.FUEL
      KEY_P: grid_view.pipe_resource = GridView.ResourceType.POWER
      KEY_H: grid_view.pipe_resource = GridView.ResourceType.HEAT
      KEY_R: reset_simulation()
    needs_redraw = true

func show_feedback(msg: String) -> void:
  feedback_message = msg
  feedback_timer = 2.0
  needs_redraw = true

func get_contextual_prompt() -> String:
  if grid_view.selected_building != GridView.BuildingType.NONE:
    var building_name: String = BUILDING_DESCRIPTIONS[grid_view.selected_building][0]
    return "Click a highlighted cell to place " + building_name + ". Press Esc to cancel."
  if grid_view.drawing_pipe:
    return "Drag to an adjacent building to connect."
  if not simulating:
    var has_extractor := false
    var has_generator := false
    for x in range(grid_view.grid_size):
      for y in range(grid_view.grid_size):
        var b: GridView.Building = grid_view.grid[x][y]
        if b != null:
          if b.type == GridView.BuildingType.EXTRACTOR:
            has_extractor = true
          if b.type == GridView.BuildingType.GENERATOR:
            has_generator = true
    if not has_extractor:
      return "Press 1 to select Extractor, then click an edge cell."
    if not has_generator:
      return "Press 2 to select Generator, then click an interior cell."
    if grid_view.pipes.size() == 0:
      return "Click and drag from a building to connect with pipes."
    return "Press Space to start simulation."
  return ""

func get_hover_tooltip() -> String:
  if grid_view.hovered_cell == Vector2i(-1, -1):
    return ""
  if grid_view.is_outport(grid_view.hovered_cell):
    return "Outport: Deliver Power here to score points."
  var b: GridView.Building = grid_view.grid[grid_view.hovered_cell.x][grid_view.hovered_cell.y]
  if b != null:
    var desc: Array = BUILDING_DESCRIPTIONS[b.type]
    var status := ""
    if b.shutdown:
      status = " [SHUTDOWN]"
    elif b.type == GridView.BuildingType.GENERATOR and b.heat_buildup > 0:
      status = " [Heat: %d/%d]" % [b.heat_buildup, heat_shutdown_threshold]
    elif b.type in [GridView.BuildingType.RADIATOR, GridView.BuildingType.HEAT_SINK]:
      status = " [Capacity: %d]" % b.heat_capacity
    return desc[0] + status + " - " + desc[1]
  return ""

func add_screen_shake(amount: float) -> void:
  screen_shake = maxf(screen_shake, amount)

func spawn_score_popup(grid_pos: Vector2i, amount: int) -> void:
  var pixel_pos := grid_view.grid_to_pixel(grid_pos)
  var popup := GridView.ScorePopup.new(pixel_pos, "+" + str(amount))
  popup.velocity = Vector2(0, -score_popup_speed)
  grid_view.score_popups.append(popup)

func spawn_absorb_particles(grid_pos: Vector2i, count: int) -> void:
  var center := grid_view.grid_to_pixel(grid_pos)
  var b: GridView.Building = grid_view.grid[grid_pos.x][grid_pos.y]
  var particle_color := Color.DEEP_SKY_BLUE if b.type == GridView.BuildingType.RADIATOR else Color.SLATE_BLUE
  for i in range(count * 3):
    var angle := randf() * TAU
    var dist := randf_range(25, 40)
    var start := center + Vector2(cos(angle), sin(angle)) * dist
    grid_view.absorb_particles.append(GridView.AbsorbParticle.new(start, center, particle_color))

func try_place_building(pos: Vector2i, type: GridView.BuildingType) -> void:
  if grid_view.can_place_building(pos, type):
    var b := GridView.Building.new(type, pos)
    b.scale = building_pop_scale
    if type == GridView.BuildingType.RADIATOR:
      b.heat_capacity = radiator_capacity
    elif type == GridView.BuildingType.HEAT_SINK:
      b.heat_capacity = heat_sink_capacity
    grid_view.grid[pos.x][pos.y] = b
    needs_redraw = true
  else:
    if grid_view.is_outport(pos):
      show_feedback("Cannot build on outport")
    elif grid_view.grid[pos.x][pos.y] != null:
      show_feedback("Cell occupied")
    elif grid_view.is_edge_cell(pos) and type in [GridView.BuildingType.GENERATOR, GridView.BuildingType.HEAT_SINK]:
      show_feedback("Generator/Heat Sink: interior only")
    elif not grid_view.is_edge_cell(pos) and type in [GridView.BuildingType.EXTRACTOR, GridView.BuildingType.RADIATOR]:
      show_feedback("Extractor/Radiator: edge only")

func try_place_pipe(from: Vector2i, to: Vector2i) -> void:
  if grid_view.can_place_pipe(from, to):
    var pipe := GridView.Pipe.new(from, to, grid_view.pipe_resource)
    grid_view.pipes.append(pipe)
    rebuild_pipe_indices()
    needs_redraw = true
  else:
    if not grid_view.is_adjacent(from, to):
      show_feedback("Pipes must connect adjacent cells")
    elif not grid_view.has_building_or_outport(from) or not grid_view.has_building_or_outport(to):
      show_feedback("Pipes need buildings at both ends")
    else:
      show_feedback("Pipe already exists")

func rebuild_pipe_indices() -> void:
  pipes_from.clear()
  pipes_to.clear()
  for pipe in grid_view.pipes:
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
  if not grid_view.is_outport(pos) and grid_view.grid[pos.x][pos.y] != null:
    grid_view.grid[pos.x][pos.y] = null
    grid_view.pipes = grid_view.pipes.filter(func(p): return p.from != pos and p.to != pos)
    rebuild_pipe_indices()
    needs_redraw = true
  elif not grid_view.is_outport(pos):
    var old_count := grid_view.pipes.size()
    grid_view.pipes = grid_view.pipes.filter(func(p): return not (p.from == pos or p.to == pos))
    if grid_view.pipes.size() != old_count:
      rebuild_pipe_indices()
      needs_redraw = true

func reset_simulation() -> void:
  simulating = false
  grid_view.simulating = false
  tick_timer = 0.0
  total_score = 0
  last_milestone = 0
  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b: GridView.Building = grid_view.grid[x][y]
      if b != null:
        b.heat_buildup = 0
        b.shutdown = false
        if b.type == GridView.BuildingType.RADIATOR:
          b.heat_capacity = radiator_capacity
        elif b.type == GridView.BuildingType.HEAT_SINK:
          b.heat_capacity = heat_sink_capacity
  needs_redraw = true

func simulate_tick() -> void:
  var fuel_available := {}
  var power_produced := {}
  var heat_produced := {}
  grid_view.active_power_pipes.clear()

  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b: GridView.Building = grid_view.grid[x][y]
      if b == null or b.shutdown:
        continue
      if b.type == GridView.BuildingType.EXTRACTOR:
        fuel_available[b.pos] = 1

  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b: GridView.Building = grid_view.grid[x][y]
      if b == null or b.shutdown:
        continue

      if b.type == GridView.BuildingType.GENERATOR:
        var path := find_path_to_fuel(b.pos)
        if path.size() > 0:
          var source: Vector2i = path[0]
          if fuel_available.has(source) and fuel_available[source] > 0:
            fuel_available[source] -= 1
            power_produced[b.pos] = 2
            heat_produced[b.pos] = 1

  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b: GridView.Building = grid_view.grid[x][y]
      if b == null or b.shutdown:
        continue

      if b.type == GridView.BuildingType.GENERATOR and heat_produced.has(b.pos):
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

  for outport in grid_view.outports:
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
      grid_view.milestone_flash = grid_view.milestone_flash_duration
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
      var b: GridView.Building = grid_view.grid[current.x][current.y]
      if b != null and b.type == GridView.BuildingType.EXTRACTOR and not b.shutdown:
        return [current]

    for pipe in get_pipes_to(current):
      if pipe.resource == GridView.ResourceType.FUEL:
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
        grid_view.active_power_pipes[pipe_key] = true
        path_node = next_node
      return

    for pipe in get_pipes_to(current):
      if pipe.resource == GridView.ResourceType.POWER:
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
      if pipe.resource == GridView.ResourceType.POWER:
        var prev: Vector2i = pipe.from
        var b: GridView.Building = grid_view.grid[prev.x][prev.y]
        if b != null and b.type == GridView.BuildingType.GENERATOR and not b.shutdown:
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
      var b: GridView.Building = grid_view.grid[current.x][current.y]
      if b != null and b.type in [GridView.BuildingType.RADIATOR, GridView.BuildingType.HEAT_SINK]:
        if b.heat_capacity > 0:
          var absorbed := mini(heat_amount, b.heat_capacity)
          b.heat_capacity -= absorbed
          heat_amount -= absorbed
          spawn_absorb_particles(current, absorbed)
          if heat_amount <= 0:
            return true

    for pipe in get_pipes_from(current):
      if pipe.resource == GridView.ResourceType.HEAT:
        var next: Vector2i = pipe.to
        var next_key := "%d,%d" % [next.x, next.y]
        if not visited.has(next_key):
          queue.append(next)

  return heat_amount <= 0

func update_ui() -> void:
  extractor_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.EXTRACTOR else BUILDING_COLORS[GridView.BuildingType.EXTRACTOR])
  generator_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.GENERATOR else BUILDING_COLORS[GridView.BuildingType.GENERATOR])
  radiator_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.RADIATOR else BUILDING_COLORS[GridView.BuildingType.RADIATOR])
  heat_sink_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.HEAT_SINK else BUILDING_COLORS[GridView.BuildingType.HEAT_SINK])

  var desc_line1: Label = building_desc.get_node("Line1")
  var desc_line2: Label = building_desc.get_node("Line2")
  if grid_view.selected_building != GridView.BuildingType.NONE:
    var desc: Array = BUILDING_DESCRIPTIONS[grid_view.selected_building]
    desc_line1.text = desc[1]
    desc_line2.text = desc[2]
    building_desc.visible = true
  else:
    building_desc.visible = false

  fuel_label.add_theme_color_override("font_color", Color.WHITE if grid_view.pipe_resource == GridView.ResourceType.FUEL else RESOURCE_COLORS[GridView.ResourceType.FUEL])
  power_label.add_theme_color_override("font_color", Color.WHITE if grid_view.pipe_resource == GridView.ResourceType.POWER else RESOURCE_COLORS[GridView.ResourceType.POWER])
  heat_label.add_theme_color_override("font_color", Color.WHITE if grid_view.pipe_resource == GridView.ResourceType.HEAT else RESOURCE_COLORS[GridView.ResourceType.HEAT])

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

  if grid_view.selected_building == GridView.BuildingType.NONE and not grid_view.drawing_pipe:
    resource_desc_label.text = RESOURCE_DESCRIPTIONS[grid_view.pipe_resource]
  else:
    resource_desc_label.text = ""
