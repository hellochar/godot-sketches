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
    var s: String = ""
    if resource_path == "":
      s = name_override
      if name_override == "":
        s = "???"
    else:
      s = resource_path.get_file().get_basename().capitalize()
    if ETag.Structure not in tags:
      if tier == ETier.Advanced:
        s = "[color=orange]" + s + "[/color]"
      elif tier == ETier.Futuristic:
        s = "[color=purple]" + s + "[/color]"
    return s

@export var name_override: String
@export var description: String
@export var icon: Texture2D
@export var tier: ETier
@export var tags: Array[ETag] = []
@export var htags: PackedStringArray = []


@export var usable: bool:
  get:
    return has_method("use")

@export var pickupable: bool = true

func tick(_inventory: World.Inventory, _amount: int, _ticks: int) -> Dictionary[Item, int]:
  return {}
