extends Control

const ResourceSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/resource_system.gd")
const BuildingSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/building_system.gd")
const WorkerSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/worker_system.gd")
const TimeSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/time_system.gd")
const GameFlowManagerScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/game_flow_manager.gd")
const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")
const EventPopupScene = preload("res://jan_28_2026-psychebuilder-ai/src/ui/event_popup.tscn")
const DiscoveryPopupScene = preload("res://jan_28_2026-psychebuilder-ai/src/ui/discovery_popup.tscn")
const MainMenuScene = preload("res://jan_28_2026-psychebuilder-ai/src/ui/main_menu.tscn")
const EndScreenScene = preload("res://jan_28_2026-psychebuilder-ai/src/ui/end_screen.tscn")
const WellbeingShader = preload("res://jan_28_2026-psychebuilder-ai/src/shaders/wellbeing_effects.gdshader")

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
@onready var effects_rect: ColorRect = %EffectsRect

var hud: Node  # Reference to hud.gd script on UILayer

var wellbeing_material: ShaderMaterial
var resource_system: Node
var building_system: Node
var worker_system: Node
var time_system: Node
var event_system: Node
var game_flow_manager: Node
var event_popup: PanelContainer
var discovery_popup: PanelContainer
var tutorial_hint_popup: PanelContainer
var main_menu: Control
var end_screen: Control
var event_completion_timer: float = 0.0
var game_started: bool = false

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
var resource_labels: Dictionary = {}
var toast_queue: Array = []
var active_toasts: Array = []

@export_group("Toast")
@export var toast_duration: float = 3.0
@export var toast_max_visible: int = 5
@export var toast_success_color: Color = Color(0.4, 0.9, 0.4)
@export var toast_warning_color: Color = Color(0.9, 0.9, 0.4)
@export var toast_error_color: Color = Color(0.9, 0.4, 0.4)
@export var toast_info_color: Color = Color(0.9, 0.9, 0.9)

@export_group("Resource Display")
@export var positive_resource_color: Color = Color(0.5, 0.9, 0.5)
@export var negative_resource_color: Color = Color(0.9, 0.5, 0.5)
@export var neutral_resource_color: Color = Color(0.8, 0.8, 0.8)
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

@export_group("Info Panel")
@export var info_panel_size: Vector2 = Vector2(220, 220)
@export var info_panel_margin: float = 10.0
@export var instructions_font_size: int = 12

@export_group("Time Controls")
@export var phase_label_min_width: float = 120.0

@export_group("Wellbeing Colors")
@export var wellbeing_high_color: Color = Color(0.3, 0.9, 0.3)
@export var wellbeing_medium_color: Color = Color(0.9, 0.9, 0.3)
@export var wellbeing_low_color: Color = Color(0.9, 0.3, 0.3)
@export var wellbeing_high_threshold: float = 70.0
@export var wellbeing_medium_threshold: float = 40.0

@export_group("Resource Colors")
@export var energy_normal_color: Color = Color(0.9, 0.9, 0.9)
@export var energy_low_color: Color = Color(0.9, 0.7, 0.3)
@export var energy_critical_color: Color = Color(0.9, 0.3, 0.3)
@export var energy_low_threshold: float = 0.3
@export var energy_critical_threshold: float = 0.1
@export var attention_normal_color: Color = Color(0.9, 0.9, 0.9)
@export var attention_high_color: Color = Color(0.9, 0.7, 0.3)
@export var attention_full_color: Color = Color(0.9, 0.3, 0.3)
@export var attention_high_threshold: float = 0.7
@export var attention_full_threshold: float = 0.95

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
  hud = ui_layer  # hud.gd is attached to UILayer
  _setup_systems()
  _setup_ui()
  event_bus.game_ended.connect(_on_game_ended)
  _on_start_game()  # Skip main menu for now

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

  event_system = get_node("/root/EventSystem")
  event_system.setup(resource_system, game_world.get_grid(), building_system)
  event_system.event_popup_requested.connect(_on_event_popup_requested)

  event_bus.resource_overflow.connect(_on_resource_overflow)

  get_node("/root/GameState").reset_to_defaults(starting_energy, max_energy, base_attention_pool, base_wellbeing, habituation_thresholds, habituation_costs)

  game_flow_manager = GameFlowManagerScript.new()
  add_child(game_flow_manager)

  _setup_wellbeing_effects()
  game_flow_manager.setup(building_system, resource_system, game_world.get_grid())
  game_flow_manager.tutorial_hint_requested.connect(_on_tutorial_hint_requested)
  game_flow_manager.discovery_available.connect(_on_discovery_available)
  game_flow_manager.starting_setup_complete.connect(_on_starting_setup_complete)
  event_bus.night_started.connect(_on_night_started)
  game_flow_manager.initialize_game()

