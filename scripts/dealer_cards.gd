extends CanvasGroup

@export var max_angle: float = 30.0
@export var radius: float = 250.0
@export var card_spacing: float = 1.0

@onready var center: Node2D = $Center
@onready var ScoreLabel: Label = $ScoreLabel
@onready var PlayerCards: CanvasGroup = $"../PlayerCards"
@onready var VBoxStats = $"../Control/RightPanel/VBoxContainer"


var dark_mode: bool = false

const VALUES := ["A","1","2","3","4","5","6","7","8","9","10","J","Q","K"]
const SUITS := ["C","D","H","P"]
var deck: Array[String] = []
var dealer_deck: Array[String] = []
var dealer_cards: Array[Sprite2D] = []
var show_dealer: bool = false

signal signal_restartgame

func _ready() -> void:
	await get_tree().process_frame
	globals.change_text(globals.RoundLabel, str(globals.current_round) + "/" + str(globals.max_round))
	spawn_cards(2)

func _generate_deck():
	deck.clear()
	for v in VALUES:
		for s in SUITS:
			deck.append(v + "-" + s)

func _get_card_value(card: String, current_total: int) -> int:
	if card.begins_with("J") or card.begins_with("Q") or card.begins_with("K"):
		return 10
	elif card.begins_with("A"):
		return 11 if current_total + 11 <= globals.max_blackjack else 1
	else:
		return card.split("-")[0].to_int()

func spawn_cards(amount: int, show_dealer: bool = false) -> void:
	if deck.is_empty():
		_generate_deck()
	
	deck.shuffle()
	
	for i in range(min(amount, deck.size())):
		dealer_deck.append(deck[i])
		var tex_path := "res://cards/" + ("dark" if dark_mode else "light") + "/" + deck[i] + ".png"
		var tex := load(tex_path) as Texture2D
		if tex == null:
			continue
		
		var card := Sprite2D.new()
		card.texture = tex
		card.position = Vector2(2000, center.position.y)
		card.centered = true
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(card)
		dealer_cards.append(card)

	for j in range(dealer_cards.size()):
		if j == 1:
			var back_path := "res://cards/" + ("dark" if dark_mode else "light") + "/BACK.png"
			var tex := load(back_path) as Texture2D
			if tex:
				dealer_cards[j].texture = tex
	
	_update_score(show_dealer)
	arrange_cards(true)
	
func _update_score(show_dealer: bool):
	globals.dealer_score = 0
	var cards_to_count := dealer_deck
	if not show_dealer:
		cards_to_count = [dealer_deck[0]]

	for card in cards_to_count:
		globals.dealer_score += _get_card_value(card, globals.dealer_score)

	var dealer_text := ""
	if not show_dealer:
		dealer_text = " + ?"
	else:
		if show_dealer and dealer_cards.size() > 0:
			for i in range(dealer_cards.size()):
				var tex_path := "res://cards/" + ("dark" if dark_mode else "light") + "/" + dealer_deck[i] + ".png"
				var tex := load(tex_path)
				if tex:
					dealer_cards[i].texture = tex

	globals.change_text(ScoreLabel, str(globals.dealer_score) + dealer_text)
	
	if globals.dealer_score > globals.max_blackjack:
		ScoreLabel.self_modulate = Color.DARK_RED
	elif globals.dealer_score == globals.max_blackjack:
		ScoreLabel.self_modulate = Color.WEB_GREEN

func arrange_cards(animated: bool = false):
	var count := dealer_cards.size()
	if count == 0:
		return

	var mid := float(count - 1) * 0.5

	for i in range(count):
		var t: float = (float(i) - mid) / max(mid, 1.0)
		var angle: float = lerp(-max_angle, max_angle, (t + 1.0) * 0.5)
		var rad := deg_to_rad(angle)

		var target_pos := center.position + Vector2(
			sin(rad) * radius * card_spacing,
			cos(rad) * radius * -0.25 + 120
		)

		var target_rot := -rad

		var card := dealer_cards[i]
		card.z_index = i

		if animated:
			var twn = create_tween()
			twn.tween_property(card, "position", target_pos, 0.3)
			twn.tween_property(card, "rotation", target_rot, 0.3)
		else:
			card.position = target_pos
			card.rotation = target_rot


func restart_game():
	var cash_win := globals.cash_gain * 2 if PlayerCards.player_cards.size() == 2 else globals.cash_gain
	var win := false
	var draw := false

	if globals.player_score > globals.max_blackjack:
		win = false
	elif globals.dealer_score > globals.max_blackjack:
		win = true
	elif globals.player_score > globals.dealer_score:
		win = true
	elif globals.player_score == globals.dealer_score:
		draw = true
	else:
		win = false

	if win:
		globals.streak += 1
		globals.add_cash(cash_win + globals.streak * 2 + PlayerCards.dark_count * 10)
	elif not draw:
		globals.streak = 0
	elif draw:
		globals.add_cash(cash_win / 2)

	if globals.streak > globals.max_streak:
		globals.max_streak = globals.streak

	globals.change_stat_text("streak")

	globals.current_round += 1
	if globals.current_round > globals.max_round:
		globals.load_scene_with_transition($"../TransitionBG", "res://payment.tscn")
		return
	globals.change_text(globals.RoundLabel, str(globals.current_round) + "/" + str(globals.max_round))
		
	for c in dealer_cards:
		if is_instance_valid(c):
			c.queue_free()

	dealer_cards.clear()
	dealer_deck.clear()
	deck.clear()
	globals.dealer_score = 0
	globals.change_text(ScoreLabel, "0")
	ScoreLabel.self_modulate = Color.WHITE

	spawn_cards(2)
	globals.ending_game = false

func show_cards():
	_update_score(true)
	
	if globals.player_score <= globals.max_blackjack:
		while globals.player_score > globals.dealer_score:
			await get_tree().create_timer(1 if globals.dealer_score < 16 else 1.5).timeout
			spawn_cards(1, true)
			_update_score(true)

	await get_tree().create_timer(1.5).timeout
	
	restart_game()
	emit_signal("signal_restartgame")

func _on_stand_button_pressed() -> void:
	if globals.ending_game or $"..".rotate_item: return
	globals.ending_game = true
	show_cards()
