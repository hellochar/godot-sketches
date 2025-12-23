@tool
class_name TagPickerDialog
extends Window

signal tag_selected(tag: String)

var tree: Tree
var search: LineEdit
var selected_label: Label

func _init() -> void:
	title = "Select Gameplay Tag"
	size = Vector2i(350, 450)
	transient = true
	exclusive = true

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Search box
	search = LineEdit.new()
	search.placeholder_text = "Filter tags..."
	search.clear_button_enabled = true
	search.text_changed.connect(_on_search_changed)
	vbox.add_child(search)

	# Tree
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.item_selected.connect(_on_item_selected)
	tree.item_activated.connect(_on_item_activated)
	vbox.add_child(tree)

	# Selected tag display
	selected_label = Label.new()
	selected_label.text = "Selected: (none)"
	selected_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(selected_label)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	vbox.add_child(button_row)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(spacer)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_on_cancel)
	button_row.add_child(cancel_btn)

	var select_btn = Button.new()
	select_btn.text = "Select"
	select_btn.pressed.connect(_on_select)
	button_row.add_child(select_btn)

	close_requested.connect(_on_cancel)

func _ready() -> void:
	_refresh_tree()
	search.grab_focus()

func _on_search_changed(_text: String) -> void:
	_refresh_tree()

func _refresh_tree() -> void:
	tree.clear()
	var root = tree.create_item()
	tree.hide_root = true

	if not GameplayTags:
		var item = tree.create_item(root)
		item.set_text(0, "(GameplayTags not loaded)")
		return

	var filter = search.text.to_lower()
	var items: Dictionary = {}
	var all_tags = GameplayTags.get_all_tags()

	if all_tags.is_empty():
		var item = tree.create_item(root)
		item.set_text(0, "(No tags registered)")
		item.set_selectable(0, false)
		return

	for tag in all_tags:
		if filter and filter not in tag.to_lower():
			continue

		var parts = tag.split(".")
		var parent = root
		var path = ""

		for i in range(parts.size()):
			if path.is_empty():
				path = parts[i]
			else:
				path = path + "." + parts[i]

			if path not in items:
				var item = tree.create_item(parent)
				item.set_text(0, parts[i])
				item.set_metadata(0, path)
				item.set_tooltip_text(0, path)
				items[path] = item
			parent = items[path]

func _on_item_selected() -> void:
	var selected = tree.get_selected()
	if selected:
		var tag = selected.get_metadata(0)
		if tag:
			selected_label.text = "Selected: " + tag

func _on_item_activated() -> void:
	_on_select()

func _on_select() -> void:
	var selected = tree.get_selected()
	if selected:
		var tag = selected.get_metadata(0)
		if tag:
			tag_selected.emit(tag)
	queue_free()

func _on_cancel() -> void:
	queue_free()
