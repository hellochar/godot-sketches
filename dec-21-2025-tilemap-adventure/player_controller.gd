extends TopDownMovement

@export var plants: int = 0

func add_plants(amount: int) -> void:
  plants += amount
