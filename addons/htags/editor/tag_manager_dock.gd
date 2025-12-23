@tool
extends Control

var tree: Tree
var add_button: Button
var remove_button: Button
var search_box: LineEdit

func _ready() -> void:
	_build_ui()
	_refresh_tree()

	# Connect to tag system changes
	await get_tree().process_frame
	if HTags:
		HTags.tags_changed.connect(_refresh_tree)

func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var label = Label.new()
	label.text = "HTags"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	add_button = Button.new()
	add_button.text = "+"
	add_button.tooltip_text = "Add new tag"
	add_button.pressed.connect(_on_add_pressed)
	header.add_child(add_button)

	remove_button = Button.new()
	remove_button.text = "-"
	remove_button.tooltip_text = "Remove selected tag"
	remove_button.disabled = true
	remove_button.pressed.connect(_on_remove_pressed)
	header.add_child(remove_button)

	# Search
	search_box = LineEdit.new()
	search_box.placeholder_text = "Search tags..."
	search_box.clear_button_enabled = true
	search_box.text_changed.connect(_on_search_changed)
	vbox.add_child(search_box)

	# Tree
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.item_selected.connect(_on_item_selected)
	tree.item_activated.connect(_on_item_activated)
	vbox.add_child(tree)

	# Info label
	var info = Label.new()
	info.text = "Double-click to copy tag"
	info.add_theme_font_size_override("font_size", 11)
	info.modulate.a = 0.6
	vbox.add_child(info)

func _refresh_tree() -> void:
	if not tree:
		return

	tree.clear()
	var root = tree.create_item()
	tree.hide_root = true

	if not HTags:
		return

	var filter = search_box.text.to_lower() if search_box else ""
	var tags = HTags.get_all_tags()

	# Build tree structure
	var items: Dictionary = {}

	for tag in tags:
		if filter and filter not in tag.to_lower():
			continue

		var parts = tag.split(".")
		var parent_item = root
		var current_path = ""

		for i in range(parts.size()):
			if current_path.is_empty():
				current_path = parts[i]
			else:
				current_path = current_path + "." + parts[i]

			if current_path in items:
				parent_item = items[current_path]
			else:
				var item = tree.create_item(parent_item)
				item.set_text(0, parts[i])
				item.set_metadata(0, current_path)

				# Show full path as tooltip
				item.set_tooltip_text(0, current_path)

				# Style registered tags differently
				if HTags.is_registered(current_path):
					var desc = HTags.get_tag_description(current_path)
					if desc:
						item.set_tooltip_text(0, current_path + "\n" + desc)

				items[current_path] = item
				parent_item = item

func _on_add_pressed() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Add HTag"
	dialog.ok_button_text = "Add"

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	dialog.add_child(vbox)

	var tag_label = Label.new()
	tag_label.text = "Tag (use dots for hierarchy):"
	vbox.add_child(tag_label)

	var tag_input = LineEdit.new()
	tag_input.placeholder_text = "Character.Enemy.Boss"
	tag_input.custom_minimum_size.x = 250
	vbox.add_child(tag_input)

	var desc_label = Label.new()
	desc_label.text = "Description (optional):"
	vbox.add_child(desc_label)

	var desc_input = LineEdit.new()
	desc_input.placeholder_text = "A powerful enemy boss character"
	vbox.add_child(desc_input)

	dialog.confirmed.connect(func():
		var tag = tag_input.text.strip_edges()
		if tag and HTags:
			HTags.register_tag(tag, desc_input.text.strip_edges())
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()
	tag_input.grab_focus()

func _on_remove_pressed() -> void:
	var selected = tree.get_selected()
	if not selected:
		return

	var tag = selected.get_metadata(0)

	# Confirm deletion
	var dialog = ConfirmationDialog.new()
	dialog.title = "Remove Tag"
	dialog.dialog_text = "Remove '%s' and all child tags?" % tag
	dialog.confirmed.connect(func():
		if HTags:
			HTags.unregister_tag(tag)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()

func _on_search_changed(_text: String) -> void:
	_refresh_tree()

func _on_item_selected() -> void:
	remove_button.disabled = tree.get_selected() == null

func _on_item_activated() -> void:
	var selected = tree.get_selected()
	if selected:
		var tag = selected.get_metadata(0)
		DisplayServer.clipboard_set(tag)

		# Brief visual feedback
		selected.set_custom_color(0, Color.GREEN)
		await get_tree().create_timer(0.3).timeout
		selected.clear_custom_color(0)
