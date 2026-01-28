extends Control

const ResourceSystemScript = preload("res://jan_28_2026/src/systems/resource_system.gd")
const BuildingSystemScript = preload("res://jan_28_2026/src/systems/building_system.gd")

@onready var game_world = %GameWorld
@onready var ui_layer: CanvasLayer = %UILayer

var resource_system: Node
var building_system: Node

# Building placement state
var selected_building_id: String = ""
var is_placing: bool = false

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

func _setup_ui() -> void:
  _create_building_toolbar()
  _create_info_panel()

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
  if building:
    print("Selected: ", building.building_id)

func _cancel_placement() -> void:
  is_placing = false
  selected_building_id = ""
  game_world.set_placement_mode(false, "")

func _update_energy_display() -> void:
  var panel = ui_layer.get_node_or_null("InfoPanel")
  if panel:
    var label = panel.get_node_or_null("VBoxContainer/EnergyLabel")
    if label:
      var gs = get_node("/root/GameState")
      label.text = "Energy: %d/%d" % [gs.current_energy, gs.max_energy]

func get_resource_system() -> Node:
  return resource_system

func get_building_system() -> Node:
  return building_system
