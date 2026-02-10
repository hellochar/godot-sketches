extends Camera3D
@export var speed := 5.0
@export var sensitivity := 0.002

func _process(delta):
	var direction := Vector3.ZERO
	if Input.is_action_pressed("camera_up"):
		direction += Vector3.FORWARD
	if Input.is_action_pressed("camera_down"):
		direction -= Vector3.FORWARD
	if Input.is_action_pressed("camera_left"):
		direction -= Vector3.RIGHT
	if Input.is_action_pressed("camera_right"):
		direction += Vector3.RIGHT
	if Input.is_action_pressed("camera_ascend"):
		direction += Vector3.UP
	if Input.is_action_pressed("camera_descend"):
		direction -= Vector3.UP

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		translate_object_local(direction * speed * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * sensitivity
		rotation.x -= event.relative.y * sensitivity
		rotation.x = clamp(rotation.x, -PI / 2, PI / 2)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
