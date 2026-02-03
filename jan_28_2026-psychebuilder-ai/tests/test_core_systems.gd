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


func test_adjacency_stacking_multiplier() -> void:
  var mult_single = AdjacencyRules.get_stacking_multiplier("worry_loop", 1)
  assert_float(mult_single).is_equal(1.0)

  var mult_double = AdjacencyRules.get_stacking_multiplier("worry_loop", 2)
  assert_float(mult_double).is_greater(1.0)


func test_adjacency_radius_constant() -> void:
  assert_int(AdjacencyRules.ADJACENCY_RADIUS).is_equal(2)
