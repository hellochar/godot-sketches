extends Control

const ResourceSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/resource_system.gd")
const BuildingSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/building_system.gd")
const WorkerSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/worker_system.gd")
const TimeSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/time_system.gd")

@export_group("Time")
@export var day_duration_seconds: float = 45.0
@export var night_duration_seconds: float = 10.0
@export var total_days: int = 20

@export_group("Energy")
@export var starting_energy: int = 10
@export var max_energy: int = 20
@export var energy_regen_per_day: int = 3

@export_group("Attention")
@export var base_attention_pool: int = 10
@export var habituation_thresholds: Array[int] = [5, 15, 30, 50]
@export var habituation_costs: Array[float] = [1.0, 0.5, 0.25, 0.1, 0.0]

@export_group("Wellbeing")
@export var base_wellbeing: float = 35.0
@export var positive_emotion_weight: float = 2.0
@export var derived_resource_weight: float = 3.0
@export var negative_emotion_weight: float = 1.5
@export var unprocessed_negative_weight: float = 2.0
@export var habit_building_weight: float = 1.0
@export var adjacency_synergy_weight: float = 0.5
@export var wellbeing_normalizer: float = 50.0
@export var positive_emotions: Array[String] = ["joy", "calm", "wisdom"]
@export var negative_emotions: Array[String] = ["grief", "anxiety"]

@export_group("Wellbeing Display")
@export var wellbeing_good_threshold: float = 70.0
@export var wellbeing_warning_threshold: float = 40.0
@export var wellbeing_good_color: Color = Color(0.3, 0.9, 0.3)
@export var wellbeing_warning_color: Color = Color(0.9, 0.9, 0.3)
@export var wellbeing_bad_color: Color = Color(0.9, 0.3, 0.3)

@export_group("Endings")
@export var flourishing_threshold: int = 80
@export var growing_threshold: int = 50
@export var surviving_threshold: int = 20

@export_group("Grid")
@export var grid_size: Vector2i = Vector2i(50, 50)
@export var tile_size: int = 64

@export_group("UI")
@export var building_button_size: Vector2 = Vector2(80, 40)
@export var speed_options: Array[float] = [1.0, 2.0, 3.0]

@export_group("Clock Display")
@export var day_hours: float = 16.0
@export var night_hours: float = 8.0
@export var day_start_hour: int = 6
@export var night_start_hour: int = 22

@onready var game_world = %GameWorld
@onready var ui_layer: CanvasLayer = %UILayer

@onready var energy_label: Label = %EnergyLabel
@onready var attention_label: Label = %AttentionLabel
@onready var day_label: Label = %DayLabel
@onready var wellbeing_label: Label = %WellbeingLabel
@onready var instructions_label: Label = %Instructions
@onready var phase_label: Label = %PhaseLabel
@onready var time_label: Label = %TimeLabel
@onready var end_night_btn: Button = %EndNightBtn
@onready var building_toolbar: Container = %BuildingToolbar

var resource_system: Node
var building_system: Node
var worker_system: Node
var time_system: Node

# Building placement state
var selected_building_id: String = ""
var is_placing: bool = false

# Worker assignment state
var selected_source_building: Node = null
var is_assigning_transport: bool = false
var transport_resource_type: String = ""

func _ready() -> void:
  _setup_systems()
  _setup_ui()
  get_node("/root/EventBus").game_started.emit()

func _setup_systems() -> void:
  game_world.setup(grid_size, tile_size)

  resource_system = ResourceSystemScript.new()
  add_child(resource_system)
  resource_system.set_resources_layer(game_world.get_resources_layer())

  building_system = BuildingSystemScript.new()
  add_child(building_system)
  building_system.setup(game_world.get_grid(), game_world.get_buildings_layer())

  worker_system = WorkerSystemScript.new()
  add_child(worker_system)
  worker_system.setup(game_world.get_grid(), base_attention_pool, habituation_thresholds, habituation_costs)

  time_system = TimeSystemScript.new()
  add_child(time_system)
  time_system.setup(day_duration_seconds, night_duration_seconds, total_days, energy_regen_per_day)
  time_system.phase_changed.connect(_on_phase_changed)

  get_node("/root/GameState").reset_to_defaults(starting_energy, max_energy, base_attention_pool, base_wellbeing, habituation_thresholds, habituation_costs)

