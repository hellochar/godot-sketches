class_name SmoothCamera
extends Camera2D

@export_group("Follow Target")
@export var target: Node2D
@export var lerp_speed: float = 5.0
@export var chase_speed: float = 300.0
@export var max_speed: float = 500.0

@export_group("Panning")
@export var pan_speed: float = 200.0
@export var drag_pan_enabled: bool = false
@export_enum("Left:1", "Right:2", "Middle:3") var drag_pan_button: int = MOUSE_BUTTON_RIGHT
@export var edge_pan_enabled: bool = false
@export var edge_pan_margin: float = 25.0
@export var edge_pan_speed: float = 200.0
@export var clamp_mouse_to_viewport: bool = false

@export_group("Zoom")
@export var zoom_enabled: bool = true
@export var zoom_speed: float = 0.1
@export var min_zoom_multiplier: float = 0.5
@export var max_zoom_multiplier: float = 2.0

var _min_zoom: float
var _max_zoom: float
var _drag_panning: bool = false
var _edge_pan_active: bool = true

func _validate_property(property: Dictionary) -> void:
  if property.name in ["pan_speed"] and target:
    property.usage = PROPERTY_USAGE_NO_EDITOR
  if property.name in ["drag_pan_button"] and not drag_pan_enabled:
    property.usage = PROPERTY_USAGE_NO_EDITOR
  if property.name in ["edge_pan_margin", "edge_pan_speed", "clamp_mouse_to_viewport"] and not edge_pan_enabled:
    property.usage = PROPERTY_USAGE_NO_EDITOR

func _ready() -> void:
  var default_zoom := zoom.x
  _min_zoom = default_zoom * min_zoom_multiplier
  _max_zoom = default_zoom * max_zoom_multiplier

  if target:
    global_position = target.global_position

  if clamp_mouse_to_viewport and edge_pan_enabled:
    _confine_mouse()
  get_viewport().focus_entered.connect(_on_focus_entered)
  get_viewport().focus_exited.connect(_on_focus_exited)

func _physics_process(delta: float) -> void:
  _follow_target_process(delta)
  _pan_process(delta)
  _edge_pan_process(delta)

func _follow_target_process(delta: float) -> void:
  if not target:
    return

  var target_position = target.global_position
  var distance = target_position - global_position

  var lerp_move = distance * lerp_speed * delta
  var chase_move = distance.normalized() * chase_speed * delta

  var total_move = lerp_move + chase_move
  total_move = total_move.limit_length(max_speed * delta)

  global_position += total_move

func _pan_process(delta: float) -> void:
  if target:
    return
  var input_vector = Vector2.ZERO
  input_vector.x = Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")
  input_vector.y = Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")
  if input_vector != Vector2.ZERO:
    input_vector = input_vector.normalized()
    global_position += input_vector * pan_speed * delta

func _edge_pan_process(delta: float) -> void:
  if not edge_pan_enabled or not _edge_pan_active:
    return
  var viewport := get_viewport()
  var mouse_pos := viewport.get_mouse_position()
  var size := viewport.get_visible_rect().size
  var direction := Vector2.ZERO
  if mouse_pos.x < edge_pan_margin:
    direction.x -= 1.0
  elif mouse_pos.x > size.x - edge_pan_margin:
    direction.x += 1.0
  if mouse_pos.y < edge_pan_margin:
    direction.y -= 1.0
  elif mouse_pos.y > size.y - edge_pan_margin:
    direction.y += 1.0
  if direction != Vector2.ZERO:
    global_position += direction.normalized() * edge_pan_speed * delta

func _confine_mouse() -> void:
  Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _release_mouse() -> void:
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_focus_entered() -> void:
  if clamp_mouse_to_viewport and edge_pan_enabled:
    _confine_mouse()
  _edge_pan_active = false
  get_tree().create_timer(0.1).timeout.connect(func() -> void: _edge_pan_active = true)

func _on_focus_exited() -> void:
  _edge_pan_active = false
  if clamp_mouse_to_viewport:
    _release_mouse()

func _unhandled_input(event: InputEvent) -> void:
  if drag_pan_enabled and event is InputEventMouseButton:
    if event.button_index == drag_pan_button:
      _drag_panning = event.pressed

  if drag_pan_enabled and event is InputEventMouseMotion and _drag_panning:
    global_position -= event.relative / zoom
    reset_smoothing()
    get_viewport().set_input_as_handled()

  if not zoom_enabled:
    return
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
      zoom += Vector2.ONE * zoom_speed
      zoom = zoom.clamp(Vector2.ONE * _min_zoom, Vector2.ONE * _max_zoom)
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
      zoom -= Vector2.ONE * zoom_speed
      zoom = zoom.clamp(Vector2.ONE * _min_zoom, Vector2.ONE * _max_zoom)

func set_target(new_target: Node2D, snap: bool = false):
  target = new_target
  if snap and target:
    global_position = target.global_position
