@tool
extends Control

@export var set_curve: bool:
  set(value):
    doit()

func doit() -> void:
  var polygon: Polygon2D = %"green-lake-boundary"

  var p0 := polygon.polygon[0]
  # reposition polygon to origin
  for i in polygon.polygon.size():
    polygon.polygon[i] = polygon.polygon[i] - p0

  var path: Path2D = %Path2D
  var curve := Curve2D.new()
  for point in polygon.polygon:
    curve.add_point(point - p0)
  path.curve = curve
  print("Converted ", polygon.polygon.size(), " polygon points to Path2D curve")

func _ready() -> void:
  pass
