extends PathFollow3D

func _process(delta):
	progress_ratio += delta * 0.1
