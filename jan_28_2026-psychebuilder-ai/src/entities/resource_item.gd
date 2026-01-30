extends Node2D

var resource_type: Resource  # ResourceType
var amount: int = 1
var carried_by: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

static var circle_texture: ImageTexture

func _ready() -> void:
  if not circle_texture:
    circle_texture = _create_circle_texture()
  sprite.texture = circle_texture
  if resource_type:
    _update_visuals()

static func _create_circle_texture() -> ImageTexture:
  var size = 32
  var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
  var center = Vector2(size / 2.0, size / 2.0)
  var radius = size / 2.0 - 2

  for x in range(size):
    for y in range(size):
      var dist = Vector2(x, y).distance_to(center)
      if dist <= radius:
        var alpha = 1.0 - smoothstep(radius - 2, radius, dist)
        image.set_pixel(x, y, Color(1, 1, 1, alpha))
      else:
        image.set_pixel(x, y, Color(0, 0, 0, 0))

  var texture = ImageTexture.create_from_image(image)
  return texture

static func smoothstep(edge0: float, edge1: float, x: float) -> float:
  var t = clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
  return t * t * (3.0 - 2.0 * t)

func initialize(p_resource_type: Resource, p_amount: int = 1) -> void:
  resource_type = p_resource_type
  amount = p_amount
  if is_inside_tree():
    _update_visuals()

func _update_visuals() -> void:
  if not resource_type:
    return

  modulate = resource_type.color

  if label:
    if amount > 1:
      label.text = str(amount)
      label.visible = true
    else:
      label.visible = false

func get_resource_id() -> String:
  return resource_type.id if resource_type else ""

func decay(rate_multiplier: float = 1.0) -> int:
  if not resource_type or resource_type.decay_rate <= 0:
    return 0

  var decay_amount = int(amount * resource_type.decay_rate * rate_multiplier)
  if decay_amount < 1 and randf() < resource_type.decay_rate * rate_multiplier:
    decay_amount = 1

  amount -= decay_amount
  _update_visuals()
  return decay_amount

func is_depleted() -> bool:
  return amount <= 0

func add_amount(delta: int) -> int:
  var max_stack = resource_type.stack_size if resource_type else 10
  var can_add = mini(delta, max_stack - amount)
  amount += can_add
  _update_visuals()
  return delta - can_add

func remove_amount(delta: int) -> int:
  var can_remove = mini(delta, amount)
  amount -= can_remove
  _update_visuals()
  return can_remove

func set_carried(worker: Node) -> void:
  carried_by = worker

func is_carried() -> bool:
  return carried_by != null
