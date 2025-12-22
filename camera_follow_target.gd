extends Camera2D

@export var target: NodePath
@export var lerp_speed: float = 5.0
@export var chase_speed: float = 300.0
@export var max_speed: float = 500.0
@export var zoom_speed: float = 0.1

var min_zoom: float
var max_zoom: float

var target_node: Node2D

func _ready():
  if target:
    target_node = get_node(target)

  var default_zoom = zoom.x
  min_zoom = default_zoom * 0.5
  max_zoom = default_zoom * 2.0

func _physics_process(delta):
  if not target_node:
    return
  
  var target_position = target_node.global_position
  var distance = target_position - global_position
  
  var lerp_move = distance * lerp_speed * delta
  var chase_move = distance.normalized() * chase_speed * delta
  
  var total_move = lerp_move + chase_move
  total_move = total_move.limit_length(max_speed * delta)
  
  global_position += total_move


func _unhandled_input(event):
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
      zoom += Vector2.ONE * zoom_speed
      zoom = zoom.clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
      zoom -= Vector2.ONE * zoom_speed
      zoom = zoom.clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
