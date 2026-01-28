class_name Word
extends Resource

var word: String:
  get:
    if resource_path == "":
      return "???"
    else:
      return resource_path.get_file().get_basename().capitalize()
@export var associations: Array[Word] = []