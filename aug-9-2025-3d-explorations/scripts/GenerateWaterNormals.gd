@tool
extends EditorScript

## Generates seamless tiling water normal maps procedurally and saves them under res://aug-9-2025/textures/.
## Run from the Script panel (File > Run) or the triangle "Run" button when this script is open.

const SIZE := 512
const OUTPUT_DIR := "res://aug-9-2025/textures"

func _run() -> void:
	print("[WaterNormals] Generating tiling water normal maps...")
	_ensure_output_dir()

	var ok1 := _generate_normal_map(
		SIZE,
		[
			{"amp": 0.35, "kx": 2, "ky": 1},
			{"amp": 0.25, "kx": 3, "ky": 4},
			{"amp": 0.15, "kx": 5, "ky": 2},
			{"amp": 0.12, "kx": 1, "ky": 3},
		],
		1.2,
		OUTPUT_DIR + "/water_normal_1.png"
	)

	var ok2 := _generate_normal_map(
		SIZE,
		[
			{"amp": 0.30, "kx": 4, "ky": 2},
			{"amp": 0.22, "kx": 6, "ky": 3},
			{"amp": 0.14, "kx": 7, "ky": 5},
			{"amp": 0.10, "kx": 2, "ky": 6},
		],
		1.0,
		OUTPUT_DIR + "/water_normal_2.png"
	)

	if ok1 and ok2:
		print("[WaterNormals] Done. Saved: \n  - %s\n  - %s" % [OUTPUT_DIR + "/water_normal_1.png", OUTPUT_DIR + "/water_normal_2.png"]) 
		print("Assign them to your water material uniforms normal_map_1 and normal_map_2.")
	else:
		push_warning("[WaterNormals] One or more outputs failed. Check the console for errors.")


func _ensure_output_dir() -> void:
	var root := DirAccess.open("res://aug-9-2025/")
	if root == null:
		push_error("Failed to open res://aug-9-2025/ for writing")
		return
	if not root.dir_exists("textures"):
		var err := root.make_dir("textures")
		if err != OK:
			push_error("Failed to create output dir: %s (err %d)" % [OUTPUT_DIR, err])


## Generate a seamless normal map from a sum of tileable sine waves.
## Waves are defined by integer cycles (kx, ky), which guarantees periodicity across the tile.
func _generate_normal_map(size: int, waves: Array, normal_strength: float, out_path: String) -> bool:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Precompute 2*pi
	var two_pi := PI * 2.0

	# For each pixel, compute height H(u,v) and its gradient analytically.
	for y in range(size):
		var v := float(y) / float(size)
		for x in range(size):
			var u := float(x) / float(size)

			var dHx := 0.0
			var dHy := 0.0

			# H(u,v) = sum_i amp_i * sin(2*pi*(kx_i*u + ky_i*v))
			# dH/du = sum_i amp_i * cos(phase) * 2*pi*kx_i
			# dH/dv = sum_i amp_i * cos(phase) * 2*pi*ky_i
			for w in waves:
				var amp: float = w["amp"]
				var kx: float = float(w["kx"])
				var ky: float = float(w["ky"])
				var phase := two_pi * (kx * u + ky * v)
				var c := cos(phase)
				dHx += amp * c * two_pi * kx
				dHy += amp * c * two_pi * ky

			# Convert gradient to normal (object space) assuming +Y up
			var nx: float = -dHx * normal_strength
			var ny: float = 1.0
			var nz: float = -dHy * normal_strength
			var nlen: float = sqrt(nx * nx + ny * ny + nz * nz)
			if nlen > 0.0:
				nx /= nlen
				ny /= nlen
				nz /= nlen

			# Pack to 0..1 range (XYZ)
			var r: float = clamp(nx * 0.5 + 0.5, 0.0, 1.0)
			var g: float = clamp(ny * 0.5 + 0.5, 0.0, 1.0)
			var b: float = clamp(nz * 0.5 + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(r, g, b, 1.0))

	var err := img.save_png(out_path)
	if err != OK:
		push_error("Failed to save %s (err %d)" % [out_path, err])
		return false
	return true
