extends Control

const ResourceSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/resource_system.gd")
const BuildingSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/building_system.gd")
const WorkerSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/worker_system.gd")
const TimeSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/time_system.gd")
const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")

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
@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")
@onready var config: Node = get_node("/root/Config")

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
var available_transport_resources: Array = []
var transport_resource_index: int = 0

# Building selection state
var selected_building: Node = null
@export_group("Building Removal")
@export var removal_refund_percent: float = 0.5

var selected_worker: Node = null
@export_group("Worker Selection")
@export var worker_click_radius: float = 16.0

var hovered_building: Node = null
var building_tooltip: PanelContainer = null
@export_group("Tooltip")
@export var tooltip_offset: Vector2 = Vector2(15, 15)
@export var tooltip_name_font_size: int = 14
@export var tooltip_desc_font_size: int = 11
@export var tooltip_desc_color: Color = Color(0.7, 0.7, 0.7)
@export var tooltip_status_font_size: int = 12
@export var tooltip_min_width: float = 220.0

@export_group("UI Toolbar")
@export var toolbar_height: float = 50.0
@export var toolbar_margin: float = 10.0
@export var toolbar_bg_color: Color = Color(0.1, 0.1, 0.15, 0.9)
@export var building_button_size: Vector2 = Vector2(80, 40)

@export_group("Info Panel")
@export var info_panel_size: Vector2 = Vector2(220, 220)
@export var info_panel_margin: float = 10.0
@export var instructions_font_size: int = 12

@export_group("Time Controls")
@export var phase_label_min_width: float = 120.0
@export var speed_options: Array[float] = [1.0, 2.0, 3.0]

@export_group("Wellbeing Colors")
@export var wellbeing_high_color: Color = Color(0.3, 0.9, 0.3)
@export var wellbeing_medium_color: Color = Color(0.9, 0.9, 0.3)
@export var wellbeing_low_color: Color = Color(0.9, 0.3, 0.3)
@export var wellbeing_high_threshold: float = 70.0
@export var wellbeing_medium_threshold: float = 40.0

@export_group("Game End")
@export var end_overlay_color: Color = Color(0, 0, 0, 0.7)
@export var end_panel_half_width: float = 200.0
@export var end_panel_half_height: float = 180.0
@export var end_panel_margin: int = 20
@export var end_title_font_size: int = 28
@export var end_tier_font_size: int = 36
@export var end_desc_font_size: int = 14
@export var end_wellbeing_font_size: int = 20
@export var end_stats_font_size: int = 14
@export var end_button_size: Vector2 = Vector2(120, 40)
@export var tier_flourishing_color: Color = Color(0.2, 0.9, 0.4)
@export var tier_growing_color: Color = Color(0.5, 0.8, 0.3)
@export var tier_surviving_color: Color = Color(0.9, 0.7, 0.2)
@export var tier_struggling_color: Color = Color(0.9, 0.3, 0.3)

func _ready() -> void:
  _setup_systems()
  _setup_ui()
  event_bus.game_ended.connect(_on_game_ended)
  event_bus.game_started.emit()

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
  time_system.day_started.connect(_on_day_started)

  event_bus.resource_overflow.connect(_on_resource_overflow)

  get_node("/root/GameState").reset_to_defaults(starting_energy, max_energy, base_attention_pool, base_wellbeing, habituation_thresholds, habituation_costs)

func _setup_ui() -> void:
  _populate_building_toolbar()
  _connect_time_controls()
  _create_building_tooltip()

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
  game_world.set_placement_mode(true, building_id, building_system)

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
      elif is_assigning_transport and available_transport_resources.size() > 1:
        if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
          _cycle_transport_resource(-1)
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
          _cycle_transport_resource(1)

  if event is InputEventKey:
    var key = event as InputEventKey
    if key.pressed and key.keycode == KEY_ESCAPE:
      if selected_building:
        selected_building = null
        _cancel_placement()
      elif selected_worker:
        _deselect_worker()
      else:
        _cancel_placement()
    elif key.pressed and key.keycode == KEY_DELETE:
      if selected_building:
        _remove_selected_building()
      elif selected_worker:
        _remove_selected_worker()
    elif key.pressed and key.keycode == KEY_W:
      var coord = game_world.hover_coord
      if game_world.get_grid().is_road_at(coord):
        spawn_worker_at(coord)
        print("Spawned worker at ", coord)