func _setup_ui() -> void:
  hud.setup(resource_system, building_system, worker_system, time_system)
  hud.building_selected.connect(_on_building_selected)
  hud.building_action_pressed.connect(_on_hud_building_action)
  hud.connect_time_controls(time_system)
  _create_building_tooltip()
  _create_event_popup()
  _create_discovery_popup()
  _create_tutorial_hint_popup()

func _on_building_selected(building_id: String) -> void:
  selected_building_id = building_id
  is_placing = true
  game_world.set_placement_mode(true, building_id, building_system)

  if not game_state.has_hint_shown("first_building_placement"):
    game_state.mark_hint_shown("first_building_placement")
    _on_tutorial_hint_requested(config.hint_first_building_placement)

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
    var def = BuildingDefs.get_definition(selected_building_id)
    show_toast("Placed %s" % def.get("name", selected_building_id), "success")
    if selected_building_id != "road":
      _cancel_placement()
  else:
    show_toast(failure_reason, "error")
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
  if selected_building and is_instance_valid(selected_building):
    selected_building.set_selected(false)
  selected_building = building
  if selected_building:
    selected_building.set_selected(true)
  _show_building_info(building)

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
    _update_instructions("Click 'Assign' to create transport\nDelete to remove building")
  else:
    _update_instructions("Selected: %s\nDelete to remove\n(No resources to transport)" % building.building_id)

func _complete_transport_assignment(dest_building: Node) -> void:
  if not selected_source_building or not dest_building:
    _cancel_transport_assignment()
    return

  var road_coord = _find_road_near_building(selected_source_building)
  if road_coord == Vector2i(-1, -1):
    show_toast("No road adjacent to source building", "error")
    _cancel_transport_assignment()
    return

  var dest_road_coord = _find_road_near_building(dest_building)
  if dest_road_coord == Vector2i(-1, -1):
    show_toast("No road adjacent to destination", "error")
    _cancel_transport_assignment()
    return

  var worker = spawn_worker_at(road_coord)
  if worker_system.assign_transport_job(worker, selected_source_building, dest_building, transport_resource_type):
    show_toast("Worker assigned: %s" % transport_resource_type, "success")
    _update_energy_display()
  else:
    show_toast("Not enough attention", "error")
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
  hud.update_instructions(text)

func _show_placement_failure(reason: String) -> void:
  hud.update_instructions(reason)
  var tween = create_tween()
  tween.tween_interval(1.5)
  tween.tween_callback(func():
    _update_instructions("Click building to select\nClick grid to place\nRight-click to cancel")
  )

func _cancel_placement() -> void:
  is_placing = false
  selected_building_id = ""
  if selected_building and is_instance_valid(selected_building):
    selected_building.set_selected(false)
  selected_building = null
  game_world.set_placement_mode(false, "")
  _cancel_transport_assignment()
  _hide_building_info()
  _update_instructions("Click building to select\nClick grid to place\nRight-click to cancel")

func _remove_selected_building() -> void:
  var building = selected_building
  var def = building.definition
  var cost = def.get("build_cost", {})
  var energy_cost = cost.get("energy", 0)
  var refund = int(energy_cost * removal_refund_percent)

  building.set_selected(false)
  building_system.remove_building(building)

  if refund > 0:
    game_state.add_energy(refund)

  selected_building = null
  _cancel_transport_assignment()
  _update_energy_display()
  show_toast("Building removed (+%d energy)" % refund, "info")
  _update_instructions("Click building to select\nClick grid to place")

func _update_energy_display() -> void:
  _calculate_wellbeing()
  # HUD handles display updates via event_bus signals

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
  _update_wellbeing_visual_effects()

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
  _update_energy_display()
  _update_visual_effects()

func _on_day_started(day_number: int) -> void:
  resource_system.process_decay()
  show_toast("Day %d begins" % day_number, "info")
  game_flow_manager.check_tutorial_hint(day_number)

func _process(delta: float) -> void:
  if time_system:
    _update_visual_effects()
  _update_building_tooltip()
  _update_event_completion_check(delta)

func _update_event_completion_check(delta: float) -> void:
  event_completion_timer += delta
  if event_completion_timer >= config.event_completion_check_interval:
    event_completion_timer = 0.0
    event_system.check_completion_conditions()

