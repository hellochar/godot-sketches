class_name InfrastructureComponent
extends BuildingComponent

var road_traffic_memory: Dictionary = {}
var road_dominant_emotion: String = ""
var road_imprinted: bool = false

func on_initialize() -> void:
  building.road_connected = true

func on_process(delta: float) -> void:
  _process_memory_decay(delta)

func record_traffic(emotion: String, amount: float) -> void:
  var gain = config.road_memory_gain_per_pass * amount
  road_traffic_memory[emotion] = road_traffic_memory.get(emotion, 0.0) + gain
  _update_dominant_emotion()
  _update_visual()

func get_speed_modifier() -> float:
  if not road_imprinted:
    return 1.0

  if road_dominant_emotion in config.road_positive_emotions:
    return 1.0 + config.road_imprint_speed_bonus
  elif road_dominant_emotion in config.road_negative_emotions:
    return 1.0 - config.road_imprint_speed_penalty

  return 1.0

func _process_memory_decay(delta: float) -> void:
  var decay = config.road_memory_decay_rate * delta
  var any_remaining = false
  for emotion in road_traffic_memory.keys():
    road_traffic_memory[emotion] = maxf(0.0, road_traffic_memory[emotion] - decay)
    if road_traffic_memory[emotion] > 0:
      any_remaining = true

  if any_remaining:
    _update_dominant_emotion()
    _update_visual()
  else:
    road_imprinted = false
    road_dominant_emotion = ""

func _update_dominant_emotion() -> void:
  var max_value = 0.0
  var dominant = ""

  for emotion in road_traffic_memory:
    if road_traffic_memory[emotion] > max_value:
      max_value = road_traffic_memory[emotion]
      dominant = emotion

  road_dominant_emotion = dominant
  road_imprinted = max_value >= config.road_memory_threshold

func _update_visual() -> void:
  var base_color = definition.get("color", Color.WHITE)

  if not road_imprinted:
    building.sprite.color = base_color
    return

  var emotion_color = base_color
  if road_dominant_emotion in config.road_positive_emotions:
    emotion_color = Color(0.6, 0.8, 0.6)
  elif road_dominant_emotion in config.road_negative_emotions:
    emotion_color = Color(0.7, 0.5, 0.6)

  building.sprite.color = base_color.lerp(emotion_color, 0.4)
