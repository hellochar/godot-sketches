extends MeshInstance3D

@export var viewport_resolution := Vector2i(1024, 1024)
@export_group("Frustum")
@export var cull_near := 0.05
@export var cull_far := 50.0

@onready var _sub_viewport: SubViewport = $SubViewport
@onready var _mirror_cam: Camera3D = $SubViewport/Camera3D


func _ready() -> void:
  _sub_viewport.size = viewport_resolution
  var mat := mesh.surface_get_material(0) as StandardMaterial3D
  mat.albedo_texture = _sub_viewport.get_texture()


func _process(_delta: float) -> void:
  var main_camera := get_viewport().get_camera_3d()
  if not main_camera:
    return

  var mirror_normal := global_basis.z
  var mirror_pos := global_position

  # Reflect the player camera across the mirror plane
  var mirror_xform := _get_mirror_transform(mirror_normal, mirror_pos)
  _mirror_cam.global_transform = mirror_xform * main_camera.global_transform

  # Reorient to look perpendicular into the mirror surface
  var midpoint := (_mirror_cam.global_position + main_camera.global_position) / 2.0
  _mirror_cam.global_transform = _mirror_cam.global_transform.looking_at(
    midpoint, global_basis.y
  )

  # Compute off-axis frustum so mirror quad fills the SubViewport
  var cam_to_mirror := mirror_pos - _mirror_cam.global_position
  var near: float = abs(cam_to_mirror.dot(mirror_normal)) + cull_near
  var far := cam_to_mirror.length() + cull_far

  var local_offset := _mirror_cam.global_basis.inverse() * cam_to_mirror
  var frustum_offset := Vector2(local_offset.x, local_offset.y)
  var quad_size: Vector2 = (mesh as QuadMesh).size
  _mirror_cam.set_frustum(quad_size.x, frustum_offset, near, far)


# Householder reflection across a plane defined by normal and point.
static func _get_mirror_transform(normal: Vector3, offset: Vector3) -> Transform3D:
  var nx := normal.x
  var ny := normal.y
  var nz := normal.z
  var basis_x := Vector3(1 - 2*nx*nx, -2*nx*ny, -2*nx*nz)
  var basis_y := Vector3(-2*ny*nx, 1 - 2*ny*ny, -2*ny*nz)
  var basis_z := Vector3(-2*nz*nx, -2*nz*ny, 1 - 2*nz*nz)
  var origin := 2.0 * normal.dot(offset) * normal
  return Transform3D(basis_x, basis_y, basis_z, origin)
