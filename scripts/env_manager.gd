extends Node

@onready var GameOver: VBoxContainer = $HBoxContainer/VBoxContainer

func _ready() -> void:
	var labels: Array[Label] = []
	_collect_labels(self, labels)
	
	for i in range(labels.size()):
		_animate_label(labels[i], i)
	
	if globals.inventory.size() > 0:
		var grid = get_tree().get_first_node_in_group("grid") as GridContainer
		for item_id in globals.inventory:
			var stats = globals.inventory[item_id][0]
			var effects = globals.inventory[item_id][1]
	
			for i in range(stats.size()):
				globals.change_stat_text_by_id(stats[i])
			globals.add_item_by_id(item_id, grid)
	
	if is_instance_valid(GameOver):
		GameOver.get_child(1).text = "Cash: " + str(globals.cash)
		GameOver.get_child(2).text = "Fee: " + str(globals.current_fee)
		GameOver.get_child(3).text = "Luck: " + str(globals.luck)
		GameOver.get_child(4).text = "Discards: " + str(globals.discards)
		GameOver.get_child(5).text = "Max streak: " + str(globals.max_streak)

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
