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

var wilderness: World.Inventory = World.Inventory.new(-1, "Wilderness")
var adventure_depth: int = 0
@export var portal_drop_interval: int = 3

func on_enemies_defeated() -> void:
  if adventure_depth % portal_drop_interval == 0:
    wilderness.add(PortalHome.new(), 1)

func _ready() -> void:
  main = self
  %PlayerCard.set_item(player, 1)
  %HomebaseInventory.set_inventory(homebase_inventory)
  %AdventuringInventory.set_inventory(adventuring_inventory)

func _on_go_home_pressed() -> void:
  # transfer all items from current inventory to homebase
  homebase_inventory.take_all_from(adventuring_inventory)
  wilderness.clear()

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
  
  func use(inventory: World.Inventory, amount: int) -> void:
    # attack first enemy in wilderness
    var first_enemy: Enemy = Dec_14_2025.main.wilderness.dict.keys().filter(
      func(i: Item): return i is Enemy
    ).front() as Enemy
    if first_enemy:
      first_enemy.take_damage(damage)

class Defend extends Item:
  @export var block: int
  func _init(_block: int) -> void:
    block = _block
    name_override = "Defend"
    description = "Grants %d block." % block

  func use(inventory: World.Inventory, amount: int) -> void:
    pass

class Unit extends Item:
  var health: int
  var max_health: int
  var damage_min: int
  var damage_max: int

  func _init() -> void:
    self.pickupable = false

  func take_damage(amount: int) -> void:
    health -= amount
    print("%s takes %d damage!" % [name, amount])
    if health <= 0:
      die()
  
  func die() -> void:
    if Dec_14_2025.main.wilderness.dict.has(self):
      Dec_14_2025.main.wilderness.remove(self, 1)
      print("%s has been defeated!" % name)

class Enemy extends Unit:
  var drop_chance: float = 0.5

  func _init() -> void:
    name_override = "Enemy"
    description = "Attacks for %d-%d damage." % [damage_min, damage_max]

  func die() -> void:
    super.die()
    if randf() < drop_chance:
      var basic_items = ItemLibrary.get_by_tier(Item.ETier.Basic).filter(
        func(i: Item): return i.pickupable
      )
      if basic_items.size() > 0:
        Dec_14_2025.main.wilderness.add(basic_items.pick_random(), 1)

  func tick(inventory: World.Inventory, amount: int, ticks: int) -> Dictionary[Item, int]:
    # attack player
    if Dec_14_2025.main.player:
      var dmg = randi() % (damage_max - damage_min + 1) + damage_min
      Dec_14_2025.main.player.health -= dmg
      print("%s attacks Player for %d damage!" % [name, dmg])
    return {}

class PortalHome extends Item:
  func _init() -> void:
    name_override = "Portal Home"
    description = "Use to return home safely."

  func use(_inventory: World.Inventory, _amount: int) -> void:
    Dec_14_2025.main.game_state = Dec_14_2025.EGameState.AtHome
    Dec_14_2025.main.homebase_inventory.take_all_from(Dec_14_2025.main.adventuring_inventory)
    Dec_14_2025.main.wilderness.clear()
    Dec_14_2025.main.adventure_depth = 0