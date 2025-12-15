extends Control
class_name Dec_14_2025

# single player extraction + roguelike:
# 
# - Maybe adapt Twilight Dungeons to this?
# - Maybe make a card/deck-builder where you take cards and get to bring them home, to Slay-the-spire-esque gameplay?
# - 2d topdown turn-based gam
# - Add the PoE2 totem build paths, e.g. skill gems and meta gems, triggers and invocations

static var main: Dec_14_2025

var player: Unit
var homebase_inventory: World.Inventory = World.Inventory.new(15, "Homebase", 10)
var current_inventory: World.Inventory = World.Inventory.new(5, "Backpack", 7)
var enemies: World.Inventory = World.Inventory.new(-1, "Enemies")

func _ready() -> void:
  main = self
  %PlayerCard.set_item(player, 1)

func _on_go_home_pressed() -> void:
  # transfer all items from current inventory to homebase
  homebase_inventory.take_all_from(current_inventory)
  enemies.clear()

class Attack extends Item:
  @export var damage: int
  func _init(_damage: int) -> void:
    damage = _damage
    name_override = "Attack"
    description = "Deals %d damage." % damage
  
  func use() -> void:
    pass

class Defend extends Item:
  @export var block: int
  func _init(_block: int) -> void:
    block = _block
    name_override = "Defend"
    description = "Grants %d block." % block

class Unit extends Item:
  var health: int
  var max_health: int
  var damage_min: int
  var damage_max: int
