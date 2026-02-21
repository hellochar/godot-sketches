extends CanvasLayer

@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton

func _ready():
  hide()
  restart_button.pressed.connect(_on_restart_pressed)

func on_player_died(source: GobboGameEntity) -> void:
  show_game_over()

func show_game_over():
  show()

func _on_restart_pressed():
  get_tree().reload_current_scene()
