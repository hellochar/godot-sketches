extends Node3D

enum FramingStyle { CENTERED, OVER_SHOULDER_LEFT, OVER_SHOULDER_RIGHT }

@export_node_path("Node3D") var target_path: NodePath
var target: Node3D

@export_group("Distance")
@export var min_distance: float = 1.5
@export var max_distance: float = 6.0
@export var default_distance: float = 4.0
@export var zoom_speed: float = 0.5

@export_group("Rotation")
@export var mouse_sensitivity: float = 0.003
@export var pitch_min: float = -80.0
@export var pitch_max: float = 60.0
@export var default_pitch: float = -20.0

@export_group("Smoothing")
@export var rotation_smoothing: float = 15.0
@export var y_tracking_smoothing: float = 5.0

@export_group("Framing")
@export var framing_style: FramingStyle = FramingStyle.OVER_SHOULDER_LEFT
@export var shoulder_offset: float = 0.5
@export var vertical_offset: float = 1.4

@export_group("Auto-Recenter")
@export var auto_recenter_enabled: bool = true
@export var auto_recenter_delay: float = 1.5
@export var auto_recenter_speed: float = 2.0

@export_group("Dynamic FOV")
@export var base_fov: float = 75.0
@export var max_fov_boost: float = 10.0
@export var fov_speed_threshold: float = 8.0
@export var fov_smoothing: float = 5.0

@export_group("Screen Shake")
@export var shake_decay: float = 5.0
@export var shake_max_offset: float = 0.5
@export var shake_max_roll: float = 0.1

var target_yaw: float = 0.0
var target_pitch: float = 0.0
var current_yaw: float = 0.0
var current_pitch: float = 0.0
var current_distance: float = 3.5
var time_since_input: float = 0.0
var smoothed_target_y: float = 0.0

var trauma: float = 0.0
var focus_target: Node3D = null
var focus_blend: float = 0.0
var focus_speed: float = 3.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

func _ready() -> void:
  add_to_group("third_person_camera")
  top_level = true
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  current_distance = default_distance
  spring_arm.spring_length = current_distance

  target_pitch = deg_to_rad(default_pitch)
  current_pitch = target_pitch

  if target_path:
    target = get_node(target_path)
  if target:
    _initialize_from_target()

func _initialize_from_target() -> void:
  smoothed_target_y = target.global_position.y
  global_position = target.global_position + Vector3(0, vertical_offset, 0)
  var player_forward = -target.global_basis.z
  target_yaw = atan2(player_forward.x, player_forward.z)
  current_yaw = target_yaw

  var player_body = target as CharacterBody3D
  if player_body:
    spring_arm.add_excluded_object(player_body.get_rid())

