class_name TopDownMovement
extends CharacterBody2D

@export var move_speed: float = 200.0

@export_group("Input Actions")
@export var action_up: String = "camera_up"
@export var action_down: String = "camera_down"
@export var action_left: String = "camera_left"
@export var action_right: String = "camera_right"

func _physics_process(_delta):
  var direction := Vector2.ZERO

  if Input.is_action_pressed(action_right):
    direction.x += 1
  if Input.is_action_pressed(action_left):
    direction.x -= 1
  if Input.is_action_pressed(action_down):
    direction.y += 1
  if Input.is_action_pressed(action_up):
    direction.y -= 1

  velocity = direction.normalized() * move_speed
  move_and_slide()