func _try_place_building() -> void:
  if not is_placing or selected_building_id == "":
    return

  var coord = game_world.hover_coord
  var failure_reason = building_system.get_placement_failure_reason(selected_building_id, coord)
  if failure_reason == "":
    building_system.place_building(selected_building_id, coord)
    _update_energy_display()
  else:
    _show_placement_failure(failure_reason)

func _handle_click() -> void:
  var coord = game_world.hover_coord
  var mouse_pos = game_world.get_global_mouse_position()

  var clicked_worker = _find_worker_at_position(mouse_pos)
  if clicked_worker:
    _select_worker(clicked_worker)
    return

  if selected_worker:
    _deselect_worker()

  var building = building_system.get_building_at(coord)

  if is_assigning_transport:
    if building and building != selected_source_building:
      _complete_transport_assignment(building)
    return

  if building:
    _select_building(building)

func _select_building(building: Node) -> void:
  selected_building = building
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
    available_transport_resources = available_resources
    transport_resource_index = 0
    transport_resource_type = available_resources[0]
    is_assigning_transport = true
    _update_transport_instructions()
  else:
    _update_instructions("Selected: %s\nDelete to remove\n(No resources to transport)" % building.building_id)

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
  available_transport_resources = []
  transport_resource_index = 0

func _find_worker_at_position(world_pos: Vector2) -> Node:
  for worker in worker_system.workers:
    if worker.position.distance_to(world_pos) <= worker_click_radius:
      return worker
  return null

func _select_worker(worker: Node) -> void:
  if selected_worker and selected_worker != worker:
    selected_worker.set_selected(false)
  selected_worker = worker
  worker.set_selected(true)
  var job_desc = _get_worker_job_description(worker)
  _update_instructions("Worker selected\n%s\nDelete: remove worker\nEscape: deselect" % job_desc)

func _deselect_worker() -> void:
  if selected_worker:
    selected_worker.set_selected(false)
  selected_worker = null
  _update_instructions("Click building to select\nClick grid to place\nRight-click to cancel")

func _remove_selected_worker() -> void:
  if selected_worker:
    worker_system.remove_worker(selected_worker)
    selected_worker = null
    _update_energy_display()
    _update_instructions("Worker removed\nClick building to select\nClick grid to place")

func _get_worker_job_description(worker: Node) -> String:
  if worker.job_type == "":
    return "Idle"
  elif worker.job_type == "transport":
    var src = worker.source_building.building_id if worker.source_building else "?"
    var dst = worker.dest_building.building_id if worker.dest_building else "?"
    return "Transport %s: %s -> %s" % [worker.resource_type, src, dst]
  elif worker.job_type == "operate":
    var bld = worker.dest_building.building_id if worker.dest_building else "?"
    return "Operating: %s" % bld
  return "Unknown job"

func _cycle_transport_resource(direction: int) -> void:
  var count = available_transport_resources.size()
  transport_resource_index = (transport_resource_index + direction + count) % count
  transport_resource_type = available_transport_resources[transport_resource_index]
  _update_transport_instructions()

func _update_transport_instructions() -> void:
  var building_name = selected_source_building.building_id
  var res_count = available_transport_resources.size()
  var base_text = "Click destination for transport\n[%s] from %s" % [transport_resource_type, building_name]
  if res_count > 1:
    base_text += "\nScroll wheel: cycle resources (%d/%d)" % [transport_resource_index + 1, res_count]
  base_text += "\nDelete to remove building"
  _update_instructions(base_text)

func _update_instructions(text: String) -> void:
  instructions_label.text = text

