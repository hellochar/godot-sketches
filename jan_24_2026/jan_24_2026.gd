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
@export var smoke_spawn_interval: float = 0.1
@export var score_popup_speed: float = 40.0
@export var milestone_shake_amount: float = 0.2

@onready var grid_view: GridView = %GridView
@onready var extractor_label: Label = %Extractor
@onready var generator_label: Label = %Generator
@onready var radiator_label: Label = %Radiator
@onready var heat_sink_label: Label = %HeatSink
@onready var pipe_label: Label = %Pipe
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
  GridView.BuildingType.PIPE: Color.GRAY,
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
  GridView.BuildingType.PIPE: ["Pipe", "Carries resources between buildings.", "Place anywhere. Auto-connects to adjacent pipes."],
}

const RESOURCE_DESCRIPTIONS := {
  GridView.ResourceType.FUEL: "Fuel pipes carry fuel from Extractors to Generators.",
  GridView.ResourceType.POWER: "Power pipes carry power from Generators to Outports (green diamonds).",
  GridView.ResourceType.HEAT: "Heat pipes carry heat from Generators to Radiators/Heat Sinks.",
}

var simulating: bool = false
var tick_timer: float = 0.0
var total_score: int = 0

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
        var b: GridView.Building = grid_view.get_building_at(Vector2i(x, y))
        if b != null and b.type == GridView.BuildingType.GENERATOR and b.heat_buildup > 0 and not b.shutdown:
          var center := grid_view.grid_to_pixel(Vector2i(x, y))
          grid_view.smoke_particles.append(GridView.SmokeParticle.new(center + Vector2(randf_range(-10, 10), -15)))

  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var element = grid_view.grid[x][y]
      if element != null and element.scale != 1.0:
        var spring := building_spring
        var damping := building_damping
        var diff: float = 1.0 - element.scale
        element.scale_velocity += diff * spring * delta
        element.scale_velocity *= exp(-damping * delta)
        element.scale += element.scale_velocity * delta
        if absf(element.scale - 1.0) < 0.01 and absf(element.scale_velocity) < 0.1:
          element.scale = 1.0
          element.scale_velocity = 0.0
        needs_redraw = true

  if needs_redraw:
    grid_view.queue_redraw()
    needs_redraw = false

  update_ui()

func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    var mb := event as InputEventMouseButton
    if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
      if grid_view.hovered_cell != Vector2i(-1, -1):
        if grid_view.selected_building != GridView.BuildingType.NONE:
          try_place_element(grid_view.hovered_cell, grid_view.selected_building)
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
      KEY_5: grid_view.selected_building = GridView.BuildingType.PIPE
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
    if grid_view.selected_building == GridView.BuildingType.PIPE:
      return "Click to place " + building_name + " (" + get_resource_name() + "). Press Esc to cancel."
    return "Click a highlighted cell to place " + building_name + ". Press Esc to cancel."
  if not simulating:
    var has_extractor := false
    var has_generator := false
    var has_pipes := false
    for x in range(grid_view.grid_size):
      for y in range(grid_view.grid_size):
        var element = grid_view.grid[x][y]
        if element is GridView.Building:
          if element.type == GridView.BuildingType.EXTRACTOR:
            has_extractor = true
          if element.type == GridView.BuildingType.GENERATOR:
            has_generator = true
        if element is GridView.Pipe:
          has_pipes = true
    if not has_extractor:
      return "Press 1 to select Extractor, then click an edge cell."
    if not has_generator:
      return "Press 2 to select Generator, then click an interior cell."
    if not has_pipes:
      return "Press 5 to select Pipe, then click to connect buildings."
    return "Press Space to start simulation."
  return ""

func get_resource_name() -> String:
  match grid_view.pipe_resource:
    GridView.ResourceType.FUEL: return "Fuel"
    GridView.ResourceType.POWER: return "Power"
    GridView.ResourceType.HEAT: return "Heat"
  return ""

func get_hover_tooltip() -> String:
  if grid_view.hovered_cell == Vector2i(-1, -1):
    return ""
  if grid_view.is_outport(grid_view.hovered_cell):
    return "Outport: Deliver Power here to score points."
  var element = grid_view.grid[grid_view.hovered_cell.x][grid_view.hovered_cell.y]
  if element is GridView.Building:
    var b: GridView.Building = element
    var desc: Array = BUILDING_DESCRIPTIONS[b.type]
    var status := ""
    if b.shutdown:
      status = " [SHUTDOWN]"
    elif b.type == GridView.BuildingType.GENERATOR and b.heat_buildup > 0:
      status = " [Heat: %d/%d]" % [b.heat_buildup, heat_shutdown_threshold]
    elif b.type in [GridView.BuildingType.RADIATOR, GridView.BuildingType.HEAT_SINK]:
      status = " [Capacity: %d]" % b.heat_capacity
    return desc[0] + status + " - " + desc[1]
  if element is GridView.Pipe:
    var p: GridView.Pipe = element
    var res_name := get_resource_name_for(p.resource)
    return "Pipe (" + res_name + ") - Connections: " + str(p.connections.size())
  return ""

