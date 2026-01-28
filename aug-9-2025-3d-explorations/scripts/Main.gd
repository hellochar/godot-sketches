extends Node2D

@export var penguin_scene: PackedScene
@export var fire_scene: PackedScene

var player_penguins := {}
var fire_node: Node2D

@onready var ui_layer = $CanvasLayer
@onready var chat_ui = $CanvasLayer/ChatUI
@onready var host_button = $CanvasLayer/TopBar/HostButton
@onready var join_button = $CanvasLayer/TopBar/JoinButton
@onready var address_input = $CanvasLayer/TopBar/Address
@onready var feed_button = $CanvasLayer/TopBar/FeedButton

func _ready():
	host_button.pressed.connect(_on_host)
	join_button.pressed.connect(_on_join)
	feed_button.pressed.connect(_on_feed_fire)
	var mm = get_node("/root/MultiplayerManager")
	mm.player_joined.connect(_on_player_joined)
	mm.player_left.connect(_on_player_left)
	if penguin_scene == null:
		push_warning("Penguin scene not assigned")
	if fire_scene:
		fire_node = fire_scene.instantiate()
		fire_node.position = Vector2(400, 300)
		add_child(fire_node)

func _on_host():
	var mm = get_node("/root/MultiplayerManager")
	if mm.host() == OK:
		_spawn_local_player()

func _on_join():
	var mm = get_node("/root/MultiplayerManager")
	if mm.join(address_input.text) == OK:
		_spawn_local_player()

func _on_feed_fire():
	if fire_node:
		fire_node.feed_log()

func _spawn_local_player():
	var id = multiplayer.get_unique_id()
	if player_penguins.has(id): return
	var p = penguin_scene.instantiate()
	p.position = Vector2(randi_range(100, 700), randi_range(100, 500))
	p.player_id = id
	add_child(p)
	player_penguins[id] = p

func _on_player_joined(id):
	if id == multiplayer.get_unique_id(): return
	if player_penguins.has(id): return
	var p = penguin_scene.instantiate()
	p.player_id = id
	p.position = Vector2(400, 300)
	add_child(p)
	player_penguins[id] = p

func _on_player_left(id):
	if player_penguins.has(id):
		player_penguins[id].queue_free()
		player_penguins.erase(id)
