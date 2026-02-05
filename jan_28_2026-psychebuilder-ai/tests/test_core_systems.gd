extends GdUnitTestSuite

const GridSystemScript = preload("res://jan_28_2026-psychebuilder-ai/src/systems/grid_system.gd")
const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")
const AdjacencyRules = preload("res://jan_28_2026-psychebuilder-ai/src/data/adjacency_rules.gd")


func test_grid_coordinate_conversion() -> void:
  var grid = GridSystemScript.new()
  grid.setup(Vector2i(10, 10), 64)

  var world_pos = grid.grid_to_world(Vector2i(5, 5))
  assert_float(world_pos.x).is_equal(5 * 64 + 32)
  assert_float(world_pos.y).is_equal(5 * 64 + 32)

  var grid_coord = grid.world_to_grid(Vector2(320 + 16, 320 + 16))
  assert_int(grid_coord.x).is_equal(5)
  assert_int(grid_coord.y).is_equal(5)


func test_grid_valid_coord() -> void:
  var grid = GridSystemScript.new()
  grid.setup(Vector2i(10, 10), 64)

  assert_bool(grid.is_valid_coord(Vector2i(0, 0))).is_true()
  assert_bool(grid.is_valid_coord(Vector2i(9, 9))).is_true()
  assert_bool(grid.is_valid_coord(Vector2i(-1, 0))).is_false()
  assert_bool(grid.is_valid_coord(Vector2i(10, 0))).is_false()
  assert_bool(grid.is_valid_coord(Vector2i(0, -1))).is_false()
  assert_bool(grid.is_valid_coord(Vector2i(0, 10))).is_false()


func test_grid_occupancy() -> void:
  var grid = GridSystemScript.new()
  grid.setup(Vector2i(10, 10), 64)

  assert_bool(grid.is_occupied(Vector2i(3, 3))).is_false()

  var mock_entity = Node.new()
  grid.set_occupied(Vector2i(3, 3), mock_entity)
  assert_bool(grid.is_occupied(Vector2i(3, 3))).is_true()
  assert_object(grid.get_occupant(Vector2i(3, 3))).is_same(mock_entity)

  grid.clear_occupied(Vector2i(3, 3))
  assert_bool(grid.is_occupied(Vector2i(3, 3))).is_false()
  assert_object(grid.get_occupant(Vector2i(3, 3))).is_null()

  mock_entity.queue_free()


func test_grid_area_operations() -> void:
  var grid = GridSystemScript.new()
  grid.setup(Vector2i(10, 10), 64)

  assert_bool(grid.is_area_free(Vector2i(2, 2), Vector2i(2, 2))).is_true()

  var mock_entity = Node.new()
  grid.occupy_area(Vector2i(2, 2), Vector2i(2, 2), mock_entity)
  assert_bool(grid.is_occupied(Vector2i(2, 2))).is_true()
  assert_bool(grid.is_occupied(Vector2i(3, 2))).is_true()
  assert_bool(grid.is_occupied(Vector2i(2, 3))).is_true()
  assert_bool(grid.is_occupied(Vector2i(3, 3))).is_true()
  assert_bool(grid.is_area_free(Vector2i(2, 2), Vector2i(2, 2))).is_false()

  grid.clear_area(Vector2i(2, 2), Vector2i(2, 2))
  assert_bool(grid.is_area_free(Vector2i(2, 2), Vector2i(2, 2))).is_true()

  mock_entity.queue_free()


func test_grid_neighbors() -> void:
  var grid = GridSystemScript.new()
  grid.setup(Vector2i(10, 10), 64)

  var neighbors = grid.get_neighbors(Vector2i(5, 5))
  assert_int(neighbors.size()).is_equal(4)
  assert_bool(Vector2i(5, 4) in neighbors).is_true()
  assert_bool(Vector2i(6, 5) in neighbors).is_true()
  assert_bool(Vector2i(5, 6) in neighbors).is_true()
  assert_bool(Vector2i(4, 5) in neighbors).is_true()

  var corner_neighbors = grid.get_neighbors(Vector2i(0, 0))
  assert_int(corner_neighbors.size()).is_equal(2)


func test_grid_pathfinding_direct() -> void:
  var grid = GridSystemScript.new()
  grid.setup(Vector2i(10, 10), 64)

  var walkable = func(coord: Vector2i) -> bool: return true
  var path = grid.find_path(Vector2i(0, 0), Vector2i(3, 0), walkable)
  assert_int(path.size()).is_greater(0)
  assert_int(path[0].x).is_equal(0)
  assert_int(path[path.size() - 1].x).is_equal(3)


