extends Node2D

const CP := preload("res://_common/chiseled_paths.gd")

@export var grid_width: int = 30
@export var grid_height: int = 20
@export_range(0.1, 100.0, 0.1) var wiggliness: float = 2.0

@onready var tile_map: TileMapLayer = %TileMap
@onready var witness_map: TileMapLayer = %WitnessMap
@onready var open_map: TileMapLayer = %OpenMap
@onready var markers: Node2D = %Markers
@onready var camera: Camera2D = %SmoothCamera
@onready var wiggliness_slider: HSlider = %WigglinessSlider
@onready var wiggliness_value: Label = %WigglinessValue
@onready var tooltip_label: Label = %TooltipLabel
@onready var timeline_slider: HSlider = %TimelineSlider
@onready var timeline_label: Label = %TimelineLabel
@onready var timeline_row: HBoxContainer = %TimelineRow
@onready var speed_slider: HSlider = %SpeedSlider
@onready var speed_value: Label = %SpeedValue
@onready var ui_scaler: UIScaler = %UIScaler

var points: Array[Vector2i] = [Vector2i(2, 10), Vector2i(27, 10)]

var animation_steps: Array[Dictionary] = []
var animation_index: int = -1
var playing := false
var frame_interval: float = 0.1
var step_accumulator: float = 0.0

var current_states: Array[int] = []
var current_witness_set: Dictionary = {}
var current_close_order: Array[int] = []
var current_total_steps: int = 0
var heatmap_enabled := false

@export var _marker_texture: Texture2D
@export var grid_border_color := Color(1, 1, 1, 0.3)
@export var grid_border_width := 2.0


func _ready() -> void:
  @warning_ignore("integer_division")
  camera.global_position = tile_map.map_to_local(Vector2i(grid_width / 2, grid_height / 2))
  camera.reset_smoothing()
  wiggliness_slider.value = wiggliness
  wiggliness_value.text = "%.2f" % wiggliness
  wiggliness_slider.value_changed.connect(_on_wiggliness_changed)
  speed_slider.value_changed.connect(_on_speed_changed)
  timeline_slider.value_changed.connect(_on_timeline_changed)
  frame_interval = speed_slider.min_value * speed_slider.max_value / speed_slider.value
  speed_value.text = "%d ms" % int(frame_interval * 1000.0)
  timeline_row.visible = false
  _generate_and_render()


func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed:
    if event.button_index == MOUSE_BUTTON_LEFT:
      var cell := _mouse_to_cell()
      if _in_bounds(cell):
        var idx := points.find(cell)
        if idx >= 0:
          if points.size() > 2:
            points.remove_at(idx)
        else:
          points.append(cell)
        _stop_animation()
        _generate_and_render()

  elif event is InputEventKey and event.pressed:
    if event.keycode == KEY_SPACE:
      if animation_steps.is_empty():
        _start_animation()
      elif animation_index >= animation_steps.size() - 1:
        _seek(0)
        playing = true
      else:
        playing = not playing
    elif event.keycode == KEY_R:
      var was_animating := not animation_steps.is_empty()
      _stop_animation()
      _generate_and_render()
      if was_animating:
        _start_animation()
    elif event.keycode == KEY_H:
      heatmap_enabled = not heatmap_enabled
      queue_redraw()
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
  step_accumulator += delta
  var advance := 0
  while step_accumulator >= frame_interval:
    step_accumulator -= frame_interval
    advance += 1
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
  var result := CP.generate(grid_width, grid_height, points, wiggliness)
  var forced: Array[Vector2i] = []
  forced.assign(result["forced"])
  current_states = result["states"]
  current_close_order = result["close_order"]
  current_total_steps = result["total_steps"]
  _build_witness_set(result["witness"])
  tile_map.clear()
  witness_map.clear()
  open_map.clear()
  tile_map.set_cells_terrain_connect(forced, 1, 0)
  _update_markers()
  queue_redraw()

func _draw() -> void:
  _draw_grid_boundary()
  _draw_heatmap()


