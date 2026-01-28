extends Control

const ResourceSystemScript = preload("res://jan_28_2026/src/systems/resource_system.gd")
const BuildingSystemScript = preload("res://jan_28_2026/src/systems/building_system.gd")
const WorkerSystemScript = preload("res://jan_28_2026/src/systems/worker_system.gd")
const TimeSystemScript = preload("res://jan_28_2026/src/systems/time_system.gd")

@onready var game_world = %GameWorld
@onready var ui_layer: CanvasLayer = %UILayer

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
  resource_system = ResourceSystemScript.new()
  add_child(resource_system)
  resource_system.set_resources_layer(game_world.get_resources_layer())

  building_system = BuildingSystemScript.new()
  add_child(building_system)
  building_system.setup(game_world.get_grid(), game_world.get_buildings_layer())

  worker_system = WorkerSystemScript.new()
  add_child(worker_system)
  worker_system.setup(game_world.get_grid())

  time_system = TimeSystemScript.new()
  add_child(time_system)
  time_system.phase_changed.connect(_on_phase_changed)

func _setup_ui() -> void:
  _create_building_toolbar()
  _create_info_panel()
  _create_time_controls()

func _create_building_toolbar() -> void:
  var toolbar = HBoxContainer.new()
  toolbar.name = "BuildingToolbar"
  toolbar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
  toolbar.offset_top = -60
  toolbar.offset_bottom = -10
  toolbar.offset_left = 10
  toolbar.offset_right = -10

  var bg = ColorRect.new()
  bg.color = Color(0.1, 0.1, 0.15, 0.9)
  bg.set_anchors_preset(Control.PRESET_FULL_RECT)
  toolbar.add_child(bg)
  bg.show_behind_parent = true

  var unlocked = building_system.get_unlocked_buildings()
  for building_id in unlocked:
    var btn = _create_building_button(building_id)
    toolbar.add_child(btn)

  ui_layer.add_child(toolbar)

func _create_building_button(building_id: String) -> Button:
  var BuildingDefs = preload("res://jan_28_2026/src/data/building_definitions.gd")
  var def = BuildingDefs.get_definition(building_id)

  var btn = Button.new()
  btn.name = building_id
  btn.text = def.get("name", building_id)
  btn.custom_minimum_size = Vector2(80, 40)
  btn.tooltip_text = def.get("description", "")

  var cost = def.get("build_cost", {})
  var energy = cost.get("energy", 0)
  if energy > 0:
    btn.text += "\n(" + str(energy) + "E)"

  btn.pressed.connect(_on_building_selected.bind(building_id))
  return btn

func _create_info_panel() -> void:
  var panel = PanelContainer.new()
  panel.name = "InfoPanel"
  panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
  panel.offset_left = 10
  panel.offset_top = 10
  panel.offset_right = 200
  panel.offset_bottom = 150

  var vbox = VBoxContainer.new()
  panel.add_child(vbox)

  var energy_label = Label.new()
  energy_label.name = "EnergyLabel"
  energy_label.text = "Energy: 10/20"
  vbox.add_child(energy_label)

  var attention_label = Label.new()
  attention_label.name = "AttentionLabel"
  attention_label.text = "Attention: 0/10"
  vbox.add_child(attention_label)

  var day_label = Label.new()
  day_label.name = "DayLabel"
  day_label.text = "Day 1"
  vbox.add_child(day_label)

  var instructions = Label.new()
  instructions.text = "Click building to select\nClick grid to place\nRight-click to cancel"
  instructions.add_theme_font_size_override("font_size", 12)
  vbox.add_child(instructions)

  ui_layer.add_child(panel)

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
  var panel = ui_layer.get_node_or_null("InfoPanel")
  if panel:
    var vbox = panel.get_node_or_null("VBoxContainer")
    if vbox and vbox.get_child_count() > 3:
      vbox.get_child(3).text = text

func _cancel_placement() -> void:
  is_placing = false
  selected_building_id = ""
  game_world.set_placement_mode(false, "")
  _cancel_transport_assignment()
  _update_instructions("Click building to select\nClick grid to place\nRight-click to cancel")

func _update_energy_display() -> void:
  var panel = ui_layer.get_node_or_null("InfoPanel")
  if panel:
    var label = panel.get_node_or_null("VBoxContainer/EnergyLabel")
    if label:
      var gs = get_node("/root/GameState")
      label.text = "Energy: %d/%d" % [gs.current_energy, gs.max_energy]

    var att_label = panel.get_node_or_null("VBoxContainer/AttentionLabel")
    if att_label and worker_system:
      att_label.text = "Attention: %d/%d" % [worker_system.attention_used, worker_system.attention_pool]

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

func _create_time_controls() -> void:
  var panel = HBoxContainer.new()
  panel.name = "TimeControls"
  panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
  panel.offset_left = -250
  panel.offset_top = 10
  panel.offset_right = -10
  panel.offset_bottom = 50

  var phase_label = Label.new()
  phase_label.name = "PhaseLabel"
  phase_label.text = "Day 1 - Day Phase"
  phase_label.custom_minimum_size = Vector2(120, 0)
  panel.add_child(phase_label)

  var speed_1x = Button.new()
  speed_1x.text = "1x"
  speed_1x.pressed.connect(func(): time_system.set_speed(1.0))
  panel.add_child(speed_1x)

  var speed_2x = Button.new()
  speed_2x.text = "2x"
  speed_2x.pressed.connect(func(): time_system.set_speed(2.0))
  panel.add_child(speed_2x)

  var speed_3x = Button.new()
  speed_3x.text = "3x"
  speed_3x.pressed.connect(func(): time_system.set_speed(3.0))
  panel.add_child(speed_3x)

  var end_night_btn = Button.new()
  end_night_btn.name = "EndNightBtn"
  end_night_btn.text = "End Night"
  end_night_btn.visible = false
  end_night_btn.pressed.connect(func(): time_system.end_night())
  panel.add_child(end_night_btn)

  ui_layer.add_child(panel)

func _on_phase_changed(_is_day: bool) -> void:
  _update_time_display()
  _update_energy_display()

func _update_time_display() -> void:
  var controls = ui_layer.get_node_or_null("TimeControls")
  if not controls:
    return

  var phase_label = controls.get_node_or_null("PhaseLabel")
  var end_night_btn = controls.get_node_or_null("EndNightBtn")

  if phase_label:
    var phase_text = "Day" if time_system.is_day() else "Night"
    phase_label.text = "Day %d - %s Phase" % [time_system.current_day, phase_text]

  if end_night_btn:
    end_night_btn.visible = time_system.is_night()

  var panel = ui_layer.get_node_or_null("InfoPanel")
  if panel:
    var day_label = panel.get_node_or_null("VBoxContainer/DayLabel")
    if day_label:
      day_label.text = "Day %d" % time_system.current_day

func _process(_delta: float) -> void:
  if time_system:
    _update_time_display()