func test_grid_pathfinding_no_path() -> void:
  var grid = GridSystemScript.new()
  grid.setup(Vector2i(10, 10), 64)

  var unwalkable = func(coord: Vector2i) -> bool: return false
  var path = grid.find_path(Vector2i(0, 0), Vector2i(3, 0), unwalkable)
  assert_int(path.size()).is_equal(0)


func test_building_definitions_exist() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  assert_int(all_defs.size()).is_greater(0)


func test_building_definitions_have_required_fields() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  for building_id in all_defs:
    var def = all_defs[building_id]
    assert_bool(def.has("name")).is_true()
    assert_bool(def.has("behaviors")).is_true()
    assert_bool(def.has("size")).is_true()


func test_building_definitions_valid_behaviors() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  for building_id in all_defs:
    var def = all_defs[building_id]
    var behaviors = def.get("behaviors", [])
    for behavior in behaviors:
      assert_int(behavior).is_greater_equal(0)


func test_unlocked_buildings_are_valid() -> void:
  var unlocked = BuildingDefs.get_all_unlocked()
  var all_defs = BuildingDefs.get_all_definitions()

  for building_id in unlocked:
    assert_bool(all_defs.has(building_id)).is_true()


func test_processor_buildings_have_io() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  for building_id in all_defs:
    var def = all_defs[building_id]
    var behaviors = def.get("behaviors", [])
    if BuildingDefs.Behavior.PROCESSOR in behaviors:
      var has_input = def.has("input") and def["input"].size() > 0
      var has_output = def.has("output") and def["output"].size() > 0
      assert_bool(has_input).is_true()
      assert_bool(has_output).is_true()


func test_generator_buildings_have_generates() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  for building_id in all_defs:
    var def = all_defs[building_id]
    var behaviors = def.get("behaviors", [])
    if BuildingDefs.Behavior.GENERATOR in behaviors:
      assert_bool(def.has("generates")).is_true()
      assert_str(def["generates"]).is_not_empty()


func test_habit_buildings_have_habit_effects() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  for building_id in all_defs:
    var def = all_defs[building_id]
    var behaviors = def.get("behaviors", [])
    if BuildingDefs.Behavior.HABIT in behaviors:
      var has_generates = def.has("habit_generates") and def["habit_generates"].size() > 0
      var has_reduces = def.has("habit_reduces") and def["habit_reduces"].size() > 0
      var has_energy_bonus = def.has("habit_energy_bonus") and def["habit_energy_bonus"] > 0
      assert_bool(has_generates or has_reduces or has_energy_bonus).is_true()


func test_adjacency_rules_exist() -> void:
  assert_int(AdjacencyRules.rules.size()).is_greater(0)


func test_adjacency_synergy_effect() -> void:
  var effect = AdjacencyRules.get_adjacency_effect("mourning_chapel", "memory_well")
  assert_bool(effect.is_empty()).is_false()
  assert_int(effect["type"]).is_equal(AdjacencyRules.EffectType.SYNERGY)
  assert_float(effect["efficiency"]).is_greater(1.0)


func test_adjacency_conflict_effect() -> void:
  var effect = AdjacencyRules.get_adjacency_effect("mourning_chapel", "rumination_spiral")
  assert_bool(effect.is_empty()).is_false()
  assert_int(effect["type"]).is_equal(AdjacencyRules.EffectType.CONFLICT)
  assert_float(effect["efficiency"]).is_less(1.0)


func test_adjacency_no_effect() -> void:
  var effect = AdjacencyRules.get_adjacency_effect("road", "road")
  assert_bool(effect.is_empty()).is_true()


func test_adjacency_stacking_multiplier_diminishes() -> void:
  var mult_single = AdjacencyRules.get_stacking_multiplier("worry_loop", 1)
  assert_float(mult_single).is_equal(1.0)

  var mult_double = AdjacencyRules.get_stacking_multiplier("worry_loop", 2)
  assert_float(mult_double).is_less(1.0)

  var mult_triple = AdjacencyRules.get_stacking_multiplier("worry_loop", 3)
  assert_float(mult_triple).is_less(mult_double)


func test_adjacency_radius_constant() -> void:
  assert_int(AdjacencyRules.ADJACENCY_RADIUS).is_equal(2)


func test_global_effect_buildings_are_unique() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  var global_effect_ids = ["optimism_lens", "stoic_foundation", "creative_core",
    "compassion_center", "acceptance_shrine", "attention_amplifier"]
  for building_id in global_effect_ids:
    var def = all_defs.get(building_id, {})
    if not def.is_empty():
      assert_bool(def.get("unique", false)).is_true()


func test_new_orphan_resource_buildings_exist() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  var new_buildings = ["self_belief_forge", "meaning_radiator",
    "excitement_channeler", "contentment_garden", "confidence_anchor",
    "boredom_alchemist", "rest_sanctuary"]
  for building_id in new_buildings:
    assert_bool(all_defs.has(building_id)).is_true()


