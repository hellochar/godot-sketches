extends Control

signal start_game_pressed()

@export_group("Title")
@export var title_text: String = "PsycheBuilder"
@export var subtitle_text: String = "Build your inner world"
@export var title_font_size: int = 48
@export var subtitle_font_size: int = 24

@export_group("Buttons")
@export var button_size: Vector2 = Vector2(200, 50)

@export_group("Layout")
@export var spacing: int = 20

var start_button: Button

func _ready() -> void:
  _build_ui()

func _build_ui() -> void:
  var center_container = CenterContainer.new()
  center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
  add_child(center_container)

  var vbox = VBoxContainer.new()
  vbox.add_theme_constant_override("separation", spacing)
  center_container.add_child(vbox)

  var title_label = Label.new()
  title_label.text = title_text
  title_label.add_theme_font_size_override("font_size", title_font_size)
  title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(title_label)

  var subtitle_label = Label.new()
  subtitle_label.text = subtitle_text
  subtitle_label.add_theme_font_size_override("font_size", subtitle_font_size)
  subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
  subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(subtitle_label)

  var spacer = Control.new()
  spacer.custom_minimum_size.y = 40
  vbox.add_child(spacer)

  start_button = Button.new()
  start_button.text = "Start Game"
  start_button.custom_minimum_size = button_size
  start_button.pressed.connect(_on_start_pressed)
  vbox.add_child(start_button)

  var description = Label.new()
  description.text = "Manage your mental architecture.\nProcess emotions, build habits, find balance."
  description.add_theme_font_size_override("font_size", 20)
  description.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
  description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(description)

func _on_start_pressed() -> void:
  start_game_pressed.emit()
