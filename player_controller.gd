extends CharacterBody2D

@export var move_speed: float = 200.0

@export var plants: int = 0

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
  
  velocity = direction.normalized() * move_speed
  move_and_slide()
