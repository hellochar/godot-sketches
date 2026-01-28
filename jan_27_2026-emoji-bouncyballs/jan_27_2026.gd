extends Node2D

@export var smiley: Node2D
@export var polygon: Polygon2D

func _ready() -> void:
  for i in range(100):
    spawn_in_polygon()

func spawn(pos: Vector2) -> void:
  var instance = smiley.duplicate()
  instance.position = pos
  var norm_rand = (randf() + randf() + randf() + randf() + randf() + randf()) / 6.0
  add_child(instance)
  var scale = Vector2.ONE * pow(4, norm_rand * 2) * 0.25
  # find the collisionshape2d with a circleshape2d and set its radius
  var collider = instance.get_node("CollisionShape2D") as CollisionShape2D
  if collider and collider.shape is CircleShape2D:
    var duplicated_shape = collider.shape.duplicate() as CircleShape2D
    collider.shape = duplicated_shape
    collider.shape.radius *= scale.x
  # find the sprite and set its scale
  var sprite = instance.get_node("Sprite2D") as Sprite2D
  if sprite:
    sprite.scale *= scale
  # Utils.spring_pop(instance, 1.5, 0.5)

func _physics_process(delta: float) -> void:
  if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
    spawn(get_global_mouse_position())
  if Input.is_physical_key_pressed(KEY_SPACE):
    spawn_in_polygon()

func spawn_in_polygon() -> void:
  var random_point = Utils.get_random_point_in_polygon(polygon)
  spawn(random_point)

func _process(delta: float) -> void:
  pass
