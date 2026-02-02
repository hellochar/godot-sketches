extends Node

signal day_started(day_number: int)
signal night_started(day_number: int)
signal phase_changed(is_day: bool)

enum Phase { DAY, NIGHT }

var current_day: int = 1
var current_phase: Phase = Phase.DAY
var phase_time: float = 0.0
var paused: bool = false
var speed_multiplier: float = 1.0

var day_duration: float
var night_duration: float
var total_days: int
var energy_regen_per_day: int

@export_group("Speed Limits")
@export var min_speed: float = 0.5
@export var max_speed: float = 3.0

func setup(p_day_duration: float, p_night_duration: float, p_total_days: int, p_energy_regen: int) -> void:
  day_duration = p_day_duration
  night_duration = p_night_duration
  total_days = p_total_days
  energy_regen_per_day = p_energy_regen

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
  get_node("/root/EventBus").night_started.emit(current_day)

func _transition_to_day() -> void:
  current_day += 1
  current_phase = Phase.DAY
  phase_time = 0.0

  if current_day > total_days:
    _end_game()
    return

  day_started.emit(current_day)
  phase_changed.emit(true)
  get_node("/root/EventBus").day_started.emit(current_day)
  _trigger_day_start_effects()

func _trigger_day_start_effects() -> void:
  var gs = get_node("/root/GameState")
  if gs:
    gs.on_day_start(energy_regen_per_day)

func end_night() -> void:
  if current_phase == Phase.NIGHT:
    _transition_to_day()

func set_paused(p: bool) -> void:
  paused = p

func set_speed(multiplier: float) -> void:
  speed_multiplier = clampf(multiplier, min_speed, max_speed)

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
  get_node("/root/EventBus").game_ended.emit()
