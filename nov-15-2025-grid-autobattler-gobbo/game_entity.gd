extends Control
class_name GobboGameEntity

@export var health: int

signal died(source: GobboGameEntity)

func play_attack_animation(target: GobboGameEntity, callback: Callable) -> Tween:
  # tween move myself towards the target, then back
  var tween = create_tween()
  tween.tween_property(self, "global_position", target.global_position, 0.2)
  callback.call()
  tween.tween_property(self, "global_position", global_position, 0.5)
  return tween

func attack(target: GobboGameEntity, damage: int) -> void:
  target.take_damage(damage, self)

func take_damage(damage: int, source: GobboGameEntity) -> void:
  health -= damage
  if health <= 0:
    health = 0
    die(source)

func die(_source: GobboGameEntity) -> void:
  died.emit(_source)
  queue_free()

func is_attackable() -> bool:
  return health != -1