func _draw_grid_boundary() -> void:
  var tile_size := Vector2(tile_map.tile_set.tile_size)
  var top_left := tile_map.map_to_local(Vector2i.ZERO) - tile_size / 2.0
  var bottom_right := tile_map.map_to_local(Vector2i(grid_width - 1, grid_height - 1)) + tile_size / 2.0
  var rect := Rect2(top_left, bottom_right - top_left)
  draw_rect(rect, grid_border_color, false, grid_border_width)


func _draw_heatmap() -> void:
  if not heatmap_enabled or current_close_order.is_empty() or current_total_steps <= 0:
    return
  var tile_size := Vector2(tile_map.tile_set.tile_size)
  var max_step := current_total_steps - 1
  var animating := not animation_steps.is_empty()
  for x in grid_width:
    for y in grid_height:
      var idx := x * grid_height + y
      var step := current_close_order[idx]
      if step < 0:
        continue
      if animating and step > animation_index:
        continue
      var t := float(step) / float(max_step) if max_step > 0 else 0.0
      var color := Color(t, t, t)
      var pos := tile_map.map_to_local(Vector2i(x, y))
      draw_rect(Rect2(pos - tile_size / 2.0, tile_size), color)


func _start_animation() -> void:
  animation_steps = CP.generate_steps(grid_width, grid_height, points, wiggliness)
  _build_close_order_from_steps()
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
  queue_redraw()


func _build_close_order_from_steps() -> void:
  current_close_order.resize(grid_width * grid_height)
  current_close_order.fill(-1)
  current_total_steps = animation_steps.size() - 1
  for i in range(1, animation_steps.size()):
    var prev_states: Array[int] = animation_steps[i - 1]["states"]
    var curr_states: Array[int] = animation_steps[i]["states"]
    for idx in prev_states.size():
      if prev_states[idx] == CP.CellState.OPEN and curr_states[idx] != CP.CellState.OPEN:
        current_close_order[idx] = i - 1


func _build_witness_set(witness_cells: Array) -> void:
  current_witness_set.clear()
  for cell in witness_cells:
    current_witness_set[cell] = true


func _update_markers() -> void:
  for child in markers.get_children():
    child.queue_free()
  for p in points:
    var sprite := Sprite2D.new()
    sprite.texture = _marker_texture
    sprite.modulate = Color(1, 1, 1, 0.9)
    sprite.position = tile_map.map_to_local(p)
    markers.add_child(sprite)


func _update_tooltip() -> void:
  var cell := _mouse_to_cell()

  if not _in_bounds(cell) or current_states.is_empty():
    tooltip_label.visible = false
    return

  tooltip_label.visible = true

  var idx := cell.x * grid_height + cell.y
  var state: int = current_states[idx]
  var on_witness: bool = current_witness_set.has(cell)
  var point_idx := points.find(cell)

  var lines: PackedStringArray = []
  lines.append("(%d, %d)" % [cell.x, cell.y])
  lines.append("State: %s" % CP.state_name(state))
  if not current_close_order.is_empty():
    var close_step := current_close_order[idx]
    if close_step >= 0:
      lines.append("Closed at step %d / %d" % [close_step, current_total_steps])
  if on_witness:
    lines.append("On witness tree")
  if point_idx >= 0:
    lines.append("POINT %d" % point_idx)

  tooltip_label.text = "\n".join(lines)
  var screen_pos := get_viewport().get_mouse_position()
  tooltip_label.position = (screen_pos + Vector2(32, 0)) / ui_scaler.ui_scale


func _on_wiggliness_changed(value: float) -> void:
  wiggliness = value
  wiggliness_value.text = "%.2f" % value
  _stop_animation()
  _generate_and_render()


func _on_speed_changed(value: float) -> void:
  frame_interval = speed_slider.min_value * speed_slider.max_value / value
  speed_value.text = "%d ms" % int(frame_interval * 1000.0)


func _on_timeline_changed(value: float) -> void:
  playing = false
  _seek(int(value))
