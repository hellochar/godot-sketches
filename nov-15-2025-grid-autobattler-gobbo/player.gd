extends GobboGameEntity
class_name GobboPlayer

@export var forward: Vector2i
@export var deck: Container

func other() -> GobboPlayer:
  return GobboGame.main.human if self == GobboGame.main.npc else GobboGame.main.npc

func play_next_card_from_deck() -> void:
  print ("%s playing next card" % [name])
  if not deck or deck.get_child_count() == 0:
    print ("%s no deck cards" % [name])
    return

  var card_node = deck.get_child(-1)
  print ("Got card node: %s" % [card_node])
  if card_node is GobboCard:
    var card = card_node as GobboCard
    print ("Playing card %s from deck for player %s" % [card.display_name, name])
    GobboGame.main.play_card(card, self)

func play_card(card: GobboCard, cell_pos: Vector2i) -> void:
  card._owner = self
  var cell_index = GobboGame.main.pos_to_index(cell_pos)
  var cell = GobboGame.main.grid.get_child(cell_index)
  deck.remove_child(card)
  cell.add_child(card)
  print ("Player %s played card %s to cell %s" % [name, card.display_name, cell_pos])

func _process(delta):
  # replace instances of {hp}/20 with current hp/20
  $Label.text = "%s\nhp %s/20" % [name, health]