func _on_resource_overflow(resource_type: String, amount: int, _building: Node, world_position: Vector2) -> void:
  resource_system.spawn_resource(resource_type, world_position, amount)
  game_world.spawn_floating_text(world_position, "Storage full: %s" % resource_type, Color.ORANGE)

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

func _create_event_popup() -> void:
  event_popup = EventPopupScene.instantiate()
  event_popup.choice_made.connect(_on_event_choice_made)
  event_popup.dismissed.connect(_on_event_dismissed)
  ui_layer.add_child(event_popup)

func _create_discovery_popup() -> void:
  discovery_popup = DiscoveryPopupScene.instantiate()
  discovery_popup.building_chosen.connect(_on_discovery_building_chosen)
  discovery_popup.dismissed.connect(_on_discovery_dismissed)
  ui_layer.add_child(discovery_popup)

func _create_tutorial_hint_popup() -> void:
  tutorial_hint_popup = PanelContainer.new()
  tutorial_hint_popup.name = "TutorialHintPopup"
  tutorial_hint_popup.visible = false
  tutorial_hint_popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
  tutorial_hint_popup.offset_top = 60
  tutorial_hint_popup.offset_left = -200
  tutorial_hint_popup.offset_right = 200

  var margin = MarginContainer.new()
  margin.add_theme_constant_override("margin_left", 16)
  margin.add_theme_constant_override("margin_right", 16)
  margin.add_theme_constant_override("margin_top", 12)
  margin.add_theme_constant_override("margin_bottom", 12)
  tutorial_hint_popup.add_child(margin)

  var vbox = VBoxContainer.new()
  vbox.add_theme_constant_override("separation", 10)
  margin.add_child(vbox)

  var hint_label = Label.new()
  hint_label.name = "HintLabel"
  hint_label.add_theme_font_size_override("font_size", 13)
  hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  hint_label.custom_minimum_size.x = 360
  vbox.add_child(hint_label)

  var dismiss_btn = Button.new()
  dismiss_btn.name = "DismissBtn"
  dismiss_btn.text = "Got it"
  dismiss_btn.pressed.connect(_on_tutorial_hint_dismissed)
  vbox.add_child(dismiss_btn)

  ui_layer.add_child(tutorial_hint_popup)

func _on_hud_building_action(action: String, building: Node) -> void:
  match action:
    "assign_worker":
      _start_transport_assignment(building)
    "remove_building":
      _remove_selected_building()
      hud.hide_building_info()

func _start_transport_assignment(building: Node) -> void:
  var def = building.definition
  var generates = def.get("generates", "")
  var output = def.get("output", {})

  var available_res: Array = []
  if generates != "":
    available_res.append(generates)
  for res_id in output.keys():
    if res_id not in available_res:
      available_res.append(res_id)
  for res_id in building.storage.keys():
    if building.storage[res_id] > 0 and res_id not in available_res:
      available_res.append(res_id)

  if available_res.size() == 0:
    show_toast("No resources to transport", "warning")
    return

  if not game_state.has_hint_shown("first_worker_assignment"):
    game_state.mark_hint_shown("first_worker_assignment")
    _on_tutorial_hint_requested(config.hint_first_worker_assignment)

  selected_source_building = building
  available_transport_resources = available_res
  transport_resource_index = 0
  transport_resource_type = available_res[0]
  is_assigning_transport = true
  _update_transport_instructions()

func show_toast(message: String, toast_type: String = "info") -> void:
  hud.show_toast(message, toast_type)

func _show_building_info(building: Node) -> void:
  hud.show_building_info(building)

func _hide_building_info() -> void:
  hud.hide_building_info()

func _is_any_popup_active() -> bool:
  return tutorial_hint_popup.visible or event_popup.visible or discovery_popup.visible

func _on_tutorial_hint_requested(hint_text: String) -> void:
  if hint_text.strip_edges() == "":
    return
  if _is_any_popup_active():
    return
  var hint_label = tutorial_hint_popup.get_node("MarginContainer/VBoxContainer/HintLabel")
  hint_label.text = hint_text
  tutorial_hint_popup.visible = true
  time_system.set_paused(true)

func _on_tutorial_hint_dismissed() -> void:
  tutorial_hint_popup.visible = false
  time_system.set_paused(false)

func _on_event_popup_requested(event_data: Dictionary) -> void:
  if _is_any_popup_active():
    return
  event_popup.show_event(event_data, time_system)

func _on_event_choice_made(choice_index: int) -> void:
  event_system.execute_choice(choice_index)

func _on_event_dismissed() -> void:
  event_system.dismiss_event()

