extends Control

# Configuration
@export var grid_size: int = 5
@export var cell_size: float = 80.0
@export var mana_spread_rate: float = 0.1
@export var mana_decay_rate: float = 0.01
@export var overheat_threshold: float = 50.0

# Game state
var grid: Array = []  # 2D array of cells
var mana_grid: Array = []  # 2D array of floats (mana amounts in empty spaces)
var components: Array = []  # List of placed components
var points: float = 0.0
var points_per_second: float = 0.0
var points_last_frame: float = 0.0
var selected_component_type: int = 0

# VFX state
var screen_shake: float = 0.0
var flash_alpha: float = 0.0
var explosion_particles: Array = []

# Component types
enum ComponentType {
	NONE,
	MANA_GENERATOR,
	POINT_CONVERTER,
	MANA_AMPLIFIER,
	WALL
}

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

class Component:
	var type: int
	var grid_pos: Vector2i
	var port_direction: int  # Direction the port faces
	var mana_output: float = 0.0
	var mana_consumption: float = 0.0

	func _init(t: int, pos: Vector2i, dir: int):
		type = t
		grid_pos = pos
		port_direction = dir
		match type:
			ComponentType.MANA_GENERATOR:
				mana_output = 2.0
			ComponentType.POINT_CONVERTER:
				mana_consumption = 1.0
			ComponentType.MANA_AMPLIFIER:
				mana_consumption = 0.5
				mana_output = 1.5

# UI state
var hovered_cell: Vector2i = Vector2i(-1, -1)
var placement_rotation: int = Direction.NORTH

func _ready():
	_init_grid()

func _init_grid():
	grid.clear()
	mana_grid.clear()
	components.clear()
	points = 0.0
	points_per_second = 0.0
	points_last_frame = 0.0

	for x in range(grid_size):
		var col = []
		var mana_col = []
		for y in range(grid_size):
			col.append(ComponentType.NONE)
			mana_col.append(0.0)
		grid.append(col)
		mana_grid.append(mana_col)

func _process(delta):
	_simulate_mana(delta)
	_process_components(delta)
	_check_overheat()
	_update_vfx(delta)

	var current_rate = (points - points_last_frame) / delta
	points_per_second = lerp(points_per_second, current_rate, 5.0 * delta)
	points_last_frame = points

	queue_redraw()

func _get_total_mana() -> float:
	var total: float = 0.0
	for x in range(grid_size):
		for y in range(grid_size):
			total += mana_grid[x][y]
	return total

func _check_overheat():
	if _get_total_mana() >= overheat_threshold:
		_trigger_explosion()

func _trigger_explosion():
	var origin = _get_grid_origin()

	for comp in components:
		var cell_pos = origin + Vector2(comp.grid_pos.x * cell_size, comp.grid_pos.y * cell_size)
		var center = cell_pos + Vector2(cell_size / 2, cell_size / 2)
		for i in range(8):
			var angle = randf() * TAU
			var speed = randf_range(100, 300)
			explosion_particles.append({
				"pos": center,
				"vel": Vector2(cos(angle), sin(angle)) * speed,
				"life": 1.0,
				"color": Color.ORANGE
			})

	for x in range(grid_size):
		for y in range(grid_size):
			if mana_grid[x][y] > 0.1:
				var cell_pos = origin + Vector2(x * cell_size, y * cell_size)
				var center = cell_pos + Vector2(cell_size / 2, cell_size / 2)
				for i in range(3):
					var angle = randf() * TAU
					var speed = randf_range(50, 150)
					explosion_particles.append({
						"pos": center,
						"vel": Vector2(cos(angle), sin(angle)) * speed,
						"life": 0.8,
						"color": Color.CYAN
					})

	for comp in components:
		grid[comp.grid_pos.x][comp.grid_pos.y] = ComponentType.NONE
	components.clear()

	for x in range(grid_size):
		for y in range(grid_size):
			mana_grid[x][y] *= 0.5

	screen_shake = 1.0
	flash_alpha = 1.0

func _update_vfx(delta):
	screen_shake = max(0.0, screen_shake - delta * 3.0)
	flash_alpha = max(0.0, flash_alpha - delta * 4.0)

	for i in range(explosion_particles.size() - 1, -1, -1):
		var p = explosion_particles[i]
		p.pos += p.vel * delta
		p.vel *= 0.95
		p.life -= delta
		if p.life <= 0:
			explosion_particles.remove_at(i)

