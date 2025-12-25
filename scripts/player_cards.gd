extends CanvasGroup

@export var max_angle: float = 30.0
@export var radius: float = 250.0
@export var card_spacing: float = 1.0

@onready var center: Node2D = $Center
@onready var ScoreLabel: Label = $ScoreLabel
@onready var DealerCards: CanvasGroup = $"../DealerCards"
@onready var HitButton = $"../Control/HitButton"
@onready var StandButton = $"../Control/StandButton"

@onready var card_prefab := preload("res://prefabs/card.tscn")

var dark_mode: bool = false

const VALUES := ["A","1","2","3","4","5","6","7","8","9","10","J","Q","K"]
const SUITS := ["C","D","H","P"]
var deck: Array[String] = []
var player_deck: Array[String] = []
var player_cards: Array[Sprite2D] = []
var player_actions: Array[int] = []

func _ready() -> void:
	
	if not globals.first_time:
		$"../TransitionBG".position = Vector2.ZERO
		var twn = create_tween()
		twn.tween_property($"../TransitionBG", "position", Vector2(0,-1366), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		globals.first_time = false
	
	globals.used_discards = 0
	await get_tree().process_frame
	globals.change_stat_text("cash")
	globals.change_stat_text("streak")
	globals.change_stat_text("discards")
	globals.change_stat_text("luck")
	globals.ending_game = false
	restart_game()

func _generate_deck():
	deck.clear()
	for v in VALUES:
		for s in SUITS:
			deck.append(v + "-" + s)

func _get_card_value(card: String) -> int:
	if card.begins_with("J") or card.begins_with("Q") or card.begins_with("K"):
		return 10
	elif card.begins_with("A"):
		return 11 if globals.player_score + 11 <= globals.max_blackjack else 1
	else:
		return card.split("-")[0].to_int()

func spawn_cards(amount: int, first: bool = true) -> void:
	var cards_to_spawn: Array = []

	if globals.pending_21 and first:
		globals.remove_item(globals.get_item_btn("horse"))
		player_deck.clear()
		cards_to_spawn = ["A-H", "K-H"]
		player_deck.append_array(cards_to_spawn)
		HitButton.disabled = true
		HitButton.modulate.a = 0.5
	else:
		if deck.is_empty():
			_generate_deck()
		deck.shuffle()

		var weighted_deck := []
		for card in deck:
			var value := _get_card_value(card)
			var diff := globals.max_blackjack - globals.player_score
			var weight := 1.0

			var luck_factor = clamp(globals.luck / 50.0, -1.0, 1.0)

			if value <= diff:
				weight += 0.05 * value * luck_factor
			else:
				weight += 0.02 * (value - diff) * luck_factor

			weight = max(weight, 0.1)
			weighted_deck.append({"card": card, "weight": weight})

		cards_to_spawn = []
		for i in range(min(amount, weighted_deck.size())):
			var total_weight := 0.0
			for w in weighted_deck:
				total_weight += w["weight"]

			var r := randf() * total_weight
			var acc := 0.0
			for j in range(weighted_deck.size()):
				acc += weighted_deck[j]["weight"]
				if r <= acc:
					cards_to_spawn.append(weighted_deck[j]["card"])
					weighted_deck.remove_at(j)
					break

		player_deck.append_array(cards_to_spawn)

	for card_name in cards_to_spawn:
		var tex_path = "res://cards/" + ("dark" if dark_mode else "light") + "/" + card_name + ".png"
		var tex := load(tex_path) as Texture2D
		if tex == null:
			continue

		var card := card_prefab.instantiate()
		card.PlayerCards = $"."
		card.texture = tex
		card.name = card_name
		card.position = Vector2(2000, center.position.y)
		card.centered = true
		add_child(card)
		player_cards.append(card)

	_update_score()
	arrange_cards(true)

func _update_score():
	globals.player_score = 0
	for card in player_deck:
		globals.player_score += _get_card_value(card)

	globals.change_text(ScoreLabel, str(globals.player_score) + " / " + str(globals.max_blackjack))

	if globals.player_score > globals.max_blackjack:
		ScoreLabel.self_modulate = Color.DARK_RED
	elif globals.player_score == globals.max_blackjack:
		ScoreLabel.self_modulate = Color.WEB_GREEN
	else:
		ScoreLabel.self_modulate = Color.WHITE
	
	if globals.player_score > globals.max_blackjack:
		HitButton.disabled = true
		HitButton.modulate.a = 0.5

func arrange_cards(animated: bool = false):
	var count := player_cards.size()
	if count == 0:
		return

	var mid := float(count - 1) * 0.5

	for i in range(count):
		var t: float = (float(i) - mid) / max(mid, 1.0)
		var angle: float = lerp(-max_angle, max_angle, (t + 1.0) * 0.5)
		var rad := deg_to_rad(angle)

		var target_pos := center.position + Vector2(
			sin(rad) * radius * card_spacing,
			cos(rad) * radius * -0.25
		)

		var target_rot := rad

		var card := player_cards[i]
		card.z_index = i
		card.centered = true

		if animated:
			var twn = create_tween()
			twn.tween_property(card, "position", target_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			twn.tween_property(card, "rotation", target_rot, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			card.position = target_pos
			card.rotation = target_rot

func use_discard(card: Sprite2D):
	if globals.used_discards >= globals.discards or globals.ending_game: return
	globals.used_discards += 1
	player_deck.erase(card.name)
	player_cards.erase(card)
	_update_score()
	card.queue_free()
	arrange_cards(true)
	
	globals.change_stat_text("discards", true, globals.used_discards - globals.discards)
	
	if not globals.tween_in_process.has(globals.VBoxStats.get_child(3)):
		globals.tween_in_process.append(globals.VBoxStats.get_child(3))
		globals.VBoxStats.get_child(3).self_modulate = Color.RED
		var twn := create_tween()
		twn.tween_property(globals.VBoxStats.get_child(3), 'self_modulate', Color.WHITE, 1)
		twn.finished.connect(func callback() -> void: globals.tween_in_process.erase(globals.VBoxStats.get_child(3)))
	
	HitButton.disabled = false
	HitButton.modulate.a = 1

func restart_game():
	if globals.current_round > globals.max_round:
		return
		
	for c in player_cards:
		if is_instance_valid(c):
			c.queue_free()

	player_cards.clear()
	player_deck.clear()
	deck.clear()
	globals.player_score = 0
	globals.change_text(ScoreLabel, "0")
	ScoreLabel.self_modulate = Color.WHITE
	
	HitButton.disabled = false
	HitButton.modulate.a = 1

	spawn_cards(2)

func _on_hit_button_pressed() -> void:
	if globals.ending_game: return
	player_actions.append(0)
	spawn_cards(1, false)
	$"../hit_sfx".play()

func _on_dealer_cards_signal_restartgame() -> void:
	restart_game()
