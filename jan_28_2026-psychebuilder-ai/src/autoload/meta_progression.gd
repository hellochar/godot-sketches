extends Node

const SAVE_PATH = "user://meta_progression.save"

var total_runs: int = 0
var runs_won: int = 0
var best_wellbeing: float = 0.0
var best_wellbeing_tier: int = 0
var total_grief_processed: int = 0
var total_anxiety_processed: int = 0
var total_wisdom_generated: int = 0
var total_insight_generated: int = 0
var total_buildings_placed: int = 0
var buildings_discovered: Array[String] = []
var beliefs_unlocked: Array[String] = []
var endings_achieved: Array[String] = []

func _ready() -> void:
  load_progress()
  var event_bus = get_node_or_null("/root/EventBus")
  if event_bus:
    event_bus.building_placed.connect(_on_building_placed)

func save_progress() -> void:
  var save_data = {
    "total_runs": total_runs,
    "runs_won": runs_won,
    "best_wellbeing": best_wellbeing,
    "best_wellbeing_tier": best_wellbeing_tier,
    "total_grief_processed": total_grief_processed,
    "total_anxiety_processed": total_anxiety_processed,
    "total_wisdom_generated": total_wisdom_generated,
    "total_insight_generated": total_insight_generated,
    "total_buildings_placed": total_buildings_placed,
    "buildings_discovered": buildings_discovered,
    "beliefs_unlocked": beliefs_unlocked,
    "endings_achieved": endings_achieved,
  }

  var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  if file:
    file.store_var(save_data)
    file.close()

func load_progress() -> void:
  if not FileAccess.file_exists(SAVE_PATH):
    return

  var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
  if not file:
    return

  var save_data = file.get_var()
  file.close()

  if not save_data is Dictionary:
    return

  total_runs = save_data.get("total_runs", 0)
  runs_won = save_data.get("runs_won", 0)
  best_wellbeing = save_data.get("best_wellbeing", 0.0)
  best_wellbeing_tier = save_data.get("best_wellbeing_tier", 0)
  total_grief_processed = save_data.get("total_grief_processed", 0)
  total_anxiety_processed = save_data.get("total_anxiety_processed", 0)
  total_wisdom_generated = save_data.get("total_wisdom_generated", 0)
  total_insight_generated = save_data.get("total_insight_generated", 0)
  total_buildings_placed = save_data.get("total_buildings_placed", 0)

  var discovered = save_data.get("buildings_discovered", [])
  buildings_discovered.clear()
  for b in discovered:
    buildings_discovered.append(b)

  var beliefs = save_data.get("beliefs_unlocked", [])
  beliefs_unlocked.clear()
  for b in beliefs:
    beliefs_unlocked.append(b)

  var endings = save_data.get("endings_achieved", [])
  endings_achieved.clear()
  for e in endings:
    endings_achieved.append(e)

func record_run_end(game_state: Node, ending_type: String) -> void:
  total_runs += 1

  if game_state.wellbeing >= game_state.get_node("/root/Config").flourishing_threshold:
    runs_won += 1

  if game_state.wellbeing > best_wellbeing:
    best_wellbeing = game_state.wellbeing

  var tier_value = game_state.highest_wellbeing_tier_reached as int
  if tier_value > best_wellbeing_tier:
    best_wellbeing_tier = tier_value

  total_grief_processed += game_state.total_grief_processed
  total_anxiety_processed += game_state.total_anxiety_processed
  total_wisdom_generated += game_state.total_wisdom_generated
  total_insight_generated += game_state.total_insight_generated

  if ending_type not in endings_achieved:
    endings_achieved.append(ending_type)

  for belief in game_state.active_beliefs:
    var belief_name = _belief_to_string(belief)
    if belief_name not in beliefs_unlocked:
      beliefs_unlocked.append(belief_name)

  for building_id in game_state.discovered_buildings:
    if building_id not in buildings_discovered:
      buildings_discovered.append(building_id)

  save_progress()

func _belief_to_string(belief: int) -> String:
  var game_state = get_node("/root/GameState")
  match belief:
    game_state.Belief.HANDLE_DIFFICULTY:
      return "handle_difficulty"
    game_state.Belief.JOY_RESILIENT:
      return "joy_resilient"
    game_state.Belief.CALM_FOUNDATION:
      return "calm_foundation"
    game_state.Belief.GROWTH_ADVERSITY:
      return "growth_adversity"
    game_state.Belief.MINDFUL_AWARENESS:
      return "mindful_awareness"
  return ""

func record_building_placed() -> void:
  total_buildings_placed += 1

func _on_building_placed(_building: Node, _coord: Vector2i) -> void:
  record_building_placed()

func has_ending(ending_type: String) -> bool:
  return ending_type in endings_achieved

func has_unlocked_belief(belief_name: String) -> bool:
  return belief_name in beliefs_unlocked

func has_discovered_building(building_id: String) -> bool:
  return building_id in buildings_discovered

func get_total_negative_processed() -> int:
  return total_grief_processed + total_anxiety_processed