func _show_placement_failure(reason: String) -> void:
  instructions_label.text = reason
  instructions_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
  var tween = create_tween()
  tween.tween_interval(1.5)
  tween.tween_callback(func():
    instructions_label.remove_theme_color_override("font_color")
    _update_instructions("Click building to select\nClick grid to place\nRight-click to cancel")
  )

func _cancel_placement() -> void:
  is_placing = false
  selected_building_id = ""
  selected_building = null
  game_world.set_placement_mode(false, "")
  _cancel_transport_assignment()
  _update_instructions("Click building to select\nClick grid to place\nRight-click to cancel")

func _remove_selected_building() -> void:
  var building = selected_building
  var def = building.definition
  var cost = def.get("build_cost", {})
  var energy_cost = cost.get("energy", 0)
  var refund = int(energy_cost * removal_refund_percent)

  building_system.remove_building(building)

  if refund > 0:
    game_state.add_energy(refund)

  selected_building = null
  _cancel_transport_assignment()
  _update_energy_display()
  _update_instructions("Building removed (+%d energy)" % refund)

func _update_energy_display() -> void:
  energy_label.text = "Energy: %d/%d" % [game_state.current_energy, game_state.max_energy]
  if worker_system:
    attention_label.text = "Attention: %d/%d" % [worker_system.attention_used, worker_system.attention_pool]
  _calculate_wellbeing()
  var wb_color = _get_wellbeing_color(game_state.wellbeing)
  wellbeing_label.text = "Wellbeing: %d" % int(game_state.wellbeing)
  wellbeing_label.add_theme_color_override("font_color", wb_color)

func _calculate_wellbeing() -> void:
  var positive_total = 0
  var negative_total = 0

  for building in game_state.active_buildings:
    for res_id in building.storage:
      var amount = building.storage[res_id]
      if res_id in positive_emotions:
        positive_total += amount
      elif res_id in negative_emotions:
        negative_total += amount

  var habit_count = 0
  for building in game_state.active_buildings:
    if building.has_behavior(BuildingDefs.Behavior.HABIT):
      habit_count += 1

  var positive_bonus = positive_total * positive_emotion_weight
  var negative_penalty = negative_total * negative_emotion_weight
  var building_bonus = habit_count * habit_building_weight

  var new_wellbeing = base_wellbeing + positive_bonus - negative_penalty + building_bonus
  game_state.set_wellbeing(new_wellbeing)

func _get_wellbeing_color(value: float) -> Color:
  if value >= wellbeing_good_threshold:
    return wellbeing_good_color
  elif value >= wellbeing_warning_threshold:
    return wellbeing_warning_color
  else:
    return wellbeing_bad_color

func _get_tier_display_info(tier: int) -> Dictionary:
  var GameStateScript = preload("res://jan_28_2026-psychebuilder-ai/src/autoload/game_state.gd")
  match tier:
    GameStateScript.WellbeingTier.STRUGGLING:
      return {"name": "Struggling (<20)", "color": tier_struggling_color}
    GameStateScript.WellbeingTier.BASELINE:
      return {"name": "Baseline (20-39)", "color": Color(0.7, 0.7, 0.7)}
    GameStateScript.WellbeingTier.STABLE:
      return {"name": "Stable (40-59)", "color": tier_surviving_color}
    GameStateScript.WellbeingTier.THRIVING:
      return {"name": "Thriving (60-79)", "color": tier_growing_color}
    GameStateScript.WellbeingTier.FLOURISHING:
      return {"name": "Flourishing (80+)", "color": tier_flourishing_color}
  return {"name": "Unknown", "color": Color.WHITE}

func _get_weather_description() -> String:
  var GameStateScript = preload("res://jan_28_2026-psychebuilder-ai/src/autoload/game_state.gd")
  match game_state.current_weather:
    GameStateScript.WeatherState.CLEAR_SKIES:
      return "Clear Skies (+15% processing)"
    GameStateScript.WeatherState.STORM:
      return "Storm (-25% processing, +30% negative)"
    GameStateScript.WeatherState.OVERCAST:
      return "Overcast (+15% grief generation)"
    GameStateScript.WeatherState.FOG:
      return "Fog (-10% processing)"
    GameStateScript.WeatherState.STILLNESS:
      return "Stillness (+10% processing)"
    _:
      return "Neutral"

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

