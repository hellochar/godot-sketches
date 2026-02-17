extends Node

@onready var mirror: MeshInstance3D = %Mirror2
@onready var mirror_cam: Camera3D = %Mirror2Camera
@onready var main_camera: Camera3D = %ThirdPersonCamera/SpringArm3D/Camera3D

@export var cull_near := 0.05
@export var cull_far := 50.0

func _ready() -> void:
  pass

func _process(_delta: float) -> void:
  var mirror_normal := mirror.global_basis.z
  var mirror_pos := mirror.global_position

  # Step 1: Reflect the player camera across the mirror plane using a
  # Householder reflection matrix. This mirrors both position and orientation
  # in one transform multiplication.
  var mirror_xform := _get_mirror_transform(mirror_normal, mirror_pos)
  mirror_cam.global_transform = mirror_xform * main_camera.global_transform

  # Step 2: Reorient the mirror camera to look perpendicular into the mirror.
  # The midpoint between mirror_cam and main_camera lies on the mirror plane.
  # This aligns the near plane with the mirror surface so set_frustum works.
  var midpoint := (mirror_cam.global_position + main_camera.global_position) / 2.0
  mirror_cam.global_transform = mirror_cam.global_transform.looking_at(
    midpoint, mirror.global_basis.y
  )

  # Step 3: Compute the off-axis frustum so the mirror quad exactly fills
  # the SubViewport. The offset is the camera-to-mirror-center vector in
  # camera-local space.
  var cam_to_mirror := mirror_pos - mirror_cam.global_position
  var near: float = abs(cam_to_mirror.dot(mirror_normal)) + cull_near
  var far := cam_to_mirror.length() + cull_far

  var local_offset := mirror_cam.global_basis.inverse() * cam_to_mirror
  var frustum_offset := Vector2(local_offset.x, local_offset.y)
  var quad_size: Vector2 = (mirror.mesh as QuadMesh).size
  mirror_cam.set_frustum(quad_size.x, frustum_offset, near, far)


# Householder reflection: reflects any transform across a plane defined by
# its normal and a point on the plane. Returns a Transform3D that, when
# multiplied with another transform, mirrors it across the plane.
static func _get_mirror_transform(normal: Vector3, offset: Vector3) -> Transform3D:
  var nx := normal.x
  var ny := normal.y
  var nz := normal.z
  var basis_x := Vector3(1 - 2*nx*nx, -2*nx*ny, -2*nx*nz)
  var basis_y := Vector3(-2*ny*nx, 1 - 2*ny*ny, -2*ny*nz)
  var basis_z := Vector3(-2*nz*nx, -2*nz*ny, 1 - 2*nz*nz)
  var origin := 2.0 * normal.dot(offset) * normal
  return Transform3D(basis_x, basis_y, basis_z, origin)
