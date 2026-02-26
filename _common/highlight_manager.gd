extends Node

const _OUTLINE_SHADER := preload("res://_common/shaders/outline.gdshader")
const _SILHOUETTE_SHADER := preload("res://_common/shaders/silhouette.gdshader")

enum Style { OUTLINE, SILHOUETTE }

class HighlightEntry:
  var source_node: Node
  var hover_node: Node
  var created_area: Area2D
  var style: int
  var outline_color: Color
  var outline_width: float
  var outline_pattern: int
  var enter_callable: Callable
  var exit_callable: Callable
  var unregister_callable: Callable
  var original_material: Material

var _entries: Dictionary
var _active_entry: HighlightEntry
var _highlight_sprite: Sprite2D
var _highlight_material: ShaderMaterial
var _active_is_control: bool


func register(node: Node, style: int, color: Color, width: float, pattern: int) -> void:
  call_deferred("_register_impl", node, style, color, width, pattern)


func _register_impl(node: Node, style: int, color: Color, width: float, pattern: int) -> void:
  if not is_instance_valid(node) or not node.is_inside_tree():
    return
  if _entries.has(node):
    unregister(node)
  var entry := HighlightEntry.new()
  entry.source_node = node
  entry.style = style
  entry.outline_color = color
  entry.outline_width = width
  entry.outline_pattern = pattern
  entry.enter_callable = _on_mouse_entered.bind(node)
  entry.exit_callable = _on_mouse_exited.bind(node)
  entry.unregister_callable = unregister.bind(node)
  var hover := _ensure_hover_node(node, entry)
  entry.hover_node = hover
  _entries[node] = entry
  hover.mouse_entered.connect(entry.enter_callable)
  hover.mouse_exited.connect(entry.exit_callable)
  node.tree_exiting.connect(entry.unregister_callable)


func unregister(node: Node) -> void:
  var entry: HighlightEntry = _entries.get(node)
  if not entry:
    return
  if _active_entry and _active_entry.source_node == node:
    _hide_highlight()
  var hover := entry.hover_node
  if is_instance_valid(hover):
    if hover.mouse_entered.is_connected(entry.enter_callable):
      hover.mouse_entered.disconnect(entry.enter_callable)
    if hover.mouse_exited.is_connected(entry.exit_callable):
      hover.mouse_exited.disconnect(entry.exit_callable)
  if is_instance_valid(node):
    if node.tree_exiting.is_connected(entry.unregister_callable):
      node.tree_exiting.disconnect(entry.unregister_callable)
  if entry.created_area and is_instance_valid(entry.created_area):
    entry.created_area.queue_free()
  _entries.erase(node)


func _ensure_hover_node(node: Node, entry: HighlightEntry) -> Node:
  if node is CollisionObject2D or node is Control:
    return node
  # Prefer hover areas created by tooltip/highlight systems for consistent triggering
  for child in node.get_children():
    if child is Area2D and (child.name == "_TooltipHoverArea" or child.name == "_HighlightHoverArea"):
      return child
  for child in node.get_children():
    if child is Area2D:
      return child
  if node is Node2D:
    var area := Area2D.new()
    area.name = "_HighlightHoverArea"
    area.collision_mask = 0
    area.monitorable = false
    area.monitoring = false
    area.input_pickable = true
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


func _on_mouse_entered(node: Node) -> void:
  var entry: HighlightEntry = _entries.get(node)
  if not entry:
    return
  if _active_entry:
    _hide_highlight()
  _show_highlight(entry)


func _on_mouse_exited(node: Node) -> void:
  if _active_entry and _active_entry.source_node == node:
    _hide_highlight()


func _show_highlight(entry: HighlightEntry) -> void:
  _active_entry = entry
  var node := entry.source_node
  if node is Sprite2D:
    _show_sprite2d_highlight(node as Sprite2D, entry)
  elif node is AnimatedSprite2D:
    _show_animated_sprite_highlight(node as AnimatedSprite2D, entry)
  elif node is Control:
    _show_control_highlight(node as Control, entry)


func _show_sprite2d_highlight(target: Sprite2D, entry: HighlightEntry) -> void:
  var sprite := _get_highlight_sprite(entry)
  if entry.style == Style.SILHOUETTE:
    sprite.texture = target.texture
    sprite.region_enabled = target.region_enabled
    sprite.region_rect = target.region_rect
    sprite.hframes = target.hframes
    sprite.vframes = target.vframes
    sprite.frame = target.frame
  else:
    sprite.texture = _extract_texture(target.texture)
    sprite.region_enabled = false
    sprite.hframes = 1
    sprite.vframes = 1
    sprite.frame = 0
  sprite.offset = target.offset
  sprite.centered = target.centered
  sprite.flip_h = target.flip_h
  sprite.flip_v = target.flip_v
  _attach_sprite(sprite, target, entry)
  _active_is_control = false