func _simulate_mana(delta):
	# Create a copy for calculations
	var new_mana: Array = []
	for x in range(grid_size):
		var col = []
		for y in range(grid_size):
			col.append(mana_grid[x][y])
		new_mana.append(col)

	# Spread mana between adjacent empty cells
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] != ComponentType.NONE:
				continue  # Skip cells with components

			var current_mana = mana_grid[x][y]
			var neighbors = _get_empty_neighbors(x, y)

			for neighbor in neighbors:
				var nx = neighbor.x
				var ny = neighbor.y
				var neighbor_mana = mana_grid[nx][ny]

				# Mana flows from high to low
				var diff = current_mana - neighbor_mana
				var flow = diff * mana_spread_rate * delta
				if flow > diff / 2:
					flow = diff / 2  # Prevent overshooting
				new_mana[x][y] -= flow
				new_mana[nx][ny] += flow

			# Apply decay
			new_mana[x][y] = max(0.0, new_mana[x][y] - mana_decay_rate * delta)

	mana_grid = new_mana

func _get_empty_neighbors(x: int, y: int) -> Array:
	var neighbors = []
	var offsets = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

	for offset in offsets:
		var nx = x + offset.x
		var ny = y + offset.y
		if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size:
			if grid[nx][ny] == ComponentType.NONE:
				neighbors.append(Vector2i(nx, ny))

	return neighbors

func _get_port_offset(direction: int) -> Vector2i:
	match direction:
		Direction.NORTH: return Vector2i(0, -1)
		Direction.EAST: return Vector2i(1, 0)
		Direction.SOUTH: return Vector2i(0, 1)
		Direction.WEST: return Vector2i(-1, 0)
	return Vector2i.ZERO

func _process_components(delta):
	for comp in components:
		var port_offset = _get_port_offset(comp.port_direction)
		var target_pos = comp.grid_pos + port_offset

		# Check if target is valid empty space
		if target_pos.x < 0 or target_pos.x >= grid_size or target_pos.y < 0 or target_pos.y >= grid_size:
			continue
		if grid[target_pos.x][target_pos.y] != ComponentType.NONE:
			continue

		match comp.type:
			ComponentType.MANA_GENERATOR:
				# Output mana to the port direction
				mana_grid[target_pos.x][target_pos.y] += comp.mana_output * delta

			ComponentType.POINT_CONVERTER:
				# Consume mana from port direction, generate points
				var available = mana_grid[target_pos.x][target_pos.y]
				var consumed = min(available, comp.mana_consumption * delta)
				mana_grid[target_pos.x][target_pos.y] -= consumed
				points += consumed * 10.0

			ComponentType.MANA_AMPLIFIER:
				var back_dir = (comp.port_direction + 2) % 4
				var back_offset = _get_port_offset(back_dir)
				var back_pos = comp.grid_pos + back_offset
				if back_pos.x < 0 or back_pos.x >= grid_size or back_pos.y < 0 or back_pos.y >= grid_size:
					continue
				if grid[back_pos.x][back_pos.y] != ComponentType.NONE:
					continue
				var available = mana_grid[back_pos.x][back_pos.y]
				var consumed = min(available, comp.mana_consumption * delta)
				mana_grid[back_pos.x][back_pos.y] -= consumed
				if grid[target_pos.x][target_pos.y] == ComponentType.NONE:
					mana_grid[target_pos.x][target_pos.y] += consumed * 3.0

func _get_grid_origin() -> Vector2:
	var total_size = grid_size * cell_size
	return (size - Vector2(total_size, total_size)) / 2 + Vector2(0, 40)

func _draw():
	var shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * screen_shake * 10.0
	var origin = _get_grid_origin() + shake_offset

	var total_mana = _get_total_mana()
	var mana_ratio = total_mana / overheat_threshold
	var mana_color = Color.WHITE.lerp(Color.RED, clamp(mana_ratio, 0, 1))

	draw_string(ThemeDB.fallback_font, Vector2(20, 30), "Points: %.0f  (+%.1f/s)  |  Mana: %.1f / %.0f" % [points, points_per_second, total_mana, overheat_threshold], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, mana_color)

	# Draw component selection
	var comp_names = ["Empty", "Generator", "Converter", "Amplifier", "Wall"]
	for i in range(5):
		var x = 20 + i * 100
		var color = Color.GREEN if i == selected_component_type else Color.GRAY
		draw_rect(Rect2(x, 50, 90, 30), color, false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(x + 5, 72), "%d: %s" % [i + 1, comp_names[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

	# Draw rotation indicator
	var dir_names = ["North ^", "East >", "South v", "West <"]
	draw_string(ThemeDB.fallback_font, Vector2(500, 72), "Rotation (R): %s" % dir_names[placement_rotation], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.CYAN)

	# Draw grid cells
	for x in range(grid_size):
		for y in range(grid_size):
			var cell_rect = Rect2(origin + Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))

			# Background based on mana level
			var mana_level = mana_grid[x][y]
			var bg_color = Color(0.1, 0.1, 0.3 + min(mana_level * 0.1, 0.5))
			draw_rect(cell_rect, bg_color)

			# Draw mana amount if empty
			if grid[x][y] == ComponentType.NONE:
				if mana_level > 0.01:
					draw_string(ThemeDB.fallback_font, cell_rect.position + Vector2(5, 50), "%.1f" % mana_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 1.0))

			# Grid lines
			draw_rect(cell_rect, Color.DARK_GRAY, false, 1.0)

			# Highlight hovered cell
			if Vector2i(x, y) == hovered_cell:
				draw_rect(cell_rect, Color(1, 1, 1, 0.3), true)

	# Draw components
	for comp in components:
		_draw_component(comp, origin)

	# Draw particles
	for p in explosion_particles:
		var alpha = p.life
		var particle_color = p.color
		particle_color.a = alpha
		draw_circle(p.pos + shake_offset, 4 + (1.0 - alpha) * 6, particle_color)

	# Draw flash overlay
	if flash_alpha > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash_alpha * 0.5))

