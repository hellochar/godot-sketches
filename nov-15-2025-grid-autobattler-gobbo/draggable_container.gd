extends BoxContainer

var dragging_child: Control = null
var drag_offset: Vector2
var original_index: int = -1

func _ready():
  mouse_filter = Control.MOUSE_FILTER_PASS

func _get_drag_data(at_position: Vector2):
  var child = _get_child_at_position(at_position)
  if child == null:
    return null

  dragging_child = child
  original_index = child.get_index()
  drag_offset = at_position - child.position

  var preview = child.duplicate()
  preview.modulate.a = 0.7
  set_drag_preview(preview)

  return {"child": child, "index": original_index}

func _can_drop_data(_at_position: Vector2, data):
  return data is Dictionary and data.has("child") and data.has("index")

func _drop_data(at_position: Vector2, data):
  var target_index = _get_drop_index(at_position)
  if target_index != -1:
    var child = data["child"]
    move_child(child, target_index)

  dragging_child = null

func _notification(what):
  if what == NOTIFICATION_DRAG_END:
    dragging_child = null

func _get_drop_index(pos: Vector2) -> int:
  for i in range(get_child_count()):
    var child = get_child(i)
    if child is Control:
      var rect = Rect2(child.position, child.size)
      if rect.has_point(pos):
        return i
  return get_child_count() - 1

func _get_child_at_position(pos: Vector2) -> Control:
  for child in get_children():
    if child is Control:
      var rect = Rect2(child.position, child.size)
      if rect.has_point(pos):
        return child
  return null
