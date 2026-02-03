extends PanelContainer

signal building_chosen(building_id: String)
signal dismissed()

const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var choices_container: HBoxContainer = %ChoicesContainer
@onready var skip_button: Button = %SkipButton

var time_system: Node
var building_options: Array = []

func _ready() -> void:
  skip_button.pressed.connect(_on_skip_pressed)
  visible = false

func show_discovery(options: Array, p_time_system: Node = null) -> void:
  time_system = p_time_system
  building_options = options

  title_label.text = "New Discovery"
  description_label.text = "You've gained new insight! Choose a building to unlock:"

  for child in choices_container.get_children():
    child.queue_free()

  for i in range(options.size()):
    var building_id = options[i]
    var def = BuildingDefs.get_definition(building_id)
    if def.is_empty():
      continue

    var option_panel = _create_option_panel(building_id, def, i)
    choices_container.add_child(option_panel)

  if choices_container.get_child_count() == 0:
    dismissed.emit()
    return

  visible = true

  if time_system:
    time_system.set_paused(true)

func _create_option_panel(building_id: String, def: Dictionary, _index: int) -> Control:
  var panel = PanelContainer.new()
  panel.custom_minimum_size = Vector2(180, 200)

  var margin = MarginContainer.new()
  margin.add_theme_constant_override("margin_left", 10)
  margin.add_theme_constant_override("margin_right", 10)
  margin.add_theme_constant_override("margin_top", 10)
  margin.add_theme_constant_override("margin_bottom", 10)
  panel.add_child(margin)

  var inner_vbox = VBoxContainer.new()
  inner_vbox.add_theme_constant_override("separation", 6)
  margin.add_child(inner_vbox)

  var color_rect = ColorRect.new()
  color_rect.custom_minimum_size = Vector2(40, 40)
  color_rect.color = def.get("color", Color.WHITE)
  color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
  inner_vbox.add_child(color_rect)

  var name_label = Label.new()
  name_label.text = def.get("name", building_id)
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  name_label.add_theme_font_size_override("font_size", 14)
  inner_vbox.add_child(name_label)

  var desc_label = Label.new()
  desc_label.text = def.get("description", "")
  desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  desc_label.add_theme_font_size_override("font_size", 11)
  desc_label.custom_minimum_size.y = 60
  inner_vbox.add_child(desc_label)

  var spacer = Control.new()
  spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
  inner_vbox.add_child(spacer)

  var choose_btn = Button.new()
  choose_btn.text = "Choose"
  choose_btn.pressed.connect(_on_choice_pressed.bind(building_id))
  inner_vbox.add_child(choose_btn)

  return panel

func _on_choice_pressed(building_id: String) -> void:
  building_chosen.emit(building_id)
  _close_popup()

func _on_skip_pressed() -> void:
  dismissed.emit()
  _close_popup()

func _close_popup() -> void:
  visible = false

  if time_system:
    time_system.set_paused(false)

  building_options = []

func _unhandled_input(event: InputEvent) -> void:
  if not visible:
    return

  if event is InputEventKey:
    var key = event as InputEventKey
    if key.pressed and key.keycode == KEY_ESCAPE:
      _on_skip_pressed()
