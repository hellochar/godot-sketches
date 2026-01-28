extends RefCounted

# Building behavior types
enum Behavior {
  GENERATOR,    # Produces resources over time
  PROCESSOR,    # Transforms input to output
  STORAGE,      # Holds resources
  CONSUMER,     # Uses resources for global effects
  HABIT,        # Runs automatically each day
  COPING,       # Activates reactively
  INFRASTRUCTURE,  # Roads, bridges
  GLOBAL_EFFECT    # Passive city-wide bonuses
}

static var definitions: Dictionary = {
  "road": {
    "id": "road",
    "name": "Road",
    "description": "Connects buildings, allowing workers to travel between them.",
    "behaviors": [Behavior.INFRASTRUCTURE],
    "build_cost": {"energy": 1},
    "size": Vector2i(1, 1),
    "color": Color(0.5, 0.5, 0.5),
    "unlocked_by_default": true,
  },

  "emotional_reservoir": {
    "id": "emotional_reservoir",
    "name": "Emotional Reservoir",
    "description": "A place to hold emotions until they can be processed.",
    "behaviors": [Behavior.STORAGE],
    "build_cost": {"energy": 3},
    "size": Vector2i(2, 2),
    "color": Color(0.4, 0.5, 0.7),
    "storage_capacity": 20,
    "unlocked_by_default": true,
  },

  "memory_well": {
    "id": "memory_well",
    "name": "Memory Well",
    "description": "Generates Nostalgia periodically, which can become Joy or Grief.",
    "behaviors": [Behavior.GENERATOR],
    "build_cost": {"energy": 4},
    "size": Vector2i(2, 2),
    "color": Color(0.6, 0.5, 0.8),
    "generates": "nostalgia",
    "generation_rate": 0.1,  # per second during day
    "generation_amount": 1,
    "unlocked_by_default": true,
  },

  "mourning_chapel": {
    "id": "mourning_chapel",
    "name": "Mourning Chapel",
    "description": "A quiet space to process grief into wisdom.",
    "behaviors": [Behavior.PROCESSOR],
    "build_cost": {"energy": 5},
    "size": Vector2i(2, 2),
    "color": Color(0.3, 0.35, 0.5),
    "input": {"grief": 2},
    "output": {"wisdom": 1},
    "process_time": 5.0,
    "requires_worker": true,
    "unlocked_by_default": true,
  },

  "morning_routine": {
    "id": "morning_routine",
    "name": "Morning Routine",
    "description": "Each day, generates a small amount of Calm and Energy.",
    "behaviors": [Behavior.HABIT],
    "build_cost": {"energy": 4},
    "size": Vector2i(2, 1),
    "color": Color(0.9, 0.8, 0.5),
    "habit_generates": {"calm": 2},
    "habit_energy_bonus": 1,
    "unlocked_by_default": true,
  },

  "comfort_hearth": {
    "id": "comfort_hearth",
    "name": "Comfort Hearth",
    "description": "Generates Calm slowly over time.",
    "behaviors": [Behavior.GENERATOR],
    "build_cost": {"energy": 3},
    "size": Vector2i(1, 1),
    "color": Color(0.9, 0.6, 0.4),
    "generates": "calm",
    "generation_rate": 0.05,
    "generation_amount": 1,
    "unlocked_by_default": true,
  },

  "anxiety_diffuser": {
    "id": "anxiety_diffuser",
    "name": "Anxiety Diffuser",
    "description": "Slowly converts Anxiety into Calm.",
    "behaviors": [Behavior.PROCESSOR],
    "build_cost": {"energy": 4},
    "size": Vector2i(2, 2),
    "color": Color(0.5, 0.7, 0.8),
    "input": {"anxiety": 3},
    "output": {"calm": 1},
    "process_time": 8.0,
    "requires_worker": false,
    "unlocked_by_default": true,
  },

  "emergency_calm_center": {
    "id": "emergency_calm_center",
    "name": "Emergency Calm Center",
    "description": "Activates when Anxiety spikes, rapidly converting it to Calm.",
    "behaviors": [Behavior.COPING],
    "build_cost": {"energy": 6},
    "size": Vector2i(2, 2),
    "color": Color(0.3, 0.8, 0.7),
    "coping_trigger": "anxiety > 10",
    "coping_input": {"anxiety": 5},
    "coping_output": {"calm": 3},
    "coping_cooldown": 30.0,
    "unlocked_by_default": false,
  },

  "reflection_pool": {
    "id": "reflection_pool",
    "name": "Reflection Pool",
    "description": "Converts negative thoughts into Insight.",
    "behaviors": [Behavior.PROCESSOR],
    "build_cost": {"energy": 5},
    "size": Vector2i(2, 2),
    "color": Color(0.5, 0.6, 0.9),
    "input": {"worry": 2, "doubt": 1},
    "output": {"insight": 1},
    "process_time": 6.0,
    "requires_worker": true,
    "unlocked_by_default": false,
  },

  "exercise_yard": {
    "id": "exercise_yard",
    "name": "Exercise Yard",
    "description": "Consumes Energy to reduce Tension and boost vitality.",
    "behaviors": [Behavior.HABIT],
    "build_cost": {"energy": 3},
    "size": Vector2i(2, 2),
    "color": Color(0.5, 0.8, 0.4),
    "habit_consumes": {"energy": 2},
    "habit_reduces": {"tension": 3},
    "habit_generates": {"calm": 1},
    "unlocked_by_default": true,
  },
}

static func get_definition(building_id: String) -> Dictionary:
  return definitions.get(building_id, {})

static func get_all_unlocked() -> Array:
  var result = []
  for id in definitions:
    if definitions[id].get("unlocked_by_default", false):
      result.append(id)
  return result

static func get_all_ids() -> Array:
  return definitions.keys()
