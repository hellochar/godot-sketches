extends CharacterBody2D

@export var speed: float = 140.0
var player_id: int = 0

var name_label: Label

func _ready():
	player_id = multiplayer.get_unique_id() if player_id == 0 else player_id
	name_label = $NameLabel
	name_label.text = str(player_id)

func _physics_process(_delta):
	if not _is_local():
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"): dir.x -= 1
	if Input.is_action_pressed("ui_down"): dir.y += 1
	if Input.is_action_pressed("ui_up"): dir.y -= 1
	velocity = dir.normalized() * speed
	move_and_slide()
	if dir != Vector2.ZERO:
		rpc("sync_transform", global_position, rotation)

func _is_local() -> bool:
	return player_id == multiplayer.get_unique_id()

@rpc
func sync_transform(pos: Vector2, rot: float):
	if _is_local():
		return
	global_position = pos
	rotation = rot
