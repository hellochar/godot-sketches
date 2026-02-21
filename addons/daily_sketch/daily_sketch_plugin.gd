@tool
extends EditorPlugin

func _enter_tree() -> void:
  add_tool_menu_item("Create Daily Sketch", _create_daily_sketch)
  var command_palette := EditorInterface.get_command_palette()
  command_palette.add_command("Create Daily Sketch", "daily_sketch/create", _create_daily_sketch)

func _exit_tree() -> void:
  remove_tool_menu_item("Create Daily Sketch")
  var command_palette := EditorInterface.get_command_palette()
  command_palette.remove_command("daily_sketch/create")

func _create_daily_sketch() -> void:
  var date := Time.get_date_dict_from_system()
  var month_names := ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
  var month: String = month_names[date.month - 1]
  var day := str(date.day)
  var year := str(date.year)

  var base_name := "%s_%s_%s" % [month, day, year]
  var folder_name := base_name
  var dir := DirAccess.open("res://")

  if dir.dir_exists(folder_name):
    var suffix := "b"
    while dir.dir_exists(base_name + suffix):
      suffix = String.chr(suffix.unicode_at(0) + 1)
    folder_name = base_name + suffix

  var folder_path := "res://%s" % folder_name
  var script_name := "%s.gd" % folder_name
  var scene_name := "%s.tscn" % folder_name

  dir.make_dir(folder_name)

  var script_content := """extends Node

func _ready() -> void:
  pass

func _process(_delta: float) -> void:
  pass
"""

  var script_file := FileAccess.open("%s/%s" % [folder_path, script_name], FileAccess.WRITE)
  script_file.store_string(script_content)
  script_file.close()

  var script_uid := ResourceUID.id_to_text(ResourceUID.create_id())

  var scene_content := """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" uid="%s" path="%s/%s" id="1_script"]

[node name="Control" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")
""" % [script_uid, folder_path, script_name]

  var scene_file := FileAccess.open("%s/%s" % [folder_path, scene_name], FileAccess.WRITE)
  scene_file.store_string(scene_content)
  scene_file.close()

  EditorInterface.get_resource_filesystem().scan()

  var scene_path := "%s/%s" % [folder_path, scene_name]
  EditorInterface.open_scene_from_path(scene_path)
  EditorInterface.edit_script(load("%s/%s" % [folder_path, script_name]))

  print("Created daily sketch: %s" % folder_path)