func _input(event: InputEvent) -> void:
  if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
    target_yaw -= event.relative.x * mouse_sensitivity
    target_pitch -= event.relative.y * mouse_sensitivity
    target_pitch = clampf(target_pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
    time_since_input = 0.0

  if event is InputEventMouseButton:
    var mb = event as InputEventMouseButton
    if mb.pressed:
      match mb.button_index:
        MOUSE_BUTTON_WHEEL_UP:
          current_distance = maxf(min_distance, current_distance - zoom_speed)
          time_since_input = 0.0
        MOUSE_BUTTON_WHEEL_DOWN:
          current_distance = minf(max_distance, current_distance + zoom_speed)
          time_since_input = 0.0
        MOUSE_BUTTON_MIDDLE:
          recenter_camera()
          time_since_input = 0.0

  if event.is_action_pressed("ui_cancel"):
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
      Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
      Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
  if not target:
    return

  time_since_input += delta
  _update_auto_recenter(delta)
  _update_focus_target(delta)

  current_yaw = lerp_angle(current_yaw, target_yaw, rotation_smoothing * delta)
  current_pitch = lerpf(current_pitch, target_pitch, rotation_smoothing * delta)

  rotation.y = current_yaw
  rotation.x = current_pitch

  spring_arm.spring_length = current_distance

  var target_y = target.global_position.y
  smoothed_target_y = lerpf(smoothed_target_y, target_y, y_tracking_smoothing * delta)
  global_position.x = target.global_position.x
  global_position.z = target.global_position.z
  global_position.y = smoothed_target_y + vertical_offset

  _apply_framing_offset()
  _update_dynamic_fov(delta)
  _apply_screen_shake(delta)

func _update_auto_recenter(delta: float) -> void:
  if not auto_recenter_enabled or time_since_input <= auto_recenter_delay:
    return

  var player_forward = -target.global_basis.z
  var desired_yaw = atan2(player_forward.x, player_forward.z)
  target_yaw = lerp_angle(target_yaw, desired_yaw, auto_recenter_speed * delta)

func _update_focus_target(delta: float) -> void:
  if focus_target and is_instance_valid(focus_target):
    focus_blend = minf(focus_blend + focus_speed * delta, 1.0)
    var to_focus = focus_target.global_position - global_position
    var focus_yaw = atan2(to_focus.x, to_focus.z)
    var focus_pitch = -atan2(to_focus.y, Vector2(to_focus.x, to_focus.z).length())
    target_yaw = lerp_angle(target_yaw, focus_yaw, focus_blend)
    target_pitch = lerpf(target_pitch, focus_pitch, focus_blend)
  else:
    focus_blend = maxf(focus_blend - focus_speed * delta, 0.0)

func _apply_framing_offset() -> void:
  var offset_x: float = 0.0
  match framing_style:
    FramingStyle.OVER_SHOULDER_LEFT:
      offset_x = -shoulder_offset
    FramingStyle.OVER_SHOULDER_RIGHT:
      offset_x = shoulder_offset
    FramingStyle.CENTERED:
      offset_x = 0.0

  camera.h_offset = offset_x

func _update_dynamic_fov(delta: float) -> void:
  var velocity := Vector3.ZERO
  if target is CharacterBody3D:
    velocity = (target as CharacterBody3D).velocity

  var horizontal_speed = Vector2(velocity.x, velocity.z).length()
  var speed_factor = clampf(horizontal_speed / fov_speed_threshold, 0.0, 1.0)
  var target_fov = base_fov + max_fov_boost * speed_factor
  camera.fov = lerpf(camera.fov, target_fov, fov_smoothing * delta)

func _apply_screen_shake(delta: float) -> void:
  trauma = maxf(trauma - shake_decay * delta, 0.0)
  if trauma <= 0.0:
    camera.h_offset = _get_base_h_offset()
    camera.v_offset = 0.0
    camera.rotation.z = 0.0
    return

  var shake_intensity = trauma * trauma
  var noise_x = randf_range(-1.0, 1.0)
  var noise_y = randf_range(-1.0, 1.0)
  var noise_z = randf_range(-1.0, 1.0)

  camera.h_offset = _get_base_h_offset() + noise_x * shake_max_offset * shake_intensity
  camera.v_offset = noise_y * shake_max_offset * shake_intensity
  camera.rotation.z = noise_z * shake_max_roll * shake_intensity

func _get_base_h_offset() -> float:
  match framing_style:
    FramingStyle.OVER_SHOULDER_LEFT:
      return -shoulder_offset
    FramingStyle.OVER_SHOULDER_RIGHT:
      return shoulder_offset
    _:
      return 0.0

func recenter_camera() -> void:
  if target:
    var player_forward = -target.global_basis.z
    target_yaw = atan2(player_forward.x, player_forward.z)
    target_pitch = deg_to_rad(default_pitch)

func set_framing(style: FramingStyle) -> void:
  framing_style = style

func set_target(new_target: Node3D) -> void:
  target = new_target
  if target:
    _initialize_from_target()

func add_trauma(amount: float) -> void:
  trauma = minf(trauma + amount, 1.0)

func shake(intensity: float = 0.5) -> void:
  add_trauma(intensity)

func focus_on(new_focus: Node3D, speed: float = 3.0) -> void:
  focus_target = new_focus
  focus_speed = speed
  focus_blend = 0.0

func clear_focus() -> void:
  focus_target = null
