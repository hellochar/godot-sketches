extends CanvasLayer

const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")

signal building_selected(building_id: String)
signal building_action_pressed(action: String, building: Node)

@export_group("UI Sizing")
@export var resource_panel_width: float = 180.0
@export var wellbeing_panel_width: float = 200.0
@export var building_button_size: Vector2 = Vector2(80, 50)
@export var toast_duration: float = 3.0
@export var toast_max_visible: int = 5

@export_group("Colors")
@export var wellbeing_high_color: Color = Color(0.3, 0.9, 0.3)
@export var wellbeing_medium_color: Color = Color(0.9, 0.9, 0.3)
@export var wellbeing_low_color: Color = Color(0.9, 0.3, 0.3)
@export var wellbeing_high_threshold: float = 70.0
@export var wellbeing_medium_threshold: float = 40.0
@export var affordable_color: Color = Color(1.0, 1.0, 1.0)
@export var unaffordable_color: Color = Color(0.5, 0.5, 0.5)
@export var positive_resource_color: Color = Color(0.5, 0.9, 0.5)
@export var negative_resource_color: Color = Color(0.9, 0.5, 0.5)
@export var neutral_resource_color: Color = Color(0.8, 0.8, 0.8)

@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")
@onready var config: Node = get_node("/root/Config")

var resource_system: Node
var building_system: Node
var worker_system: Node
var time_system: Node

var resource_labels: Dictionary = {}
var building_buttons: Dictionary = {}
var selected_building_node: Node = null
var toast_queue: Array = []
var active_toasts: Array = []

func _ready() -> void:
  event_bus.resource_total_changed.connect(_on_resource_total_changed)
  event_bus.energy_changed.connect(_on_energy_changed)
  event_bus.wellbeing_changed.connect(_on_wellbeing_changed)
  event_bus.building_placed.connect(_on_building_placed)
  event_bus.building_removed.connect(_on_building_removed)

func setup(p_resource_system: Node, p_building_system: Node, p_worker_system: Node, p_time_system: Node) -> void:
  resource_system = p_resource_system
  building_system = p_building_system
  worker_system = p_worker_system
  time_system = p_time_system
  _populate_building_toolbar()
  _update_all_resource_labels()
  _update_energy_display()
  _update_wellbeing_display()

func _process(_delta: float) -> void:
  if time_system:
    _update_time_display()
  _update_building_button_affordability()

func _populate_building_toolbar() -> void:
  var toolbar = %BuildingToolbar
  for child in toolbar.get_children():
    if child is Button:
      child.queue_free()

  var unlocked = building_system.get_unlocked_buildings()
  for building_id in unlocked:
    var btn = _create_building_button(building_id)
    toolbar.add_child(btn)
    building_buttons[building_id] = btn

func _create_building_button(building_id: String) -> Button:
  var def = BuildingDefs.get_definition(building_id)
  var btn = Button.new()
  btn.name = building_id
  btn.custom_minimum_size = building_button_size
  btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

  var vbox = VBoxContainer.new()
  vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

  var name_label = Label.new()
  name_label.text = def.get("name", building_id)
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  name_label.add_theme_font_size_override("font_size", 11)
  name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  vbox.add_child(name_label)

  var cost = def.get("build_cost", {})
  var energy = cost.get("energy", 0)
  if energy > 0:
    var cost_label = Label.new()
    cost_label.text = "%d Energy" % energy
    cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cost_label.add_theme_font_size_override("font_size", 9)
    cost_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
    cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_child(cost_label)

  btn.add_child(vbox)
  btn.tooltip_text = _get_building_tooltip(def)
  btn.pressed.connect(func(): building_selected.emit(building_id))
  return btn

func _get_building_tooltip(def: Dictionary) -> String:
  var lines: Array[String] = []
  lines.append(def.get("name", ""))
  lines.append(def.get("description", ""))

  var cost = def.get("build_cost", {})
  var energy = cost.get("energy", 0)
  if energy > 0:
    lines.append("")
    lines.append("Cost: %d Energy" % energy)

  if def.has("generates"):
    lines.append("Generates: %s" % def.get("generates", ""))

  if def.has("input") and def.has("output"):
    var inp = def.get("input", {})
    var out = def.get("output", {})
    var input_str = ", ".join(inp.keys().map(func(k): return "%d %s" % [inp[k], k]))
    var output_str = ", ".join(out.keys().map(func(k): return "%d %s" % [out[k], k]))
    lines.append("Converts: %s -> %s" % [input_str, output_str])

  return "\n".join(lines)

func _update_building_button_affordability() -> void:
  for building_id in building_buttons:
    var btn = building_buttons[building_id]
    var def = BuildingDefs.get_definition(building_id)
    var cost = def.get("build_cost", {})
    var energy = cost.get("energy", 0)
    var can_afford = game_state.current_energy >= energy
    btn.disabled = not can_afford
    btn.modulate = affordable_color if can_afford else unaffordable_color

