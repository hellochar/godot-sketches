@tool
extends Control

@export var diagram_radius := 50.0:
  set(value):
    diagram_radius = value
    queue_redraw()

@export var node_radius := 12.0:
  set(value):
    node_radius = value
    queue_redraw()

@export var arrow_size := 6.0:
  set(value):
    arrow_size = value
    queue_redraw()

@export var line_width := 1.5:
  set(value):
    line_width = value
    queue_redraw()

@export var font_size := 20:
  set(value):
    font_size = value
    queue_redraw()


func _draw() -> void:
  var center := size / 2
  var element_positions: Array[Vector2] = []
  var types := Elements.Type.values()

  for i in range(types.size()):
    var angle := -PI / 2 + i * TAU / types.size()
    element_positions.append(center + Vector2(cos(angle), sin(angle)) * diagram_radius)

  for attacker in Elements.BEATS:
    for defender in Elements.BEATS[attacker]:
      var color: Color = Elements.COLORS[attacker]
      draw_arrow(element_positions[attacker], element_positions[defender], color)

  for i in range(types.size()):
    var element: Elements.Type = types[i]
    var color: Color = Elements.COLORS[element]
    draw_circle(element_positions[i], node_radius, color)
    draw_arc(element_positions[i], node_radius, 0, TAU, 32, Color.WHITE, line_width)
    draw_element_label(element_positions[i], Elements.NAMES[element], color)


func draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
  var direction := (to - from).normalized()
  var start := from + direction * node_radius
  var end := to - direction * (node_radius + arrow_size)

  draw_line(start, end, color, line_width, true)

  var arrow_base := end - direction * arrow_size
  var perp := Vector2(-direction.y, direction.x) * arrow_size * 0.5
  var arrow_points := PackedVector2Array([end, arrow_base + perp, arrow_base - perp])
  draw_colored_polygon(arrow_points, color)


func draw_element_label(pos: Vector2, text: String, bg_color: Color) -> void:
  var font := ThemeDB.fallback_font
  var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
  var text_pos := pos - text_size / 2 + Vector2(0, text_size.y * 0.35)
  var text_color := Elements.get_text_color(bg_color)
  draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
