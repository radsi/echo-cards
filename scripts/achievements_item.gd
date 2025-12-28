extends Button

@onready var InterrogationImage := preload("res://items/interrogation.png")
@export var item_id: String

func set_locked() -> void:
	var cfg := ConfigFile.new()
	var unlocked_items: Array = []

	if FileAccess.file_exists("user://save.cfg"):
		cfg.load("user://save.cfg")
		unlocked_items = cfg.get_value("unlocks", "items", [])

	if not unlocked_items.has(item_id):
		icon = InterrogationImage
		get_child(0).text = "???"
		get_child(1).text = globals.items[item_id].reason
		globals.change_text(get_child(2), "???")
