extends Item
class_name Peasants

const FOOD = preload("res://items/basic/food.tres")
const GRASS = preload("res://items/basic/grass.tres")
const HUT = preload("res://items/basic/hut.tres")
const BONES = preload("res://items/basic/bones.tres")
const STONE = preload("res://items/basic/stone.tres")
const WOOD = preload("res://items/basic/wood.tres")
const LIVESTOCK = preload("res://items/basic/livestock.tres")

func tick(inventory: World.Inventory, peasants: int, ticks: int) -> Dictionary[Item, int]:
  # separate peasants into housed and unhoused:
  # housed = min(peasants, huts * 2)
  # unhoused = peasants - housed
  # deathrate:
  #  starvation = (peasants - (food * 5)) / 5
  #  natural = housed_peasants / 20 + unhoused_peasants / 5
  # birthrate is housed_peasants / 5 + unhoused_peasants / 10, but only if starvation < 5% of peasant population

  # dead peasants turn into bones

  # unhoused peasants automatically build huts if able:
  # a hut is 1 stone, 1 wood

  # peasants automatically slaughter livestock if able:
  # one livestock is 5 food

  var changes: Dictionary[Item, int] = {}
  
  const HOUSING_PER_HUT = 2
  var huts = inventory.num(HUT)
  var housed = min(peasants, huts * HOUSING_PER_HUT)
  var unhoused = peasants - housed
  print ("Peasants: %d (Housed: %d, Unhoused: %d)" % [peasants, housed, unhoused])
  
  var food = inventory.num(FOOD)
  # var livestock_count = inventory.num(LIVESTOCK)
  var stone = inventory.num(STONE)
  var wood = inventory.num(WOOD)
  
  var new_huts_desired = int(ceil(unhoused / float(HOUSING_PER_HUT)))
  var huts_to_build = 0 # min(new_huts_desired, stone, wood)
  changes[HUT] = changes.get(HUT, 0) + huts_to_build
  changes[STONE] = changes.get(STONE, 0) - huts_to_build
  changes[WOOD] = changes.get(WOOD, 0) - huts_to_build
  huts += huts_to_build
  housed = min(peasants, huts * HOUSING_PER_HUT)
  unhoused = peasants - housed
  print ("Wanted %d huts, Built %d huts, now %d housed, %d unhoused" % [new_huts_desired, huts_to_build, housed, unhoused])
  
  var num_hungry = max(0, peasants - (food * 5))

  # if livestock_count > 0:
  #   var to_slaughter = min(livestock_count, int(ceil(num_hungry / 5.0)))
  #   changes[LIVESTOCK] = changes.get(LIVESTOCK, 0) - to_slaughter
  #   changes[FOOD] = changes.get(FOOD, 0) + to_slaughter * 5
  #   food += to_slaughter * 5
  #   num_hungry = max(0, peasants - (food * 5))
  #   print ("Slaughtered %d livestock for %d food" % [to_slaughter, to_slaughter * 5])
  
  print ("Num hungry: %d" % num_hungry)

  var starvation = max(0, num_hungry / 5)
  # if there's absolutely no food, make starvation at least 1
  if food == 0 and peasants > 0:
    starvation = max(starvation, 1)
  var natural = housed / 20 + unhoused / 5
  var deaths = int(starvation + natural)

  print ("Starvation: %d, Natural: %d, Total deaths: %d" % [int(starvation), int(natural), deaths])
  
  if deaths > 0:
    changes[self as Item] = changes.get(self as Item, 0) - deaths
    changes[BONES] = changes.get(BONES, 0) + deaths
  
  if starvation < peasants * 0.05:
    var births = int(housed / 5 + unhoused / 10)
    changes[self as Item] = changes.get(self as Item, 0) + births
    print ("Births: %d" % births)
  
  # eat food (assume ticks is 1)
  var food_needed = int(ceil(peasants / 5.0))
  var food_used = min(food, food_needed)
  changes[FOOD] = changes.get(FOOD, 0) - food_used
  
  print ("Food used: %d" % food_used)
  print ("Total changes: %s" % changes)
  return changes
