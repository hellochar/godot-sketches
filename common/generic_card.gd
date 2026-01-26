class_name GenericCard
extends PanelContainer

signal pressed

enum Corner { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

@export var card_size: Vector2 = Vector2(140, 100)
@export var background_color: Color = Color(0.3, 0.3, 0.35)
@export var hover_lighten: float = 0.1
@export var enable_hover: bool = false
@export var corner_radius: int = 8
@export var content_margin: int = 10
@export var tag_corner_radius: int = 4
@export var tag_margin_h: int = 8
@export var tag_margin_v: int = 4

var _hovered: bool = false

var title: String:
  set(v):
    title = v
    if is_node_ready():
      %TitleLabel.text = v

var icon: Texture2D:
  set(v):
    icon = v
    if is_node_ready():
      %IconSlot.texture = v
      %IconSlot.visible = v != null

var description: String:
  set(v):
    description = v
    if is_node_ready():
      %DescriptionLabel.text = v
      %DescriptionLabel.visible = not v.is_empty()

var description_color: Color = Color.WHITE:
  set(v):
    description_color = v
    if is_node_ready():
      %DescriptionLabel.add_theme_color_override("font_color", v)


func _ready() -> void:
  custom_minimum_size = card_size
  %TitleLabel.text = title
  %IconSlot.texture = icon
  %IconSlot.visible = icon != null
  %DescriptionLabel.text = description
  %DescriptionLabel.visible = not description.is_empty()
  if description_color != Color.WHITE:
    %DescriptionLabel.add_theme_color_override("font_color", description_color)
  apply_style()
  mouse_entered.connect(_on_mouse_entered)
  mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
  if enable_hover:
    _hovered = true
    apply_style()


func _on_mouse_exited() -> void:
  if enable_hover:
    _hovered = false
    apply_style()


func _gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
      pressed.emit()


func apply_style() -> void:
  var style := StyleBoxFlat.new()
  var color := background_color.lightened(hover_lighten) if _hovered else background_color
  style.bg_color = color
  style.corner_radius_top_left = corner_radius
  style.corner_radius_top_right = corner_radius
  style.corner_radius_bottom_left = corner_radius
  style.corner_radius_bottom_right = corner_radius
  style.content_margin_left = content_margin
  style.content_margin_right = content_margin
  style.content_margin_top = content_margin
  style.content_margin_bottom = content_margin
  add_theme_stylebox_override("panel", style)


func set_corner_text(corner: Corner, text: String, color: Color = Color.WHITE) -> Label:
  var container := get_corner(corner)
  clear_corner(corner)
  var label := Label.new()
  label.text = text
  label.add_theme_font_size_override("font_size", 12)
  if color != Color.WHITE:
    label.add_theme_color_override("font_color", color)
  if corner == Corner.TOP_RIGHT or corner == Corner.BOTTOM_RIGHT:
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  container.add_child(label)
  return label


func set_corner_node(corner: Corner, node: Node) -> void:
  var container := get_corner(corner)
  clear_corner(corner)
  container.add_child(node)


func clear_corner(corner: Corner) -> void:
  var container := get_corner(corner)
  for child in container.get_children():
    child.queue_free()


func get_corner(corner: Corner) -> Control:
  match corner:
    Corner.TOP_LEFT:
      return %TopLeft
    Corner.TOP_RIGHT:
      return %TopRight
    Corner.BOTTOM_LEFT:
      return %BottomLeft
    Corner.BOTTOM_RIGHT:
      return %BottomRight
  return null


func add_tag(tag_name: String, color: Color) -> void:
  var tag_label := Label.new()
  tag_label.text = tag_name

  var style := StyleBoxFlat.new()
  style.bg_color = color
  style.corner_radius_top_left = tag_corner_radius
  style.corner_radius_top_right = tag_corner_radius
  style.corner_radius_bottom_left = tag_corner_radius
  style.corner_radius_bottom_right = tag_corner_radius
  style.content_margin_left = tag_margin_h
  style.content_margin_right = tag_margin_h
  style.content_margin_top = tag_margin_v
  style.content_margin_bottom = tag_margin_v

  var panel := PanelContainer.new()
  panel.add_theme_stylebox_override("panel", style)
  panel.add_child(tag_label)
  %TagsContainer.add_child(panel)


func clear_tags() -> void:
  for child in %TagsContainer.get_children():
    child.queue_free()


func add_content_label(text: String, font_size: int = 12, color: Color = Color.WHITE) -> Label:
  var label := Label.new()
  label.text = text
  label.add_theme_font_size_override("font_size", font_size)
  if color != Color.WHITE:
    label.add_theme_color_override("font_color", color)
  label.autowrap_mode = TextServer.AUTOWRAP_WORD
  var main_content := %TitleLabel.get_parent()
  main_content.add_child(label)
  main_content.move_child(label, %TagsContainer.get_index())
  return label


func get_main_content() -> VBoxContainer:
  return %TitleLabel.get_parent()
