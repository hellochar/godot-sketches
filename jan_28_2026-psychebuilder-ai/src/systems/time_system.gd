extends Node

signal day_started(day_number: int)
signal night_started(day_number: int)
signal phase_changed(is_day: bool)

enum Phase { DAY, NIGHT }

@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")
@onready var config: Node = get_node("/root/Config")

var current_day: int = 1
var current_phase: Phase = Phase.DAY
var phase_time: float = 0.0
var paused: bool = false
var speed_multiplier: float = 1.0

@export var day_duration: float = 45.0
@export var night_duration: float = 10.0
@export var total_days: int = 20

func _ready() -> void:
  if config:
    day_duration = config.day_duration_seconds
    total_days = config.total_days

func _process(delta: float) -> void:
  if paused:
    return

  phase_time += delta * speed_multiplier

  match current_phase:
    Phase.DAY:
      if phase_time >= day_duration:
        _transition_to_night()
    Phase.NIGHT:
      pass

func _transition_to_night() -> void:
  current_phase = Phase.NIGHT
  phase_time = 0.0
  night_started.emit(current_day)
  phase_changed.emit(false)
  event_bus.night_started.emit(current_day)

func _transition_to_day() -> void:
  current_day += 1
  current_phase = Phase.DAY
  phase_time = 0.0

  if current_day > total_days:
    _end_game()
    return

  day_started.emit(current_day)
  phase_changed.emit(true)
  event_bus.day_started.emit(current_day)
  _trigger_day_start_effects()

func _trigger_day_start_effects() -> void:
  var gs = game_state
  if gs:
    gs.on_day_start()

func end_night() -> void:
  if current_phase == Phase.NIGHT:
    _transition_to_day()

func set_paused(p: bool) -> void:
  paused = p

func set_speed(multiplier: float) -> void:
  speed_multiplier = clampf(multiplier, 0.5, 3.0)

func get_phase_progress() -> float:
  match current_phase:
    Phase.DAY:
      return phase_time / day_duration
    Phase.NIGHT:
      return phase_time / night_duration
  return 0.0

func is_day() -> bool:
  return current_phase == Phase.DAY

func is_night() -> bool:
  return current_phase == Phase.NIGHT

func _end_game() -> void:
  paused = true
  var ending_tier = _calculate_ending_tier()
  event_bus.game_ended.emit(ending_tier)

func _calculate_ending_tier() -> String:
  var wb = game_state.wellbeing
  if wb >= config.flourishing_threshold:
    return "flourishing"
  elif wb >= config.growing_threshold:
    return "growing"
  elif wb >= config.surviving_threshold:
    return "surviving"
  else:
    return "struggling"
