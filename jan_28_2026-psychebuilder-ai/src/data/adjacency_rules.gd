extends RefCounted

const ADJACENCY_RADIUS: int = 2

enum EffectType {
  SYNERGY,
  CONFLICT,
  NEUTRAL
}

static var rules: Dictionary = {
  "mourning_chapel": {
    "memory_well": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Memory enhances grief processing"
    },
    "rumination_spiral": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.7,
      "description": "Rumination interferes with mourning"
    }
  },

  "meditation_garden": {
    "reflection_pool": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "output_bonus": 1,
      "description": "Reflection deepens meditation"
    },
    "worry_loop": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.8,
      "description": "Worry disrupts meditation"
    },
    "anxiety_diffuser": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Meditation accelerates anxiety diffusion"
    }
  },

  "reflection_pool": {
    "meditation_garden": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "output_bonus": 1,
      "description": "Meditation enhances reflection"
    },
    "mourning_chapel": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Reflection on grief yields deeper insight"
    }
  },

  "exercise_yard": {
    "sleep_chamber": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.25,
      "description": "Exercise improves rest quality"
    }
  },

  "sleep_chamber": {
    "exercise_yard": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.25,
      "description": "Rest follows exertion naturally"
    },
    "rumination_spiral": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.7,
      "description": "Racing thoughts disrupt sleep"
    },
    "worry_loop": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.8,
      "description": "Worry keeps the mind awake"
    }
  },

  "worry_loop": {
    "hope_beacon": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.8,
      "output_penalty": -1,
      "description": "Worry and hope diminish each other"
    }
  },

  "anger_forge": {
    "comfort_hearth": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.85,
      "spillover": {"tension": 1},
      "description": "Anger processing creates tension spillover"
    },
    "emergency_calm_center": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.85,
      "spillover": {"tension": 1},
      "description": "Anger processing creates tension spillover"
    }
  },

  "emotional_reservoir": {
    "mourning_chapel": {
      "type": EffectType.NEUTRAL,
      "transport_bonus": 0.2,
      "description": "Storage near processor speeds delivery"
    },
    "anxiety_diffuser": {
      "type": EffectType.NEUTRAL,
      "transport_bonus": 0.2,
      "description": "Storage near processor speeds delivery"
    },
    "reflection_pool": {
      "type": EffectType.NEUTRAL,
      "transport_bonus": 0.2,
      "description": "Storage near processor speeds delivery"
    },
    "grounding_station": {
      "type": EffectType.NEUTRAL,
      "transport_bonus": 0.2,
      "description": "Storage near processor speeds delivery"
    },
    "memory_processor": {
      "type": EffectType.NEUTRAL,
      "transport_bonus": 0.2,
      "description": "Storage near processor speeds delivery"
    }
  },

  "comfort_hearth": {
    "anxiety_diffuser": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Comfort aids anxiety processing"
    },
    "morning_routine": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.1,
      "description": "Comfort enhances daily rituals"
    }
  },

  "anxiety_diffuser": {
    "comfort_hearth": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Comfort aids anxiety processing"
    },
    "grounding_station": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.1,
      "description": "Grounding supports calm"
    }
  },

  "grounding_station": {
    "anxiety_diffuser": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.1,
      "description": "Calm supports grounding"
    },
    "inner_critic": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.85,
      "description": "Criticism undermines grounding"
    }
  },

  "morning_routine": {
    "comfort_hearth": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.1,
      "description": "Comfort enhances daily rituals"
    },
    "wound": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.9,
      "description": "Old wounds drain morning energy"
    }
  },

  "memory_well": {
    "mourning_chapel": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Grief finds natural outlet"
    },
    "memory_processor": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Memory flows easily between processing"
    }
  },

  "memory_processor": {
    "memory_well": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Memory flows easily from well"
    },
    "comfort_hearth": {
      "type": EffectType.SYNERGY,
      "conditional_output": "joy",
      "efficiency": 1.1,
      "description": "Comfort guides memories toward joy"
    }
  },

  "inner_critic": {
    "grounding_station": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.85,
      "description": "Grounding resists criticism"
    }
  },

  "integration_temple": {
    "mourning_chapel": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Processed grief enriches meaning"
    },
    "reflection_pool": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Insight flows into integration"
    },
    "gratitude_practice": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Gratitude grounds meaning"
    },
    "meditation_garden": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Stillness allows integration"
    },
    "journaling_corner": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.1,
      "description": "Written reflection aids synthesis"
    }
  },

  "hope_beacon": {
    "worry_loop": {
      "type": EffectType.CONFLICT,
      "efficiency": 0.8,
      "output_penalty": -1,
      "description": "Worry and hope diminish each other"
    },
    "wound": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.3,
      "description": "Hope shines brighter near darkness"
    },
    "despair_alchemist": {
      "type": EffectType.SYNERGY,
      "output_bonus": 1,
      "description": "Hope fuels the transformation"
    }
  },

  "love_shrine": {
    "social_connection_hub": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.25,
      "description": "Connection deepens love"
    }
  },

  "curiosity_garden": {
    "reflection_pool": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Curiosity drives deeper reflection"
    }
  },

  "emotion_fountain": {
    "hope_beacon": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.1,
      "description": "Hope sustains positive emotions"
    }
  },

  "quick_cache": {
    "mourning_chapel": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Fast storage accelerates processing"
    },
    "anxiety_diffuser": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Fast storage accelerates processing"
    },
    "memory_processor": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Fast storage accelerates processing"
    },
    "grounding_station": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Fast storage accelerates processing"
    },
    "reflection_pool": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Fast storage accelerates processing"
    },
    "anger_forge": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Fast storage accelerates processing"
    },
    "tension_release": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Fast storage accelerates processing"
    }
  },

  "meaning_radiator": {
    "integration_temple": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.25,
      "description": "Meaning cycles back through integration"
    },
    "meditation_garden": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Stillness amplifies meaning"
    }
  },

  "self_belief_forge": {
    "resilience_monument": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Resilience reinforces self-belief"
    },
    "anger_forge": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Courage forges strength"
    }
  },

  "excitement_channeler": {
    "curiosity_garden": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Excitement fuels curiosity"
    },
    "creative_studio": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Creative energy flows"
    }
  },

  "contentment_garden": {
    "gratitude_practice": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.2,
      "description": "Gratitude grows from contentment"
    },
    "comfort_hearth": {
      "type": EffectType.SYNERGY,
      "efficiency": 1.15,
      "description": "Comfort nurtures contentment"
    }
  }
}

static var generator_stacking: Dictionary = {
  "memory_well": 0.85,
  "comfort_hearth": 0.9,
  "worry_loop": 0.9,
  "wound": 0.9,
  "rumination_spiral": 0.85,
  "inner_critic": 0.9
}

static func get_adjacency_effect(building_id: String, neighbor_id: String) -> Dictionary:
  if rules.has(building_id):
    if rules[building_id].has(neighbor_id):
      return rules[building_id][neighbor_id]
  return {}

static func get_stacking_multiplier(building_id: String, count: int) -> float:
  if count <= 1:
    return 1.0
  var base = generator_stacking.get(building_id, 1.0)
  return pow(base, count - 1)

static func get_all_affecting(building_id: String) -> Array:
  var result = []
  for source_id in rules:
    if rules[source_id].has(building_id):
      result.append({"source": source_id, "effect": rules[source_id][building_id]})
  return result
