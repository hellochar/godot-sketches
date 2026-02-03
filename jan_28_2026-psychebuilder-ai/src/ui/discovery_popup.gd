extends PanelContainer

signal building_chosen(building_id: String)
signal dismissed()

const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var choices_container: HBoxContainer = %ChoicesContainer
@onready var skip_button: Button = %SkipButton
@onready var game_state: Node = get_node("/root/GameState")

var time_system: Node
var building_options: Array = []
var recommended_building: String = ""

func _ready() -> void:
  skip_button.pressed.connect(_on_skip_pressed)
  visible = false

func show_discovery(options: Array, p_time_system: Node = null) -> void:
  time_system = p_time_system
  building_options = options
  recommended_building = _determine_recommendation(options)

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

  visible = true

  if time_system:
    time_system.set_paused(true)

func _determine_recommendation(options: Array) -> String:
  var negative_total = game_state.get_resource_total("grief") + game_state.get_resource_total("anxiety") + game_state.get_resource_total("worry")
  var processor_count = 0
  var habit_count = 0
  var coping_count = 0

  for building in game_state.active_buildings:
    if building.has_behavior(BuildingDefs.Behavior.PROCESSOR):
      processor_count += 1
    if building.has_behavior(BuildingDefs.Behavior.HABIT):
      habit_count += 1
    if building.has_behavior(BuildingDefs.Behavior.COPING):
      coping_count += 1

  for building_id in options:
    var def = BuildingDefs.get_definition(building_id)
    var behaviors = def.get("behaviors", [])

    if negative_total > 10 and behaviors.has(BuildingDefs.Behavior.PROCESSOR):
      return building_id
    if negative_total > 15 and behaviors.has(BuildingDefs.Behavior.COPING):
      return building_id
    if processor_count < 2 and behaviors.has(BuildingDefs.Behavior.PROCESSOR):
      return building_id
    if habit_count < 2 and behaviors.has(BuildingDefs.Behavior.HABIT):
      return building_id

  return ""

func _get_recommendation_text(building_id: String, def: Dictionary) -> String:
  var behaviors = def.get("behaviors", [])
  var negative_total = game_state.get_resource_total("grief") + game_state.get_resource_total("anxiety") + game_state.get_resource_total("worry")

  if behaviors.has(BuildingDefs.Behavior.PROCESSOR):
    if negative_total > 10:
      return "Good for processing negative emotions"
    return "Converts resources into useful forms"
  if behaviors.has(BuildingDefs.Behavior.GENERATOR):
    return "Generates resources passively"
  if behaviors.has(BuildingDefs.Behavior.HABIT):
    return "Provides daily bonuses"
  if behaviors.has(BuildingDefs.Behavior.COPING):
    return "Activates during emotional crises"
  return ""

func _get_stats_text(def: Dictionary) -> String:
  var lines: Array[String] = []

  if def.has("generates"):
    lines.append("Generates: %s" % def.get("generates", ""))
  if def.has("input") and def.has("output"):
    var inp = def.get("input", {})
    var out = def.get("output", {})
    lines.append("Converts: %s → %s" % [", ".join(inp.keys()), ", ".join(out.keys())])
  if def.has("storage_capacity"):
    var cap = def.get("storage_capacity", 0)
    if cap > 0:
      lines.append("Storage: %d" % cap)

  return "\n".join(lines)

func _create_option_panel(building_id: String, def: Dictionary, index: int) -> Control:
  var panel = PanelContainer.new()
  panel.custom_minimum_size = Vector2(200, 260)

  var is_recommended = building_id == recommended_building
  if is_recommended:
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.15, 0.15, 0.2, 1)
    style.border_color = Color(0.3, 0.9, 0.4, 0.8)
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.border_width_left = 2
    style.border_width_right = 2
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    panel.add_theme_stylebox_override("panel", style)

  var vbox = VBoxContainer.new()
  vbox.add_theme_constant_override("separation", 8)
  panel.add_child(vbox)

  var margin = MarginContainer.new()
  margin.add_theme_constant_override("margin_left", 10)
  margin.add_theme_constant_override("margin_right", 10)
  margin.add_theme_constant_override("margin_top", 10)
  margin.add_theme_constant_override("margin_bottom", 10)

  var inner_vbox = VBoxContainer.new()
  inner_vbox.add_theme_constant_override("separation", 4)

  if is_recommended:
    var rec_label = Label.new()
    rec_label.text = "★ Recommended"
    rec_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rec_label.add_theme_font_size_override("font_size", 10)
    rec_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
    inner_vbox.add_child(rec_label)

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
  desc_label.custom_minimum_size.y = 40
  inner_vbox.add_child(desc_label)

  var stats_text = _get_stats_text(def)
  if stats_text != "":
    var stats_label = Label.new()
    stats_label.text = stats_text
    stats_label.add_theme_font_size_override("font_size", 10)
    stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
    inner_vbox.add_child(stats_label)

  var hint_text = _get_recommendation_text(building_id, def)
  if hint_text != "":
    var hint_label = Label.new()
    hint_label.text = hint_text
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.add_theme_font_size_override("font_size", 10)
    hint_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
    inner_vbox.add_child(hint_label)

  var spacer = Control.new()
  spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
  inner_vbox.add_child(spacer)

  var choose_btn = Button.new()
  choose_btn.text = "Choose"
  choose_btn.pressed.connect(_on_choice_pressed.bind(building_id))
  inner_vbox.add_child(choose_btn)

  margin.add_child(inner_vbox)
  panel.add_child(margin)

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
