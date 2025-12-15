extends Control
class_name Dec_14_2025

# single player extraction + roguelike:
# 
# - Maybe adapt Twilight Dungeons to this?
# - Maybe make a card/deck-builder where you take cards and get to bring them home, to Slay-the-spire-esque gameplay?
# - 2d topdown turn-based gam
# - Add the PoE2 totem build paths, e.g. skill gems and meta gems, triggers and invocations

static var main: Dec_14_2025

enum EGameState {
  AtHome,
  Adventuring,
}

var game_state: EGameState = EGameState.AtHome
var player: Unit
var homebase_inventory: World.Inventory = World.Inventory.new(15, "Homebase", 10)
var adventuring_inventory: World.Inventory = World.Inventory.new(5, "Backpack", 7)
var enemies: World.Inventory = World.Inventory.new(-1, "Enemies")

func _ready() -> void:
  main = self
  %PlayerCard.set_item(player, 1)
  %HomebaseInventory.set_inventory(homebase_inventory)
  %AdventuringInventory.set_inventory(adventuring_inventory)

func _on_go_home_pressed() -> void:
  # transfer all items from current inventory to homebase
  homebase_inventory.take_all_from(adventuring_inventory)
  enemies.clear()

func _process(delta: float) -> void:
  refresh_ui()

func refresh_ui() -> void:
  # we're either at home, or adventuring.
  # when at home, show homebase inventory, adventuring inventory, and the begin adventure button. hide adventurepanel
  # when adventuring, show adventuring inventory and adventure panel
  if game_state == EGameState.AtHome:
    %HomebaseInventory.visible = true
    %AdventuringInventory.visible = true
    %BeginAdventureButton.visible = true
    %AdventurePanel.visible = false
  else:
    %HomebaseInventory.visible = false
    %AdventuringInventory.visible = true
    %BeginAdventureButton.visible = false
    %AdventurePanel.visible = true

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

class Enemy extends Unit:
  func _init() -> void:
    name_override = "Enemy"
    description = "Attacks for %d-%d damage." % [damage_min, damage_max]
  
  func tick(inventory: World.Inventory, amount: int, ticks: int) -> Dictionary[Item, int]:
    # attack player
    if Dec_14_2025.main.player:
      var dmg = randi() % (damage_max - damage_min + 1) + damage_min
      Dec_14_2025.main.player.health -= dmg
      print("%s attacks Player for %d damage!" % [name, dmg])
    return {}