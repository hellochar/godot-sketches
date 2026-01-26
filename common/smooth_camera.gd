class_name SmoothCamera
extends Camera2D

@export_group("Follow Target")
@export var target: Node2D
@export var lerp_speed: float = 5.0
@export var chase_speed: float = 300.0
@export var max_speed: float = 500.0

@export_group("Zoom")
@export var zoom_enabled: bool = true
@export var zoom_speed: float = 0.1
@export var min_zoom_multiplier: float = 0.5
@export var max_zoom_multiplier: float = 2.0

var _min_zoom: float
var _max_zoom: float

func _ready():
  var default_zoom = zoom.x
  _min_zoom = default_zoom * min_zoom_multiplier
  _max_zoom = default_zoom * max_zoom_multiplier

  if target:
    global_position = target.global_position

func _physics_process(delta):
  if not target:
    return

  var target_position = target.global_position
  var distance = target_position - global_position

  var lerp_move = distance * lerp_speed * delta
  var chase_move = distance.normalized() * chase_speed * delta

  var total_move = lerp_move + chase_move
  total_move = total_move.limit_length(max_speed * delta)

  global_position += total_move

func _unhandled_input(event):
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
