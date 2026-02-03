class_name AttunementComponent
extends BuildingComponent

var attunement_levels: Dictionary = {}
var attuned_partners: Array[Node] = []

func on_process(delta: float) -> void:
  var old_attuned = attuned_partners.duplicate()

  if not building.is_in_harmony:
    _decay_attunement(delta, old_attuned)
    return

  _build_attunement(delta)

func _decay_attunement(delta: float, old_attuned: Array) -> void:
  for partner_id in attunement_levels.keys():
    var was_above_threshold = attunement_levels[partner_id] >= config.attunement_threshold
    attunement_levels[partner_id] = maxf(0.0, attunement_levels[partner_id] - config.attunement_decay_on_break * delta)
    var is_above_threshold = attunement_levels[partner_id] >= config.attunement_threshold
    if was_above_threshold and not is_above_threshold:
      for old_partner in old_attuned:
        if old_partner.get_instance_id() == partner_id:
          event_bus.attunement_broken.emit(building, old_partner)
          break
    if attunement_levels[partner_id] <= 0:
      attunement_levels.erase(partner_id)
  _update_attuned_partners()

func _build_attunement(delta: float) -> void:
  for partner in building.harmony_partners:
    var partner_id = partner.get_instance_id()
    var current = attunement_levels.get(partner_id, 0.0)
    var new_level = minf(current + config.attunement_gain_rate * delta, config.attunement_max_level)
    var was_attuned = current >= config.attunement_threshold
    var is_attuned = new_level >= config.attunement_threshold
    attunement_levels[partner_id] = new_level
    if not was_attuned and is_attuned:
      event_bus.attunement_achieved.emit(building, partner)
    if new_level > current and int(new_level * 10) > int(current * 10):
      event_bus.attunement_progress.emit(building, partner, new_level)
  _update_attuned_partners()

func _update_attuned_partners() -> void:
  attuned_partners.clear()
  for partner in building.harmony_partners:
    var partner_id = partner.get_instance_id()
    if attunement_levels.get(partner_id, 0.0) >= config.attunement_threshold:
      attuned_partners.append(partner)

func is_attuned_with(partner: Node) -> bool:
  return partner in attuned_partners

func get_speed_multiplier() -> float:
  if attuned_partners.is_empty():
    return 1.0
  return 1.0 + config.attunement_speed_bonus * attuned_partners.size()

func get_output_bonus() -> int:
  if attuned_partners.is_empty():
    return 0
  return config.attunement_output_bonus * attuned_partners.size()

func get_storage_bonus() -> int:
  if attuned_partners.is_empty():
    return 0
  return config.attunement_storage_bonus * attuned_partners.size()

func try_synergy() -> Dictionary:
  var result = {"triggered": false}
  if attuned_partners.is_empty():
    return result
  for partner in attuned_partners:
    var pair_key = "%s+%s" % [building.building_id, partner.building_id]
    var reverse_key = "%s+%s" % [partner.building_id, building.building_id]
    var synergy = config.attunement_synergy_bonuses.get(pair_key, config.attunement_synergy_bonuses.get(reverse_key, {}))
    if synergy.is_empty():
      continue
    if synergy.has("output_type") and synergy.has("chance"):
      if randf() < synergy["chance"]:
        result["triggered"] = true
        result["output_type"] = synergy["output_type"]
        result["amount"] = 1
        event_bus.attunement_synergy_triggered.emit(building, partner, synergy["output_type"])
    if synergy.has("tension_reduction"):
      var reduced = building.remove_from_storage("tension", synergy["tension_reduction"])
      if reduced > 0:
        result["triggered"] = true
        event_bus.attunement_synergy_triggered.emit(building, partner, "tension_reduction")
    if synergy.has("calm_bonus"):
      result["triggered"] = true
      result["calm_bonus"] = synergy["calm_bonus"]
    if synergy.has("energy_bonus"):
      result["triggered"] = true
      result["energy_bonus"] = synergy["energy_bonus"]
  return result
