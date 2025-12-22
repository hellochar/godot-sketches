extends Camera2D

@export var pan_speed: float = 500.0
@export var zoom_speed: float = 0.1

var min_zoom: float
var max_zoom: float

func _ready():
  var default_zoom = zoom.x
  min_zoom = default_zoom * 0.5
  max_zoom = default_zoom * 2.0

func _physics_process(delta):
  var direction = Vector2.ZERO
  
  if Input.is_action_pressed("camera_right"):
    direction.x += 1
  if Input.is_action_pressed("camera_left"):
    direction.x -= 1
  if Input.is_action_pressed("camera_down"):
    direction.y += 1
  if Input.is_action_pressed("camera_up"):
    direction.y -= 1
  
  position += direction.normalized() * pan_speed * delta

func _unhandled_input(event):
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
      zoom += Vector2.ONE * zoom_speed
      zoom = zoom.clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
      zoom -= Vector2.ONE * zoom_speed
      zoom = zoom.clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