func _update_all_resource_labels() -> void:
  var container = %ResourceList
  for child in container.get_children():
    child.queue_free()
  resource_labels.clear()

  var resource_types = resource_system.get_all_resource_types()
  for res_type in resource_types:
    var hbox = HBoxContainer.new()

    var color_rect = ColorRect.new()
    color_rect.custom_minimum_size = Vector2(12, 12)
    color_rect.color = res_type.color
    hbox.add_child(color_rect)

    var label = Label.new()
    label.text = "%s: %d" % [res_type.display_name, game_state.get_resource_total(res_type.id)]
    label.add_theme_font_size_override("font_size", 12)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    if res_type.is_positive_emotion():
      label.add_theme_color_override("font_color", positive_resource_color)
    elif res_type.is_negative_emotion():
      label.add_theme_color_override("font_color", negative_resource_color)
    else:
      label.add_theme_color_override("font_color", neutral_resource_color)

    hbox.add_child(label)
    hbox.tooltip_text = res_type.description
    container.add_child(hbox)
    resource_labels[res_type.id] = label

func _on_resource_total_changed(resource_type: String, new_total: int) -> void:
  if resource_labels.has(resource_type):
    var res_type = resource_system.get_resource_type(resource_type)
    if res_type:
      resource_labels[resource_type].text = "%s: %d" % [res_type.display_name, new_total]

func _update_energy_display() -> void:
  var energy_label = %EnergyLabel
  energy_label.text = "Energy: %d/%d" % [game_state.current_energy, game_state.max_energy]

  var attention_label = %AttentionLabel
  if worker_system:
    attention_label.text = "Attention: %.1f/%.1f" % [worker_system.attention_used, worker_system.attention_pool]

func _on_energy_changed(_old: int, _new: int) -> void:
  _update_energy_display()

func _update_wellbeing_display() -> void:
  var wellbeing_value = %WellbeingValue
  var wellbeing_bar = %WellbeingBar
  var value = game_state.wellbeing

  wellbeing_value.text = "%d" % int(value)
  wellbeing_bar.value = value

  var color = _get_wellbeing_color(value)
  wellbeing_value.add_theme_color_override("font_color", color)
  var style = wellbeing_bar.get_theme_stylebox("fill").duplicate()
  style.bg_color = color
  wellbeing_bar.add_theme_stylebox_override("fill", style)

func _get_wellbeing_color(value: float) -> Color:
  if value >= wellbeing_high_threshold:
    return wellbeing_high_color
  elif value >= wellbeing_medium_threshold:
    return wellbeing_medium_color
  else:
    return wellbeing_low_color

func _on_wellbeing_changed(_old: float, _new: float) -> void:
  _update_wellbeing_display()

func _update_time_display() -> void:
  var phase_label = %PhaseLabel
  var time_label = %TimeLabel
  var day_label = %DayLabel

  var phase_text = "Day" if time_system.is_day() else "Night"
  phase_label.text = "%s Phase" % phase_text
  day_label.text = "Day %d" % time_system.current_day
  time_label.text = _format_clock_time(time_system.get_phase_progress(), time_system.is_day())

  var end_night_btn = %EndNightBtn
  end_night_btn.visible = time_system.is_night()

func _format_clock_time(progress: float, is_day: bool) -> String:
  var day_hours = 16.0
  var night_hours = 8.0
  var day_start = 6
  var night_start = 22

  var total_hours = day_hours if is_day else night_hours
  var start_hour = day_start if is_day else night_start
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

func _on_building_placed(_building: Node, _coord: Vector2i) -> void:
  _update_energy_display()

func _on_building_removed(_building: Node, _coord: Vector2i) -> void:
  _update_energy_display()

func show_building_info(building: Node) -> void:
  selected_building_node = building
  var panel = %BuildingInfoPanel
  panel.visible = true

  var def = building.definition
  %BuildingNameLabel.text = def.get("name", building.building_id)
  %BuildingDescLabel.text = def.get("description", "")

  _update_building_storage_display(building)
  _update_building_workers_display(building)
  _update_building_status_display(building)

func _update_building_storage_display(building: Node) -> void:
  var storage_container = %StorageContainer
  for child in storage_container.get_children():
    child.queue_free()

  if building.storage_capacity <= 0:
    var label = Label.new()
    label.text = "No storage"
    label.add_theme_font_size_override("font_size", 11)
    storage_container.add_child(label)
    return

  var total = 0
  for res_id in building.storage:
    total += building.storage[res_id]

  var header = Label.new()
  header.text = "Storage (%d/%d):" % [total, building.storage_capacity]
  header.add_theme_font_size_override("font_size", 12)
  storage_container.add_child(header)

  if building.storage.is_empty() or total == 0:
    var empty_label = Label.new()
    empty_label.text = "  Empty"
    empty_label.add_theme_font_size_override("font_size", 11)
    empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    storage_container.add_child(empty_label)
  else:
    for res_id in building.storage:
      var amount = building.storage[res_id]
      if amount > 0:
        var item_label = Label.new()
        item_label.text = "  %s: %d" % [res_id.capitalize(), amount]
        item_label.add_theme_font_size_override("font_size", 11)
        storage_container.add_child(item_label)

