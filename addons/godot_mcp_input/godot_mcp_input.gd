extends Node

## Polls for input commands from godot-mcp and executes them.
## Add this as an autoload named "GodotMCPInput" in your project.

const INPUT_FILE := ".godot_mcp_input.json"
const RESPONSE_FILE := ".godot_mcp_response.json"
const POLL_INTERVAL := 0.05  # 50ms

var _project_path: String
var _input_file_path: String
var _response_file_path: String
var _poll_timer: float = 0.0
var _command_queue: Array = []
var _current_command_index: int = 0
var _waiting_until: float = 0.0
var _current_request_id: String = ""
var _errors: Array[String] = []
var _screenshot_path: String = ""

func _ready() -> void:
	_project_path = ProjectSettings.globalize_path("res://").get_base_dir()
	_input_file_path = _project_path.path_join(INPUT_FILE)
	_response_file_path = _project_path.path_join(RESPONSE_FILE)
	process_mode = Node.PROCESS_MODE_ALWAYS  # Run even when paused

func _process(delta: float) -> void:
	# Handle waiting
	if _waiting_until > 0:
		if Time.get_ticks_msec() < _waiting_until:
			return
		_waiting_until = 0
		_current_command_index += 1

	# Process queued commands
	if _command_queue.size() > 0 and _current_command_index < _command_queue.size():
		_execute_next_command()
		return

	# If we finished all commands, write response
	if _command_queue.size() > 0 and _current_command_index >= _command_queue.size():
		_write_response()
		_command_queue.clear()
		_current_command_index = 0
		_current_request_id = ""
		_errors.clear()
		_screenshot_path = ""

	# Poll for new commands
	_poll_timer += delta
	if _poll_timer >= POLL_INTERVAL:
		_poll_timer = 0.0
		_check_for_commands()

func _check_for_commands() -> void:
	if not FileAccess.file_exists(_input_file_path):
		return

	var file = FileAccess.open(_input_file_path, FileAccess.READ)
	if not file:
		return

	var text = file.get_as_text()
	file.close()

	# Delete input file immediately
	DirAccess.remove_absolute(_input_file_path)

	var data = JSON.parse_string(text)
	if data == null or not data.has("commands"):
		push_error("GodotMCPInput: Invalid command file")
		return

	_current_request_id = str(data.get("id", ""))
	_command_queue = data.commands
	_current_command_index = 0
	_errors.clear()
	_screenshot_path = ""

func _execute_next_command() -> void:
	var cmd = _command_queue[_current_command_index]
	var cmd_type = cmd.get("type", "")

	match cmd_type:
		"click":
			_do_click(cmd)
		"mouse_move":
			_do_mouse_move(cmd)
		"mouse_drag":
			_do_mouse_drag(cmd)
		"key":
			_do_key(cmd)
		"action":
			_do_action(cmd)
		"action_pulse":
			_do_action_pulse(cmd)
		"text":
			_do_text(cmd)
		"wait":
			_do_wait(cmd)
			return  # Don't increment index, wait handles it
		"screenshot":
			_do_screenshot(cmd)
		_:
			_errors.append("Unknown command type: %s" % cmd_type)

	_current_command_index += 1

func _do_click(cmd: Dictionary) -> void:
	var pos = Vector2(cmd.get("x", 0), cmd.get("y", 0))
	var button = _parse_mouse_button(cmd.get("button", "left"))
	var double = cmd.get("double", false)

	# Move mouse first
	var motion = InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	Input.parse_input_event(motion)

	# Click
	var event = InputEventMouseButton.new()
	event.position = pos
	event.global_position = pos
	event.button_index = button
	event.double_click = double
	event.pressed = true
	Input.parse_input_event(event)

	# Release after short delay (use call_deferred for timing)
	await get_tree().create_timer(0.05).timeout
	event = InputEventMouseButton.new()
	event.position = pos
	event.global_position = pos
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)

func _do_mouse_move(cmd: Dictionary) -> void:
	var pos = Vector2(cmd.get("x", 0), cmd.get("y", 0))
	var event = InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	Input.parse_input_event(event)

func _do_mouse_drag(cmd: Dictionary) -> void:
	var from_pos = Vector2(cmd.get("from_x", 0), cmd.get("from_y", 0))
	var to_pos = Vector2(cmd.get("to_x", 0), cmd.get("to_y", 0))
	var button = _parse_mouse_button(cmd.get("button", "left"))

	# Move to start
	var motion = InputEventMouseMotion.new()
	motion.position = from_pos
	motion.global_position = from_pos
	Input.parse_input_event(motion)

	# Press
	var press = InputEventMouseButton.new()
	press.position = from_pos
	press.global_position = from_pos
	press.button_index = button
	press.pressed = true
	Input.parse_input_event(press)

	# Drag (interpolate)
	var steps = 10
	for i in range(steps + 1):
		var t = float(i) / steps
		var pos = from_pos.lerp(to_pos, t)
		var drag = InputEventMouseMotion.new()
		drag.position = pos
		drag.global_position = pos
		drag.button_mask = 1 << (button - 1)
		Input.parse_input_event(drag)
		await get_tree().create_timer(0.01).timeout

	# Release
	var release = InputEventMouseButton.new()
	release.position = to_pos
	release.global_position = to_pos
	release.button_index = button
	release.pressed = false
	Input.parse_input_event(release)

