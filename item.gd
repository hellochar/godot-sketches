extends Resource
class_name Item

enum ETier {
  Basic,
  Advanced,
  Futuristic
}

enum ETag {
  Structure,
  Living,
  Waste,
}

@export var name: String:
  get:
    var str: String = ""
    if resource_path == "":
      str = name_override
      if name_override == "":
        str = "???"
    else:
      str = resource_path.get_file().get_basename().capitalize()
    if ETag.Structure not in tags:
      if tier == ETier.Advanced:
        str = "[color=orange]" + str + "[/color]"
      elif tier == ETier.Futuristic:
        str = "[color=purple]" + str + "[/color]"
    return str

@export var name_override: String
@export var description: String
@export var icon: Texture2D
@export var tier: ETier
@export var tags: Array[ETag] = []

func tick(inventory: World.Inventory, amount: int, ticks: int) -> Dictionary[Item, int]:
  return {}
