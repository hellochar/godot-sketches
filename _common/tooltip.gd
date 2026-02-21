## Drop-in tooltip component. Add as a child of any Area2D, Control, or Node3D.
## Registers the parent node with the Tooltip autoload on _ready.
class_name TooltipComponent
extends Node

@export var title: String = ""
@export var description: String = ""
## If set, instantiated as tooltip content instead of the default title/description layout.
@export var custom_content: PackedScene

@export_group("Positioning")
## When true, computes attachment_offset from the parent's bounding box automatically.
@export var auto_attachment_offset: bool = true
## World-space offset from parent origin to the tooltip attachment point.
## Only used when auto_attachment_offset is false.
@export var attachment_offset: Vector2 = Vector2(48.0, 0.0)
## Which corner of the tooltip panel aligns to the attachment point.
@export_enum("Top Left", "Top Center", "Top Right", "Center Left", "Center Right",
    "Bottom Left", "Bottom Center", "Bottom Right")
var panel_anchor: int = Tooltip.PanelAnchor.CENTER_LEFT

@export_group("Edge Behavior")
@export_enum("Clamp", "Flip", "Allow Offscreen")
var edge_behavior: int = Tooltip.EdgeBehavior.FLIP

var _registered_parent: Node


func _ready() -> void:
  _registered_parent = get_parent()
  var offset := _compute_offset(_registered_parent) if auto_attachment_offset else attachment_offset
  if custom_content:
    Tooltip.register_custom(_registered_parent, custom_content, offset, panel_anchor, edge_behavior)
  else:
    Tooltip.register(_registered_parent, title, description, offset, panel_anchor, edge_behavior)


func _exit_tree() -> void:
  if _registered_parent:
    Tooltip.unregister(_registered_parent)
    _registered_parent = null


func _compute_offset(node: Node) -> Vector2:
  var right_x := _node_right_edge(node)
  if node is Node2D:
    right_x *= absf((node as Node2D).global_scale.x)
  return Vector2(right_x + 8.0, 0.0)


func _node_right_edge(node: Node) -> float:
  if node is Control:
    return (node as Control).size.x
  if node.has_method("get_rect"):
    return (node.call("get_rect") as Rect2).end.x
  var max_x := 0.0
  for child in node.get_children():
    if child.has_method("get_rect"):
      max_x = maxf(max_x, (child.call("get_rect") as Rect2).end.x)
    elif child is CollisionShape2D:
      var cs := child as CollisionShape2D
      if cs.shape:
        max_x = maxf(max_x, cs.position.x + _shape_half_width(cs.shape))
  return max_x if max_x > 0.0 else 32.0


static func _shape_half_width(shape: Shape2D) -> float:
  if shape is CircleShape2D:
    return (shape as CircleShape2D).radius
  if shape is RectangleShape2D:
    return (shape as RectangleShape2D).size.x * 0.5
  if shape is CapsuleShape2D:
    return (shape as CapsuleShape2D).radius
  return 32.0