func _on_day_started(_day_number: int) -> void:
  resource_system.process_decay()

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
  _update_building_tooltip()

func _on_resource_overflow(resource_type: String, amount: int, _building: Node, world_position: Vector2) -> void:
  resource_system.spawn_resource(resource_type, world_position, amount)

func _create_building_tooltip() -> void:
  building_tooltip = PanelContainer.new()
  building_tooltip.name = "BuildingTooltip"
  building_tooltip.visible = false
  building_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

  var vbox = VBoxContainer.new()
  vbox.name = "VBox"
  building_tooltip.add_child(vbox)

  var name_label = Label.new()
  name_label.name = "NameLabel"
  name_label.add_theme_font_size_override("font_size", tooltip_name_font_size)
  vbox.add_child(name_label)

  var desc_label = Label.new()
  desc_label.name = "DescLabel"
  desc_label.add_theme_font_size_override("font_size", tooltip_desc_font_size)
  desc_label.add_theme_color_override("font_color", tooltip_desc_color)
  desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  desc_label.custom_minimum_size.x = tooltip_min_width
  vbox.add_child(desc_label)

  var separator = HSeparator.new()
  vbox.add_child(separator)

  var status_label = Label.new()
  status_label.name = "StatusLabel"
  status_label.add_theme_font_size_override("font_size", tooltip_status_font_size)
  vbox.add_child(status_label)

  var storage_label = Label.new()
  storage_label.name = "StorageLabel"
  storage_label.add_theme_font_size_override("font_size", tooltip_status_font_size)
  vbox.add_child(storage_label)

  var production_label = Label.new()
  production_label.name = "ProductionLabel"
  production_label.add_theme_font_size_override("font_size", tooltip_status_font_size)
  vbox.add_child(production_label)

  var connection_label = Label.new()
  connection_label.name = "ConnectionLabel"
  connection_label.add_theme_font_size_override("font_size", tooltip_desc_font_size)
  vbox.add_child(connection_label)

  var indicators_label = Label.new()
  indicators_label.name = "IndicatorsLabel"
  indicators_label.add_theme_font_size_override("font_size", tooltip_desc_font_size)
  indicators_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9))
  vbox.add_child(indicators_label)

  ui_layer.add_child(building_tooltip)

func _update_building_tooltip() -> void:
  if is_placing:
    building_tooltip.visible = false
    hovered_building = null
    game_world.set_aura_building(null)
    return

  var coord = game_world.hover_coord
  var building = building_system.get_building_at(coord)

  if building and building != hovered_building:
    hovered_building = building
    _populate_tooltip(building)
    game_world.set_aura_building(building)
  elif building and building == hovered_building:
    _populate_tooltip(building)
  elif not building and hovered_building:
    game_world.set_aura_building(null)

  if hovered_building:
    building_tooltip.visible = true
    var mouse_pos = get_viewport().get_mouse_position()
    var viewport_size = get_viewport().get_visible_rect().size
    var tooltip_size = building_tooltip.size

    var pos = mouse_pos + tooltip_offset
    if pos.x + tooltip_size.x > viewport_size.x:
      pos.x = mouse_pos.x - tooltip_size.x - tooltip_offset.x
    if pos.y + tooltip_size.y > viewport_size.y:
      pos.y = mouse_pos.y - tooltip_size.y - tooltip_offset.y

    building_tooltip.position = pos
  else:
    building_tooltip.visible = false
    hovered_building = null
    game_world.set_aura_building(null)

