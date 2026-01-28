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
var homebase_inventory: World.Inventory = World.Inventory.new(30, "Homebase", 10)

var backpack: World.Inventory = World.Inventory.new(30, "Backpack", 7)

var wilderness: World.Inventory = World.Inventory.new(-1, "Wilderness")
var adventure_depth: int = 0
@export var portal_drop_interval: int = 3

func on_enemies_defeated() -> void:
  if adventure_depth % portal_drop_interval == 0:
    wilderness.add(PortalHome.new(), 1)

func _ready() -> void:
  main = self
  player = Unit.new(50)
  player.name_override = "Player"

  %PlayerCard.set_item(player, 1)
  %HomebaseInventory.set_inventory(homebase_inventory)
  %AdventuringInventory.set_inventory(backpack)
  %EnemiesUI.set_inventory(wilderness)
  backpack.add(Armor.new(5), 1)
  backpack.add(Food.new(2), 1)
  backpack.add(Food.new(2), 1)
  backpack.add(Attack.new(6), 30)

func begin_adventure() -> void:
  game_state = EGameState.Adventuring
  # backpack.take_from(homebase_inventory, PortalHome.new(), 1)
  start_depth(1)

func start_depth(depth: int) -> void:
  adventure_depth = depth
  %AdventureTitle.text = "Adventuring - Depth %d" % adventure_depth
  # generate some enemies
  var enemy_count = 1 + adventure_depth / 3
  for i in range(enemy_count):
    var enemy = Enemy.new(9 + adventure_depth * 3)
    enemy.name_override = "Goblin Lv.%d" % adventure_depth
    enemy.damage_min = adventure_depth
    enemy.damage_max = int(1 + adventure_depth * 1.3)
    enemy.update_description()
    wilderness.add(enemy, 1)

func go_home() -> void:
  game_state = EGameState.AtHome
  homebase_inventory.take_all_from(backpack)
  wilderness.clear()
  adventure_depth = 0
  player.health = player.max_health

func go_deeper() -> void:
  wilderness.clear()
  start_depth(adventure_depth + 1)

func is_in_danger() -> bool:
  for item in wilderness.dict.keys():
    if item is Enemy:
      return true
  return false

func _process(delta: float) -> void:
  player.description = "HP: %d/%d" % [player.health, player.max_health]
  for item in wilderness.dict.keys():
    if item is Enemy:
      item.process(delta)
  refresh_ui()

func refresh_ui() -> void:
  # we're either at home, or adventuring.
  # when at home, show homebase inventory, adventuring inventory, and the begin adventure button. hide adventurepanel
  # when adventuring, show adventuring inventory and adventure panel
  if game_state == EGameState.AtHome:
    %HomebaseInventory.visible = true
    %AdventuringInventory.visible = true
    %BeginAdventure.visible = true
    %AdventurePanel.visible = false
  else:
    %HomebaseInventory.visible = false
    %AdventuringInventory.visible = true
    %BeginAdventure.visible = false
    %AdventurePanel.visible = true
  %GoDeeper.visible = not is_in_danger()

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
    inventory.remove(self, 1)
    Dec_14_2025.main.wilderness.tick(1)

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
  var base_max_health: int
  var _cached_max_health: int = 0
  var max_health: int:
    get:
      var bonus = 0
      for item in Dec_14_2025.main.backpack.dict.keys():
        if item is Armor:
          bonus += item.hp_bonus * Dec_14_2025.main.backpack.dict[item]
      var new_max = base_max_health + bonus
      if new_max != _cached_max_health:
        health += new_max - _cached_max_health
        _cached_max_health = new_max
      return new_max
  var damage_min: int
  var damage_max: int

  func _init(hp: int) -> void:
    base_max_health = hp
    health = base_max_health
    _cached_max_health = base_max_health
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
  var drop_chance: float = 1
  var description_base: String

  func _init(hp: int) -> void:
    super._init(hp)
    name_override = "Enemy"
  
  func update_description() -> void:
    description_base = "Attacks for %d-%d damage." % [damage_min, damage_max]
  
  func process(delta):
    description = " HP: %d/%d\n%s" % [health, max_health, description_base]
  
  func attack_player() -> void:
    if Dec_14_2025.main.player:
      var dmg = randi() % (damage_max - damage_min + 1) + damage_min
      Dec_14_2025.main.player.health -= dmg
      print("%s attacks Player for %d damage!" % [name, dmg])

  func die() -> void:
    super.die()
    if randf() < drop_chance:
      var basic_items = ItemLibrary.get_by_tier(Item.ETier.Basic).filter(
        func(i: Item): return i.pickupable
      )
      if basic_items.size() > 0:
        Dec_14_2025.main.wilderness.add(basic_items.pick_random(), randi_range(1, 3))
    if not Dec_14_2025.main.is_in_danger():
      Dec_14_2025.main.on_enemies_defeated()

  func tick(inventory: World.Inventory, amount: int, ticks: int) -> Dictionary[Item, int]:
    # attack player
    if Dec_14_2025.main.player:
      var dmg = randi() % (damage_max - damage_min + 1) + damage_min
      Dec_14_2025.main.player.health -= dmg
      print("%s attacks Player for %d damage!" % [name, dmg])
    return {}

class PortalHome extends Item:
  func _init() -> void:
    pickupable = false
    name_override = "Portal Home"
    description = "Use to return home safely."

  func use(_inventory: World.Inventory, _amount: int) -> void:
    Dec_14_2025.main.go_home()

class Armor extends Item:
  var hp_bonus: int

  func _init(_hp_bonus: int = 10) -> void:
    hp_bonus = _hp_bonus
    name_override = "Armor +%d" % hp_bonus
    description = "+%d max HP while in backpack." % hp_bonus

class Food extends Item:
  var heal_amount: int

  func _init(_heal_amount: int = 5) -> void:
    heal_amount = _heal_amount
    # name_override = "Food +%d" % heal_amount
    if heal_amount < 3:
      name_override = "Berry"
    elif heal_amount < 7:
      name_override = "Meat"
    else:
      name_override = "Food +%d" % heal_amount
    description = "Heals %d HP." % heal_amount

  func use(_inventory: World.Inventory, _amount: int) -> void:
    if Dec_14_2025.main.player:
      Dec_14_2025.main.player.health = mini(
        Dec_14_2025.main.player.health + heal_amount,
        Dec_14_2025.main.player.max_health
      )
      _inventory.remove(self, 1)
