extends VBoxContainer

@onready var ItemPrefab = preload("res://prefabs/achv_item_prefab.tscn")

func _ready() -> void:
	for item_id in globals.items:
		var new_item: Button = ItemPrefab.instantiate()
		add_child(new_item)
		
		new_item.icon = load("res://items/%s.png" % item_id)
		new_item.item_id = item_id
		new_item.get_child(0).text = item_id.capitalize()
		new_item.get_child(1).text = globals.items[item_id].description
		globals.change_text(new_item.get_child(2), str(int(globals.items[item_id].price)))
		
		new_item.set_locked()
