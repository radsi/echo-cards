extends Node

@onready var GameOver: VBoxContainer = $HBoxContainer/VBoxContainer
@onready var BGs: Array[Sprite2D] = [$Background1, $Background2] 

func _ready() -> void:
	var labels: Array[Label] = []
	_collect_labels(self, labels)
	
	for i in range(labels.size()):
		_animate_label(labels[i], i)
	
	if globals.inventory.size() > 0:
		var grid := get_tree().get_first_node_in_group("grid") as GridContainer

		for item_id in globals.inventory:
			for item in globals.inventory[item_id]:
				var stats = item[0]
				var effects = item[1]

				for i in range(stats.size()):
					globals.change_stat_text_by_id(stats[i])

				globals.add_item_by_id(item_id, grid)
	
	
	if is_instance_valid(GameOver):
		GameOver.get_child(1).text = "Cash: " + str(globals.cash)
		GameOver.get_child(2).text = "Fee: " + str(globals.current_fee)
		GameOver.get_child(3).text = "Luck: " + str(globals.luck)
		GameOver.get_child(4).text = "Discards: " + str(globals.discards)
		GameOver.get_child(5).text = "Max streak: " + str(globals.max_streak)
		$RestartButton.pressed.connect(_on_restart_button_pressed)
		
func _process(delta: float) -> void:
	if not is_instance_valid(BGs[0]): return
	
	BGs[0].position.y += 0.5
	BGs[1].position.y += 0.5
	
	for bg in BGs:
		if bg.position.y >= 1860:
			bg.position.y = -1260

func _collect_labels(node: Node, out: Array[Label]) -> void:
	if node is Label and not node.name.contains("shadow"):
		out.append(node)
	for c in node.get_children():
		_collect_labels(c, out)

func _animate_label(label: Label, index: int) -> void:
	await get_tree().process_frame

	var base_y := label.position.y
	var offset := -10
	var duration := 1.0
	var delay := index * 0.1 + 0.2

	await get_tree().create_timer(delay).timeout

	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(
		label,
		"position:y",
		base_y + offset,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		label,
		"position:y",
		base_y,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_restart_button_pressed():
	globals.luck = 1
	globals.cash = 100
	globals.discards = 0
	globals.max_streak = 0
	globals.streak = 0
	globals.inventory.clear()
	globals.cash_gain = 20
	globals.current_fee = 50
	globals.load_scene_with_transition($TransitionBG, "res://game.tscn")


func _on_play_button_pressed() -> void:
	$PlayButton.button_mask = MOUSE_BUTTON_NONE
	
	var tween := create_tween()
	var tween2 := create_tween()

	tween.tween_property(
		$PlayButton,
		"position",
		$PlayButton.position + Vector2(-100, 0),
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween2.tween_property(
		$PlayButton,
		"rotation_degrees",
		-20,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var tween3 := create_tween()
	var tween4 := create_tween()

	tween3.tween_property(
		$KD,
		"position",
		$KD.position + Vector2(100, 0),
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween4.tween_property(
		$KD,
		"rotation_degrees",
		20,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween4.finished.connect(func(): globals.load_scene_with_transition($TransitionBG, "res://game.tscn"))