func get_resource_name_for(res: GridView.ResourceType) -> String:
  match res:
    GridView.ResourceType.FUEL: return "Fuel"
    GridView.ResourceType.POWER: return "Power"
    GridView.ResourceType.HEAT: return "Heat"
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
  var b: GridView.Building = grid_view.get_building_at(grid_pos)
  var particle_color := Color.DEEP_SKY_BLUE if b.type == GridView.BuildingType.RADIATOR else Color.SLATE_BLUE
  for i in range(count * 3):
    var angle := randf() * TAU
    var dist := randf_range(25, 40)
    var start := center + Vector2(cos(angle), sin(angle)) * dist
    grid_view.absorb_particles.append(GridView.AbsorbParticle.new(start, center, particle_color))

func try_place_element(pos: Vector2i, type: GridView.BuildingType) -> void:
  if not grid_view.can_place_at(pos, type):
    if grid_view.is_outport(pos):
      show_feedback("Cannot build on outport")
    elif grid_view.grid[pos.x][pos.y] != null:
      show_feedback("Cell occupied")
    elif grid_view.is_edge_cell(pos) and type in [GridView.BuildingType.GENERATOR, GridView.BuildingType.HEAT_SINK]:
      show_feedback("Generator/Heat Sink: interior only")
    elif not grid_view.is_edge_cell(pos) and type in [GridView.BuildingType.EXTRACTOR, GridView.BuildingType.RADIATOR]:
      show_feedback("Extractor/Radiator: edge only")
    return

  if type == GridView.BuildingType.PIPE:
    var p := grid_view.place_pipe(pos)
    p.scale = building_pop_scale
  else:
    var b := GridView.Building.new(type, pos)
    b.scale = building_pop_scale
    if type == GridView.BuildingType.RADIATOR:
      b.heat_capacity = radiator_capacity
    elif type == GridView.BuildingType.HEAT_SINK:
      b.heat_capacity = heat_sink_capacity
    grid_view.grid[pos.x][pos.y] = b
    update_adjacent_pipe_connections(pos)
  needs_redraw = true

func update_adjacent_pipe_connections(pos: Vector2i) -> void:
  for neighbor in grid_view.get_adjacent_cells(pos):
    var p := grid_view.get_pipe_at(neighbor)
    if p != null:
      grid_view.update_pipe_connections(neighbor)

func remove_at(pos: Vector2i) -> void:
  if grid_view.is_outport(pos):
    return
  if grid_view.grid[pos.x][pos.y] != null:
    grid_view.grid[pos.x][pos.y] = null
    update_adjacent_pipe_connections(pos)
    needs_redraw = true

func reset_simulation() -> void:
  simulating = false
  grid_view.simulating = false
  tick_timer = 0.0
  total_score = 0
  last_milestone = 0
  grid_view.active_flows.clear()
  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var element = grid_view.grid[x][y]
      if element is GridView.Building:
        var b: GridView.Building = element
        b.heat_buildup = 0
        b.shutdown = false
        if b.type == GridView.BuildingType.RADIATOR:
          b.heat_capacity = radiator_capacity
        elif b.type == GridView.BuildingType.HEAT_SINK:
          b.heat_capacity = heat_sink_capacity
      if element is GridView.Pipe:
        var p: GridView.Pipe = element
        p.carrying = 0
  needs_redraw = true

func simulate_tick() -> void:
  grid_view.active_flows.clear()

  var fuel_produced := propagate_resource(GridView.ResourceType.FUEL, GridView.BuildingType.EXTRACTOR, GridView.BuildingType.GENERATOR)
  var power_produced := propagate_resource(GridView.ResourceType.POWER, GridView.BuildingType.GENERATOR, GridView.BuildingType.NONE)
  var heat_produced := propagate_resource(GridView.ResourceType.HEAT, GridView.BuildingType.GENERATOR, GridView.BuildingType.NONE)

  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b := grid_view.get_building_at(Vector2i(x, y))
      if b == null or b.shutdown:
        continue
      if b.type == GridView.BuildingType.GENERATOR:
        var has_fuel: bool = fuel_produced.has(b.pos) and fuel_produced[b.pos] > 0
        if has_fuel:
          fuel_produced[b.pos] -= 1
          if not power_produced.has(b.pos):
            power_produced[b.pos] = 0
          power_produced[b.pos] += 2
          if not heat_produced.has(b.pos):
            heat_produced[b.pos] = 0
          heat_produced[b.pos] += 1

  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b := grid_view.get_building_at(Vector2i(x, y))
      if b == null or b.shutdown:
        continue
      if b.type == GridView.BuildingType.GENERATOR and heat_produced.has(b.pos) and heat_produced[b.pos] > 0:
        var heat_amount: int = heat_produced[b.pos]
        var heat_routed := route_heat_from(b.pos, heat_amount)
        if not heat_routed:
          b.heat_buildup += heat_amount
          if b.heat_buildup >= heat_shutdown_threshold:
            b.shutdown = true
            show_feedback("Generator overheated!")
            add_screen_shake(shake_duration)
        else:
          b.heat_buildup = max(0, b.heat_buildup - 1)

  for outport in grid_view.outports:
    var power := get_power_at_outport(outport, power_produced)
    if power > 0:
      total_score += power
      spawn_score_popup(outport, power)

  check_milestones()