func _draw_component(comp: Component, origin: Vector2):
	var cell_pos = origin + Vector2(comp.grid_pos.x * cell_size, comp.grid_pos.y * cell_size)
	var center = cell_pos + Vector2(cell_size / 2, cell_size / 2)

	# Component body
	var body_size = cell_size * 0.7
	var body_rect = Rect2(center - Vector2(body_size / 2, body_size / 2), Vector2(body_size, body_size))

	var color: Color
	match comp.type:
		ComponentType.MANA_GENERATOR:
			color = Color.BLUE
		ComponentType.POINT_CONVERTER:
			color = Color.GOLD
		ComponentType.MANA_AMPLIFIER:
			color = Color.PURPLE
		ComponentType.WALL:
			color = Color.DIM_GRAY

	draw_rect(body_rect, color)
	draw_rect(body_rect, Color.WHITE, false, 2.0)

	# Wall has no port, just draw a simple block
	if comp.type == ComponentType.WALL:
		# draw_string(ThemeDB.fallback_font, center - Vector2(20, -5), "WALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		return

	# Draw port indicator (arrow showing direction)
	var port_offset = _get_port_offset(comp.port_direction)
	var arrow_start = center
	var arrow_end = center + Vector2(port_offset.x, port_offset.y) * (cell_size * 0.4)
	draw_line(arrow_start, arrow_end, Color.WHITE, 3.0)

	# Arrow head
	var arrow_dir = (arrow_end - arrow_start).normalized()
	var perp = Vector2(-arrow_dir.y, arrow_dir.x)
	draw_line(arrow_end, arrow_end - arrow_dir * 10 + perp * 6, Color.WHITE, 2.0)
	draw_line(arrow_end, arrow_end - arrow_dir * 10 - perp * 6, Color.WHITE, 2.0)

	# Type label
	var label: String
	match comp.type:
		ComponentType.MANA_GENERATOR: label = "GEN"
		ComponentType.POINT_CONVERTER: label = "PTS"
		ComponentType.MANA_AMPLIFIER: label = "AMP"
	draw_string(ThemeDB.fallback_font, center - Vector2(15, -5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _input(event):
	if event is InputEventMouseMotion:
		var origin = _get_grid_origin()
		var local_pos = event.position - origin
		var gx = int(local_pos.x / cell_size)
		var gy = int(local_pos.y / cell_size)

		if gx >= 0 and gx < grid_size and gy >= 0 and gy < grid_size:
			hovered_cell = Vector2i(gx, gy)
		else:
			hovered_cell = Vector2i(-1, -1)

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if hovered_cell.x >= 0:
				_place_component(hovered_cell)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if hovered_cell.x >= 0:
				_remove_component(hovered_cell)

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: selected_component_type = 0
			KEY_2: selected_component_type = 1
			KEY_3: selected_component_type = 2
			KEY_4: selected_component_type = 3
			KEY_5: selected_component_type = 4
			KEY_R: placement_rotation = (placement_rotation + 1) % 4
			KEY_BACKSLASH: get_tree().reload_current_scene()

func _place_component(pos: Vector2i):
	# Empty mode removes components
	if selected_component_type == ComponentType.NONE:
		_remove_component(pos)
		return

	# Check if cell is already occupied
	if grid[pos.x][pos.y] != ComponentType.NONE:
		return

	var comp = Component.new(selected_component_type, pos, placement_rotation)
	components.append(comp)
	grid[pos.x][pos.y] = selected_component_type

func _remove_component(pos: Vector2i):
	if grid[pos.x][pos.y] == ComponentType.NONE:
		return

	grid[pos.x][pos.y] = ComponentType.NONE

	# Find and remove the component
	for i in range(components.size() - 1, -1, -1):
		if components[i].grid_pos == pos:
			components.remove_at(i)
			break
