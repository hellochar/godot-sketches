extends Resource
class_name Item

enum ETier {
  Basic,
  Advanced,
  Futuristic
}

enum ETag {
  Structure
}

@export var name: String:
  get:
    if resource_path == "":
      return description
    return resource_path.get_file().get_basename().capitalize()

@export var description: String
@export var icon: Texture2D
@export var tier: ETier
@export var tags: Array[ETag] = []

func _process(inventory: World.Inventory, amount: int, delta: float) -> void:
  pass