extends Area2D

signal interacted

@export var interaction_radius: float = 50.0
@export var highlight_color: Color = Color(1, 1, 0.5, 0.3)
@export var target_sprite: NodePath
@export var highlight_shader: ShaderMaterial

var player_in_range: bool = false
var player_ref: Node2D = null
var _sprite_node: CanvasItem = null
var _original_material: Material = null

func _ready():
  var collision = CollisionShape2D.new()
  var shape = CircleShape2D.new()
  shape.radius = interaction_radius
  collision.shape = shape
  add_child(collision)

  body_entered.connect(_on_body_entered)
  body_exited.connect(_on_body_exited)

  if target_sprite:
    _sprite_node = get_node_or_null(target_sprite)
    if _sprite_node:
      _original_material = _sprite_node.material

func _unhandled_input(event):
  if player_in_range and event.is_action_pressed("interact"):
    interacted.emit()
    get_viewport().set_input_as_handled()

func _draw() -> void:
  pass
  # if player_in_range:
  #   draw_circle(Vector2.ZERO, interaction_radius, highlight_color, false)

func _on_body_entered(body: Node2D):
  if body.is_in_group("player"):
    player_in_range = true
    player_ref = body
    _apply_highlight(true)
    queue_redraw()

func _on_body_exited(body: Node2D):
  if body == player_ref:
    player_in_range = false
    player_ref = null
    _apply_highlight(false)
    queue_redraw()

func _apply_highlight(enabled: bool):
  if _sprite_node and highlight_shader:
    if enabled:
      _sprite_node.material = highlight_shader
    else:
      _sprite_node.material = _original_material