func _populate_tooltip(building: Node) -> void:
  var vbox = building_tooltip.get_node("VBox")
  var def = building.definition

  var name_label = vbox.get_node("NameLabel")
  name_label.text = def.get("name", building.building_id)

  var desc_label = vbox.get_node("DescLabel")
  desc_label.text = def.get("description", "")

  var status_label = vbox.get_node("StatusLabel")
  status_label.text = _get_status_text(building)
  status_label.add_theme_color_override("font_color", _get_status_color(building))

  var storage_label = vbox.get_node("StorageLabel")
  storage_label.text = _get_storage_text(building)
  storage_label.visible = storage_label.text != ""

  var production_label = vbox.get_node("ProductionLabel")
  production_label.text = _get_production_text(building)
  production_label.visible = production_label.text != ""

  var connection_label = vbox.get_node("ConnectionLabel")
  if building.is_road():
    connection_label.text = ""
    connection_label.visible = false
  elif building.road_connected:
    connection_label.text = "Connected to roads"
    connection_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
    connection_label.visible = true
  else:
    connection_label.text = "Not connected to roads"
    connection_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
    connection_label.visible = true

  var indicators_label = vbox.get_node("IndicatorsLabel")
  indicators_label.text = _get_indicator_explanations_text(building)
  indicators_label.visible = indicators_label.text != ""

func _get_indicator_explanations_text(building: Node) -> String:
  var lines: Array[String] = []

  if building.attuned_partners.size() > 0:
    lines.append("[A] Attuned: bonded with nearby building")
  if building.is_specialized:
    lines.append("[M] Mastery: specialized in a resource")
  if building.velocity_momentum >= 0.5:
    lines.append("[V] Velocity: processing momentum active")
  if building.is_legacy:
    lines.append("[L] Legacy: imprinted by past worker")
  if building._is_in_any_sync_chain():
    lines.append("[S] Sync: emotionally synchronized")

  var has_quality_indicators = false
  for res_id in building.storage:
    if building.storage[res_id] > 0:
      var purity = building.storage_purity.get(res_id, config.purity_initial_level)
      var mastery_level = building.get_mastery_level(res_id)
      if purity >= config.purity_output_bonus_threshold or purity <= config.purity_min_level + 0.1:
        has_quality_indicators = true
      if mastery_level > 0:
        has_quality_indicators = true

  if has_quality_indicators:
    if lines.size() > 0:
      lines.append("")
    lines.append("Resource symbols:")
    lines.append("* = pure (>80% purity)")
    lines.append("~ = diluted (<40% purity)")
    lines.append("! = max mastery")
    lines.append("+N = mastery level N")

  return "\n".join(lines)

func _get_status_text(building: Node) -> String:
  var Building = preload("res://jan_28_2026-psychebuilder-ai/src/entities/building.gd")
  match building.current_status:
    Building.Status.IDLE:
      return "Idle"
    Building.Status.PROCESSING:
      var remaining = building.process_timer
      return "Processing... (%.1fs)" % remaining
    Building.Status.WAITING_INPUT:
      var inputs = building.definition.get("input", {})
      var needed = []
      for res_id in inputs:
        var has = building.storage.get(res_id, 0)
        var req = inputs[res_id]
        if has < req:
          needed.append("%s: %d/%d" % [res_id, has, req])
      return "Waiting for: " + ", ".join(needed)
    Building.Status.WAITING_WORKER:
      return "Waiting for worker"
    Building.Status.STORAGE_FULL:
      return "Storage full"
    Building.Status.GENERATING:
      return "Generating"
    Building.Status.COPING_READY:
      return "Ready to activate"
    Building.Status.COPING_COOLDOWN:
      return "Cooldown: %.1fs" % building.coping_cooldown_timer
  return ""

func _get_status_color(building: Node) -> Color:
  return building.status_colors.get(building.current_status, Color.GRAY)

