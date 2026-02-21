extends Node2D
class_name GobboGame

static var main: GobboGame
func _init() -> void:
  main = self

@export var human: GobboPlayer
@export var npc: GobboPlayer
@export var grid: GridContainer
var columns: int:
  get:
    return grid.columns
var rows: int:
  get:
    return grid.get_child_count() / grid.columns

var turn_entities: Array[Node]

func index_to_pos(cell_index: int) -> Vector2i:
  return Vector2i(
    cell_index % columns,
    cell_index / columns
  )

func in_bounds(pos: Vector2i) -> bool:
  return pos.x >= 0 and pos.y >= 0 and pos.x < columns and pos.y < rows

func pos_to_index(pos: Vector2i) -> int:
  return pos.x + pos.y * columns

func card_at(pos: Vector2i) -> GobboCard:
  var index = pos_to_index(pos)
  var cell = grid.get_child(index)
  if cell && cell.get_child_count() > 0:
    return cell.get_child(0) as GobboCard
  return null

func entity_at(pos: Vector2i) -> GobboGameEntity:
  if in_bounds(pos):
    return card_at(pos)
  else:
    if pos.y < 0: # above the grid
      return npc
    elif pos.y >= rows: # below the grid
      return human
  return null

func take_turn() -> void:
  for entity in turn_entities:
    if entity is GobboCard:
      await (entity as GobboCard).take_turn()

func find_playable_cell(_card: GobboCard, player: GobboPlayer) -> Vector2i:
  var start_row := 0 if player == npc else rows - 1
  # start in start_row and go in the player's forward
  for i in range(rows):
    var y := start_row + i * player.forward.y

    # find first column that's free
    for x in range(columns):
      var pos := Vector2i(x, y)
      if card_at(pos) == null:
        return pos
  return Vector2i(-1, -1)

func play_card(card: GobboCard, player: GobboPlayer) -> void:
  var cell = find_playable_cell(card, player)
  print ("Found playable cell %s for player %s" % [cell, player.name])
  if cell != Vector2i(-1, -1):
    player.play_card(card, cell)

func _process(_delta: float) -> void:
  if Input.is_key_pressed(KEY_R) && Input.is_key_pressed(KEY_CTRL):
    get_tree().reload_current_scene()
