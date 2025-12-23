extends ColorRect

@onready var ShopButton: Button = $ShopButton
var shop_open: bool = false

func _ready():
	position.x = -406
	globals.VBoxItems = $VBoxContainer
	globals.GridItems = $"../RightPanel/GridContainer"
	globals.VBoxStats = $"../RightPanel/VBoxContainer"
	globals.VBoxItems.visible = false
	globals.RoundLabel = $"../../PlayerCards/RoundsLabel"

	for btn: Button in globals.VBoxItems.get_children():
		if btn.name.contains("Refresh"): continue
		btn.pressed.connect(_on_item_pressed.bind(btn))

	globals.generate_shop()

func _on_item_pressed(button):
	buy_item(button)

func buy_item(btn: Button):
	if globals.get_item_amount() >= 12: return
	
	if btn.price > globals.cash:
		if not globals.tween_in_process.has(globals.VBoxStats.get_child(1)):
			globals.tween_in_process.append(globals.VBoxStats.get_child(1))
			globals.VBoxStats.get_child(1).self_modulate = Color.RED
			var twn := create_tween()
			twn.tween_property(globals.VBoxStats.get_child(1), 'self_modulate', Color.WHITE, 1)
			twn.finished.connect(func callback() -> void: globals.tween_in_process.erase(globals.VBoxStats.get_child(1)))
		return
	
	btn.visible = false
	
	globals.add_cash(-btn.price)
	globals.add_item(btn)


func _on_refresh_button_pressed() -> void:
	if globals.refresh_cost > globals.cash:
		if not globals.tween_in_process.has(globals.VBoxStats.get_child(1)):
			globals.tween_in_process.append(globals.VBoxStats.get_child(1))
			globals.VBoxStats.get_child(1).self_modulate = Color.RED
			var twn := create_tween()
			twn.tween_property(globals.VBoxStats.get_child(1), 'self_modulate', Color.WHITE, 1)
			twn.finished.connect(func callback() -> void: globals.tween_in_process.erase(globals.VBoxStats.get_child(1)))
		return
		
	globals.add_cash(-globals.refresh_cost)
	globals.refresh_cost += 25
	globals.change_text(globals.VBoxItems.get_child(6).get_child(1), str(globals.refresh_cost))

	globals.generate_shop()

func open_shop(open: bool) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property($".", "position", (Vector2(0,0) if open else Vector2(-406, 0)), 1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _on_shop_button_pressed() -> void:
	shop_open = !shop_open
	ShopButton.text = "<" if shop_open else ">"
	open_shop(shop_open)
	if !shop_open:
		await get_tree().create_timer(1).timeout
	globals.VBoxItems.visible = !globals.VBoxItems.visible
