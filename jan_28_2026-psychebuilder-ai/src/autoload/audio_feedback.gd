class_name AudioFeedback
extends Node

static var instance: AudioFeedback
func _init(): instance = self

const SFX_PATH := "res://jan_28_2026-psychebuilder-ai/assets/audio/sfx/"

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
@export var pool_size: int = 6
@export var sfx_volume_db: float = -10.0

func _ready() -> void:
  _load_streams()
  _create_player_pool()
  _connect_signals()

func _load_streams() -> void:
  var names: Array[String] = [
    "place_success", "place_fail", "remove", "worker_spawn",
    "process_complete", "event_arrive", "discovery", "day_start",
    "night_start", "tier_up", "tier_down", "breakthrough",
    "belief_unlock", "ui_click",
  ]
  for sfx_name in names:
    var path := SFX_PATH + sfx_name + ".wav"
    var stream := load(path) as AudioStream
    if stream:
      streams[sfx_name] = stream

func _create_player_pool() -> void:
  for i in pool_size:
    var player := AudioStreamPlayer.new()
    player.bus = "Master"
    player.volume_db = sfx_volume_db
    add_child(player)
    players.append(player)

func _get_available_player() -> AudioStreamPlayer:
  for player in players:
    if not player.playing:
      return player
  return players[0]

func play_sfx(sfx_name: String) -> void:
  var stream: AudioStream = streams.get(sfx_name)
  if not stream:
    return
  var player := _get_available_player()
  player.stream = stream
  player.volume_db = sfx_volume_db
  player.play()

func _connect_signals() -> void:
  var bus := EventBus.instance
  bus.building_placed.connect(_on_building_placed)
  bus.building_removed.connect(_on_building_removed)
  bus.event_triggered.connect(_on_event_triggered)
  bus.building_unlocked.connect(_on_building_unlocked)
  bus.building_discovered.connect(_on_building_discovered)
  bus.day_started.connect(_on_day_started)
  bus.night_started.connect(_on_night_started)
  bus.wellbeing_tier_changed.connect(_on_wellbeing_tier_changed)
  bus.breakthrough_triggered.connect(_on_breakthrough_triggered)
  bus.belief_unlocked.connect(_on_belief_unlocked)
  bus.building_awakened.connect(_on_building_awakened)
  bus.worker_assigned.connect(_on_worker_assigned)

func _on_building_placed(_building: Node, _coord: Vector2i) -> void:
  play_sfx("place_success")

func _on_building_removed(_building: Node, _coord: Vector2i) -> void:
  play_sfx("remove")

func _on_event_triggered(_event_id: String) -> void:
  play_sfx("event_arrive")

func _on_building_unlocked(_building_id: String) -> void:
  play_sfx("discovery")

func _on_building_discovered(_building_id: String) -> void:
  play_sfx("discovery")

func _on_day_started(_day: int) -> void:
  play_sfx("day_start")

func _on_night_started(_day: int) -> void:
  play_sfx("night_start")

func _on_wellbeing_tier_changed(old_tier: int, new_tier: int) -> void:
  if new_tier > old_tier:
    play_sfx("tier_up")
  else:
    play_sfx("tier_down")

func _on_breakthrough_triggered(_insight: int, _wisdom: int) -> void:
  play_sfx("breakthrough")

func _on_belief_unlocked(_belief: int) -> void:
  play_sfx("belief_unlock")

func _on_building_awakened(_building: Node) -> void:
  play_sfx("discovery")

func _on_worker_assigned(_worker: Node, _job_type: String, _target: Node) -> void:
  play_sfx("worker_spawn")
