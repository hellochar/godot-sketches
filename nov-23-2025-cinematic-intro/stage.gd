extends Control

var camera_shake_intensity: float = 0.0
var camera_shake_decay: float = 0.0
var camera_original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    camera_original_position = position
    pass
    # %Dialogue.pause_typing()
    # await set_overlay_opacity(0.0, 2)
    # await 2 seoncds
    await get_tree().create_timer(2.0).timeout

    %audio.play()

    # %Dialogue.resume_typing()

func _process(delta: float) -> void:
    if camera_shake_intensity > 0:
        position = camera_original_position + Vector2(
            randf_range(-camera_shake_intensity, camera_shake_intensity),
            randf_range(-camera_shake_intensity, camera_shake_intensity)
        )
        camera_shake_intensity = lerp(camera_shake_intensity, 0.0, camera_shake_decay * delta)
    else:
        position = camera_original_position

func screen_shake(intensity: float = 10.0, decay: float = 5.0) -> void:
    camera_shake_intensity = intensity
    camera_shake_decay = decay

func set_overlay_opacity(opacity: float, duration: float) -> void:
    var tween = get_tree().create_tween()
    tween.tween_property(%Overlay, "modulate:a", opacity, duration)
    await tween.finished