func test_quick_cache_has_processor_adjacencies() -> void:
  var processors = ["mourning_chapel", "anxiety_diffuser", "memory_processor",
    "grounding_station", "reflection_pool", "anger_forge", "tension_release"]
  for processor_id in processors:
    var effect = AdjacencyRules.get_adjacency_effect("quick_cache", processor_id)
    assert_bool(effect.is_empty()).is_false()
    assert_int(effect["type"]).is_equal(AdjacencyRules.EffectType.SYNERGY)


func test_integration_temple_has_adjacencies() -> void:
  var synergy_buildings = ["mourning_chapel", "reflection_pool", "gratitude_practice",
    "meditation_garden", "journaling_corner"]
  for building_id in synergy_buildings:
    var effect = AdjacencyRules.get_adjacency_effect("integration_temple", building_id)
    assert_bool(effect.is_empty()).is_false()
    assert_int(effect["type"]).is_equal(AdjacencyRules.EffectType.SYNERGY)


func test_coping_buildings_have_adjacencies() -> void:
  var coping_buildings = ["emergency_calm_center", "anger_vent", "comfort_den",
    "support_hotline", "grounding_chamber"]
  for coping_id in coping_buildings:
    var effect_count = 0
    for source_id in AdjacencyRules.rules:
      if AdjacencyRules.rules[source_id].has(coping_id):
        effect_count += 1
    if AdjacencyRules.rules.has(coping_id):
      effect_count += AdjacencyRules.rules[coping_id].size()
    assert_int(effect_count).is_greater(0)


func test_new_orphan_buildings_have_adjacencies() -> void:
  var new_buildings = ["meaning_radiator", "self_belief_forge", "excitement_channeler",
    "contentment_garden", "confidence_anchor", "boredom_alchemist", "rest_sanctuary"]
  for building_id in new_buildings:
    assert_bool(AdjacencyRules.rules.has(building_id)).is_true()
    assert_int(AdjacencyRules.rules[building_id].size()).is_greater(0)


func test_all_buildings_have_valid_behaviors() -> void:
  var all_defs = BuildingDefs.get_all_definitions()
  for building_id in all_defs:
    var def = all_defs[building_id]
    var behaviors = def.get("behaviors", [])
    assert_int(behaviors.size()).is_greater(0)


func test_key_bidirectional_adjacencies_exist() -> void:
  var bidirectional_pairs = [
    ["meditation_garden", "reflection_pool"],
    ["meditation_garden", "anxiety_diffuser"],
    ["curiosity_garden", "reflection_pool"],
    ["curiosity_garden", "excitement_channeler"],
    ["love_shrine", "social_connection_hub"],
    ["sleep_chamber", "rest_sanctuary"],
    ["comfort_hearth", "contentment_garden"],
    ["integration_temple", "mourning_chapel"],
    ["gratitude_practice", "integration_temple"],
  ]
  for pair in bidirectional_pairs:
    var a = pair[0]
    var b = pair[1]
    var effect_a_to_b = AdjacencyRules.get_adjacency_effect(a, b)
    var effect_b_to_a = AdjacencyRules.get_adjacency_effect(b, a)
    assert_bool(effect_a_to_b.is_empty()).is_false()
    assert_bool(effect_b_to_a.is_empty()).is_false()


func test_creative_studio_has_adjacencies() -> void:
  assert_bool(AdjacencyRules.rules.has("creative_studio")).is_true()
  var effect = AdjacencyRules.get_adjacency_effect("creative_studio", "excitement_channeler")
  assert_bool(effect.is_empty()).is_false()
  assert_int(effect["type"]).is_equal(AdjacencyRules.EffectType.SYNERGY)


func test_resilience_monument_has_adjacencies() -> void:
  assert_bool(AdjacencyRules.rules.has("resilience_monument")).is_true()
  var effect = AdjacencyRules.get_adjacency_effect("resilience_monument", "self_belief_forge")
  assert_bool(effect.is_empty()).is_false()
  assert_int(effect["type"]).is_equal(AdjacencyRules.EffectType.SYNERGY)


func test_journaling_corner_has_adjacencies() -> void:
  assert_bool(AdjacencyRules.rules.has("journaling_corner")).is_true()
  var synergies = ["integration_temple", "reflection_pool"]
  for building_id in synergies:
    var effect = AdjacencyRules.get_adjacency_effect("journaling_corner", building_id)
    assert_bool(effect.is_empty()).is_false()
    assert_int(effect["type"]).is_equal(AdjacencyRules.EffectType.SYNERGY)