func propagate_resource(res: GridView.ResourceType, source_type: GridView.BuildingType, _dest_type: GridView.BuildingType) -> Dictionary:
  var amounts := {}
  for x in range(grid_view.grid_size):
    for y in range(grid_view.grid_size):
      var b := grid_view.get_building_at(Vector2i(x, y))
      if b != null and b.type == source_type and not b.shutdown:
        amounts[b.pos] = 1
        mark_flow_path(b.pos, res)
  return amounts

func mark_flow_path(start: Vector2i, res: GridView.ResourceType) -> void:
  var visited := {}
  var queue := [start]
  while queue.size() > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]
    if visited.has(key):
      continue
    visited[key] = true
    grid_view.active_flows[key] = true
    for neighbor in grid_view.get_adjacent_cells(current):
      var p := grid_view.get_pipe_at(neighbor)
      if p != null and p.resource == res:
        queue.append(neighbor)

func get_power_at_outport(outport: Vector2i, power_produced: Dictionary) -> int:
  var total := 0
  var visited := {}
  var queue: Array[Vector2i] = []
  for neighbor in grid_view.get_adjacent_cells(outport):
    var p := grid_view.get_pipe_at(neighbor)
    if p != null and p.resource == GridView.ResourceType.POWER:
      queue.append(neighbor)
  while queue.size() > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]
    if visited.has(key):
      continue
    visited[key] = true
    var b := grid_view.get_building_at(current)
    if b != null and b.type == GridView.BuildingType.GENERATOR and not b.shutdown:
      if power_produced.has(b.pos) and power_produced[b.pos] > 0:
        total += power_produced[b.pos]
        power_produced[b.pos] = 0
      continue
    var p := grid_view.get_pipe_at(current)
    if p != null and p.resource == GridView.ResourceType.POWER:
      for conn in p.connections:
        var conn_key := "%d,%d" % [conn.x, conn.y]
        if not visited.has(conn_key):
          queue.append(conn)
  return total

func route_heat_from(generator_pos: Vector2i, heat_amount: int) -> bool:
  var visited := {}
  var queue: Array[Vector2i] = []
  for neighbor in grid_view.get_adjacent_cells(generator_pos):
    var p := grid_view.get_pipe_at(neighbor)
    if p != null and p.resource == GridView.ResourceType.HEAT:
      queue.append(neighbor)
  while queue.size() > 0 and heat_amount > 0:
    var current: Vector2i = queue.pop_front()
    var key := "%d,%d" % [current.x, current.y]
    if visited.has(key):
      continue
    visited[key] = true
    var b := grid_view.get_building_at(current)
    if b != null and b.type in [GridView.BuildingType.RADIATOR, GridView.BuildingType.HEAT_SINK]:
      if b.heat_capacity > 0:
        var absorbed := mini(heat_amount, b.heat_capacity)
        b.heat_capacity -= absorbed
        heat_amount -= absorbed
        spawn_absorb_particles(current, absorbed)
        if heat_amount <= 0:
          return true
      continue
    var p := grid_view.get_pipe_at(current)
    if p != null and p.resource == GridView.ResourceType.HEAT:
      for conn in p.connections:
        var conn_key := "%d,%d" % [conn.x, conn.y]
        if not visited.has(conn_key):
          queue.append(conn)
  return heat_amount <= 0

func check_milestones() -> void:
  var milestones := [10, 25, 50, 100, 200, 500]
  for m in milestones:
    if total_score >= m and last_milestone < m:
      last_milestone = m
      grid_view.milestone_flash = grid_view.milestone_flash_duration
      add_screen_shake(milestone_shake_amount)
      show_feedback("Milestone: " + str(m) + " power!")
      break

func update_ui() -> void:
  extractor_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.EXTRACTOR else BUILDING_COLORS[GridView.BuildingType.EXTRACTOR])
  generator_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.GENERATOR else BUILDING_COLORS[GridView.BuildingType.GENERATOR])
  radiator_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.RADIATOR else BUILDING_COLORS[GridView.BuildingType.RADIATOR])
  heat_sink_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.HEAT_SINK else BUILDING_COLORS[GridView.BuildingType.HEAT_SINK])
  var pipe_color: Color = RESOURCE_COLORS[grid_view.pipe_resource] if grid_view.selected_building == GridView.BuildingType.PIPE else Color.GRAY
  pipe_label.add_theme_color_override("font_color", Color.WHITE if grid_view.selected_building == GridView.BuildingType.PIPE else pipe_color)

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

  if grid_view.selected_building == GridView.BuildingType.NONE:
    resource_desc_label.text = RESOURCE_DESCRIPTIONS[grid_view.pipe_resource]
  else:
    resource_desc_label.text = ""
