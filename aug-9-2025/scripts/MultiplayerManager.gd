extends Node
# Autoload (singleton) that manages ENet multiplayer peer and basic events.

signal player_joined(id)
signal player_left(id)
signal chat_message(sender_id, text)
signal fire_state_changed(intensity, fuel)

const DEFAULT_PORT := 4242
const MAX_CLIENTS := 32

var is_host := false
var _peer : ENetMultiplayerPeer

var fire_intensity: float = 1.0
var fire_fuel: float = 10.0 # arbitrary units
var fire_decay_rate: float = 0.2 # fuel per second consumed

# Called from host only: periodically broadcasts fire state
var _fire_timer := 0.0
const FIRE_BROADCAST_INTERVAL := 0.5

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print("MultiplayerManager ready")

func host(port: int = DEFAULT_PORT):
	_peer = ENetMultiplayerPeer.new()
	var err = _peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	is_host = true
	print("Hosting on port %d" % port)
	return OK

func join(address: String, port: int = DEFAULT_PORT):
	_peer = ENetMultiplayerPeer.new()
	var err = _peer.create_client(address, port)
	if err != OK:
		push_error("Failed to connect: %s" % err)
		return err
	multiplayer.multiplayer_peer = _peer
	is_host = false
	print("Connecting to %s:%d" % [address, port])
	return OK

func _process(delta):
	if is_host:
		_fire_timer += delta
		fire_fuel = max(fire_fuel - fire_decay_rate * delta, 0.0)
		fire_intensity = clamp(fire_fuel / 10.0, 0.0, 5.0)
		if _fire_timer >= FIRE_BROADCAST_INTERVAL:
			_fire_timer = 0.0
			rpc("sync_fire_state", fire_intensity, fire_fuel)

@rpc
func send_chat(text: String):
	text = text.strip_edges()
	if text.is_empty():
		return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: # host calling locally
		sender = multiplayer.get_unique_id()
	rpc("receive_chat", sender, text)

@rpc
func feed_fire(log_amount: float = 3.0):
	# Called by clients; authority is server so only host executes logic
	if multiplayer.is_server():
		fire_fuel = min(fire_fuel + log_amount, 50.0)
		rpc("sync_fire_state", fire_intensity, fire_fuel) # intensity recalculated in _process soon

@rpc
func sync_fire_state(intensity: float, fuel: float):
	fire_intensity = intensity
	fire_fuel = fuel
	emit_signal("fire_state_changed", intensity, fuel)

@rpc
func receive_chat(sender_id: int, text: String):
	emit_signal("chat_message", sender_id, text)

func _on_peer_connected(id):
	emit_signal("player_joined", id)
	if is_host:
		# Give new peer the current fire state
		rpc_id(id, "sync_fire_state", fire_intensity, fire_fuel)

func _on_peer_disconnected(id):
	emit_signal("player_left", id)

func _on_server_disconnected():
	print("Disconnected from server")