func _update_building_workers_display(building: Node) -> void:
  var workers_container = %WorkersContainer
  for child in workers_container.get_children():
    child.queue_free()

  var assigned_workers: Array = []
  for worker in game_state.active_workers:
    if worker.source_building == building or worker.dest_building == building:
      assigned_workers.append(worker)

  var header = Label.new()
  header.text = "Workers (%d):" % assigned_workers.size()
  header.add_theme_font_size_override("font_size", 12)
  workers_container.add_child(header)

  if assigned_workers.is_empty():
    var none_label = Label.new()
    none_label.text = "  None assigned"
    none_label.add_theme_font_size_override("font_size", 11)
    none_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    workers_container.add_child(none_label)
  else:
    for worker in assigned_workers:
      var worker_label = Label.new()
      var desc = _get_worker_short_description(worker, building)
      worker_label.text = "  " + desc
      worker_label.add_theme_font_size_override("font_size", 11)
      workers_container.add_child(worker_label)

func _get_worker_short_description(worker: Node, context_building: Node) -> String:
  if worker.job_type == "transport":
    if worker.source_building == context_building:
      var dest = worker.dest_building.building_id if worker.dest_building else "?"
      return "Transporting %s to %s" % [worker.resource_type, dest]
    else:
      var src = worker.source_building.building_id if worker.source_building else "?"
      return "Bringing %s from %s" % [worker.resource_type, src]
  elif worker.job_type == "operate":
    return "Operating"
  return "Idle"

func _update_building_status_display(building: Node) -> void:
  var status_label = %BuildingStatusLabel
  var Building = preload("res://jan_28_2026-psychebuilder-ai/src/entities/building.gd")

  match building.current_status:
    Building.Status.IDLE:
      status_label.text = "Status: Idle"
    Building.Status.PROCESSING:
      status_label.text = "Status: Processing (%.1fs)" % building.process_timer
    Building.Status.WAITING_INPUT:
      status_label.text = "Status: Waiting for input"
    Building.Status.WAITING_WORKER:
      status_label.text = "Status: Waiting for worker"
    Building.Status.STORAGE_FULL:
      status_label.text = "Status: Storage full"
    Building.Status.GENERATING:
      status_label.text = "Status: Generating"
    _:
      status_label.text = "Status: Unknown"

func hide_building_info() -> void:
  selected_building_node = null
  var panel = %BuildingInfoPanel
  panel.visible = false

func show_toast(message: String, toast_type: String = "info") -> void:
  toast_queue.append({"message": message, "type": toast_type})
  _process_toast_queue()

func _process_toast_queue() -> void:
  while toast_queue.size() > 0 and active_toasts.size() < toast_max_visible:
    var toast_data = toast_queue.pop_front()
    _create_toast(toast_data.message, toast_data.type)

func _create_toast(message: String, toast_type: String) -> void:
  var toast_container = %ToastContainer

  var panel = PanelContainer.new()
  panel.modulate.a = 0.0

  var margin = MarginContainer.new()
  margin.add_theme_constant_override("margin_left", 10)
  margin.add_theme_constant_override("margin_right", 10)
  margin.add_theme_constant_override("margin_top", 5)
  margin.add_theme_constant_override("margin_bottom", 5)
  panel.add_child(margin)

  var label = Label.new()
  label.text = message
  label.add_theme_font_size_override("font_size", 12)

  match toast_type:
    "success":
      label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
    "warning":
      label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))
    "error":
      label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
    _:
      label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

  margin.add_child(label)
  toast_container.add_child(panel)
  active_toasts.append(panel)

  var tween = create_tween()
  tween.tween_property(panel, "modulate:a", 1.0, 0.2)
  tween.tween_interval(toast_duration)
  tween.tween_property(panel, "modulate:a", 0.0, 0.3)
  tween.tween_callback(func():
    active_toasts.erase(panel)
    panel.queue_free()
    _process_toast_queue()
  )

func update_instructions(text: String) -> void:
  %InstructionsLabel.text = text

func connect_time_controls(p_time_system: Node) -> void:
  %Speed1xBtn.pressed.connect(func(): p_time_system.set_speed(1.0))
  %Speed2xBtn.pressed.connect(func(): p_time_system.set_speed(2.0))
  %Speed3xBtn.pressed.connect(func(): p_time_system.set_speed(3.0))
  %EndNightBtn.pressed.connect(func(): p_time_system.end_night())

func _on_assign_worker_pressed() -> void:
  if selected_building_node:
    building_action_pressed.emit("assign_worker", selected_building_node)

func _on_remove_building_pressed() -> void:
  if selected_building_node:
    building_action_pressed.emit("remove_building", selected_building_node)
    hide_building_info()
