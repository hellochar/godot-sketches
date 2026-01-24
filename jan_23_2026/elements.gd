class_name Elements

enum Type { FIRE, WATER, EARTH, AIR, LIGHTNING, ICE }

const NAMES := {
  Type.FIRE: "Fire",
  Type.WATER: "Water",
  Type.EARTH: "Earth",
  Type.AIR: "Air",
  Type.LIGHTNING: "Lightning",
  Type.ICE: "Ice"
}

const COLORS := {
  Type.FIRE: Color(1.0, 0.3, 0.1),
  Type.WATER: Color(0.2, 0.5, 1.0),
  Type.EARTH: Color(0.6, 0.4, 0.2),
  Type.AIR: Color(0.8, 0.9, 1.0),
  Type.LIGHTNING: Color(1.0, 1.0, 0.3),
  Type.ICE: Color(0.7, 0.9, 1.0)
}

const BEATS := {
  Type.FIRE: [Type.ICE, Type.AIR],
  Type.WATER: [Type.FIRE, Type.EARTH],
  Type.EARTH: [Type.LIGHTNING, Type.WATER],
  Type.AIR: [Type.EARTH, Type.ICE],
  Type.LIGHTNING: [Type.WATER, Type.AIR],
  Type.ICE: [Type.LIGHTNING, Type.FIRE]
}


static func get_text_color(bg_color: Color) -> Color:
  var luminance := 0.299 * bg_color.r + 0.587 * bg_color.g + 0.114 * bg_color.b
  return Color.BLACK if luminance > 0.5 else Color.WHITE


static func resolve_battle(attacker: Type, defender: Type) -> int:
  if attacker == defender:
    return 0
  if defender in BEATS[attacker]:
    return 1
  return -1