func _get_storage_text(building: Node) -> String:
  if building.storage_capacity <= 0:
    return ""

  var total = 0
  var items = []
  for res_id in building.storage:
    var amount = building.storage[res_id]
    if amount > 0:
      var purity = building.storage_purity.get(res_id, config.purity_initial_level)
      var mastery_level = building.get_mastery_level(res_id)
      var indicator = ""
      if purity >= config.purity_output_bonus_threshold:
        indicator += "*"
      elif purity <= config.purity_min_level + 0.1:
        indicator += "~"
      if mastery_level >= config.mastery_max_level:
        indicator += "!"
      elif mastery_level > 0:
        indicator += "+" + str(mastery_level)
      items.append("%s: %d%s" % [res_id, amount, indicator])
      total += amount

  if items.size() == 0:
    return "Storage: empty (0/%d)" % building.storage_capacity

  return "Storage (%d/%d): %s" % [total, building.storage_capacity, ", ".join(items)]

func _get_production_text(building: Node) -> String:
  var def = building.definition
  var lines = []

  if building.has_behavior(BuildingDefs.Behavior.GENERATOR):
    var generates = def.get("generates", "")
    var rate = def.get("generation_rate", 0.0)
    var amount = def.get("generation_amount", 1)
    if generates != "" and rate > 0:
      lines.append("Generates: %d %s every %.1fs" % [amount, generates, 1.0 / rate])

  if building.has_behavior(BuildingDefs.Behavior.PROCESSOR):
    var inputs = def.get("input", {})
    var outputs = def.get("output", {})
    var time = def.get("process_time", 1.0)
    var input_str = ", ".join(inputs.keys().map(func(k): return "%d %s" % [inputs[k], k]))
    var output_str = ", ".join(outputs.keys().map(func(k): return "%d %s" % [outputs[k], k]))
    lines.append("Converts: %s -> %s (%.1fs)" % [input_str, output_str, time])
    if def.get("requires_worker", false):
      lines.append("Requires worker: Yes")

  if building.has_behavior(BuildingDefs.Behavior.HABIT):
    var habit_gen = def.get("habit_generates", {})
    var habit_cons = def.get("habit_consumes", {})
    var habit_red = def.get("habit_reduces", {})
    var energy_bonus = def.get("habit_energy_bonus", 0)
    var parts = []
    if habit_gen.size() > 0:
      parts.append("generates " + ", ".join(habit_gen.keys().map(func(k): return "%d %s" % [habit_gen[k], k])))
    if habit_cons.size() > 0:
      parts.append("costs " + ", ".join(habit_cons.keys().map(func(k): return "%d %s" % [habit_cons[k], k])))
    if habit_red.size() > 0:
      parts.append("reduces " + ", ".join(habit_red.keys().map(func(k): return "%d %s" % [habit_red[k], k])))
    if energy_bonus > 0:
      parts.append("+%d energy" % energy_bonus)
    if parts.size() > 0:
      lines.append("Daily: " + ", ".join(parts))

  if building.has_behavior(BuildingDefs.Behavior.COPING):
    var trigger = def.get("coping_trigger", "")
    var cop_in = def.get("coping_input", {})
    var cop_out = def.get("coping_output", {})
    var cooldown = def.get("coping_cooldown", 30.0)
    lines.append("Trigger: %s" % trigger)
    var in_str = ", ".join(cop_in.keys().map(func(k): return "%d %s" % [cop_in[k], k]))
    var out_str = ", ".join(cop_out.keys().map(func(k): return "%d %s" % [cop_out[k], k]))
    lines.append("Effect: %s -> %s (%.0fs cooldown)" % [in_str, out_str, cooldown])

  return "\n".join(lines)

func _on_game_ended(ending_tier: String) -> void:
  get_tree().paused = true
  _create_game_end_screen(ending_tier)