func _setup_ui() -> void:
  _populate_building_toolbar()
  _connect_time_controls()

func _populate_building_toolbar() -> void:
  var unlocked = building_system.get_unlocked_buildings()
  for building_id in unlocked:
    var btn = _create_building_button(building_id)
    building_toolbar.add_child(btn)

func _create_building_button(building_id: String) -> Button:
  var BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")
  var def = BuildingDefs.get_definition(building_id)

  var btn = Button.new()
  btn.name = building_id
  btn.text = def.get("name", building_id)
  btn.custom_minimum_size = building_button_size
  btn.tooltip_text = def.get("description", "")

  var cost = def.get("build_cost", {})
  var energy = cost.get("energy", 0)
  if energy > 0:
    btn.text += "\n(" + str(energy) + "E)"

  btn.pressed.connect(_on_building_selected.bind(building_id))
  return btn

func _connect_time_controls() -> void:
  %Speed1xBtn.pressed.connect(func(): time_system.set_speed(speed_options[0]))
  %Speed2xBtn.pressed.connect(func(): time_system.set_speed(speed_options[1]))
  %Speed3xBtn.pressed.connect(func(): time_system.set_speed(speed_options[2]))
  end_night_btn.pressed.connect(func(): time_system.end_night())

func _on_building_selected(building_id: String) -> void:
  selected_building_id = building_id
  is_placing = true
  game_world.set_placement_mode(true, building_id)

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    var mb = event as InputEventMouseButton
    if mb.pressed:
      if mb.button_index == MOUSE_BUTTON_LEFT:
        if is_placing:
          _try_place_building()
        else:
          _handle_click()
      elif mb.button_index == MOUSE_BUTTON_RIGHT:
        _cancel_placement()

  if event is InputEventKey:
    var key = event as InputEventKey
    if key.pressed and key.keycode == KEY_ESCAPE:
      _cancel_placement()
    elif key.pressed and key.keycode == KEY_W:
      var coord = game_world.hover_coord
      if game_world.get_grid().is_road_at(coord):
        spawn_worker_at(coord)
        print("Spawned worker at ", coord)

func _try_place_building() -> void:
  if not is_placing or selected_building_id == "":
    return

  var coord = game_world.hover_coord
  if building_system.can_place(selected_building_id, coord):
    building_system.place_building(selected_building_id, coord)
    _update_energy_display()

    # Keep placing same building type (shift to cancel)
    if not Input.is_key_pressed(KEY_SHIFT):
      pass  # Continue placing

func _handle_click() -> void:
  var coord = game_world.hover_coord
  var building = building_system.get_building_at(coord)

  if is_assigning_transport:
    if building and building != selected_source_building:
      _complete_transport_assignment(building)
    return

  if building:
    _select_building(building)

func _select_building(building: Node) -> void:
  var def = building.definition

  var generates = def.get("generates", "")
  var output = def.get("output", {})

  var available_resources: Array = []
  if generates != "":
    available_resources.append(generates)
  for res_id in output.keys():
    if res_id not in available_resources:
      available_resources.append(res_id)
  for res_id in building.storage.keys():
    if building.storage[res_id] > 0 and res_id not in available_resources:
      available_resources.append(res_id)

  if available_resources.size() > 0:
    selected_source_building = building
    transport_resource_type = available_resources[0]
    is_assigning_transport = true
    _update_instructions("Click destination building for transport\n(%s from %s)" % [transport_resource_type, building.building_id])
  else:
    _update_instructions("Selected: %s\n(No resources to transport)" % building.building_id)

func _complete_transport_assignment(dest_building: Node) -> void:
  if not selected_source_building or not dest_building:
    _cancel_transport_assignment()
    return

  var road_coord = _find_road_near_building(selected_source_building)
  if road_coord == Vector2i(-1, -1):
    _update_instructions("No road adjacent to source building!")
    _cancel_transport_assignment()
    return

  var worker = spawn_worker_at(road_coord)
  if worker_system.assign_transport_job(worker, selected_source_building, dest_building, transport_resource_type):
    _update_instructions("Worker assigned: %s\n%s -> %s" % [transport_resource_type, selected_source_building.building_id, dest_building.building_id])
    _update_energy_display()
  else:
    _update_instructions("Not enough attention!")
    worker_system.remove_worker(worker)

  _cancel_transport_assignment()

