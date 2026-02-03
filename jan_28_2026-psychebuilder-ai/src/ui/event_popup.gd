extends PanelContainer

signal choice_made(choice_index: int)
signal dismissed()

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var dismiss_button: Button = %DismissButton

var event_data: Dictionary = {}
var time_system: Node

func _ready() -> void:
  dismiss_button.pressed.connect(_on_dismiss_pressed)
  visible = false

func show_event(data: Dictionary, p_time_system: Node = null) -> void:
  event_data = data
  time_system = p_time_system

  title_label.text = data.get("name", "Event")
  description_label.text = data.get("description", "")

  for child in choices_container.get_children():
    child.queue_free()

  var choices = data.get("choices", [])
  if choices.size() > 0:
    dismiss_button.visible = false
    for i in range(choices.size()):
      var choice = choices[i]
      var btn = Button.new()
      btn.text = choice.get("text", "Choice %d" % (i + 1))

      var effect = choice.get("effect", {})
      var cost_text = ""
      if effect.has("energy_cost"):
        cost_text = " (%d Energy)" % effect.get("energy_cost")
      btn.text += cost_text

      btn.pressed.connect(_on_choice_pressed.bind(i))
      choices_container.add_child(btn)
  else:
    dismiss_button.visible = true

  visible = true

  if time_system:
    time_system.set_paused(true)

func _on_choice_pressed(choice_index: int) -> void:
  choice_made.emit(choice_index)
  _close_popup()

func _on_dismiss_pressed() -> void:
  dismissed.emit()
  _close_popup()

func _close_popup() -> void:
  visible = false

  if time_system:
    time_system.set_paused(false)

  event_data = {}

func _unhandled_input(event: InputEvent) -> void:
  if not visible:
    return

  if event is InputEventKey:
    var key = event as InputEventKey
    if key.pressed and key.keycode == KEY_ESCAPE:
      if dismiss_button.visible:
        _on_dismiss_pressed()
