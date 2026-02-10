extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var rotation_speed: float = 10.0
@export var camera_pivot: Node3D

func _physics_process(delta: float) -> void:
  if not is_on_floor():
    velocity += get_gravity() * delta

  if Input.is_action_just_pressed("ui_accept") and is_on_floor():
    velocity.y = jump_velocity

  var input_dir := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")

  var camera_forward := -camera_pivot.global_basis.z
  camera_forward.y = 0
  camera_forward = camera_forward.normalized()
  var camera_right := camera_pivot.global_basis.x
  camera_right.y = 0
  camera_right = camera_right.normalized()

  var direction := (camera_right * input_dir.x + camera_forward * -input_dir.y).normalized()

  if direction:
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    var target_angle := atan2(direction.x, direction.z)
    rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
  else:
    velocity.x = move_toward(velocity.x, 0, speed)
    velocity.z = move_toward(velocity.z, 0, speed)

  move_and_slide()
