extends Node

enum PanelAnchor {
  TOP_LEFT, TOP_CENTER, TOP_RIGHT,
  CENTER_LEFT, CENTER_RIGHT,
  BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT
}

enum EdgeBehavior { CLAMP, FLIP, ALLOW_OFFSCREEN }

const _DEFAULT_CONTENT := preload("res://_common/default_tooltip_content.tscn")

class TooltipEntry:
  var source_node: Node
  var hover_node: Node
  var created_area: Area2D
  var content_scene: PackedScene
  var title: String
  var description: String
  var attachment_offset: Vector2
  var panel_anchor: int
  var edge_behavior: int
  var enter_callable: Callable
  var unregister_callable: Callable

var _layer: CanvasLayer
var _current_content: Control
var _active_entry: TooltipEntry
var _entries: Dictionary


func _get_layer() -> CanvasLayer:
  if _layer and is_instance_valid(_layer):
    return _layer
  _layer = CanvasLayer.new()
  _layer.layer = 50
  _layer.name = "TooltipLayer"
  get_tree().current_scene.add_child(_layer)
  return _layer


func _process(_delta: float) -> void:
  if not _current_content or not _active_entry:
    return
  var node := _active_entry.source_node
  if not is_instance_valid(node):
    hide()
    return
  var attach_screen := _get_screen_pos(node, _active_entry.attachment_offset)
  var pos := _anchor_panel(attach_screen, _active_entry.panel_anchor)
  pos = _apply_edge(pos, attach_screen, _active_entry)
  _current_content.position = pos


func _get_screen_pos(node: Node, offset: Vector2) -> Vector2:
  if node is Node2D:
    return get_viewport().get_canvas_transform() * ((node as Node2D).global_position + offset)
  elif node is Node3D:
    var cam := get_viewport().get_camera_3d()
    if not cam:
      return Vector2.ZERO
    return cam.unproject_position((node as Node3D).global_position) + offset
  elif node is Control:
    return (node as Control).global_position + offset
  return Vector2.ZERO


func _anchor_panel(attach: Vector2, anchor: int) -> Vector2:
  var s := _current_content.size
  match anchor:
    PanelAnchor.TOP_LEFT:      return attach
    PanelAnchor.TOP_CENTER:    return attach + Vector2(-s.x * 0.5, 0.0)
    PanelAnchor.TOP_RIGHT:     return attach + Vector2(-s.x, 0.0)
    PanelAnchor.CENTER_LEFT:   return attach + Vector2(0.0, -s.y * 0.5)
    PanelAnchor.CENTER_RIGHT:  return attach + Vector2(-s.x, -s.y * 0.5)
    PanelAnchor.BOTTOM_LEFT:   return attach + Vector2(0.0, -s.y)
    PanelAnchor.BOTTOM_CENTER: return attach + Vector2(-s.x * 0.5, -s.y)
    PanelAnchor.BOTTOM_RIGHT:  return attach + Vector2(-s.x, -s.y)
  return attach


func _apply_edge(pos: Vector2, attach: Vector2, entry: TooltipEntry) -> Vector2:
  var vp := get_viewport().get_visible_rect().size
  var ps := _current_content.size
  match entry.edge_behavior:
    EdgeBehavior.CLAMP:
      pos.x = clampf(pos.x, 0.0, vp.x - ps.x)
      pos.y = clampf(pos.y, 0.0, vp.y - ps.y)
    EdgeBehavior.FLIP:
      if pos.x + ps.x > vp.x:
        pos.x = attach.x - ps.x
      if pos.x < 0.0:
        pos.x = attach.x
      if pos.y + ps.y > vp.y:
        pos.y = attach.y - ps.y
      if pos.y < 0.0:
        pos.y = attach.y
  return pos


func _register_internal(node: Node, content_scene: PackedScene, title: String, description: String,
    attachment_offset: Vector2, panel_anchor: int, edge_behavior: int) -> void:
  if _entries.has(node):
    unregister(node)
  var entry := TooltipEntry.new()
  entry.source_node = node
  entry.content_scene = content_scene
  entry.title = title
  entry.description = description
  entry.attachment_offset = attachment_offset
  entry.panel_anchor = panel_anchor
  entry.edge_behavior = edge_behavior
  entry.enter_callable = _on_enter.bind(node)
  entry.unregister_callable = unregister.bind(node)
  var hover := _ensure_hover_node(node, entry)
  entry.hover_node = hover
  _entries[node] = entry
  hover.mouse_entered.connect(entry.enter_callable)
  hover.mouse_exited.connect(hide)
  node.tree_exiting.connect(entry.unregister_callable)