func _show_animated_sprite_highlight(target: AnimatedSprite2D, entry: HighlightEntry) -> void:
  var sprite := _get_highlight_sprite(entry)
  var anim := target.animation
  var frame_idx := target.frame
  if target.sprite_frames and target.sprite_frames.has_animation(anim):
    var frame_tex := target.sprite_frames.get_frame_texture(anim, frame_idx)
    if entry.style == Style.SILHOUETTE:
      sprite.texture = frame_tex
    else:
      sprite.texture = _extract_texture(frame_tex)
  sprite.centered = true
  sprite.offset = target.offset
  sprite.flip_h = target.flip_h
  sprite.flip_v = target.flip_v
  sprite.hframes = 1
  sprite.vframes = 1
  sprite.frame = 0
  sprite.region_enabled = false
  _attach_sprite(sprite, target, entry)
  if not target.frame_changed.is_connected(_on_animated_frame_changed):
    target.frame_changed.connect(_on_animated_frame_changed.bind(target))
  _active_is_control = false


func _show_control_highlight(target: Control, entry: HighlightEntry) -> void:
  entry.original_material = target.material
  if entry.original_material:
    push_warning("Highlight: %s already has a material; highlight may conflict" % target.name)
  var mat := ShaderMaterial.new()
  mat.shader = _OUTLINE_SHADER
  mat.set_shader_parameter("color", entry.outline_color)
  mat.set_shader_parameter("width", entry.outline_width)
  mat.set_shader_parameter("pattern", entry.outline_pattern)
  mat.set_shader_parameter("inside", false)
  mat.set_shader_parameter("add_margins", true)
  target.material = mat
  _active_is_control = true


func _hide_highlight() -> void:
  if not _active_entry:
    return
  var node := _active_entry.source_node
  if _active_is_control and is_instance_valid(node) and node is Control:
    (node as Control).material = _active_entry.original_material
  elif _highlight_sprite and is_instance_valid(_highlight_sprite):
    _highlight_sprite.visible = false
    if _highlight_sprite.get_parent():
      _highlight_sprite.get_parent().remove_child(_highlight_sprite)
  if is_instance_valid(node) and node is AnimatedSprite2D:
    var anim_target := node as AnimatedSprite2D
    if anim_target.frame_changed.is_connected(_on_animated_frame_changed):
      anim_target.frame_changed.disconnect(_on_animated_frame_changed)
  _active_entry = null


func _on_animated_frame_changed(target: AnimatedSprite2D) -> void:
  if not _active_entry or _active_entry.source_node != target:
    return
  if not _highlight_sprite or not is_instance_valid(_highlight_sprite):
    return
  var anim := target.animation
  var frame_idx := target.frame
  if target.sprite_frames and target.sprite_frames.has_animation(anim):
    var frame_tex := target.sprite_frames.get_frame_texture(anim, frame_idx)
    if _active_entry.style == Style.SILHOUETTE:
      _highlight_sprite.texture = frame_tex
    else:
      _highlight_sprite.texture = _extract_texture(frame_tex)


func _get_highlight_sprite(entry: HighlightEntry) -> Sprite2D:
  if not _highlight_sprite:
    _highlight_sprite = Sprite2D.new()
    _highlight_sprite.name = "_HighlightOutline"
  if not _highlight_material:
    _highlight_material = ShaderMaterial.new()
  if entry.style == Style.SILHOUETTE:
    _highlight_material.shader = _SILHOUETTE_SHADER
    _highlight_material.set_shader_parameter("color", entry.outline_color)
  else:
    _highlight_material.shader = _OUTLINE_SHADER
    _highlight_material.set_shader_parameter("color", entry.outline_color)
    _highlight_material.set_shader_parameter("width", entry.outline_width)
    _highlight_material.set_shader_parameter("pattern", entry.outline_pattern)
    _highlight_material.set_shader_parameter("inside", false)
    _highlight_material.set_shader_parameter("add_margins", true)
  _highlight_sprite.material = _highlight_material
  return _highlight_sprite


func _attach_sprite(sprite: Sprite2D, target: Node2D, entry: HighlightEntry) -> void:
  if sprite.get_parent() != target:
    if sprite.get_parent():
      sprite.get_parent().remove_child(sprite)
    target.add_child(sprite)
  sprite.position = Vector2.ZERO
  sprite.rotation = 0.0
  sprite.show_behind_parent = true
  sprite.visible = true
  if entry.style == Style.SILHOUETTE:
    var tex_size := sprite.texture.get_size() if sprite.texture else Vector2(32, 32)
    var sx := (tex_size.x + entry.outline_width * 2.0) / tex_size.x
    var sy := (tex_size.y + entry.outline_width * 2.0) / tex_size.y
    sprite.scale = Vector2(sx, sy)
    sprite.offset = Vector2(sprite.offset.x / sx, sprite.offset.y / sy)
    sprite.z_index = 0
  else:
    sprite.scale = Vector2.ONE
    sprite.z_index = 0


func _extract_texture(tex: Texture2D) -> Texture2D:
  if tex is AtlasTexture:
    var atlas_tex := tex as AtlasTexture
    var atlas_image := atlas_tex.atlas.get_image()
    var region := Rect2i(atlas_tex.region)
    var extracted := atlas_image.get_region(region)
    return ImageTexture.create_from_image(extracted)
  return tex


func _get_local_rect(node: Node) -> Rect2:
  if node.has_method("get_rect"):
    return node.call("get_rect") as Rect2
  var combined := Rect2()
  var found := false
  for child in node.get_children():
    if child.has_method("get_rect") and child is Node2D:
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
