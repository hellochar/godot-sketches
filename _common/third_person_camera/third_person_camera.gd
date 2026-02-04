extends Node3D

enum FramingStyle { CENTERED, OVER_SHOULDER_LEFT, OVER_SHOULDER_RIGHT }

@export_node_path("Node3D") var target_path: NodePath
var target: Node3D

@export_group("Distance")
@export var min_distance: float = 1.5
@export var max_distance: float = 6.0
@export var default_distance: float = 3.5
@export var zoom_speed: float = 0.5

@export_group("Rotation")
@export var mouse_sensitivity: float = 0.003
@export var pitch_min: float = -80.0
@export var pitch_max: float = 60.0

@export_group("Smoothing")
@export var rotation_smoothing: float = 15.0
@export var y_tracking_smoothing: float = 5.0

@export_group("Framing")
@export var framing_style: FramingStyle = FramingStyle.OVER_SHOULDER_RIGHT
@export var shoulder_offset: float = 0.5
@export var vertical_offset: float = 0.8

@export_group("Auto-Recenter")
@export var auto_recenter_enabled: bool = false
@export var auto_recenter_delay: float = 2.0
@export var auto_recenter_speed: float = 2.0

@export_group("Dynamic FOV")
@export var base_fov: float = 75.0
@export var max_fov_boost: float = 10.0
@export var fov_speed_threshold: float = 8.0
@export var fov_smoothing: float = 5.0

var target_yaw: float = 0.0
var target_pitch: float = 0.0
var current_yaw: float = 0.0
var current_pitch: float = 0.0
var current_distance: float = 3.5
var time_since_input: float = 0.0
var smoothed_target_y: float = 0.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

func _ready() -> void:
  add_to_group("third_person_camera")
  top_level = true
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  current_distance = default_distance
  spring_arm.spring_length = current_distance

  target_pitch = deg_to_rad(-20.0)
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

  if auto_recenter_enabled and time_since_input > auto_recenter_delay:
    var player_forward = -target.global_basis.z
    var target_angle = atan2(player_forward.x, player_forward.z)
    target_yaw = lerpf(target_yaw, target_angle, auto_recenter_speed * delta)

  current_yaw = lerpf(current_yaw, target_yaw, rotation_smoothing * delta)
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

func recenter_camera() -> void:
  if target:
    var player_forward = -target.global_basis.z
    target_yaw = atan2(player_forward.x, player_forward.z)
    target_pitch = deg_to_rad(-20.0)

func set_framing(style: FramingStyle) -> void:
  framing_style = style

func set_target(new_target: Node3D) -> void:
  target = new_target
  if target:
    _initialize_from_target()