func _ensure_hover_node(node: Node, entry: TooltipEntry) -> Node:
  if node.has_signal("mouse_entered"):
    return node
  if node is Node2D:
    var area := Area2D.new()
    area.name = "_TooltipHoverArea"
    area.collision_mask = 0
    area.monitorable = false
    area.monitoring = false
    var col := CollisionShape2D.new()
    var rect := _get_local_rect(node)
    var shape := RectangleShape2D.new()
    shape.size = rect.size
    col.shape = shape
    col.position = rect.get_center()
    area.add_child(col)
    node.add_child.call_deferred(area)
    entry.created_area = area
    return area
  return node


func _get_local_rect(node: Node) -> Rect2:
  if node.has_method("get_rect"):
    return node.call("get_rect") as Rect2
  var combined := Rect2()
  var found := false
  for child in node.get_children():
    if child.has_method("get_rect"):
      var r: Rect2 = child.call("get_rect")
      r.position += (child as Node2D).position
      combined = r if not found else combined.merge(r)
      found = true
    elif child is CollisionShape2D and (child as CollisionShape2D).shape:
      var cs := child as CollisionShape2D
      var hw := _shape_half_size(cs.shape)
      var r := Rect2(cs.position - hw, hw * 2.0)
      combined = r if not found else combined.merge(r)
      found = true
  return combined if found else Rect2(-32.0, -32.0, 64.0, 64.0)


static func _shape_half_size(shape: Shape2D) -> Vector2:
  if shape is CircleShape2D:
    var r := (shape as CircleShape2D).radius
    return Vector2(r, r)
  if shape is RectangleShape2D:
    return (shape as RectangleShape2D).size * 0.5
  if shape is CapsuleShape2D:
    var cs := shape as CapsuleShape2D
    return Vector2(cs.radius, cs.height * 0.5 + cs.radius)
  return Vector2(32.0, 32.0)


func register(node: Node, title: String, description: String = "",
    attachment_offset: Vector2 = Vector2(48.0, 0.0),
    panel_anchor: int = PanelAnchor.CENTER_LEFT,
    edge_behavior: int = EdgeBehavior.FLIP) -> void:
  _register_internal(node, null, title, description, attachment_offset, panel_anchor, edge_behavior)


func register_custom(node: Node, content_scene: PackedScene,
    attachment_offset: Vector2 = Vector2(48.0, 0.0),
    panel_anchor: int = PanelAnchor.CENTER_LEFT,
    edge_behavior: int = EdgeBehavior.FLIP) -> void:
  _register_internal(node, content_scene, "", "", attachment_offset, panel_anchor, edge_behavior)


func unregister(node: Node) -> void:
  var entry: TooltipEntry = _entries.get(node)
  if not entry:
    return
  if _active_entry and _active_entry.source_node == node:
    hide()
  var hover := entry.hover_node
  if is_instance_valid(hover):
    if hover.mouse_entered.is_connected(entry.enter_callable):
      hover.mouse_entered.disconnect(entry.enter_callable)
    if hover.mouse_exited.is_connected(hide):
      hover.mouse_exited.disconnect(hide)
  if is_instance_valid(node):
    if node.tree_exiting.is_connected(entry.unregister_callable):
      node.tree_exiting.disconnect(entry.unregister_callable)
  if entry.created_area and is_instance_valid(entry.created_area):
    entry.created_area.queue_free()
  _entries.erase(node)


func _on_enter(node: Node) -> void:
  var entry: TooltipEntry = _entries.get(node)
  if not entry:
    return
  var scene := entry.content_scene if entry.content_scene else _DEFAULT_CONTENT
  var content: Control = scene.instantiate()
  if not entry.content_scene and content is DefaultTooltipContent:
    (content as DefaultTooltipContent).title = entry.title
    (content as DefaultTooltipContent).description = entry.description
  show_at(content, node, entry.attachment_offset, entry.panel_anchor, entry.edge_behavior)


func show_at(content: Control, world_pos_source: Node,
    attachment_offset: Vector2 = Vector2(48.0, 0.0),
    panel_anchor: int = PanelAnchor.CENTER_LEFT,
    edge_behavior: int = EdgeBehavior.FLIP) -> void:
  _get_layer()
  if _current_content and is_instance_valid(_current_content):
    _current_content.queue_free()
  _current_content = content
  content.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _layer.add_child(content)
  var entry := TooltipEntry.new()
  entry.source_node = world_pos_source
  entry.attachment_offset = attachment_offset
  entry.panel_anchor = panel_anchor
  entry.edge_behavior = edge_behavior
  _active_entry = entry


func hide() -> void:
  if _current_content and is_instance_valid(_current_content):
    _current_content.queue_free()
  _current_content = null
  _active_entry = null
