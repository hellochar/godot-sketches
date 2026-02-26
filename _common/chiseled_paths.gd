class_name ChiseledPaths
extends RefCounted

enum CellState { OPEN, BLOCKED, FORCED }


class CellSet:
  var _index_map: Dictionary = {}
  var _cells: Array[Vector2i] = []

  func contains(cell: Vector2i) -> bool:
    return _index_map.has(cell)

  func add(cell: Vector2i) -> void:
    if _index_map.has(cell):
      return
    _index_map[cell] = _cells.size()
    _cells.append(cell)

  func remove(cell: Vector2i) -> void:
    if not _index_map.has(cell):
      return
    var idx: int = _index_map[cell]
    _index_map.erase(cell)
    var last_idx := _cells.size() - 1
    if idx < last_idx:
      var other := _cells[last_idx]
      _cells[idx] = other
      _index_map[other] = idx
    _cells.pop_back()

  func random_cell() -> Vector2i:
    return _cells[randi() % _cells.size()]

  func size() -> int:
    return _cells.size()

  func get_cells() -> Array[Vector2i]:
    return _cells


static func path(w: int, h: int, points: Array[Vector2i], wiggliness: float = 1.0) -> Array[Vector2i]:
  var result := generate(w, h, points, wiggliness)
  var forced: Array[Vector2i] = []
  forced.assign(result["forced"])
  return forced


static func generate(w: int, h: int, points: Array[Vector2i], wiggliness: float = 1.0) -> Dictionary:
  var states: Array[int] = []
  states.resize(w * h)
  states.fill(CellState.OPEN)

  var close_order: Array[int] = []
  close_order.resize(w * h)
  close_order.fill(-1)

  var open := CellSet.new()
  for x in w:
    for y in h:
      open.add(Vector2i(x, y))

  for p in points:
    open.remove(p)
    states[p.x * h + p.y] = CellState.FORCED

  var witness := _find_witness_tree(w, h, points, states)
  var step := 0

  while open.size() > 0:
    var c: Vector2i
    if is_equal_approx(wiggliness, 1.0):
      c = open.random_cell()
    else:
      c = _weighted_random_open_cell(open, witness, wiggliness)

    states[c.x * h + c.y] = CellState.BLOCKED
    close_order[c.x * h + c.y] = step
    open.remove(c)

    if witness.contains(c):
      var new_witness := _find_witness_tree(w, h, points, states)
      if new_witness == null:
        states[c.x * h + c.y] = CellState.FORCED
      else:
        witness = new_witness
    step += 1

  var forced: Array[Vector2i] = []
  for x in w:
    for y in h:
      if states[x * h + y] == CellState.FORCED:
        forced.append(Vector2i(x, y))
  return {
    "forced": forced,
    "states": states.duplicate(),
    "witness": witness.get_cells().duplicate(),
    "close_order": close_order,
    "total_steps": step,
  }


static func generate_steps(w: int, h: int, points: Array[Vector2i], wiggliness: float = 1.0) -> Array[Dictionary]:
  var steps: Array[Dictionary] = []
  var states: Array[int] = []
  states.resize(w * h)
  states.fill(CellState.OPEN)

  var open := CellSet.new()
  for x in w:
    for y in h:
      open.add(Vector2i(x, y))

  for p in points:
    open.remove(p)
    states[p.x * h + p.y] = CellState.FORCED

  var witness := _find_witness_tree(w, h, points, states)
  steps.append(_snapshot(w, h, states, witness))

  while open.size() > 0:
    var c: Vector2i
    if is_equal_approx(wiggliness, 1.0):
      c = open.random_cell()
    else:
      c = _weighted_random_open_cell(open, witness, wiggliness)

    states[c.x * h + c.y] = CellState.BLOCKED
    open.remove(c)

    if witness.contains(c):
      var new_witness := _find_witness_tree(w, h, points, states)
      if new_witness == null:
        states[c.x * h + c.y] = CellState.FORCED
      else:
        witness = new_witness

    steps.append(_snapshot(w, h, states, witness))

  return steps


static func _snapshot(w: int, h: int, states: Array[int], witness: CellSet) -> Dictionary:
  var forced: Array[Vector2i] = []
  for x in w:
    for y in h:
      if states[x * h + y] == CellState.FORCED:
        forced.append(Vector2i(x, y))
  return {
    "forced": forced,
    "states": states.duplicate(),
    "witness": witness.get_cells().duplicate(),
  }


static func state_name(state: int) -> String:
  match state:
    CellState.OPEN: return "OPEN"
    CellState.BLOCKED: return "BLOCKED"
    CellState.FORCED: return "FORCED"
    _: return "UNKNOWN"


static func _find_witness_tree(w: int, h: int, points: Array[Vector2i], states: Array[int]) -> CellSet:
  if points.size() < 2:
    var single := CellSet.new()
    if points.size() == 1:
      single.add(points[0])
    return single

  var distances: Dictionary = {}
  var current: Array[Vector2i] = [points[0]]
  distances[points[0]] = 0
  var current_dist := 0

  while current.size() > 0:
    var next_cells: Array[Vector2i] = []
    for cell in current:
      for neighbor in _neighbors(w, h, cell):
        if distances.has(neighbor):
          continue
        if states[neighbor.x * h + neighbor.y] == CellState.BLOCKED:
          continue
        distances[neighbor] = current_dist + 1
        next_cells.append(neighbor)
    current = next_cells
    current_dist += 1

  for i in range(1, points.size()):
    if not distances.has(points[i]):
      return null

  var tree := CellSet.new()
  tree.add(points[0])

  for i in range(1, points.size()):
    var c := points[i]
    tree.add(c)
    var d: int = distances[c]
    while d > 0:
      var candidates: Array[Vector2i] = []
      var tree_candidates: Array[Vector2i] = []
      for n in _neighbors(w, h, c):
        if distances.has(n) and distances[n] == d - 1:
          candidates.append(n)
          if tree.contains(n):
            tree_candidates.append(n)
      if tree_candidates.size() > 0:
        c = tree_candidates[randi() % tree_candidates.size()]
        tree.add(c)
        break
      c = candidates[randi() % candidates.size()]
      tree.add(c)
      d -= 1

  return tree


static func _neighbors(w: int, h: int, cell: Vector2i) -> Array[Vector2i]:
  var result: Array[Vector2i] = []
  if cell.x > 0:
    result.append(Vector2i(cell.x - 1, cell.y))
  if cell.x < w - 1:
    result.append(Vector2i(cell.x + 1, cell.y))
  if cell.y > 0:
    result.append(Vector2i(cell.x, cell.y - 1))
  if cell.y < h - 1:
    result.append(Vector2i(cell.x, cell.y + 1))
  return result


static func _weighted_random_open_cell(open: CellSet, witness: CellSet, wiggliness: float) -> Vector2i:
  var open_on_path: Array[Vector2i] = []
  for cell in witness.get_cells():
    if open.contains(cell):
      open_on_path.append(cell)

  var path_weight := open_on_path.size() * wiggliness
  var non_path_weight := (open.size() - open_on_path.size()) * 1.0
  var total := path_weight + non_path_weight
  var r := randf() * total

  if r <= path_weight and open_on_path.size() > 0:
    return open_on_path[randi() % open_on_path.size()]
  else:
    var non_path: Array[Vector2i] = []
    for cell in open.get_cells():
      if not witness.contains(cell):
        non_path.append(cell)
    if non_path.size() > 0:
      return non_path[randi() % non_path.size()]
    return open.random_cell()
