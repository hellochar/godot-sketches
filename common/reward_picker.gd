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
  var wrapper := Control.new()
  wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
  wrapper.set_meta("index", index)
  wrapper.gui_input.connect(func(event: InputEvent):
    if event is InputEventMouseButton:
      if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _on_option_clicked(index)
  )
  wrapper.add_child(node)
  wrapper.custom_minimum_size = node.custom_minimum_size
  if node is Control:
    node.anchors_preset = Control.PRESET_FULL_RECT
  return wrapper

func _on_option_clicked(index: int) -> void:
  if index >= 0 and index < _options.size():
    item_selected.emit(_options[index])

func _on_skip_pressed() -> void:
  skipped.emit()
