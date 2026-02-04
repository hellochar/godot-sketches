@tool
extends Control

func _ready() -> void:
  if Engine.is_editor_hint():
    var polygon = %"green-lake-boundary"
    var path = %Path2D
    var curve = Curve2D.new()
    for point in polygon.polygon:
      curve.add_point(point)
    path.curve = curve
    print("Converted ", polygon.polygon.size(), " polygon points to Path2D curve")

func _process(delta: float) -> void:
  pass
