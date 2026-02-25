extends Node2D

const CP := preload("res://_common/chiseled_paths.gd")

@export var grid_width: int = 30
@export var grid_height: int = 20
@export_range(0.1, 100.0, 0.1) var wiggliness: float = 2.0

@onready var tile_map: TileMapLayer = %TileMap
@onready var witness_map: TileMapLayer = %WitnessMap
@onready var open_map: TileMapLayer = %OpenMap
@onready var start_marker: Sprite2D = %StartMarker
@onready var end_marker: Sprite2D = %EndMarker
@onready var camera: Camera2D = %SmoothCamera
@onready var wiggliness_slider: HSlider = %WigglinessSlider
@onready var wiggliness_value: Label = %WigglinessValue
@onready var tooltip_label: Label = %TooltipLabel
@onready var timeline_slider: HSlider = %TimelineSlider
@onready var timeline_label: Label = %TimelineLabel
@onready var timeline_row: HBoxContainer = %TimelineRow
@onready var speed_slider: HSlider = %SpeedSlider
@onready var speed_value: Label = %SpeedValue

var start_cell := Vector2i(2, 10)
var end_cell := Vector2i(27, 10)

var animation_steps: Array[Dictionary] = []
var animation_index: int = -1
var playing := false
var steps_per_frame: float = 1.0
var step_accumulator: float = 0.0

var current_states: Array[int] = []
var current_witness_set: Dictionary = {}


func _ready() -> void:
  @warning_ignore("integer_division")
  camera.global_position = tile_map.map_to_local(Vector2i(grid_width / 2, grid_height / 2))
  wiggliness_slider.value = wiggliness
  wiggliness_value.text = "%.1f" % wiggliness
  wiggliness_slider.value_changed.connect(_on_wiggliness_changed)
  speed_slider.value_changed.connect(_on_speed_changed)
  timeline_slider.value_changed.connect(_on_timeline_changed)
  steps_per_frame = speed_slider.value
  speed_value.text = "%d" % int(steps_per_frame)
  timeline_row.visible = false
  _generate_and_render()


func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed:
    if event.button_index == MOUSE_BUTTON_LEFT:
      var cell := _mouse_to_cell()
      if _in_bounds(cell):
        start_cell = cell
        _stop_animation()
        _generate_and_render()
    elif event.button_index == MOUSE_BUTTON_RIGHT:
      var cell := _mouse_to_cell()
      if _in_bounds(cell):
        end_cell = cell
        _stop_animation()
        _generate_and_render()

  elif event is InputEventKey and event.pressed:
    if event.keycode == KEY_SPACE:
      if animation_steps.is_empty():
        _generate_and_render()
      else:
        playing = not playing
    elif event.keycode == KEY_Z:
      _start_animation()
    elif event.keycode == KEY_LEFT and not animation_steps.is_empty():
      playing = false
      _seek(animation_index - 1)
    elif event.keycode == KEY_RIGHT and not animation_steps.is_empty():
      playing = false
      _seek(animation_index + 1)


func _process(delta: float) -> void:
  _update_tooltip()
  if not playing or animation_steps.is_empty():
    return
  step_accumulator += steps_per_frame * delta * 60.0
  var advance := int(step_accumulator)
  step_accumulator -= advance
  if advance > 0:
    _seek(animation_index + advance)
    if animation_index >= animation_steps.size() - 1:
      playing = false


func _mouse_to_cell() -> Vector2i:
  return tile_map.local_to_map(tile_map.get_local_mouse_position())


func _in_bounds(cell: Vector2i) -> bool:
  return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height


func _generate_and_render() -> void:
  animation_steps = []
  playing = false
  timeline_row.visible = false
  var result := CP.generate(grid_width, grid_height, start_cell, end_cell, wiggliness)
  var forced: Array[Vector2i] = []
  forced.assign(result["forced"])
  current_states = result["states"]
  _build_witness_set(result["witness"])
  tile_map.clear()
  witness_map.clear()
  open_map.clear()
  tile_map.set_cells_terrain_connect(forced, 1, 0)
  _update_markers()


func _start_animation() -> void:
  animation_steps = CP.generate_steps(grid_width, grid_height, start_cell, end_cell, wiggliness)
  timeline_row.visible = true
  timeline_slider.max_value = animation_steps.size() - 1
  timeline_slider.value = 0
  animation_index = -1
  step_accumulator = 0.0
  _seek(0)
  playing = true


func _stop_animation() -> void:
  playing = false
  animation_steps = []
  timeline_row.visible = false
  witness_map.clear()
  open_map.clear()


func _seek(target: int) -> void:
  target = clampi(target, 0, animation_steps.size() - 1)
  if target == animation_index:
    return
  animation_index = target
  timeline_slider.set_value_no_signal(animation_index)
  _render_step(animation_steps[animation_index])


func _render_step(step: Dictionary) -> void:
  tile_map.clear()
  witness_map.clear()
  open_map.clear()

  var forced: Array[Vector2i] = []
  forced.assign(step["forced"])
  var witness: Array[Vector2i] = []
  witness.assign(step["witness"])
  var states: Array[int] = step["states"]

  current_states = states
  _build_witness_set(step["witness"])

  var open_cells: Array[Vector2i] = []
  for x in grid_width:
    for y in grid_height:
      if states[x * grid_height + y] == CP.CellState.OPEN:
        open_cells.append(Vector2i(x, y))

  tile_map.set_cells_terrain_connect(forced, 1, 0)
  witness_map.set_cells_terrain_connect(witness, 0, 0)
  if open_cells.size() > 0:
    open_map.set_cells_terrain_connect(open_cells, 1, 0)

  timeline_label.text = "Step %d / %d" % [animation_index, animation_steps.size() - 1]
  _update_markers()


func _build_witness_set(witness_cells: Array) -> void:
  current_witness_set.clear()
  for cell in witness_cells:
    current_witness_set[cell] = true


func _update_markers() -> void:
  start_marker.position = tile_map.map_to_local(start_cell)
  end_marker.position = tile_map.map_to_local(end_cell)


func _update_tooltip() -> void:
  var cell := _mouse_to_cell()

  if not _in_bounds(cell) or current_states.is_empty():
    tooltip_label.visible = false
    return

  tooltip_label.visible = true

  var idx := cell.x * grid_height + cell.y
  var state: int = current_states[idx]
  var on_witness: bool = current_witness_set.has(cell)
  var is_start: bool = cell == start_cell
  var is_end: bool = cell == end_cell

  var lines: PackedStringArray = []
  lines.append("(%d, %d)" % [cell.x, cell.y])
  lines.append("State: %s" % CP.state_name(state))
  if on_witness:
    lines.append("On witness path")
  if is_start:
    lines.append("START")
  if is_end:
    lines.append("END")

  tooltip_label.text = "\n".join(lines)
  var screen_pos := get_viewport().get_mouse_position()
  tooltip_label.position = screen_pos + Vector2(16, 16)


func _on_wiggliness_changed(value: float) -> void:
  wiggliness = value
  wiggliness_value.text = "%.1f" % value
  _stop_animation()
  _generate_and_render()


func _on_speed_changed(value: float) -> void:
  steps_per_frame = value
  speed_value.text = "%d" % int(value)


func _on_timeline_changed(value: float) -> void:
  playing = false
  _seek(int(value))
