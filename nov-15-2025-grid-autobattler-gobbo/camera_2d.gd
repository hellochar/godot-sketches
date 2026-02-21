extends Camera2D
@export var pan_speed = 300.0

func _process(delta):
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