func _find_road_near_building(building: Node) -> Vector2i:
  var grid = game_world.get_grid()
  var building_coord = building.grid_coord
  var building_size = building.size

  for x in range(-1, building_size.x + 1):
    for y in range(-1, building_size.y + 1):
      if x >= 0 and x < building_size.x and y >= 0 and y < building_size.y:
        continue
      var check = building_coord + Vector2i(x, y)
      if grid.is_valid_coord(check) and grid.is_road_at(check):
        return check
  return Vector2i(-1, -1)

func _cancel_transport_assignment() -> void:
  selected_source_building = null
  is_assigning_transport = false
  transport_resource_type = ""

func _update_instructions(text: String) -> void:
  instructions_label.text = text

func _cancel_placement() -> void:
  is_placing = false
  selected_building_id = ""
  game_world.set_placement_mode(false, "")
  _cancel_transport_assignment()
  _update_instructions("Click building to select\nClick grid to place\nRight-click to cancel")

func _update_energy_display() -> void:
  var gs = get_node("/root/GameState")
  energy_label.text = "Energy: %d/%d" % [gs.current_energy, gs.max_energy]
  if worker_system:
    attention_label.text = "Attention: %d/%d" % [worker_system.attention_used, worker_system.attention_pool]
  _calculate_wellbeing()
  var wb_color = _get_wellbeing_color(gs.wellbeing)
  wellbeing_label.text = "Wellbeing: %d" % int(gs.wellbeing)
  wellbeing_label.add_theme_color_override("font_color", wb_color)

func _calculate_wellbeing() -> void:
  var gs = get_node("/root/GameState")

  var positive_total = 0
  var negative_total = 0

  for building in gs.active_buildings:
    for res_id in building.storage:
      var amount = building.storage[res_id]
      if res_id in positive_emotions:
        positive_total += amount
      elif res_id in negative_emotions:
        negative_total += amount

  var positive_bonus = positive_total * positive_emotion_weight
  var negative_penalty = negative_total * negative_emotion_weight
  var building_bonus = gs.active_buildings.size() * habit_building_weight

  var new_wellbeing = base_wellbeing + positive_bonus - negative_penalty + building_bonus
  gs.set_wellbeing(new_wellbeing)

func _get_wellbeing_color(value: float) -> Color:
  if value >= wellbeing_good_threshold:
    return wellbeing_good_color
  elif value >= wellbeing_warning_threshold:
    return wellbeing_warning_color
  else:
    return wellbeing_bad_color

func get_resource_system() -> Node:
  return resource_system

func get_building_system() -> Node:
  return building_system

func get_worker_system() -> Node:
  return worker_system

func spawn_worker_at(coord: Vector2i) -> Node:
  var world_pos = game_world.get_grid().grid_to_world(coord)
  var worker = worker_system.spawn_worker(world_pos)
  game_world.get_workers_layer().add_child(worker)
  return worker

func _on_phase_changed(_is_day: bool) -> void:
  _update_time_display()
  _update_energy_display()

func _update_time_display() -> void:
  var phase_text = "Day" if time_system.is_day() else "Night"
  phase_label.text = "Day %d - %s Phase" % [time_system.current_day, phase_text]
  end_night_btn.visible = time_system.is_night()
  day_label.text = "Day %d" % time_system.current_day
  time_label.text = _format_clock_time(time_system.get_phase_progress(), time_system.is_day())

func _format_clock_time(progress: float, is_day: bool) -> String:
  var total_hours = day_hours if is_day else night_hours
  var start_hour = day_start_hour if is_day else night_start_hour
  var elapsed_hours = progress * total_hours
  var hour = start_hour + int(elapsed_hours)
  if hour >= 24:
    hour -= 24
  var minute = int(fmod(elapsed_hours, 1.0) * 60.0)
  var suffix = "AM" if hour < 12 else "PM"
  var display_hour = hour % 12
  if display_hour == 0:
    display_hour = 12
  return "%d:%02d %s" % [display_hour, minute, suffix]

func _process(_delta: float) -> void:
  if time_system:
    _update_time_display()
