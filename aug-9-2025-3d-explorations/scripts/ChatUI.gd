extends Control

@onready var chat_log: RichTextLabel = $VBoxContainer/ChatLog
@onready var chat_input: LineEdit = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_btn: Button = $VBoxContainer/HBoxContainer/SendButton

func _ready():
	var mm = get_node("/root/MultiplayerManager")
	mm.chat_message.connect(_on_chat_message)
	send_btn.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_text_submitted)

func _on_chat_message(sender_id: int, text: String):
	chat_log.append_text("[b]%s:[/b] %s\n" % [sender_id, text])
	chat_log.scroll_to_line(chat_log.get_line_count() - 1)

func _on_send_pressed():
	_send_chat()

func _on_text_submitted(_t):
	_send_chat()

func _send_chat():
	var text = chat_input.text
	if text.strip_edges() == "": return
	var mm = get_node("/root/MultiplayerManager")
	mm.send_chat(text)
	chat_input.text = ""
	chat_input.grab_focus()
