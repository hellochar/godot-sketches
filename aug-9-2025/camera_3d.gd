extends Camera3D
@export var speed := 5.0

func _process(delta):
	var direction := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= Vector3.FORWARD
	if Input.is_action_pressed("move_back"):
		direction += Vector3.FORWARD
	if Input.is_action_pressed("move_left"):
		direction -= Vector3.RIGHT
	if Input.is_action_pressed("move_right"):
		direction += Vector3.RIGHT
	if Input.is_action_pressed("move_up"):
		direction += Vector3.UP
	if Input.is_action_pressed("move_down"):
		direction -= Vector3.UP

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		direction = global_transform.basis * direction
		translate(direction * speed * delta)

	# if Input.is_action_pressed("mouse_right"):
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var mouse_motion = Input.get_last_mouse_velocity()
	var sensitivity := 0.00005
	rotate_y(-mouse_motion.x * sensitivity)
	rotate_z(mouse_motion.y * sensitivity)
	# else:
	#     Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
