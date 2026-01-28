class_name RewardPicker
extends Control

signal item_selected(node: Node)
signal skipped

@export var title_text: String = "Select a Reward"
@export var skippable: bool = true
@export var background_color: Color = Color(0, 0.24, 0.19, 1)

@onready var container: BoxContainer = %Container
@onready var skip_button: Button = %SkipButton
@onready var title_label: Label = %TitleLabel

var _options: Array[Node] = []

func _ready() -> void:
  %TitleLabel.text = title_text
  skip_button.visible = skippable
  skip_button.pressed.connect(_on_skip_pressed)
  var style: StyleBox = %PanelContainer.get_theme_stylebox("panel").duplicate()
  if style is StyleBoxFlat:
    (style as StyleBoxFlat).bg_color = background_color
    %PanelContainer.add_theme_stylebox_override("panel", style)

func set_options(options: Array[Node]) -> void:
  _options = options
  _refresh()

func _refresh() -> void:
  for child in container.get_children():
    child.queue_free()

  for i in range(_options.size()):
    var node := _options[i]
    var wrapper := _create_clickable_wrapper(node, i)
    container.add_child(wrapper)

func _create_clickable_wrapper(node: Node, index: int) -> Control:
  var wrapper := MarginContainer.new()
  wrapper.set_meta("index", index)
  wrapper.add_child(node)
  wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
  wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

  var buttons := _find_buttons(node)
  if buttons.is_empty():
    wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
    wrapper.gui_input.connect(func(event: InputEvent):
      if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
          _on_option_clicked(index)
    )
  else:
    for button in buttons:
      button.pressed.connect(func(): _on_option_clicked(index))
  return wrapper

func _find_buttons(node: Node) -> Array[BaseButton]:
  var result: Array[BaseButton] = []
  if node is BaseButton:
    result.append(node)
  for child in node.get_children():
    result.append_array(_find_buttons(child))
  return result

func _on_option_clicked(index: int) -> void:
  if index >= 0 and index < _options.size():
    item_selected.emit(_options[index])

func _on_skip_pressed() -> void:
  skipped.emit()
