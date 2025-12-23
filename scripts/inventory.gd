extends GridContainer

@onready var VBoxItems = $"../../LeftPanel/VBoxContainer"
@onready var VBoxStats = $"../VBoxContainer"

func _ready():
	for button in get_children():
		button.pressed.connect(_on_item_pressed.bind(button))
		
func _on_item_pressed(button):
	globals.remove_item(button)
