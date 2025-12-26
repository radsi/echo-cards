extends Node

var GridItems
var VBoxItems
var VBoxStats
var RoundLabel: Label

var player_score := 0
var dealer_score := 0
var max_blackjack:= 21

var cash := 100
var cash_gain: float = 20
var luck := 1
var discards := 0
var used_discards := 0
var streak := 0

var refresh_cost := 100
var max_items_shop := 4
var max_round := 6
var max_streak := 0
var current_round := 0
var ending_game := false
var pending_21 := 0
var dark_chance := 0

var current_fee := 50

var inventory := {}
var items := {}
var item_keys := []

var tween_in_process: Array[Node] = []

func _init() -> void:
	var path = "res://items_data.json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open " + path)
		return

	items = JSON.parse_string(file.get_as_text())
	file.close()

	item_keys = items.keys()

func load_scene_with_transition(transition: ColorRect, scene: String):
	var twn = create_tween()
	twn.tween_property(transition, "position", Vector2(0,0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	twn.finished.connect(func callback() -> void: get_tree().change_scene_to_file(scene))

func change_text(label: Label, new_text: String):
	label.text = new_text
	label.get_child(0).text = new_text

func change_stat_text_by_id(stat: int, use_value: bool = false, value: int = 0):
	
	if not is_instance_valid(VBoxStats): return
	
	if stat == 1:
		change_text(VBoxStats.get_child(1), " Cash: "+str(cash if not use_value else value))
	if stat == 3:
		change_text(VBoxStats.get_child(3), " Discards: "+str(discards if not use_value else value))
	if stat == 2:
		change_text(VBoxStats.get_child(2), " Luck: "+str(luck if not use_value else value))
	if stat == 4:
		change_text(VBoxStats.get_child(4), " Streak: "+str(streak if not use_value else value))
	if stat == 5:
		change_text(RoundLabel, str(current_round) + "/" + str(max_round if not use_value else value))

func change_stat_text(stat: String, use_value: bool = false, value: int = 0):
	if stat == "cash":
		change_text(VBoxStats.get_child(1), " Cash: "+str(cash if not use_value else value))
	if stat == "discards":
		change_text(VBoxStats.get_child(3), " Discards: "+str(discards if not use_value else value))
	if stat == "luck":
		change_text(VBoxStats.get_child(2), " Luck: "+str(luck if not use_value else value))
	if stat == "streak":
		change_text(VBoxStats.get_child(4), " Streak: "+str(streak if not use_value else value))
	if stat == "round":
		change_text(RoundLabel, str(current_round) + "/"+str(max_round if not use_value else value))

func add_cash(amount: int):
	cash += amount
	change_stat_text("cash")
	
	if not tween_in_process.has(VBoxStats.get_child(1)):
		tween_in_process.append(VBoxStats.get_child(1))
		VBoxStats.get_child(1).self_modulate = Color.GREEN if amount > 0 else Color.RED
		var twn := create_tween()
		twn.tween_property(VBoxStats.get_child(1), 'self_modulate', Color.WHITE, 1)
		twn.finished.connect(func callback() -> void: tween_in_process.erase(globals.VBoxStats.get_child(1)))

func get_item_amount():
	var amount := 0
	for item: Button in GridItems.get_children():
		if item.visible == true:
			amount += 1
	return amount

func get_item_btn(item_id: String, grid: GridContainer = GridItems):
	for item: Button in grid.get_children():
			if item.item_id == item_id:
				return item
	return null

func add_item_by_id(id: String, grid: GridContainer = GridItems):
	var data = items[id]
	for item: Button in grid.get_children():
		if item.visible == false:
			item.visible = true
			
			item.item_id = id
			item.price = data.price
			item.type = data.type
			for stat_v in data.stats:
				item.stats.append(int(stat_v))
			for effect_v in data.values:
				item.stats_effect.append(effect_v)
			item.icon = load("res://items/%s.png" % id)
			break

func add_item(btn: Button):
	if get_item_amount() >= 12: return
	
	if btn.type == "trinket":
		execute_trinket(btn.item_id)
	
	if btn.item_id == "D6": return
	
	inventory.get_or_add(btn.item_id, []).append([
		btn.stats.duplicate(),
		btn.stats_effect.duplicate()
	])
	
	for item: Button in GridItems.get_children():
		if item.visible == false:
			item.stats.clear()
			item.stats_effect.clear()
			item.visible = true
			item.item_id = btn.item_id
			item.price = btn.price
			item.type = btn.type
			for stat_v in btn.stats:
				item.stats.append(int(stat_v))
			for effect_v in btn.stats_effect:
				item.stats_effect.append(effect_v)
			item.icon = btn.icon
			break
	
	if btn.type == "stat":
		var index = -1
		for stat in btn.stats:
			index += 1
			
			var current_stat
			var current_effect = btn.stats_effect[index]
			var old_value
			
			if stat == 5:
				current_stat = RoundLabel
				old_value = max_round
			else:
				current_stat = VBoxStats.get_child(stat)
				old_value = int(current_stat.text)

			var new_value
			
			if is_equal_approx(current_effect, int(current_effect)):
				new_value = old_value + int(current_effect)
			else:
				new_value = int(old_value * current_effect)
			
			match stat:
				2:
					luck = new_value
				3:
					discards = new_value
				4:
					streak = new_value
				5:
					max_round = new_value
				_:
					pass
			
			change_stat_text_by_id(stat)
			if not tween_in_process.has(current_stat):
				tween_in_process.append(current_stat)
				current_stat.self_modulate = Color.GREEN if new_value > old_value else Color.RED
				var twn := create_tween()
				twn.tween_property(current_stat, 'self_modulate', Color.WHITE, 0.5)
				twn.finished.connect(func callback() -> void: tween_in_process.erase(current_stat))

func remove_item(btn: Button):
	
	if btn.type == "trinket":
		execute_trinket(btn.item_id + "_remove")
	
	if btn.type == "stat":
		var index = -1
		for stat in btn.stats:
			index += 1
			
			var current_stat
			var current_effect = btn.stats_effect[index]
			var old_value
			
			if stat == 5:
				current_stat = RoundLabel
				old_value = max_round
			else:
				current_stat = VBoxStats.get_child(stat)
				old_value = int(current_stat.text)

			var new_value
			
			if is_equal_approx(current_effect, int(current_effect)):
				new_value = old_value - int(current_effect)
			else:
				new_value = int(old_value / current_effect)
			
			match stat:
				2:
					luck = new_value
				3:
					discards = new_value
				4:
					streak = new_value
				5:
					max_round = new_value
				_:
					pass
			
			change_stat_text_by_id(stat)
			if not tween_in_process.has(current_stat):
				tween_in_process.append(current_stat)
				current_stat.self_modulate = Color.GREEN if new_value > old_value else Color.RED
				var twn := create_tween()
				twn.tween_property(current_stat, 'self_modulate', Color.WHITE, 0.5)
				twn.finished.connect(func callback() -> void: tween_in_process.erase(current_stat))

	btn.visible = false
	
	if inventory.has(btn.item_id):
		inventory[btn.item_id].pop_back()

		if inventory[btn.item_id].is_empty():
			inventory.erase(btn.item_id)

func execute_trinket(id: String):
	if has_method(id):
		call(id)

func generate_shop():
	var index := -1
	for btn: Button in VBoxItems.get_children():
		index += 1
		
		if index == max_items_shop or index > VBoxItems.get_children().size(): break
		
		if btn.name.contains("Refresh"):
			continue
		
		btn.visible = true

		var id = pick_item_by_rarity()
		var data = items[id]

		btn.item_id = id
		btn.price = data.price
		btn.type = data.type

		btn.stats.clear()
		btn.stats_effect.clear()

		for stat_v in data.stats:
			btn.stats.append(int(stat_v))
		for effect_v in data.values:
			btn.stats_effect.append(effect_v)

		btn.icon = load("res://items/%s.png" % id)

		btn.get_child(0).text = id.capitalize()
		btn.get_child(1).text = data.description
		change_text(btn.get_child(2), str(int(data.price)))

		
func pick_item_by_rarity() -> String:
	var eligible_items := []

	var min_rarity := 100 
	if luck >= 2:
		min_rarity = 100 - (luck) * 10
	else:
		min_rarity = 90

	for id in item_keys:
		if items[id].rarity >= min_rarity:
			eligible_items.append(id)

	if eligible_items.is_empty():
		var max_rarity := 0
		for id in item_keys:
			if items[id].rarity > max_rarity:
				max_rarity = items[id].rarity
		for id in item_keys:
			if items[id].rarity == max_rarity:
				eligible_items.append(id)

	var total_weight := 0.0
	var weights := {}
	for id in eligible_items:
		var weight := pow(items[id].rarity, 3)
		weights[id] = weight
		total_weight += weight

	var roll := randf() * total_weight
	var acc := 0.0
	for id in eligible_items:
		acc += weights[id]
		if roll <= acc:
			return id

	return eligible_items[0]

func D6():
	for item in GridItems.get_children():
		if item.visible == false: return
		
		var id = pick_item_by_rarity()
		
		while id == "D6":
			id = pick_item_by_rarity()
		
		var data = items[id]

		item.item_id = id
		item.price = data.price
		item.type = data.type

		item.stats.clear()
		item.stats_effect.clear()

		for stat_v in data.stats:
			item.stats.append(int(stat_v))
		for effect_v in data.values:
			item.stats_effect.append(effect_v)
		
		item.icon = load("res://items/%s.png" % id)

func horse():
	pending_21 += 1

func horse_remove():
	pending_21 -= 1

func gold():
	cash_gain *= 1.25

func gold_remove():
	cash_gain /= 1.25

func briefcase():
	max_items_shop += 1

func briefcase_remove():
	max_items_shop -= 1

func deal():
	dark_chance += 5
	
func deal_remove():
	dark_chance -= 5
