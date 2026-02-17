extends Node

@onready var mirror: MeshInstance3D = %Mirror2
@onready var mirror_cam: Camera3D = %Mirror2Camera
@onready var main_camera: Camera3D = %ThirdPersonCamera/SpringArm3D/Camera3D

func _ready() -> void:
  pass

func _process(_delta: float) -> void:
  var mirror_normal := mirror.global_basis.z
  var mirror_pos := mirror.global_position
  var cam_pos := main_camera.global_position

  # goal - reflect camera position and facing along the mirror plane
  # how? well, for the position, we basically want to move cam_pos
  # along the normal backwards, until it's at the same distance to the
  # plane as it is now, just reversed.
  # dist to plane

  var dist_to_plane := mirror_normal.dot(cam_pos - mirror_pos)
  var mirror_cam_pos := cam_pos - mirror_normal * dist_to_plane * 2.0

  # that flips the position. now we must reflect the rotation along the normal
  # a rotation is defined with 3 axes - forward, up, left
  # we can simply reflect forward and up
  # then call look_at which will set all three axes.

  var cam_forward := -main_camera.global_basis.z
  var mirror_cam_forward := cam_forward - mirror_normal * mirror_normal.dot(cam_forward) * 2.0

  var cam_up := main_camera.global_basis.y
  var mirror_cam_up := cam_up - mirror_normal * mirror_normal.dot(cam_up) * 2.0

  mirror_cam.global_position = mirror_cam_pos
  mirror_cam.look_at(mirror_cam_pos + mirror_cam_forward, mirror_cam_up)

  # --- Option 1: simple - match FOV, clip at mirror plane ---
  #_apply_simple_projection(dist_to_plane)

  # --- Option 2: oblique frustum - mirror quad exactly fills viewport ---
  _apply_oblique_frustum()


# Match main camera FOV and set near clip to the mirror surface.
# Cheap but the reflection slides around because the viewport-to-quad
# mapping doesn't account for the viewer's off-axis position.
func _apply_simple_projection(dist_to_plane: float) -> void:
  mirror_cam.set_perspective(main_camera.fov, abs(dist_to_plane), 100.0)


# Compute an off-axis frustum so the mirror quad's four corners map exactly
# to the SubViewport edges. This makes the texture-to-quad mapping 1:1 —
# no sliding, no off-center shift.
#
# Steps:
#   1. Get mirror quad corners in mirror-camera-local space
#   2. Use the closest corner's depth as the near plane
#   3. Project all corners onto that near plane
#   4. Fit the frustum (size + offset) to those projected bounds
#
# Limitation: set_frustum uses one size for both axes (adjusted by aspect).
# With a square viewport + square quad this is exact. Non-square would need
# a custom projection matrix.
func _apply_oblique_frustum() -> void:
  var quad_size: Vector2 = (mirror.mesh as QuadMesh).size
  var half := quad_size / 2.0

  var corners_local := [
    Vector3(-half.x, -half.y, 0.0),
    Vector3(half.x, -half.y, 0.0),
    Vector3(half.x, half.y, 0.0),
    Vector3(-half.x, half.y, 0.0),
  ]

  var cam_inv := mirror_cam.global_transform.affine_inverse()
  var cam_corners: Array[Vector3] = []
  var near_z := INF

  for c: Vector3 in corners_local:
    var cam_space := cam_inv * (mirror.global_transform * c)
    cam_corners.append(cam_space)
    near_z = min(near_z, -cam_space.z)

  near_z = max(near_z, 0.01)

  # Project each corner onto the near plane
  var left := INF
  var right := -INF
  var bottom := INF
  var top := -INF

  for cs: Vector3 in cam_corners:
    var proj_x := cs.x * near_z / (-cs.z)
    var proj_y := cs.y * near_z / (-cs.z)
    left = min(left, proj_x)
    right = max(right, proj_x)
    bottom = min(bottom, proj_y)
    top = max(top, proj_y)

  var size: float = max(top - bottom, right - left)
  var offset := Vector2((left + right) / 2.0, (top + bottom) / 2.0)

  mirror_cam.set_frustum(size, offset, near_z, 100.0)
