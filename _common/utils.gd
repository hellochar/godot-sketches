extends Node

class ShakeHelper extends Node:
  var target: Node
  var original_offset: Vector2
  var duration: float
  var amplitude: float
  var elapsed: float = 0.0

  func _process(delta: float) -> void:
    elapsed += delta
    if elapsed >= duration:
      _restore_and_free()
      return
    var trauma := 1.0 - (elapsed / duration)
    var shake := Vector2(
      randf_range(-amplitude, amplitude),
      randf_range(-amplitude, amplitude)
    ) * trauma * trauma
    if target is Camera2D:
      target.offset = original_offset + shake
    elif target is Control:
      target.position = original_offset + shake
    elif target is Node2D:
      target.position = original_offset + shake

  func _restore_and_free() -> void:
    if is_instance_valid(target):
      if target is Camera2D:
        target.offset = original_offset
      elif target is Control or target is Node2D:
        target.position = original_offset
    queue_free()

class SpringHelper extends Node:
  var target: Node
  var current_scale: float
  var velocity: float = 0.0
  var spring: float
  var damping: float

  func _process(delta: float) -> void:
    if not is_instance_valid(target):
      queue_free()
      return
    var diff := 1.0 - current_scale
    velocity += diff * spring * delta
    velocity *= exp(-damping * delta)
    current_scale += velocity * delta
    if target is Control:
      target.scale = Vector2.ONE * current_scale
      target.pivot_offset = target.size / 2.0
    elif target is Node2D:
      target.scale = Vector2.ONE * current_scale
    if absf(current_scale - 1.0) < 0.01 and absf(velocity) < 0.1:
      if target is Control:
        target.scale = Vector2.ONE
      elif target is Node2D:
        target.scale = Vector2.ONE
      queue_free()

class FloatingLabel extends Label:
  var velocity: Vector2
  var lifetime: float
  var elapsed: float = 0.0

  func _process(delta: float) -> void:
    elapsed += delta
    position += velocity * delta
    var alpha := 1.0 - (elapsed / lifetime)
    modulate.a = alpha
    if elapsed >= lifetime:
      queue_free()

var _feedback_layer: CanvasLayer

func _get_shake_target() -> Node:
  var tree := get_tree()
  if not tree:
    return null
  var root := tree.current_scene
  if not root:
    return null
  var camera := root.get_viewport().get_camera_2d()
  if camera:
    return camera
  if root is Control or root is Node2D:
    return root
  for child in root.get_children():
    if child is Control or child is Node2D:
      return child
  return null

func screen_shake(duration: float = 0.3, amplitude: float = 8.0) -> void:
  var target := _get_shake_target()
  if not target:
    return
  var existing: ShakeHelper = null
  for child in target.get_children():
    if child is ShakeHelper:
      existing = child
      break
  if existing:
    existing.duration = maxf(existing.duration - existing.elapsed, duration)
    existing.elapsed = 0.0
    existing.amplitude = maxf(existing.amplitude, amplitude)
    return
  var helper := ShakeHelper.new()
  helper.target = target
  helper.duration = duration
  helper.amplitude = amplitude
  if target is Camera2D:
    helper.original_offset = target.offset
  elif target is Control or target is Node2D:
    helper.original_offset = target.position
  target.add_child(helper)

func _get_feedback_layer() -> CanvasLayer:
  if _feedback_layer and is_instance_valid(_feedback_layer):
    return _feedback_layer
  _feedback_layer = CanvasLayer.new()
  _feedback_layer.layer = 100
  _feedback_layer.name = "FeedbackLayer"
  get_tree().current_scene.add_child(_feedback_layer)
  return _feedback_layer

func feedback(msg: String, duration: float = 2.0, color: Color = Color.WHITE, screen_pos: Vector2 = Vector2(-1, -1)) -> Label:
  var layer := _get_feedback_layer()
  var label := Label.new()
  label.text = msg
  label.add_theme_color_override("font_color", color)
  label.add_theme_font_size_override("font_size", 24)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  layer.add_child(label)
  if screen_pos == Vector2(-1, -1):
    var viewport_size := get_viewport().get_visible_rect().size
    label.position = viewport_size / 2.0
    label.position.x -= label.size.x / 2.0
  else:
    label.position = screen_pos
  var tween := create_tween()
  tween.tween_interval(duration * 0.7)
  tween.tween_property(label, "modulate:a", 0.0, duration * 0.3)
  tween.tween_callback(label.queue_free)
  return label

func floating_text(global_pos: Vector2, text: String, color: Color = Color.WHITE, velocity: Vector2 = Vector2(0, -40), lifetime: float = 1.0) -> Label:
  var layer := _get_feedback_layer()
  var label := FloatingLabel.new()
  label.text = text
  label.velocity = velocity
  label.lifetime = lifetime
  label.add_theme_color_override("font_color", color)
  label.add_theme_font_size_override("font_size", 20)
  var camera := get_viewport().get_camera_2d()
  if camera:
    var screen_pos := get_viewport().get_visible_rect().size / 2.0 + (global_pos - camera.global_position)
    label.position = screen_pos
  else:
    label.position = global_pos
  layer.add_child(label)
  return label

func spring_scale(target: Node, overshoot: float = 1.3, spring: float = 150.0, damping: float = 12.0) -> void:
  if not is_instance_valid(target):
    return
  for child in target.get_children():
    if child is SpringHelper:
      child.queue_free()
  var helper := SpringHelper.new()
  helper.target = target
  helper.current_scale = overshoot
  helper.spring = spring
  helper.damping = damping
  if target is Control:
    target.scale = Vector2.ONE * overshoot
    target.pivot_offset = target.size / 2.0
  elif target is Node2D:
    target.scale = Vector2.ONE * overshoot
  target.add_child(helper)

func spring_pop(target: Node, overshoot: float = 1.3, duration: float = 0.3) -> Tween:
  if not is_instance_valid(target):
    return null
  if target is Control:
    target.pivot_offset = target.size / 2.0
  var tween := create_tween()
  tween.tween_property(target, "scale", Vector2.ONE, duration).from(Vector2.ONE * overshoot).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  return tween

func get_random_point_in_polygon(polygon: Polygon2D) -> Vector2:
  return polygon.global_position + get_random_point_in_polygon_points(polygon.polygon)

func get_random_point_in_polygon_points(points: PackedVector2Array) -> Vector2:
  # Pick a random triangle using ear clipping approximation
  # Simple approach: use bounding box rejection sampling
  var min_x = points[0].x
  var max_x = points[0].x
  var min_y = points[0].y
  var max_y = points[0].y
  for point in points:
    min_x = min(min_x, point.x)
    max_x = max(max_x, point.x)
    min_y = min(min_y, point.y)
    max_y = max(max_y, point.y)
  
  while true:
    var random_point = Vector2(
      randf_range(min_x, max_x),
      randf_range(min_y, max_y)
    )
    if Geometry2D.is_point_in_polygon(random_point, points):
      return random_point
  return Vector2.ZERO