func _on_discovery_available(options: Array) -> void:
  if _is_any_popup_active():
    return
  discovery_popup.show_discovery(options, time_system)

func _on_discovery_building_chosen(building_id: String) -> void:
  game_flow_manager.apply_discovery(building_id)
  hud.show_toast("Unlocked: %s" % BuildingDefs.get_definition(building_id).get("name", building_id), "success")

func _on_discovery_dismissed() -> void:
  pass

func _on_night_started(day_number: int) -> void:
  game_flow_manager.check_discovery(day_number)

func _on_starting_setup_complete() -> void:
  game_world.focus_on_buildings(game_state.active_buildings)

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
    hovered_building = null
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
  desc_label.visible = false

  var status_label = vbox.get_node("StatusLabel")
  status_label.text = _get_status_text(building)
  status_label.add_theme_color_override("font_color", _get_status_color(building))

  var storage_label = vbox.get_node("StorageLabel")
  storage_label.text = _get_compact_storage_text(building)
  storage_label.visible = storage_label.text != ""

  var production_label = vbox.get_node("ProductionLabel")
  production_label.visible = false

  var connection_label = vbox.get_node("ConnectionLabel")
  connection_label.visible = false

  var indicators_label = vbox.get_node("IndicatorsLabel")
  indicators_label.visible = false

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

func _get_compact_storage_text(building: Node) -> String:
  if building.storage_capacity <= 0:
    return ""

  var items = []
  for res_id in building.storage:
    var amount = building.storage[res_id]
    if amount > 0:
      items.append("%d %s" % [amount, res_id])

  if items.size() == 0:
    return ""

  return ", ".join(items)

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
  _show_end_screen(ending_tier)

func _show_main_menu() -> void:
  game_world.visible = false
  ui_layer.visible = true
  for child in ui_layer.get_children():
    child.visible = false
  if main_menu:
    main_menu.queue_free()
  main_menu = MainMenuScene.instantiate()
  main_menu.start_game_pressed.connect(_on_start_game)
  ui_layer.add_child(main_menu)

func _on_start_game() -> void:
  if main_menu:
    main_menu.queue_free()
    main_menu = null
  game_world.visible = true
  for child in ui_layer.get_children():
    if child == event_popup or child == discovery_popup or child == tutorial_hint_popup:
      continue
    child.visible = true
  game_started = true
  game_flow_manager.initialize_game()
  _update_energy_display()
  event_bus.game_started.emit()

func _show_end_screen(ending_tier: String) -> void:
  if end_screen:
    end_screen.queue_free()
  end_screen = EndScreenScene.instantiate()
  end_screen.setup(game_flow_manager, game_state)
  end_screen.play_again_pressed.connect(_on_play_again)
  end_screen.main_menu_pressed.connect(_on_return_to_menu)
  var stats = _gather_end_stats()
  end_screen.show_ending(ending_tier, game_state.wellbeing, stats)
  ui_layer.add_child(end_screen)

func _gather_end_stats() -> Dictionary:
  var total_positive = 0
  var total_negative = 0
  for building in game_state.active_buildings:
    for res_id in building.storage:
      var amount = building.storage[res_id]
      if res_id in positive_emotions:
        total_positive += amount
      elif res_id in negative_emotions:
        total_negative += amount
  return {
    "days": time_system.current_day,
    "buildings": game_state.active_buildings.size(),
    "workers": game_state.active_workers.size(),
    "positive_resources": total_positive,
    "negative_resources": total_negative,
    "beliefs": game_state.active_beliefs,
  }

func _on_return_to_menu() -> void:
  get_tree().paused = false
  get_tree().reload_current_scene()


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
  return game_flow_manager.get_ending_text(tier)

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

func _setup_wellbeing_effects() -> void:
  if not effects_rect:
    return
  wellbeing_material = ShaderMaterial.new()
  wellbeing_material.shader = WellbeingShader
  wellbeing_material.set_shader_parameter("wellbeing", base_wellbeing)
  wellbeing_material.set_shader_parameter("vignette_intensity", 0.35)
  effects_rect.material = wellbeing_material

func _update_wellbeing_visual_effects() -> void:
  if not wellbeing_material:
    return
  var wb = game_state.wellbeing
  wellbeing_material.set_shader_parameter("wellbeing", wb)

func _update_visual_effects() -> void:
  if time_system and game_world.has_method("set_time_of_day"):
    var progress = time_system.get_phase_progress()
    var is_day = time_system.is_day()
    var time_value = progress if is_day else 0.3 - progress * 0.2
    game_world.set_time_of_day(clampf(time_value, 0.0, 1.0))