func _create_game_end_screen(ending_tier: String) -> void:
  var overlay = ColorRect.new()
  overlay.name = "GameEndOverlay"
  overlay.color = end_overlay_color
  overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
  overlay.mouse_filter = Control.MOUSE_FILTER_STOP

  var center_panel = PanelContainer.new()
  center_panel.set_anchors_preset(Control.PRESET_CENTER)
  center_panel.offset_left = -end_panel_half_width
  center_panel.offset_right = end_panel_half_width
  center_panel.offset_top = -end_panel_half_height
  center_panel.offset_bottom = end_panel_half_height
  overlay.add_child(center_panel)

  var margin = MarginContainer.new()
  margin.add_theme_constant_override("margin_left", end_panel_margin)
  margin.add_theme_constant_override("margin_right", end_panel_margin)
  margin.add_theme_constant_override("margin_top", end_panel_margin)
  margin.add_theme_constant_override("margin_bottom", end_panel_margin)
  center_panel.add_child(margin)

  var vbox = VBoxContainer.new()
  vbox.add_theme_constant_override("separation", 12)
  margin.add_child(vbox)

  var title = Label.new()
  title.text = "Game Complete"
  title.add_theme_font_size_override("font_size", end_title_font_size)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(title)

  var tier_label = Label.new()
  tier_label.text = ending_tier.capitalize()
  tier_label.add_theme_font_size_override("font_size", end_tier_font_size)
  tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  tier_label.add_theme_color_override("font_color", _get_tier_color(ending_tier))
  vbox.add_child(tier_label)

  var desc_label = Label.new()
  desc_label.text = _get_ending_description(ending_tier)
  desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  desc_label.add_theme_font_size_override("font_size", end_desc_font_size)
  vbox.add_child(desc_label)

  var separator = HSeparator.new()
  vbox.add_child(separator)

  var wellbeing_label = Label.new()
  wellbeing_label.text = "Final Wellbeing: %d" % int(game_state.wellbeing)
  wellbeing_label.add_theme_font_size_override("font_size", end_wellbeing_font_size)
  wellbeing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  wellbeing_label.add_theme_color_override("font_color", _get_wellbeing_color(game_state.wellbeing))
  vbox.add_child(wellbeing_label)

  var stats = _gather_summary_stats()
  var stats_label = Label.new()
  stats_label.text = stats
  stats_label.add_theme_font_size_override("font_size", end_stats_font_size)
  stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(stats_label)

  var separator2 = HSeparator.new()
  vbox.add_child(separator2)

  var play_again_btn = Button.new()
  play_again_btn.text = "Play Again"
  play_again_btn.custom_minimum_size = end_button_size
  play_again_btn.pressed.connect(_on_play_again)
  vbox.add_child(play_again_btn)

  ui_layer.add_child(overlay)

func _get_tier_color(tier: String) -> Color:
  match tier:
    "flourishing":
      return tier_flourishing_color
    "growing":
      return tier_growing_color
    "surviving":
      return tier_surviving_color
    "struggling":
      return tier_struggling_color
  return Color.WHITE

func _get_ending_description(tier: String) -> String:
  match tier:
    "flourishing":
      return "You have built a thriving inner world. Your habits, routines, and emotional processing have created lasting wellbeing."
    "growing":
      return "You are on a positive path. With continued attention to your mental architecture, flourishing is within reach."
    "surviving":
      return "You have managed to get by, but there is room for growth. Consider building more sustainable habits."
    "struggling":
      return "Times have been difficult. Remember that building wellbeing takes time and patience."
  return ""

func _gather_summary_stats() -> String:
  var building_count = game_state.active_buildings.size()
  var worker_count = game_state.active_workers.size()

  var total_positive = 0
  var total_negative = 0
  for building in game_state.active_buildings:
    for res_id in building.storage:
      var amount = building.storage[res_id]
      if res_id in ["joy", "calm", "wisdom"]:
        total_positive += amount
      elif res_id in ["grief", "anxiety"]:
        total_negative += amount

  var lines: Array[String] = []
  lines.append("Buildings: %d" % building_count)
  lines.append("Active Workers: %d" % worker_count)
  lines.append("Positive Resources: %d" % total_positive)
  lines.append("Negative Resources: %d" % total_negative)
  return "\n".join(lines)

func _on_play_again() -> void:
  get_tree().paused = false
  get_tree().reload_current_scene()
