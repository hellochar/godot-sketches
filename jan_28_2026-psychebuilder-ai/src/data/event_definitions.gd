extends RefCounted

enum EventType {
  MINOR_POSITIVE,
  MINOR_NEGATIVE,
  INCITING_INCIDENT
}

enum EventPhase {
  EARLY,
  MID,
  LATE,
  ANY
}

static var definitions: Dictionary = {
  "good_day": {
    "id": "good_day",
    "name": "Good Day",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_POSITIVE,
    "description": "Sometimes the sun just shines a little brighter. A burst of good feeling washes over you.",
    "spawns": [
      {"resource": "joy", "amount": 3, "location": "random"},
      {"resource": "calm", "amount": 2, "location": "random"}
    ],
    "choices": [],
    "completion_condition": "",
    "completion_reward": {}
  },

  "intrusive_thought": {
    "id": "intrusive_thought",
    "name": "Intrusive Thought",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_NEGATIVE,
    "description": "An unwanted thought surfaces, bringing worry and tension with it.",
    "spawns": [
      {"resource": "worry", "amount": 3, "location": "center"},
      {"resource": "tension", "amount": 2, "location": "random"}
    ],
    "choices": [
      {
        "text": "Acknowledge and release",
        "effect": {"spawns": [{"resource": "calm", "amount": 1, "location": "center"}]}
      },
      {
        "text": "Push it away",
        "effect": {"energy_cost": 2, "spawns": [{"resource": "tension", "amount": 2, "location": "random"}]}
      }
    ],
    "completion_condition": "",
    "completion_reward": {}
  },

  "the_rejection": {
    "id": "the_rejection",
    "name": "The Rejection",
    "phase": EventPhase.MID,
    "type": EventType.INCITING_INCIDENT,
    "description": "Something you cared about deeply has ended. A relationship, a job, a dream. The loss hits hard.",
    "spawns": [
      {"resource": "grief", "amount": 15, "location": "center"},
      {"resource": "shame", "amount": 8, "location": "center"},
      {"resource": "anger", "amount": 5, "location": "random"}
    ],
    "choices": [
      {
        "text": "Sit with the feelings",
        "effect": {"spawns": [{"resource": "calm", "amount": 3, "location": "center"}]}
      },
      {
        "text": "Push through",
        "effect": {"energy_cost": 5, "spawns": [{"resource": "tension", "amount": 5, "location": "random"}]}
      }
    ],
    "completion_condition": "grief < 3 and shame < 2",
    "completion_reward": {
      "unlock_building": "resilience_monument",
      "spawn": {"resource": "wisdom", "amount": 5, "location": "center"}
    }
  },

  "the_loss": {
    "id": "the_loss",
    "name": "The Loss",
    "phase": EventPhase.MID,
    "type": EventType.INCITING_INCIDENT,
    "description": "Someone or something precious is gone. The weight of absence settles in.",
    "spawns": [
      {"resource": "grief", "amount": 20, "location": "center"},
      {"resource": "loneliness", "amount": 10, "location": "center"},
      {"resource": "nostalgia", "amount": 8, "location": "random"}
    ],
    "choices": [
      {
        "text": "Honor what was",
        "effect": {"spawns": [{"resource": "wisdom", "amount": 2, "location": "center"}]}
      },
      {
        "text": "Distract yourself",
        "effect": {"energy_cost": 3, "spawns": [{"resource": "anxiety", "amount": 4, "location": "random"}]}
      }
    ],
    "completion_condition": "grief < 5 and loneliness < 3",
    "completion_reward": {
      "spawn": {"resource": "wisdom", "amount": 8, "location": "center"}
    }
  },

  "the_failure": {
    "id": "the_failure",
    "name": "The Failure",
    "phase": EventPhase.MID,
    "type": EventType.INCITING_INCIDENT,
    "description": "You tried your best and it wasn't enough. Self-doubt creeps in.",
    "spawns": [
      {"resource": "shame", "amount": 12, "location": "center"},
      {"resource": "doubt", "amount": 10, "location": "center"},
      {"resource": "fear", "amount": 6, "location": "random"}
    ],
    "choices": [
      {
        "text": "Learn from this",
        "effect": {"spawns": [{"resource": "insight", "amount": 2, "location": "center"}]}
      },
      {
        "text": "Blame circumstances",
        "effect": {"spawns": [{"resource": "anger", "amount": 3, "location": "random"}]}
      }
    ],
    "completion_condition": "shame < 3 and doubt < 3",
    "completion_reward": {
      "spawn": {"resource": "confidence", "amount": 5, "location": "center"}
    }
  },

  "the_overwhelm": {
    "id": "the_overwhelm",
    "name": "The Overwhelm",
    "phase": EventPhase.MID,
    "type": EventType.INCITING_INCIDENT,
    "description": "Everything is too much. The demands pile up faster than you can manage.",
    "spawns": [
      {"resource": "anxiety", "amount": 15, "location": "center"},
      {"resource": "tension", "amount": 12, "location": "center"},
      {"resource": "fatigue", "amount": 8, "location": "random"}
    ],
    "choices": [
      {
        "text": "Take a breath",
        "effect": {"spawns": [{"resource": "calm", "amount": 4, "location": "center"}]}
      },
      {
        "text": "Power through",
        "effect": {"energy_cost": 4, "spawns": [{"resource": "tension", "amount": 6, "location": "random"}]}
      }
    ],
    "completion_condition": "anxiety < 5 and tension < 4",
    "completion_reward": {
      "spawn": {"resource": "calm", "amount": 8, "location": "center"}
    }
  },

  "the_betrayal": {
    "id": "the_betrayal",
    "name": "The Betrayal",
    "phase": EventPhase.MID,
    "type": EventType.INCITING_INCIDENT,
    "description": "Trust has been broken. Someone you relied on has let you down deeply.",
    "spawns": [
      {"resource": "anger", "amount": 12, "location": "center"},
      {"resource": "grief", "amount": 8, "location": "center"},
      {"resource": "doubt", "amount": 6, "location": "random"}
    ],
    "choices": [
      {
        "text": "Feel the anger fully",
        "effect": {"spawns": [{"resource": "tension", "amount": 3, "location": "center"}]}
      },
      {
        "text": "Seek understanding",
        "effect": {"spawns": [{"resource": "insight", "amount": 2, "location": "center"}]}
      }
    ],
    "completion_condition": "anger < 4 and grief < 3",
    "completion_reward": {
      "spawn": {"resource": "wisdom", "amount": 6, "location": "center"}
    }
  },

  "the_change": {
    "id": "the_change",
    "name": "The Change",
    "phase": EventPhase.MID,
    "type": EventType.INCITING_INCIDENT,
    "description": "Something new is beginning. It's exciting and terrifying in equal measure.",
    "spawns": [
      {"resource": "excitement", "amount": 10, "location": "center"},
      {"resource": "fear", "amount": 8, "location": "center"},
      {"resource": "hope", "amount": 6, "location": "random"}
    ],
    "choices": [
      {
        "text": "Embrace the unknown",
        "effect": {"spawns": [{"resource": "courage", "amount": 3, "location": "center"}]}
      },
      {
        "text": "Hold onto the familiar",
        "effect": {"spawns": [{"resource": "nostalgia", "amount": 4, "location": "random"}]}
      }
    ],
    "completion_condition": "fear < 3",
    "completion_reward": {
      "spawn": {"resource": "joy", "amount": 6, "location": "center"}
    }
  },

  "bad_sleep": {
    "id": "bad_sleep",
    "name": "Bad Sleep",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_NEGATIVE,
    "description": "Last night was rough. You wake up tired and foggy.",
    "spawns": [
      {"resource": "fatigue", "amount": 4, "location": "center"},
      {"resource": "tension", "amount": 2, "location": "random"}
    ],
    "choices": [],
    "effect": {"energy_regen_modifier": -2},
    "completion_condition": "",
    "completion_reward": {}
  },

  "unexpected_joy": {
    "id": "unexpected_joy",
    "name": "Unexpected Joy",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_POSITIVE,
    "description": "A small delight catches you by surprise. A favorite song, a kind word, a beautiful moment.",
    "spawns": [
      {"resource": "joy", "amount": 5, "location": "random"}
    ],
    "choices": [],
    "completion_condition": "",
    "completion_reward": {}
  },

  "memory_surfaces": {
    "id": "memory_surfaces",
    "name": "Memory Surfaces",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_NEGATIVE,
    "description": "An old memory rises unbidden, bringing mixed feelings with it.",
    "spawns": [
      {"resource": "nostalgia", "amount": 4, "location": "center"},
      {"resource": "grief", "amount": 2, "location": "random"}
    ],
    "choices": [
      {
        "text": "Reflect on it",
        "effect": {"spawns": [{"resource": "insight", "amount": 1, "location": "center"}]}
      },
      {
        "text": "Let it pass",
        "effect": {}
      }
    ],
    "completion_condition": "",
    "completion_reward": {}
  },

  "social_moment": {
    "id": "social_moment",
    "name": "Social Moment",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_POSITIVE,
    "description": "A meaningful connection with another person.",
    "spawns": [
      {"resource": "love", "amount": 3, "location": "center"}
    ],
    "conditional_spawns": {
      "loneliness > 5": [{"resource": "loneliness", "amount": 2, "location": "center"}]
    },
    "choices": [],
    "completion_condition": "",
    "completion_reward": {}
  },

  "creative_spark": {
    "id": "creative_spark",
    "name": "Creative Spark",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_POSITIVE,
    "description": "An idea strikes! Curiosity and inspiration flow.",
    "spawns": [
      {"resource": "curiosity", "amount": 4, "location": "random"},
      {"resource": "joy", "amount": 2, "location": "random"}
    ],
    "choices": [],
    "completion_condition": "",
    "completion_reward": {}
  },

  "body_check_in": {
    "id": "body_check_in",
    "name": "Body Check-In",
    "phase": EventPhase.ANY,
    "type": EventType.MINOR_NEGATIVE,
    "description": "You become aware of physical tension you've been carrying.",
    "spawns": [
      {"resource": "tension", "amount": 3, "location": "center"}
    ],
    "choices": [
      {
        "text": "Stretch and breathe",
        "effect": {"spawns": [{"resource": "calm", "amount": 2, "location": "center"}], "energy_cost": 1}
      },
      {
        "text": "Ignore it for now",
        "effect": {"spawns": [{"resource": "tension", "amount": 2, "location": "random"}]}
      }
    ],
    "completion_condition": "",
    "completion_reward": {}
  }
}

static func get_definition(event_id: String) -> Dictionary:
  return definitions.get(event_id, {})

static func get_all_ids() -> Array:
  return definitions.keys()

static func get_events_by_phase(phase: EventPhase) -> Array:
  var result = []
  for event_id in definitions:
    var event = definitions[event_id]
    if event.get("phase") == phase or event.get("phase") == EventPhase.ANY:
      result.append(event_id)
  return result

static func get_events_by_type(type: EventType) -> Array:
  var result = []
  for event_id in definitions:
    var event = definitions[event_id]
    if event.get("type") == type:
      result.append(event_id)
  return result

static func get_inciting_incidents() -> Array:
  return get_events_by_type(EventType.INCITING_INCIDENT)

static func get_minor_events() -> Array:
  var result = []
  result.append_array(get_events_by_type(EventType.MINOR_POSITIVE))
  result.append_array(get_events_by_type(EventType.MINOR_NEGATIVE))
  return result
