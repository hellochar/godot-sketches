@tool
extends GobboGameEntity
class_name GobboCard

@export var display_name: String = ""
@export var types: Array[String] = []
@export var mana_given := 0
@export var base_damage := 0
@export var _owner: GobboPlayer
@export var attacks: bool

var pos: Vector2i:
  get:
    var is_in_grid := get_parent().get_parent() == GobboGame.main.grid
    if not is_in_grid:
      return Vector2i(-1, -1)

    var cell_index := get_parent().get_index()
    return GobboGame.main.index_to_pos(cell_index)

func _ready() -> void:
  add_to_group("cards")
  %Name.text = display_name
  _process(0)

func _enter_tree() -> void:
  if pos != Vector2i(-1, -1):
    enter_play()

func _exit_tree() -> void:
  if pos != Vector2i(-1, -1):
    leave_play()

func enter_play() -> void:
  GobboGame.main.turn_entities.append(self)
  # if we're in a cell, center ourselves
  var is_in_grid := get_parent().get_parent() == GobboGame.main.grid
  if is_in_grid:
    position = Vector2(5, 5)

func leave_play() -> void:
  GobboGame.main.turn_entities.erase(self)

func _process(_delta: float) -> void:
  if Engine.is_editor_hint():
    return

  var lines: Array[String] = []

  if base_damage > 0:
    lines.append("🗡️%s" % [base_damage])

  if mana_given > 0:
    lines.append("🔷%s" % [mana_given])

  if health != -1:
    lines.append("❤️%s" % [health])

  $Stats.text = " ".join(lines)


func take_turn() -> void:
  if attacks:
    await attack_forward()

func attack_forward() -> void:
  var target_pos := pos + _owner.forward
  var entity := GobboGame.main.entity_at(target_pos)
  var guard = 0
  while not entity && guard < GobboGame.main.rows * 2:
    guard += 1
    target_pos += _owner.forward
    entity = GobboGame.main.entity_at(target_pos)
    if entity && !entity.is_attackable():
      entity = null
  if entity:
    await play_attack_animation(
      entity,
      func () -> void: attack(entity, base_damage)
    ).finished