func _do_key(cmd: Dictionary) -> void:
	var key_string = cmd.get("key", "")
	var modifiers = cmd.get("modifiers", [])
	var keycode = _parse_keycode(key_string)

	if keycode == KEY_NONE:
		_errors.append("Unknown key: %s" % key_string)
		return

	var event = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.shift_pressed = "shift" in modifiers
	event.ctrl_pressed = "ctrl" in modifiers
	event.alt_pressed = "alt" in modifiers
	event.meta_pressed = "meta" in modifiers

	event.pressed = true
	Input.parse_input_event(event)

	await get_tree().create_timer(0.05).timeout

	event.pressed = false
	Input.parse_input_event(event)

func _do_action(cmd: Dictionary) -> void:
	var action = cmd.get("action", "")
	var pressed = cmd.get("pressed", true)

	if not InputMap.has_action(action):
		_errors.append("Unknown action: %s" % action)
		return

	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _do_action_pulse(cmd: Dictionary) -> void:
	var action = cmd.get("action", "")
	var duration_ms = cmd.get("duration_ms", 100)

	if not InputMap.has_action(action):
		_errors.append("Unknown action: %s" % action)
		return

	Input.action_press(action)
	await get_tree().create_timer(duration_ms / 1000.0).timeout
	Input.action_release(action)

func _do_text(cmd: Dictionary) -> void:
	var text = cmd.get("text", "")
	var delay_ms = cmd.get("delay_ms", 50)

	for c in text:
		var event = InputEventKey.new()
		event.unicode = c.unicode_at(0)
		event.keycode = _char_to_keycode(c)
		event.pressed = true
		Input.parse_input_event(event)

		await get_tree().create_timer(0.02).timeout

		event.pressed = false
		Input.parse_input_event(event)

		await get_tree().create_timer(delay_ms / 1000.0).timeout

func _do_wait(cmd: Dictionary) -> void:
	var duration_ms = cmd.get("duration_ms", 100)
	_waiting_until = Time.get_ticks_msec() + duration_ms

func _do_screenshot(cmd: Dictionary) -> void:
	var output_path = cmd.get("output_path", "")
	if output_path.is_empty():
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		output_path = OS.get_temp_dir().path_join("godot_screenshot_%s.png" % timestamp)

	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	var err = image.save_png(output_path)
	if err != OK:
		_errors.append("Failed to save screenshot: %s" % error_string(err))
	else:
		_screenshot_path = output_path

func _write_response() -> void:
	var response = {
		"id": _current_request_id,
		"success": _errors.is_empty(),
		"commands_executed": _current_command_index,
		"errors": _errors,
		"screenshot_path": _screenshot_path,
		"timestamp": Time.get_datetime_string_from_system(),
	}

	var file = FileAccess.open(_response_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(response, "  "))
		file.close()

func _parse_mouse_button(button: String) -> MouseButton:
	match button:
		"left": return MOUSE_BUTTON_LEFT
		"right": return MOUSE_BUTTON_RIGHT
		"middle": return MOUSE_BUTTON_MIDDLE
		_: return MOUSE_BUTTON_LEFT

func _parse_keycode(key: String) -> Key:
	# Handle special keys
	match key.to_lower():
		"space", " ": return KEY_SPACE
		"enter", "return": return KEY_ENTER
		"escape", "esc": return KEY_ESCAPE
		"tab": return KEY_TAB
		"backspace": return KEY_BACKSPACE
		"delete", "del": return KEY_DELETE
		"insert": return KEY_INSERT
		"home": return KEY_HOME
		"end": return KEY_END
		"pageup": return KEY_PAGEUP
		"pagedown": return KEY_PAGEDOWN
		"up": return KEY_UP
		"down": return KEY_DOWN
		"left": return KEY_LEFT
		"right": return KEY_RIGHT
		"shift": return KEY_SHIFT
		"ctrl", "control": return KEY_CTRL
		"alt": return KEY_ALT
		"f1": return KEY_F1
		"f2": return KEY_F2
		"f3": return KEY_F3
		"f4": return KEY_F4
		"f5": return KEY_F5
		"f6": return KEY_F6
		"f7": return KEY_F7
		"f8": return KEY_F8
		"f9": return KEY_F9
		"f10": return KEY_F10
		"f11": return KEY_F11
		"f12": return KEY_F12

	# Single character
	if key.length() == 1:
		return _char_to_keycode(key)

	return KEY_NONE

func _char_to_keycode(c: String) -> Key:
	var code = c.to_upper().unicode_at(0)
	if code >= 65 and code <= 90:  # A-Z
		return code as Key
	if code >= 48 and code <= 57:  # 0-9
		return code as Key
	return KEY_NONE
