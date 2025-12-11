extends Resource
class_name Res

enum ETier {
  Basic,
  Advanced,
  Futuristic
}

enum ETag {
}

@export var name: String:
  get:
    return resource_path.get_file().get_basename().capitalize()

@export var description: String
@export var icon: Texture2D
@export var tier: ETier
@export var tags: Array[ETag]
